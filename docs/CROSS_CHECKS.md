# How the results are cross-checked

Different checks establish different facts. A hash establishes file identity;
it does not prove a scientific interpretation. A passing archived live query
does not establish that a later database has the same contents.

| Result | Inputs or query | Output location | Cross-check |
| --- | --- | --- | --- |
| Cohort and ownership | Core Q01, Q02, Q09; prepared manifest | `evidence/paper_query_verification.json` | Node/link counts, one owner and recipient per award, export hashes and row counts |
| RQ1 team shape and amounts | Core Q03; prepared projects and WORK_ON | `results/rq1/RQ1_project_team_funding.csv` | Five categories sum to 17,503; amount denominators and medians match archived analysis |
| RQ1 subject combinations | New subject-pair query; offline subject module | `results/rq1/RQ1_team_subject_combinations_*.csv` | Full ranking recomputation, distinct-person and per-project deduplication fixtures |
| RQ1 coverage | New coverage queries | `results/rq1/RQ1_team_subject_combination_coverage.json` | 14,329 two-tagged-member projects and 14,217 supporting different subjects |
| Multiple PI structure | Supplemental query and prepared ownership | `evidence/table3_pi_structure_verification.json` | 5,112 multi-award plus 220 single-award projects |
| RQ2 classification | Core Q05–Q07; reviewed crosswalk and workbook | `results/rq2/` | 612 reviewed identities; 18,267 classified awards; four class totals; exact workbook hash and audited exception |
| RQ3 participation and roles | Core Q04/Q08 and supplemental queries | Baseline `RQ3_*.csv` in `results/rq3/` | Full activity tail and mutually exclusive role-group totals |
| RQ3 edges and degree | Distinct shared-award membership | `results/rq3/award_edges.csv` and investigator CSV | Independent roster-derived edge set; repeated strengths; degree sum equals twice edge count |
| RQ3 funding | Distinct investigator–award IDs and Award amounts | Investigator CSV and funding top ten | Independent Decimal sum for every person; positive/zero/negative/missing distinctions |
| RQ3 exact betweenness | igraph unweighted simple projection | Both investigator CSVs | Independent NetworkX fixtures and historical grouped full-person score comparison |
| RQ3 eigenvector | Largest connected component of each projection | Eigenvector columns and top ten | Independent connectivity check and adjacency equation residual below 1e-9 |
| RQ3 grouping sensitivity | Same people and awards; two edge definitions | `results/rq3/network_sensitivity.csv` | Award edges are a subset; same displayed top tens; correlations state common populations |
| RQ3 local figure | Focal investigator plus all neighbors | `results/rq3/figures/` and ego CSVs | Exact induced nodes and all edges match the award graph |

## Run checks in increasing depth

```shell
python scripts/check_repository.py
python scripts/check_repository.py --full
python scripts/check_repository.py --full --recompute-centrality
```

The default uses only the standard library. It checks the complete published
file inventory, all prepared exports, exact core Cypher/workbook/crosswalk
hashes, recalculates the offline RQ/cohort JSONs in temporary files, verifies
all-person award activity and funding, and checks exported eigenvector
equations and rankings. It also scans for embedded credential assignments,
workstation user paths, manuscript files, oversized files and broken local links.

`--full` adds the actual workbook join and graph-library verification,
including independent synthetic tests. `--recompute-centrality` additionally
recalculates exact betweenness and eigenvector for both networks before the
graph-library verifier runs. Those options require installed dependencies and
intentionally refresh result files; use a pristine checkout to compare to the
original manifest afterward.

The assembly-time record is
[ASSEMBLY_CHECK_RESULTS.json](../verification/ASSEMBLY_CHECK_RESULTS.json).
The original RQ3 graph verification is
[verification.json](../results/rq3/verification.json).

## Evidence chronology

- `evidence/paper_query_verification.json`: original nine live read-only core
  blocks and eleven comparisons, with original timestamps and hashes.
- `evidence/latest_cohort_verification.json`: live grouping and role checks.
- `evidence/table3_pi_structure_verification.json`: live multiple-PI split.
- `evidence/historical_centrality/`: earlier live-read grouped projection.
- `results/rq3/summary.json`: later offline award and grouping calculations,
  pinned software versions, input hashes and spectral diagnostics.
- New RQ1 subject queries and the RQ3 direct degree/funding queries are provided
  as read-only reruns, not mislabeled as previously executed live evidence.

Optional live verification saves new timestamped files in `results/live/`.
It never overwrites these historical evidence files. If a live comparison
fails, diagnose snapshot drift, database selection, IDs, units and the
reviewed classification mapping before changing expected values.
