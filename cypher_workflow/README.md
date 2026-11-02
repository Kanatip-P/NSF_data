# Cypher workflow for RQ1–RQ3

Run every calculation here through Cypher in Neo4j Browser. No Python runtime or script is required for this workflow. The original offline workflow and archived results remain elsewhere in this repository. Paper documents are excluded.

## Prepare the session

1. Open the already populated **nsf-project-workon-enriched** database. Its selected cohort must contain 17,503 Projects, 24,748 Awards, 30,239 Persons, and 1,374 Universities. These queries do not import or change the stored graph.
2. Install compatible **Graph Data Science (GDS)** and **APOC Core** plugins, enable their procedures according to your installation policy, and restart the database. The isolated validation environment used Neo4j Community **5.26.0**, GDS **2.13.4**, and APOC Core **5.26.0**, with a 5 GB Java heap. Version compatibility matters; consult the [GDS compatibility guide](https://neo4j.com/docs/graph-data-science/current/installation/supported-neo4j-versions/).
3. Copy the five CSV files from [inputs](inputs/) into the database's configured `import` directory. Keep their filenames. Enable local `LOAD CSV` access if disabled. These supplied CSV views avoid any spreadsheet conversion step. See [input provenance](inputs/README.md).
4. Run [preflight](00_setup/01_preflight.cypher). Check the database name and every count before proceeding. A different cohort requires revised denominators and reference files.
5. Run each `// @query NAME` block in [library fixtures](00_setup/02_library_fixtures.cypher), then the [Cypher eigenvector fixture](00_setup/03_cypher_eigenvector_fixture.cypher). Submit one block at a time, including its full query through the terminating semicolon. Every returned `passed` field must be true.

## Execution order and results

Follow [RQ1](rq1/README.md), [RQ2](rq2/README.md), then [RQ3](rq3/README.md). Run numbered files and query blocks in order. Keep the same database session running through RQ3: GDS projections are temporary in-memory graphs. A database restart removes them.

In Browser, select the **table** view and download each result as CSV, using the query marker as its filename. Full rankings and all-person exports are result tables, not database properties. Browser settings must allow all rows to be returned/exported: the full RQ3 export contains **60,478 rows**, and the complete RQ1 ranking contains **435 rows**. Check exported row counts. For large exports, use `cypher-shell` against the same database with the complete query block and CSV output redirected to a local file; shell connection credentials belong outside this repository.

Actual isolated-run exports are in [results/validated](results/validated/); [verification](checks/README.md) explains how to cross-check them. These are separate from the historical reference CSVs used by the comparisons.

RQ1 and RQ2 use standard Cypher. RQ3 calls GDS for degree, exact betweenness, and components; eigenvector uses explicit normalized power iteration written in Cypher. APOC supplies maps, cumulative counts, and the virtual local graph. GDS `mutate` changes only a projection in memory. There are no stored-node `SET`, `CREATE`, `MERGE`, `DELETE`, or GDS `.write` operations. The graph view uses APOC **virtual** nodes and relationships.

After exporting and checking everything, run [cleanup](99_cleanup.cypher) to drop the four reserved GDS projections. If a projection already exists when restarting the workflow, run cleanup first. Do not run cleanup between RQ3 calculation and export.

## Interpretation

Subject labels describe investigator profiles; shared awards describe recorded roster membership, including former roles. Neither establishes project topics, direct collaboration, or simultaneous participation. Centrality measures **network prominence**, not research quality, personal funding, or proposal success. Associated positive award funding overlaps across investigators and cannot be summed into portfolio funding.

## Algorithm documentation

- [Cypher graph projection](https://neo4j.com/docs/graph-data-science/current/management-ops/graph-creation/graph-project-cypher-projection/)
- [Exact betweenness](https://neo4j.com/docs/graph-data-science/current/algorithms/betweenness-centrality/)
- [Eigenvector centrality](https://neo4j.com/docs/graph-data-science/current/algorithms/eigenvector-centrality/)
- [Component graph filtering](https://neo4j.com/docs/graph-data-science/current/management-ops/graph-creation/graph-filter/)
