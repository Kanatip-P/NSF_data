"""Export the current RQ1 ranking from the offline analysis JSON."""
from pathlib import Path
import csv
import json

ROOT = Path(__file__).resolve().parents[1]
data = json.loads((ROOT / 'results/rq_analysis.json').read_text(encoding='utf-8'))['rq1']
out = ROOT / 'results/rq1'
for name, rows in [('RQ1_team_subject_combinations_all.csv', data['team_subject_combinations']['ranking']),
                   ('RQ1_team_subject_combinations_top10.csv', data['team_subject_combinations']['ranking'][:10]),
                   ('RQ1_leading_ordered_tag_cells.csv', data['leading_ordered_broad_tag_cells'])]:
    with (out / name).open('w', newline='', encoding='utf-8-sig') as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)
coverage = {k: v for k, v in data['team_subject_combinations'].items() if k != 'ranking'}
(out / 'RQ1_team_subject_combination_coverage.json').write_text(json.dumps(coverage, indent=2), encoding='utf-8')
print('RQ1 subject ranking and coverage exported.')
