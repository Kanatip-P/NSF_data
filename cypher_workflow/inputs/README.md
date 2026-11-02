# Static inputs and provenance

Copy all five CSVs here into Neo4j's configured import directory. Do not load them as graph nodes. Queries read them with `LOAD CSV`.

| CSV | Source / purpose |
| --- | --- |
| `carnegie_2025_research.csv` | 3,927 rows; literal `unitid`, `instnm`, and `research2025` columns from the enclosed [2025 workbook](../../data/reference/2025-Public-Data-File.xlsx), sheet `data`. Includes all reference codes and the literal UT Austin `F` value. |
| `reviewed_recipient_ids.csv` | 1,374 recipient keys and reviewed verified UnitIDs from the existing RQ2 identity crosswalk; expected classifications/counts are used only for checks. |
| `expected_rq1_subjects.csv` | Existing complete 435-row RQ1 subject ranking, used only to cross-check the fresh Cypher calculation. |
| `expected_award_centrality.csv` | Existing all-investigator award-network results, used only as a numerical reference. |
| `expected_grouped_centrality.csv` | Existing grouped-project sensitivity results, used only as a numerical reference. |

These are supplied static CSV views, not new analysis performed outside Cypher. Every RQ calculation and validation in the new workflow is Cypher. [PROVENANCE.json](PROVENANCE.json) records the source workbook SHA256 and extraction columns. Graph records come from the matching prepared graph already loaded into Neo4j; the snapshot is under [data/prepared](../../data/prepared/).

Reference comparisons alone do not prove correctness. Independent checks also test fixtures, deduplication, degree sums, component populations, funding counts, a separately reconstructed subject matrix, and the eigenvector equation.
