"""Optional read-only Neo4j verification; never overwrites archived evidence."""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import json
import os
import re
from neo4j import GraphDatabase, READ_ACCESS

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--rq', choices=['all', '1', '2', '3'], default='all')
    args = parser.parse_args()
    database = os.environ.get('NEO4J_DATABASE', 'nsf-project-workon-enriched')
    if database != 'nsf-project-workon-enriched':
        raise RuntimeError('This snapshot verifier requires nsf-project-workon-enriched explicitly.')
    password = os.environ.get('NEO4J_PASSWORD')
    if not password:
        raise RuntimeError('Set NEO4J_PASSWORD in your environment. No credentials are included.')
    text = (ROOT / 'queries/CORE_VERIFICATION.cypher').read_text(encoding='utf-8')
    parts = re.split(r'// @query (\w+)\s*\n', text)
    queries = {parts[i]: parts[i + 1].strip().rstrip(';') for i in range(1, len(parts), 2)}
    selected = {'1': ['Q01_POPULATION', 'Q02_AWARD_LINKS', 'Q03_TEAM_AMOUNTS'],
                '2': ['Q05_RAW_RECIPIENT_CODES', 'Q06_VERIFIED_ID_RECOVERY', 'Q07_VERIFIED_OFFICIAL_CLASSIFICATION'],
                '3': ['Q04_PERSON_ACTIVITY', 'Q08_PROFILE_AND_PROGRAM_COVERAGE']}
    names = list(queries) if args.rq == 'all' else selected[args.rq]
    expected = json.loads((ROOT / 'evidence/paper_query_verification.json').read_text())['results']
    parameters = json.loads((ROOT / 'queries/parameters/classifications.json').read_text())
    report = {'database': database, 'checked_utc': datetime.now(timezone.utc).isoformat(),
              'rq': args.rq, 'access': 'read-only', 'results': {}, 'checks': []}
    with GraphDatabase.driver(os.environ.get('NEO4J_URI', 'bolt://127.0.0.1:7687'),
                              auth=(os.environ.get('NEO4J_USER', 'neo4j'), password)) as driver:
        with driver.session(database=database, default_access_mode=READ_ACCESS) as session:
            for name in names:
                params = parameters if name.startswith('Q07') else {}
                session.run('EXPLAIN ' + queries[name], **params).consume()
                actual = [dict(r) for r in session.run(queries[name], **params)]
                report['results'][name] = actual
                report['checks'].append({'query': name, 'passed': actual == expected[name]})
    report['passed'] = all(r['passed'] for r in report['checks'])
    out = ROOT / 'results/live'
    out.mkdir(exist_ok=True)
    filename = out / ('core_checks_' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ') + '.json')
    filename.write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps({'passed': report['passed'], 'checks': len(report['checks']),
                      'output': str(filename.relative_to(ROOT))}, indent=2))
    if not report['passed']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
