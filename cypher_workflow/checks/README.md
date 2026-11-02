# Cross-check execution

Run the [library fixtures](../00_setup/02_library_fixtures.cypher) before RQ3, then these numbered files after all RQ3 projections exist. Do not clean up GDS graphs until all checks and exports are complete.

| File | Evidence |
| --- | --- |
| [02](02_counting_fixtures.cypher) | Synthetic duplicate/reversed/same-person subject cases and distinct-award funding with zero, negative, and missing amounts. |
| [03](03_rq1_subjects.cypher) | All 435 subject counts and ranks versus the reference. |
| [04](04_network_crosschecks.cypher) | People/edges/components/LCC, isolate count, component-size sum, degree sum equals twice edges. |
| [05](05_reference_scores.cypher) | Every person in each network versus existing degree/betweenness/eigenvector results and LCC membership. Tolerances: normalized betweenness `1e-8`, eigenvector `1e-6`. |
| [06](06_funding_crosscheck.cypher) | All people: distinct awards/projects, positive funding, and missing-amount counts against existing results. |
| [07](07_eigenvector_residual.cypher) | Independently reconstruct adjacency from distinct roster neighbors; estimate lambda and test `A*x = lambda*x`, relative L2 residual below `1e-9`. |
| [08](08_independent_subject_matrix.cypher) | Independently enumerate each project's subject universe and test distinct-member support, then compare the complete matrix. |

Fixtures exercise paths, stars, triangles, disconnected graphs, an isolated node, tied competition ranks, and average-rank Spearman. RQ1 membership queries require different person keys and distinct projects, so repeated memberships or reversed subjects cannot inflate the output; the independently sorted subject matrix provides a second counting route. RQ2 checks retain the exact UnitID exception and reconcile the complete crosswalk. RQ3 graph queries deduplicate pairs, forbid equal source/target keys, and use all recorded roles.

The actual validation exports and environment record are under [results/validated](../results/validated/). Inspect every `passed`, mismatch count, and convergence field; a successful query execution alone is insufficient. The isolated validation database is named `neo4j`, so its production database-name assertion is explicitly not applicable. Cohort and algorithm checks still run against all prepared records. No claim is made that these queries were run against the user's live database.
