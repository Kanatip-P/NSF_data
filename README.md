# NSF enriched graph reproducibility

This repository explains and reproduces three descriptive research questions
using the selected 2015–2025 NSF Standard Grant cohort: **17,503 grouped
projects, 24,748 awards, 30,239 investigators, and 1,374 recipient nodes**.
It contains data, read-only Cypher, portable analysis code, result tables,
and cross-check evidence. Manuscripts and Word/PDF methods documents are
kept outside this repository.

## Start here

1. Run the offline repository check from this folder:

   ```shell
   python scripts/check_repository.py
   ```

   This needs Python 3.12 or later and the standard library only. It verifies
   file hashes, recalculates RQ1 and cohort summaries, checks RQ2 classifications,
   and reconciles RQ3 identities, funding, edges, rankings, and eigenvector
   equations. It does not connect to Neo4j or replace archived evidence.

2. Read [Setup and execution order](docs/SETUP.md).
3. Follow each question's guide:

   | Question | Step-by-step guide | Main outputs |
   | --- | --- | --- |
   | RQ1 Team structure and subject combinations | [RQ1](docs/RQ1_STEP_BY_STEP.md) | [RQ1 results](results/rq1/README.md) |
   | RQ2 Verified recipient classifications | [RQ2](docs/RQ2_STEP_BY_STEP.md) | [RQ2 results](results/rq2/README.md) |
   | RQ3 Network prominence and funding exposure | [RQ3](docs/RQ3_STEP_BY_STEP.md) | [RQ3 results](results/rq3/README.md) |

4. Use the [verification map](docs/CROSS_CHECKS.md) to trace each reported result
   to its inputs, calculation, and independent check.

## Full offline rerun

Create a virtual environment, install [requirements](requirements.txt), then run:

```shell
python analysis/analyze_rqs.py
python scripts/export_rq1.py
python analysis/analyze_cohort.py
python analysis/analyze_rq2.py
python analysis/analyze_award_centrality.py
python analysis/verify_award_centrality.py
```

Exact betweenness is calculated for both network projections and can take a
few minutes. All analysis inputs are enclosed. The archived reference results
under `evidence/` remain separate from regenerated results under `results/`.

For a complete check including a fresh graph recalculation:

```shell
python scripts/check_repository.py --full --recompute-centrality
```

## Optional live Cypher

The database target is **`nsf-project-workon-enriched`**. A matching, already
loaded database is required. This repository does not automatically create or
modify a database. Start with [Setup](docs/SETUP.md), then run the numbered
blocks in [queries](queries/README.md), one at a time.

Cypher supplies direct graph counts, source rows, and verified classification
aggregation. RQ3 exact betweenness and eigenvector centrality are calculated
in Python from the exported graph structure. Source-extraction queries are
not presented as if they themselves computed those centralities.

## What is established

- The original nine core Cypher blocks have archived live returns and eleven
  passing comparisons; their query bytes and hashes are preserved.
- Later RQ1 subject-combination queries are supplied for reruns; their reported
  counts were checked offline, not newly executed against Neo4j here.
- RQ3 centralities were computed offline from the hash-recorded graph exports,
  with graph fixtures, funding reconciliation, and grouping sensitivity.
- Repository assembly and its checks do not connect to a database. Optional
  future live reruns save timestamped files in ignored `results/live/`.

See [Data provenance](docs/DATA_PROVENANCE.md) for source and licensing context,
[data dictionary](docs/DATA_DICTIONARY.md) for fields, and
[GitHub upload instructions](docs/UPLOAD_TO_GITHUB.md) for publishing the folder.
Repository: [Kanatip-P/NSF_data](https://github.com/Kanatip-P/NSF_data).
