"""Offline repository audit using the Python standard library only.

Use --full to additionally run the workbook join, graph fixture suite, and
the graph-library verification. --recompute-centrality also recalculates both
exact networks. No option connects to Neo4j.
"""
from collections import Counter, defaultdict
from decimal import Decimal
from itertools import combinations
from pathlib import Path
from urllib.parse import unquote
import argparse
import csv
import gzip
import hashlib
import json
import math
import os
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / 'analysis'))
from subject_combinations import rank_subject_combinations


def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def csv_rows(path):
    with path.open(encoding='utf-8-sig') as f:
        return list(csv.DictReader(f))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def included(path):
    relative = path.relative_to(ROOT)
    return (path.is_file() and '__pycache__' not in relative.parts
            and '.git' not in relative.parts and '.venv' not in relative.parts
            and relative.as_posix() != 'FILE_MANIFEST.json'
            and not relative.as_posix().startswith('results/live/')
            and not path.name.startswith('local_'))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--content-only', action='store_true')
    parser.add_argument('--full', action='store_true')
    parser.add_argument('--recompute-centrality', action='store_true')
    args = parser.parse_args()
    checks = []
    def check(name, passed, detail=''):
        checks.append({'check': name, 'passed': bool(passed), 'detail': detail})
        if not passed:
            raise AssertionError(name + ': ' + detail)
    if not args.content_only:
        manifest = load(ROOT / 'FILE_MANIFEST.json')
        check('Complete published file inventory',
              {p.relative_to(ROOT).as_posix() for p in ROOT.rglob('*') if included(p)} ==
              {r['path'] for r in manifest['files']})
        check('Every published file hash and size matches', all(
            (ROOT / r['path']).is_file() and sha(ROOT / r['path']) == r['sha256'] and
            (ROOT / r['path']).stat().st_size == r['bytes'] for r in manifest['files']))
    prepared = ROOT / 'data/prepared'
    source_manifest = load(prepared / 'manifest.json')
    data = {}
    for name, info in source_manifest['files'].items():
        path = prepared / info['file']
        with gzip.open(path, 'rt', encoding='utf-8') as f:
            data[name] = [json.loads(line) for line in f]
        check('Prepared snapshot ' + name, sha(path) == info['sha256'] and len(data[name]) == info['rows'])
    people = {r['key']: r['props'] for r in data['people']}
    projects = {r['key']: r['props'] for r in data['projects']}
    awards = {r['key']: r['props'] for r in data['awards']}
    check('Declared cohort sizes', (len(people), len(projects), len(awards), len(data['universities'])) ==
          (30239, 17503, 24748, 1374))
    credential_fields = {'password', 'passwd', 'api_key', 'apikey', 'access_token',
                         'refresh_token', 'client_secret', 'neo4j_pass', 'mongodb_uri'}
    def has_credentials(value):
        if isinstance(value, dict):
            return any(str(k).lower() in credential_fields and bool(v) or has_credentials(v)
                       for k, v in value.items())
        if isinstance(value, list):
            return any(has_credentials(v) for v in value)
        return False
    check('No credential fields in prepared graph exports', not has_credentials(data))
    reference = load(ROOT / 'evidence/rq_analysis_reference.json')
    rosters = defaultdict(list)
    for r in data['work_on']:
        rosters[r['project_id']].append((r['person_key'], r['props']['role']))
    combinations_result = rank_subject_combinations(projects, rosters, people)
    check('RQ1 full subject ranking and coverage', combinations_result == reference['rq1']['team_subject_combinations'])
    ranking = combinations_result['ranking']
    check('RQ1 top-ten CSV matches computed ranking', csv_rows(ROOT / 'results/rq1/RQ1_team_subject_combinations_top10.csv') ==
          [{k: str(v) for k, v in r.items()} for r in ranking[:10]])
    check('RQ1 complete CSV matches computed ranking', csv_rows(ROOT / 'results/rq1/RQ1_team_subject_combinations_all.csv') ==
          [{k: str(v) for k, v in r.items()} for r in ranking])
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1')
    with tempfile.TemporaryDirectory(prefix='local_check_', dir=ROOT / 'verification') as tmp:
        for script, expected in [('analyze_rqs.py', reference),
                                 ('analyze_cohort.py', load(ROOT / 'evidence/cohort_analysis_reference.json'))]:
            target = Path(tmp) / (script + '.json')
            result = subprocess.run([sys.executable, str(ROOT / 'analysis' / script)],
                env=dict(env, NSF_ANALYSIS_OUTPUT=str(target)), capture_output=True, text=True)
            check('Portable offline recomputation ' + script,
                  result.returncode == 0 and target.exists() and load(target) == expected,
                  result.stderr[-500:] if result.returncode else 'Exact archived JSON match')
    core = load(ROOT / 'evidence/paper_query_verification.json')
    check('Archived core evidence passed eleven comparisons', core['passed'] and len(core['checks']) == 11 and
          all(r['passed'] for r in core['checks']))
    check('Exact executed core Cypher preserved', sha(ROOT / 'queries/CORE_VERIFICATION.cypher') == core['query_file_sha256'])
    check('Exact crosswalk preserved', sha(ROOT / 'data/reference/live_recipient_classification.csv') == core['crosswalk_sha256'])
    check('Exact Carnegie workbook preserved', sha(ROOT / 'data/reference/2025-Public-Data-File.xlsx') == core['workbook_sha256'])
    latest = load(ROOT / 'evidence/latest_cohort_verification.json')
    check('Supplemental live evidence passed on the same enriched database', latest['passed'] and
          latest['database'] == core['database'] == 'nsf-project-workon-enriched')
    table_sources = {
        'results/rq1/RQ1_awards_per_project.csv': latest['results']['awards_per_project'],
        'results/rq2/RQ2_verified_research_classification.csv': core['results']['Q07_VERIFIED_OFFICIAL_CLASSIFICATION'],
        'results/rq3/RQ3_project_activity_histogram.csv': core['results']['Q04_PERSON_ACTIVITY'],
        'results/rq3/RQ3_exclusive_person_roles.csv': latest['results']['person_role_groups'],
        'results/rq3/RQ3_project_role_positions.csv': latest['results']['project_role_positions'],
        'results/shared/profile_program_coverage.csv': core['results']['Q08_PROFILE_AND_PROGRAM_COVERAGE']}
    check('Six baseline result tables match archived live query rows', all(
        csv_rows(ROOT / path) == [{k: str(v) for k, v in r.items()} for r in expected]
        for path, expected in table_sources.items()))
    funding_table = [{'team': r['team'], 'projects': r['projects'], 'positive_amount_n': r['amount_n'],
                      'median_positive_amount_usd': r['median_amount'],
                      'median_positive_duration_years': reference['rq1']['median_positive_duration_years'][r['team']]}
                     for r in core['results']['Q03_TEAM_AMOUNTS']]
    check('RQ1 funding table matches live amounts and offline durations',
          csv_rows(ROOT / 'results/rq1/RQ1_project_team_funding.csv') ==
          [{k: str(v) for k, v in r.items()} for r in funding_table])
    crosswalk = csv_rows(ROOT / 'data/reference/live_recipient_classification.csv')
    weighted = Counter()
    for r in crosswalk:
        if r['official_research'] != '':
            weighted[r['official_research']] += int(r['awards'])
    check('RQ2 verified classification totals', dict(weighted) == {'1': 16137, '2': 1088, '3': 568, '-2': 474})
    check('RQ2 classification subset and full-award denominator', sum(weighted.values()) == 18267 and
          sum(int(r['awards']) for r in crosswalk) == 24748 and
          sum(r['official_research'] != '' for r in crosswalk) == 612)
    mapping = load(ROOT / 'queries/parameters/classifications.json')['classifications']
    check('RQ2 parameters reproduce the reviewed crosswalk',
          {r['source_key']: (r['verified_unitid'], r['official_research']) for r in mapping} ==
          {r['source_key']: (r['verified_unitid'], int(r['official_research'])) for r in crosswalk if r['official_research'] != ''})
    owners = {r['award_id']: r['project_id'] for r in data['has_award']}
    membership, activity = defaultdict(set), defaultdict(set)
    teams = defaultdict(set)
    for r in data['investigator_on']:
        membership[r['person_key']].add(r['award_id'])
        teams[r['award_id']].add(r['person_key'])
    for r in data['work_on']:
        activity[r['person_key']].add(r['project_id'])
    check('Award and project roster layers reconcile', len(owners) == len(awards) and all(
        {owners[a] for a in membership[p]} == activity[p] for p in people))
    counts = Counter()
    for team in teams.values():
        counts.update(combinations(sorted(team), 2))
    neighbors = defaultdict(set)
    for a, b in counts:
        neighbors[a].add(b); neighbors[b].add(a)
    central = csv_rows(ROOT / 'results/rq3/award_investigator_centrality.csv')
    check('RQ3 all-person export', len(central) == len(people) and {r['source_person_key'] for r in central} == set(people))
    for r in central:
        p = r['source_person_key']
        assert int(r['awards']) == len(membership[p])
        assert int(r['projects']) == len(activity[p])
        assert int(r['distinct_collaborators']) == len(neighbors[p])
        values = [awards[a].get('total_amount') for a in membership[p]]
        known = [Decimal(str(v)) for v in values if isinstance(v, (int, float)) and math.isfinite(v)]
        amount = sum((v for v in known if v > 0), Decimal(0)) if known else None
        actual = Decimal(r['associated_positive_award_funding_usd']) if r['associated_positive_award_funding_usd'] else None
        assert actual == amount
        assert int(r['positive_amount_awards']) == sum(v > 0 for v in known)
        assert int(r['missing_amount_awards']) == len(values) - len(known)
        assert math.isclose(float(r['degree_centrality']), len(neighbors[p]) / (len(people) - 1))
        assert math.isclose(float(r['betweenness_normalized']),
                            float(r['betweenness_raw']) * 2 / ((len(people) - 1) * (len(people) - 2)), abs_tol=1e-14)
    check('RQ3 independent all-person activity, degree, normalization and Decimal funding', True)
    edge_rows = csv_rows(ROOT / 'results/rq3/award_edges.csv')
    check('RQ3 independently derived award edges and repeat strengths',
          {(r['person_1'], r['person_2']): int(r['shared_units']) for r in edge_rows} == dict(counts))
    summary = load(ROOT / 'results/rq3/summary.json')
    for network in ['award', 'grouped_project']:
        rows = csv_rows(ROOT / f'results/rq3/{network}_investigator_centrality.csv')
        check(network + ' degree and component identities',
              sum(int(r['distinct_collaborators']) for r in rows) == 2 * summary['networks'][network]['edges'] and
              len(rows) == 30239)
        check(network + ' eigenvector convergence', summary['networks'][network]['eigenvector_converged'] and
              summary['networks'][network]['eigenvector_relative_residual'] < 1e-9)
        for metric, expected in summary['networks'][network]['top10'].items():
            check(network + ' top-ten export ' + metric,
                  csv_rows(ROOT / f'results/rq3/{network}_top10_{metric}.csv') ==
                  [{k: '' if v is None else str(v) for k, v in r.items()} for r in expected])
    exported = {r['source_person_key']: r for r in central}
    eigenvalue = summary['networks']['award']['eigenvalue']
    errors, denominator = [], []
    for p, row in exported.items():
        if row['eigenvector_centrality']:
            x = float(row['eigenvector_centrality'])
            ax = math.fsum(float(exported[q]['eigenvector_centrality'] or 0) for q in neighbors[p])
            errors.append((ax - eigenvalue * x) ** 2)
            denominator.append((eigenvalue * x) ** 2)
    check('RQ3 eigenvector equation independently checked from exported values',
          math.sqrt(math.fsum(errors) / math.fsum(denominator)) < 1e-9)
    historical = {r['source_person_key']: r for r in csv_rows(ROOT / 'evidence/historical_centrality/investigator_centrality.csv')}
    grouped = csv_rows(ROOT / 'results/rq3/grouped_project_investigator_centrality.csv')
    check('Historical full-person grouped centralities reproduced', all(
        int(r['distinct_collaborators']) == int(historical[r['source_person_key']]['distinct_collaborators']) and
        math.isclose(float(r['betweenness_raw']), float(historical[r['source_person_key']]['betweenness_raw']), rel_tol=1e-10, abs_tol=1e-8)
        for r in grouped))
    check('Archived supplemental graph verification passed', load(ROOT / 'results/rq3/verification.json')['passed'])
    all_files = [p for p in ROOT.rglob('*') if included(p)]
    check('No manuscript or office document files in repository',
          not any(p.suffix.lower() in ['.docx', '.doc', '.pdf', '.pptx'] for p in all_files))
    check('Every file below GitHub browser limit of 25 MiB', all(p.stat().st_size < 25 * 1024**2 for p in all_files))
    secret = re.compile(r'''(?im)^\s*(?:\w*password|\w*passwd|\w*api_key|neo4j_pass)\s*=\s*["'][^"'\r\n]+["']''')
    bad, local_paths, links = [], [], []
    for p in all_files:
        if p.suffix in ['.py', '.md', '.json', '.txt', '.cypher', '.example']:
            text = p.read_text(encoding='utf-8-sig')
            if secret.search(text):
                bad.append(p.relative_to(ROOT).as_posix())
            if re.search(r'[A-Za-z]:[\\/]Users[\\/]', text):
                local_paths.append(p.relative_to(ROOT).as_posix())
            if p.suffix == '.py':
                compile(text, str(p), 'exec')
            if p.suffix == '.md':
                for target in re.findall(r'!?\[[^\]]*\]\(([^)]+)\)', text):
                    if '://' not in target and not target.startswith('#'):
                        route = unquote(target.split('#')[0])
                        if route and not (p.parent / route).exists():
                            links.append(p.relative_to(ROOT).as_posix() + ': ' + target)
    check('No hardcoded credential assignments', not bad, ', '.join(bad))
    check('No workstation user paths', not local_paths, ', '.join(local_paths))
    check('All Python scripts compile', True)
    check('Local Markdown links resolve', not links, '; '.join(links))
    if args.full or args.recompute_centrality:
        scripts = ['analysis/analyze_rq2.py']
        if args.recompute_centrality:
            scripts.append('analysis/analyze_award_centrality.py')
        scripts += ['analysis/test_subject_combinations.py', 'analysis/verify_award_centrality.py']
        for script in scripts:
            run = subprocess.run([sys.executable, str(ROOT / script)], env=env, capture_output=True, text=True)
            detail = (run.stdout + run.stderr).replace(str(ROOT), '[repository]')[-1000:]
            check('Execute ' + script, run.returncode == 0, detail)
    print(json.dumps({'passed': True, 'checks': checks, 'check_count': len(checks),
                      'database_connection_used': False}, indent=2))


if __name__ == '__main__':
    main()
