"""Offline RQ3 award network, grouped-project sensitivity, and funding exposure.

Run python analysis/analyze_award_centrality.py. All inputs are audited prepared files.
The historical live centrality_results directory is never written.
"""
from collections import Counter, defaultdict
from datetime import datetime, timezone
from itertools import combinations
from pathlib import Path
import csv
import gzip
import hashlib
import json
import math
import random
from importlib.metadata import version

import igraph as ig
import numpy as np
from scipy.stats import spearmanr

ROOT = Path(__file__).resolve().parents[1] / 'data'
OUT = ROOT.parent / 'results/rq3'
METRICS = {'degree': 'degree_centrality', 'betweenness': 'betweenness_normalized',
           'eigenvector': 'eigenvector_centrality', 'award_participation': 'awards',
           'funding': 'associated_positive_award_funding_usd'}


def read(name):
    with gzip.open(ROOT / 'prepared' / (name + '.jsonl.gz'), 'rt', encoding='utf-8') as f:
        return [json.loads(line) for line in f]


def write_csv(path, rows):
    assert rows, path
    with path.open('w', newline='', encoding='utf-8-sig') as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def build_graph(ids, links, unit_field):
    index = {key: i for i, key in enumerate(ids)}
    teams = defaultdict(set)
    for link in links:
        teams[link[unit_field]].add(index[link['person_key']])
    shared = Counter()
    for team in teams.values():
        shared.update(combinations(sorted(team), 2))
    edges = sorted(shared)
    graph = ig.Graph(n=len(ids), edges=edges, directed=False)
    graph.vs['person_key'] = ids
    graph.es['shared_units'] = [shared[e] for e in edges]
    assert graph.is_simple()
    return graph


def measure_graph(graph):
    assert not graph.is_directed()
    n = graph.vcount()
    degree = graph.degree()
    between = graph.betweenness(directed=False, weights=None)
    components = graph.connected_components()
    largest = sorted(components, key=lambda c: (-len(c), min(c)))[0] if n else []
    largest_set = set(largest)
    vertex_index = {key: i for i, key in enumerate(graph.vs['person_key'])}
    eigen = [None] * n
    residual = eigenvalue = None
    if len(largest) > 1:
        subgraph = graph.induced_subgraph(largest)
        assert subgraph.is_connected()
        options = ig.ARPACKOptions()
        options.tol = 1e-12
        options.maxiter = 10000
        # igraph 1.0 rejects directed=False here even for an undirected graph.
        # The graph itself is explicitly undirected; omit the redundant flag.
        scores, eigenvalue = subgraph.eigenvector_centrality(
            weights=None, return_eigenvalue=True, arpack_options=options)
        scores = np.asarray(scores, dtype=float)
        scores /= max(scores)
        # Independently verify A*x = lambda*x from the edge list.
        ax = np.zeros(len(scores))
        for a, b in subgraph.get_edgelist():
            ax[a] += scores[b]
            ax[b] += scores[a]
        residual = float(np.linalg.norm(ax - eigenvalue * scores) /
                         max(np.linalg.norm(eigenvalue * scores), 1e-30))
        assert residual < 1e-9 and options.info == 0, 'Eigenvector convergence failed'
        for key, value in zip(subgraph.vs['person_key'], scores):
            eigen[vertex_index[key]] = float(max(0, value))
    sizes = components.sizes()
    assert sum(degree) == 2 * graph.ecount()
    assert sum(sizes) == n
    scale = 2 / ((n - 1) * (n - 2)) if n > 2 else 0
    values = [{'distinct_collaborators': degree[i],
               'degree_centrality': degree[i] / (n - 1) if n > 1 else 0,
               'betweenness_raw': between[i], 'betweenness_normalized': between[i] * scale,
               'eigenvector_centrality': eigen[i],
               'component_id': components.membership[i] + 1,
               'component_size': sizes[components.membership[i]],
               'in_largest_component': i in largest_set} for i in range(n)]
    summary = {'people': n, 'edges': graph.ecount(), 'components': len(sizes),
               'largest_component': len(largest), 'isolated_people': sum(d == 0 for d in degree),
               'positive_betweenness_people': sum(v > 0 for v in between),
               'degree_sum': sum(degree), 'component_size_sum': sum(sizes),
               'eigenvalue': eigenvalue, 'eigenvector_relative_residual': residual,
               'eigenvector_converged': residual is not None and residual < 1e-9,
               'largest_component_connected': len(largest) > 1,
               'eigenvector_scores_below_1e_12': sum(v is not None and v < 1e-12 for v in eigen),
               'repeated_edges': sum(e['shared_units'] > 1 for e in graph.es)}
    return values, summary


