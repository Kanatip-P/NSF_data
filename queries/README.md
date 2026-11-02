# Read-only Cypher query map

First select the intended database in Neo4j Browser, running this command
separately:

```cypher
:use `nsf-project-workon-enriched`
```

Run one numbered block at a time, not several `MATCH` queries pasted together.

| File | Purpose | Execution status |
| --- | --- | --- |
| [CORE_VERIFICATION.cypher](CORE_VERIFICATION.cypher) | Exact original nine core query blocks | Archived live execution and eleven passing comparisons |
| [RQ1_STEPS.cypher](RQ1_STEPS.cypher) | Population, ownership, team categories and amount medians | Exact core blocks grouped for RQ1 |
| [RQ1_TEAM_SUBJECT_COMBINATIONS.cypher](RQ1_TEAM_SUBJECT_COMBINATIONS.cypher) | Top ten and subject coverage | Supplied for live rerun; results independently computed offline |
| [RQ2_STEPS.cypher](RQ2_STEPS.cypher) | Raw codes, identity recovery, verified classification | Exact core blocks grouped for RQ2; Q07 requires parameters |
| [RQ3_STEPS.cypher](RQ3_STEPS.cypher) | All-person project activity and coverage | Exact core blocks grouped for RQ3 |
| [RQ3_NETWORK_SOURCE_READS.cypher](RQ3_NETWORK_SOURCE_READS.cypher) | Source extraction for the two network projections | Supplied read-only queries; centralities are calculated offline |
| [RQ3_DIRECT_DEGREE_AND_FUNDING.cypher](RQ3_DIRECT_DEGREE_AND_FUNDING.cypher) | Direct degree and award funding reconciliation | Additional optional manual reruns, not archived live results |
| [SUPPLEMENTAL_CHECKS.cypher](SUPPLEMENTAL_CHECKS.cypher) | Grouping, roles and multiple PI labels | Original queries preserved from archived supplemental evidence |

Q07 expects the complete object in
[parameters/classifications.json](parameters/classifications.json), supplied
through Browser's `:params` command or automatically by
`python scripts/run_live_checks.py --rq 2` from the repository root.

No query here creates, updates, deletes, imports, or renames database data.
There is no hidden GDS write step. RQ3's Python script explicitly builds the
investigator adjacency structure from the enclosed graph exports and applies
igraph's exact betweenness and largest-component eigenvector algorithms.
