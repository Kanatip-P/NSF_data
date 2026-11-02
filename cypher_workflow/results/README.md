# Fresh Cypher results

The [validated](validated/) folder contains actual result tables from an isolated Neo4j execution of the prepared snapshot. Filenames match `// @query NAME` markers. These exports are distinct from historical reference files under [inputs](../inputs/README.md).

Start with `RQ1_ALL_SUBJECT_COMBINATIONS.csv`, `RQ2_VERIFIED_CLASSIFICATION.csv`, `RQ3_ALL_PERSON_SCORES_AND_RANKS.csv`, `RQ3_TOP_TEN_RANKINGS.csv`, and `RQ3_SPEARMAN_CORRELATIONS.csv`. The complete RQ3 export has one row per person per network; the top-ten export combines five metrics and two networks. Filter the `network` and `metric` columns to select an individual list.

`VALIDATION.json` records versions, environment, row counts, timings, and failing `passed` assertions. The production database-name assertion is not applicable to the isolated database named `neo4j`. All other source and algorithm checks must be assessed from their CSVs. The virtual graph view is represented by its exported node and edge tables; its transient node objects are not a portable graph file.