def funding_exposure(award_ids, awards):
    amounts = [awards[a].get('total_amount') for a in set(award_ids)]
    valid = [float(v) for v in amounts if isinstance(v, (int, float))
             and not isinstance(v, bool) and math.isfinite(v)]
    positive = [v for v in valid if v > 0]
    return {'associated_positive_award_funding_usd': round(math.fsum(positive), 2) if valid else None,
            'positive_amount_awards': len(positive), 'zero_amount_awards': sum(v == 0 for v in valid),
            'negative_amount_awards': sum(v < 0 for v in valid),
            'missing_amount_awards': len(amounts) - len(valid),
            'funding_complete': len(valid) == len(amounts) and bool(amounts)}


def score_key(value):
    # Suppress floating solver noise when assigning competition ranks.
    return round(value, 12)


def add_ranks(rows):
    top = {}
    for label, field in METRICS.items():
        eligible = [r for r in rows if r[field] is not None
                    and (label != 'funding' or r['funding_complete'])]
        ordered = sorted(eligible, key=lambda r: (-score_key(r[field]), r['source_person_key']))
        ranks = {}
        for position, row in enumerate(ordered, 1):
            value = score_key(row[field])
            ranks.setdefault(value, position)
            row[label + '_rank'] = ranks[value]
        for row in rows:
            row.setdefault(label + '_rank', None)
        top[label] = ordered[:10]
    return top


def correlations(rows):
    result = []
    for (label_a, field_a), (label_b, field_b) in combinations(METRICS.items(), 2):
        sample = [r for r in rows if r[field_a] is not None and r[field_b] is not None
                  and ('funding' not in (label_a, label_b) or r['funding_complete'])]
        a, b = [score_key(r[field_a]) for r in sample], [score_key(r[field_b]) for r in sample]
        rho = float(spearmanr(a, b).statistic) if len(set(a)) > 1 and len(set(b)) > 1 else None
        result.append({'measure_1': label_a, 'measure_2': label_b,
                       'people': len(sample), 'spearman_rho': rho})
    return result


def overlap(top):
    return [{'ranking_1': a, 'ranking_2': b,
             'shared_top10_people': len({r['source_person_key'] for r in top[a]} &
                                       {r['source_person_key'] for r in top[b]})}
            for a, b in combinations(top, 2)]


def draw_ego(graph, rows, leader):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import networkx as nx
    center = next(i for i, r in enumerate(rows) if r['source_person_key'] == leader['source_person_key'])
    vertices = sorted({center, *graph.neighbors(center)})
    sub = graph.induced_subgraph(vertices)
    local = nx.Graph()
    local.add_nodes_from(sub.vs['person_key'])
    local.add_edges_from((sub.vs[a]['person_key'], sub.vs[b]['person_key']) for a, b in sub.get_edgelist())
    lookup = {r['source_person_key']: r for r in rows}
    pos = nx.spring_layout(local, seed=42, iterations=300)
    fig, ax = plt.subplots(figsize=(10, 7.5))
    nx.draw_networkx_edges(local, pos, ax=ax, edge_color='#b6bec7', width=.65)
    nodes = list(local)
    dots = nx.draw_networkx_nodes(local, pos, ax=ax, nodelist=nodes,
        node_size=[60 + 12 * lookup[k]['distinct_collaborators'] for k in nodes],
        node_color=[lookup[k]['betweenness_normalized'] for k in nodes], cmap='YlOrRd',
        edgecolors=['#152f50' if k == leader['source_person_key'] else 'white' for k in nodes],
        linewidths=[2.5 if k == leader['source_person_key'] else .8 for k in nodes])
    labels = {key: str(i + 1) for i, key in enumerate(nodes)}
    nx.draw_networkx_labels(local, pos, labels=labels, font_size=10, ax=ax)
    ax.set_axis_off()
    ax.set_title(f"Shared-award neighborhood of {leader['name']}\n"
                 f"{len(nodes)} investigators and {local.number_of_edges()} local edges", fontsize=12)
    fig.colorbar(dots, ax=ax, shrink=.7, label='Normalized betweenness in full award network')
    fig.text(.12, .02, 'Node area increases with full-network degree; outlined node is the focal investigator.', fontsize=9)
    fig.tight_layout(rect=(0, .04, 1, 1))
    figures = OUT / 'figures'
    figures.mkdir(exist_ok=True)
    fig.savefig(figures / 'rq3_award_betweenness_ego.png', dpi=300)
    plt.close(fig)
    legend = [{'figure_node': labels[k], 'source_person_key': k, 'name': lookup[k]['name'],
               'distinct_collaborators': lookup[k]['distinct_collaborators'],
               'betweenness_normalized': lookup[k]['betweenness_normalized']}
              for k in nodes]
    write_csv(OUT / 'ego_node_legend.csv', legend)
    write_csv(OUT / 'ego_edges.csv', [{'person_1': a, 'person_2': b} for a, b in sorted(local.edges())])
    return {'focal_person_key': leader['source_person_key'], 'name': leader['name'],
            'nodes': len(nodes), 'edges': local.number_of_edges(),
            'focal_figure_node': labels[leader['source_person_key']]}


