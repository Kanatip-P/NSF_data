# RQ1: team structure and profile subjects

Run all query blocks in these files in order. Export each result using its `@query` name.

| Step | Cypher file | Output and check |
| --- | --- | --- |
| 1 | [01_team_funding](01_team_funding.cypher) | Five PI/Co-PI configurations; project counts, positive funding/duration denominators and medians. Counts must sum to 17,503. |
| 2 | [02_subject_combinations](02_subject_combinations.cypher) | Complete 435-combination ranking; filter `rank <= 10` for the top ten. Counts descend, ties sort alphabetically. |
| 3 | [03_subject_coverage](03_subject_coverage.cypher) | 14,329 projects with two usable tagged members; 14,217 with a different-subject combination. |
| 4 | [04_ordered_pairs](04_ordered_pairs.cypher) | Separate ordered PI→Co-PI analysis, tag agreement, and repeated member pairs. |
| 5 | [05_grouping_crosschecks](05_grouping_crosschecks.cypher) | Awards per grouped project and multi-PI source-roster explanation. |
| 6 | [06_top_ten_combinations](06_top_ten_combinations.cypher) | Separate ten-row subject-combination table, using exactly the same counting rules as the complete ranking. |

The combination query uses broad profile labels ending in `(all)` on two **distinct active PI/Co-PI members**. Each unordered, different-subject combination counts once per project, even if multiple people support it. A single person's multiple tags cannot produce a combination alone. Engineering + Medicine and its reversal merge; same-subject combinations are excluded. Projects can support multiple combinations, so percentages use all **17,503 projects** and need not sum to 100%.

The first combination is Engineering (all) + Medicine (all), 9,351 projects (53.4%). The ordered PI–Co-PI tables remain a separate analysis. Multi-PI source labels do not prove simultaneous lead PIs.

Run the [reference cross-check](../checks/03_rq1_subjects.cypher) and [independent matrix](../checks/08_independent_subject_matrix.cypher) after calculation. They compare all combinations and ranks with the reference and independently reconstruct the subject matrix.
