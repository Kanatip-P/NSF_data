# Validated execution

All **68 query blocks** completed against an isolated, complete copy of the prepared snapshot. This directory contains actual Neo4j result tables. Query markers identify the source blocks; [VALIDATION.json](VALIDATION.json) records versions, row counts, timings, and export checks. No live database was accessed.

- All 435 RQ1 subject counts/ranks matched the reference; an independent project-by-subject reconstruction also matched.
- All 1,374 RQ2 recipient classifications and award counts matched, including the exact UT Austin exception.
- Both projections retained 30,239 unique people. Degree sums, components, and edge totals passed.
- Across both complete networks, degree, normalized betweenness, eigenvector, and LCC membership had zero mismatches at the stated tolerances. Maximum betweenness error was below `1.2e-16`; maximum eigenvector error was below `8.8e-13`.
- All 30,239 investigators' distinct award/project counts, positive funding, positive-amount counts, and missing-amount counts matched.
- Explicit Cypher eigenvector iteration converged after 260 award-network iterations and 259 grouped-network iterations. Relative equation residuals were below `9.7e-14`.
- The complete score export has 60,478 rows. The combined top-ten table has 100 rows; the ten individual ranking CSVs are filtered views of that same table. Exported competition ranks and deterministic top tens were independently reconciled to exported scores.
- Synthetic fixtures passed for graph shapes, isolation, ranking ties, Spearman ties, distinct-member subjects, duplicate memberships, and distinct-award funding with missing/zero/negative amounts.

The expected production database name is `nsf-project-workon-enriched`; the embedded validation copy is named `neo4j`. Consequently the database-name assertion in `PREFLIGHT_DATABASE.csv` is false and explicitly **not applicable** to this isolated run. It must be true when running against the intended production database.

The ego view contains 29 people and 78 induced edges around Ian Foster. The graph-view query returns virtual nodes/edges; use `RQ3_EGO_NODE_TABLE.csv` and `RQ3_EGO_EDGE_TABLE.csv` as portable data. GDS projections were removed after all exports and checks; stored source records were not changed by these query blocks.