def main():
    OUT.mkdir(exist_ok=True)
    ig.set_random_number_generator(random.Random(42))
    people = {r['key']: r['props'] for r in read('people')}
    awards = {r['key']: r['props'] for r in read('awards')}
    projects = {r['key']: r['props'] for r in read('projects')}
    award_links, project_links = read('investigator_on'), read('work_on')
    ids = sorted(people)
    award_activity, project_activity, roles = defaultdict(set), defaultdict(set), defaultdict(set)
    for link in award_links:
        assert link['award_id'] in awards
        award_activity[link['person_key']].add(link['award_id'])
        props = link['props']
        roles[link['person_key']].update(props.get('roles') or [props['role']])
    for link in project_links:
        project_activity[link['person_key']].add(link['project_id'])
    base = [{'source_person_key': key, 'name': people[key].get('name') or '',
             'roles': '; '.join(sorted(roles[key])), 'awards': len(award_activity[key]),
             'projects': len(project_activity[key]), **funding_exposure(award_activity[key], awards)}
            for key in ids]
    graphs, outputs, summaries, tops = {}, {}, {}, {}
    for label, links, field in [('award', award_links, 'award_id'), ('grouped_project', project_links, 'project_id')]:
        graph = build_graph(ids, links, field)
        write_csv(OUT / f'{label}_edges.csv', [
            {'person_1': ids[e.source], 'person_2': ids[e.target], 'shared_units': e['shared_units']}
            for e in graph.es])
        print(f'{label}: {graph.vcount()} investigators, {graph.ecount()} edges; exact betweenness...', flush=True)
        values, summary = measure_graph(graph)
        rows = [{**b, **v} for b, v in zip(base, values)]
        top = add_ranks(rows)
        write_csv(OUT / f'{label}_investigator_centrality.csv', rows)
        for metric, top_rows in top.items():
            write_csv(OUT / f'{label}_top10_{metric}.csv', top_rows)
        write_csv(OUT / f'{label}_spearman_correlations.csv', correlations(rows))
        write_csv(OUT / f'{label}_top10_overlaps.csv', overlap(top))
        summary['top10'] = top
        summary['correlations'] = correlations(rows)
        summary['top10_overlaps'] = overlap(top)
        graphs[label], outputs[label], summaries[label], tops[label] = graph, rows, summary, top
        print(f'{label}: largest component {summary["largest_component"]}; eigen residual {summary["eigenvector_relative_residual"]:.2e}', flush=True)
    award_edges = set(graphs['award'].get_edgelist())
    grouped_edges = set(graphs['grouped_project'].get_edgelist())
    assert award_edges <= grouped_edges, 'Award edge missing from grouped-project projection'
    sensitivity = []
    for label, field in METRICS.items():
        pairs = [(a[field], b[field]) for a, b in zip(outputs['award'], outputs['grouped_project'])
                 if a[field] is not None and b[field] is not None
                 and (label != 'funding' or a['funding_complete'])]
        rho = float(spearmanr([score_key(a) for a, b in pairs], [score_key(b) for a, b in pairs]).statistic)
        a = {r['source_person_key'] for r in tops['award'][label]}
        b = {r['source_person_key'] for r in tops['grouped_project'][label]}
        sensitivity.append({'measure': label, 'common_people': len(pairs),
                            'spearman_rho_between_networks': rho, 'top10_overlap': len(a & b)})
    write_csv(OUT / 'network_sensitivity.csv', sensitivity)
    ego = draw_ego(graphs['award'], outputs['award'], tops['award']['betweenness'][0])
    hashes = {name: hashlib.sha256((ROOT / 'prepared' / (name + '.jsonl.gz')).read_bytes()).hexdigest()
              for name in ['people', 'awards', 'projects', 'investigator_on', 'work_on', 'has_award']}
    summary = {'computed_utc': datetime.now(timezone.utc).isoformat(), 'source': 'prepared files only; no database connection',
               'people': len(ids), 'awards': len(awards), 'projects': len(projects),
               'investigator_on_links': len(award_links), 'work_on_links': len(project_links),
               'igraph_version': ig.__version__, 'numpy_version': np.__version__,
               'software_versions': {name: version(name) for name in ['igraph', 'numpy', 'scipy', 'matplotlib', 'networkx']},
               'input_sha256': hashes, 'networks': summaries, 'sensitivity': sensitivity,
               'grouping_added_edges': len(grouped_edges - award_edges), 'ego_figure': ego,
               'ranking_rule': 'competition ranks on scores rounded to 12 decimals; person-key tie break for ten displayed rows',
               'checks': {'simple_graphs': True, 'degree_sums': True, 'component_size_sums': True,
                          'award_edges_subset_of_grouped': True, 'eigenvector_convergence': True}}
    (OUT / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False, allow_nan=False), encoding='utf-8')
    print(OUT, flush=True)


if __name__ == '__main__':
    main()
