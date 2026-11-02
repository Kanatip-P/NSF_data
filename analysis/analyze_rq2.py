"""Offline verified-UnitID join against the enclosed Carnegie workbook."""
from pathlib import Path
from collections import Counter
import csv
import gzip
import json
import re
import unicodedata
from openpyxl import load_workbook

ROOT = Path(__file__).resolve().parents[1]


def read(name):
    with gzip.open(ROOT / 'data/prepared' / (name + '.jsonl.gz'), 'rt', encoding='utf-8') as f:
        return [json.loads(line) for line in f]


def norm(value):
    text = unicodedata.normalize('NFKD', str(value or '')).encode('ascii', 'ignore').decode().lower()
    return re.sub('[^a-z0-9]', '', text).removeprefix('the')


def main():
    book = load_workbook(ROOT / 'data/reference/2025-Public-Data-File.xlsx', read_only=True, data_only=True)
    rows = book['data'].iter_rows(values_only=True)
    headers = next(rows)
    records = [dict(zip(headers, row)) for row in rows]
    book.close()
    official = {str(int(r['unitid'])): r for r in records
                if isinstance(r['unitid'], (int, float)) and r['unitid'] > 0}
    recipients = {r['key']: r['props'] for r in read('universities')}
    awards = Counter(r['university_key'] for r in read('hosted_by'))
    assert sum(awards.values()) == 24748
    anomalies, output = [], []
    for key, recipient in recipients.items():
        uid = str(recipient.get('verified_unitid', '')).removesuffix('.0')
        reference = official.get(uid)
        if uid and reference is None:
            # Preserve the audited exception; never promote an arbitrary name candidate.
            matches = [r for r in records if norm(r['instnm']) == norm(recipient.get('name'))]
            assert uid == '228778' and len(matches) == 1 and str(matches[0]['unitid']) == 'F', \
                'An unreviewed workbook exception requires identity review'
            reference = matches[0]
            anomalies.append({'verified_unitid': uid, 'name': recipient['name'], 'workbook_unitid': 'F'})
        output.append({'source_key': key, 'recipient': recipient.get('name', ''),
                       'verified_unitid': uid, 'awards': awards[key],
                       'official_research': int(reference['research2025']) if reference else ''})
    counts = Counter()
    for row in output:
        if row['official_research'] != '':
            counts[str(row['official_research'])] += row['awards']
    expected = {'1': 16137, '2': 1088, '3': 568, '-2': 474}
    assert dict(counts) == expected
    with (ROOT / 'data/reference/live_recipient_classification.csv').open(encoding='utf-8-sig') as f:
        archived = {r['source_key']: r for r in csv.DictReader(f)}
    assert all(str(row['official_research']) == archived[row['source_key']]['official_research']
               and row['awards'] == int(archived[row['source_key']]['awards']) for row in output)
    out = ROOT / 'results/rq2'
    out.mkdir(exist_ok=True)
    with (out / 'offline_recipient_join.csv').open('w', newline='', encoding='utf-8-sig') as f:
        writer = csv.DictWriter(f, fieldnames=list(output[0]))
        writer.writeheader(); writer.writerows(output)
    summary = {'source': 'prepared recipient and award links plus archived Carnegie workbook',
               'verified_recipient_identities': sum(r['official_research'] != '' for r in output),
               'classified_awards': sum(counts.values()), 'class_awards': dict(counts),
               'outside_subset_awards': 24748 - sum(counts.values()),
               'workbook_exceptions': anomalies, 'archived_crosswalk_matches': True}
    (out / 'offline_classification_summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
