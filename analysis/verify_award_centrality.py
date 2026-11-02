"""Reconcile published RQ3 exports independently with the prepared snapshot."""
from collections import defaultdict
from decimal import Decimal
from itertools import combinations
from pathlib import Path
import csv
import hashlib
import json
import math
import subprocess
import sys

from analyze_award_centrality import ROOT, OUT, read, build_graph


def load_csv(path):
    with path.open(encoding='utf-8-sig') as f:
        return list(csv.DictReader(f))


def main():
    summary = json.loads((OUT / 'summary.json').read_text(encoding='utf-8'))
    checks = []
    def check(label, passed):
        checks.append({'check': label, 'passed': bool(passed)})
        assert passed, label
    tests = subprocess.run([sys.executable, str(Path(__file__).with_name('test_award_centrality.py'))],
                           capture_output=True, text=True)
    check('Seven synthetic graph/funding/ranking regression tests', tests.returncode == 0)
    for name, digest in summary['input_sha256'].items():
        check('Input hash ' + name, hashlib.sha256(
            (ROOT / 'prepared' / (name + '.jsonl.gz')).read_bytes()).hexdigest() == digest)
    people = {r['key']: r['props'] for r in read('people')}
    amounts = {r['key']: r['props'].get('total_amount') for r in read('awards')}
    membership, project_membership = defaultdict(set), defaultdict(set)
    award_rosters = defaultdict(set)
    for row in read('investigator_on'):
        membership[row['person_key']].add(row['award_id'])
        award_rosters[row['award_id']].add(row['person_key'])
    for row in read('work_on'):
        project_membership[row['person_key']].add(row['project_id'])
    owners = {r['award_id']: r['project_id'] for r in read('has_award')}
    check('All award owners unique and present', len(owners) == len(amounts))
    check('Project membership equals union of owned award rosters', all(
        {owners[a] for a in membership[p]} == project_membership[p] for p in people))
    independent_edges = {tuple(sorted(pair)) for team in award_rosters.values() for pair in combinations(team, 2)}
    neighbor = defaultdict(set)
    for a, b in independent_edges:
        neighbor[a].add(b); neighbor[b].add(a)
    rows = load_csv(OUT / 'award_investigator_centrality.csv')
    check('All 30,239 source IDs retained once', len(rows) == len(people) == 30239 and
          {r['source_person_key'] for r in rows} == set(people))
    for r in rows:
        p = r['source_person_key']
        assert int(r['awards']) == len(membership[p])
        assert int(r['projects']) == len(project_membership[p])
        assert int(r['distinct_collaborators']) == len(neighbor[p])
        values = [amounts[a] for a in membership[p]]
        known = [Decimal(str(v)) for v in values if isinstance(v, (int, float)) and math.isfinite(v)]
        expected = sum((v for v in known if v > 0), Decimal(0)) if known else None
        assert (Decimal(r['associated_positive_award_funding_usd']) if r['associated_positive_award_funding_usd'] else None) == expected
        assert int(r['positive_amount_awards']) == sum(v > 0 for v in known)
        assert int(r['missing_amount_awards']) == len(values) - len(known)
    check('Independent per-person awards, projects, neighbors and Decimal funding sums', True)
    check('Independent award edge count', len(independent_edges) == summary['networks']['award']['edges'])
    historical = {r['source_person_key']: r for r in load_csv(ROOT.parent / 'evidence/historical_centrality' / 'investigator_centrality.csv')}
    grouped = load_csv(OUT / 'grouped_project_investigator_centrality.csv')
    check('Grouped degree and exact betweenness reproduce historical full-person export', all(
        int(r['distinct_collaborators']) == int(historical[r['source_person_key']]['distinct_collaborators']) and
        math.isclose(float(r['betweenness_raw']), float(historical[r['source_person_key']]['betweenness_raw']), rel_tol=1e-10, abs_tol=1e-8)
        for r in grouped))
    for label in ['award', 'grouped_project']:
        graph = build_graph(sorted(people), read('investigator_on' if label == 'award' else 'work_on'),
                            'award_id' if label == 'award' else 'project_id')
        network_rows = load_csv(OUT / f'{label}_investigator_centrality.csv')
        check(label + ' graph is simple with reconciled degree and components', graph.is_simple() and
              sum(graph.degree()) == 2 * graph.ecount() and sum(graph.connected_components().sizes()) == len(people))
        largest = max(graph.connected_components(), key=len)
        connected = graph.induced_subgraph(largest).is_connected()
        below = sum(bool(r['eigenvector_centrality']) and float(r['eigenvector_centrality']) < 1e-12 for r in network_rows)
        summary['networks'][label]['largest_component_connected'] = connected
        summary['networks'][label]['eigenvector_scores_below_1e_12'] = below
        check(label + ' LCC connected and eigenvector residual below 1e-9', connected and
              summary['networks'][label]['eigenvector_relative_residual'] < 1e-9)
        exported_edges = load_csv(OUT / f'{label}_edges.csv')
        check(label + ' edge endpoints and repeat counts', exported_edges == [
            {'person_1': graph.vs[e.source]['person_key'], 'person_2': graph.vs[e.target]['person_key'],
             'shared_units': str(e['shared_units'])} for e in graph.es])
        for metric, expected_rows in summary['networks'][label]['top10'].items():
            actual_rows = load_csv(OUT / f'{label}_top10_{metric}.csv')
            check(label + ' top ten ' + metric, len(actual_rows) == 10 and actual_rows == [
                {k: '' if v is None else str(v) for k, v in r.items()} for r in expected_rows])
    legend = load_csv(OUT / 'ego_node_legend.csv')
    center = summary['ego_figure']['focal_person_key']
    check('Ego figure retains focal node and all neighbors',
          {r['source_person_key'] for r in legend} == neighbor[center] | {center})
    local = {r['source_person_key'] for r in legend}
    check('Ego figure retains all induced edges',
          len([1 for a, b in independent_edges if a in local and b in local]) == summary['ego_figure']['edges'])
    (OUT / 'summary.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False, allow_nan=False), encoding='utf-8')
    result = {'passed': all(c['passed'] for c in checks), 'checks': checks,
              'regression_test_output': tests.stderr.strip()}
    (OUT / 'verification.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(f'{len(checks)} verification checks passed.')


if __name__ == '__main__':
    main()
