# RQ1 Team structure and subject combinations

RQ1 describes funded project teams, their recorded amounts and durations,
and recurring profile-subject combinations. Its main unit is a **grouped
project**, not an individual award or investigator.

## Step 1 Check the graph and denominator

Select `nsf-project-workon-enriched`, then run Q01 and Q02 from
[RQ1_STEPS.cypher](../queries/RQ1_STEPS.cypher). Expect 17,503 projects,
24,748 awards, 30,239 people and 1,374 recipients, with exactly one owner
project and one recipient per award. These are different counting units.

Archived live results are in
[paper_query_verification.json](../evidence/paper_query_verification.json).
The [prepared manifest](../data/prepared/manifest.json) defines the offline
source rows and hashes.

## Step 2 Count PI and Co-PI team categories

Run Q03 in the same query file. Count `WORK_ON.role` values `PI` and `Co-PI`
on each project, then assign exactly one team category. Former roles remain
in the graph but do not enter this active team classification.

| Category | Projects | Median positive recorded amount USD |
| --- | ---: | ---: |
| One PI and one Co-PI | 7,640 | 299,818 |
| One PI and multiple Co-PIs | 4,059 | 464,102 |
| Multiple PIs and no Co-PI | 3,265 | 508,887 |
| Multiple PIs and Co-PIs | 2,067 | 701,379 |
| One PI and no Co-PI | 472 | 461,928 |

The counts sum to 17,503. Amount medians exclude nonpositive or unavailable
amounts; 17,489 projects have positive amounts. Keep each category's positive
amount denominator. Positive duration medians are calculated offline and are
four years for one PI/one Co-PI and five for the other categories.

Result: [RQ1_project_team_funding.csv](../results/rq1/RQ1_project_team_funding.csv).
Cross-check: Q03's counts, denominators and medians match the archived RQ
analysis; the checker recomputes that entire JSON from prepared files.

## Step 3 Explain multiple PI labels

Run `MULTI_PI_STRUCTURE` in
[SUPPLEMENTAL_CHECKS.cypher](../queries/SUPPLEMENTAL_CHECKS.cypher).
Of 5,332 projects with multiple PI-coded investigators, 5,112 combine multiple
awards and 220 contain one award whose source roster already has multiple
PI labels. This does not prove simultaneous lead PI appointments.

Evidence: [table3_pi_structure_verification.json](../evidence/table3_pi_structure_verification.json).
Use [RQ1_awards_per_project.csv](../results/rq1/RQ1_awards_per_project.csv)
to keep project counts distinct from linked award counts.

## Step 4 Rank the top ten different-subject combinations

Run the first block in
[RQ1_TEAM_SUBJECT_COMBINATIONS.cypher](../queries/RQ1_TEAM_SUBJECT_COMBINATIONS.cypher).
This newer query is supplied for reruns; its reported counts were established
offline and it is not part of the nine archived live blocks.

1. Keep active PI and Co-PI members and deduplicate person identities.
2. Select profile subjects ending in `(all)`.
3. Require two distinct members to support a subject pair. One multi-tagged
   person alone cannot create a team combination.
4. Exclude equal-subject pairs. Sort each pair alphabetically so its reverse
   is the same combination.
5. Count a combination once per project, even if several member pairs support it.
6. Rank by project count descending, breaking ties alphabetically. Percentages
   use all 17,503 projects, including projects lacking sufficient tags.

The leading combination is Engineering + Medicine: **9,351 projects, 53.4%**.
Combinations overlap; their percentages need not sum to 100%.

Results: [top ten](../results/rq1/RQ1_team_subject_combinations_top10.csv),
[all 435 combinations](../results/rq1/RQ1_team_subject_combinations_all.csv).
Remove `LIMIT 10` from the query to retrieve the full ranking.

## Step 5 Check subject coverage

Run the second and third blocks in that file. Expected counts:

- 14,329 projects have at least two distinct active members with broad tags.
- 14,217 support at least one different-subject combination.

Result: [coverage JSON](../results/rq1/RQ1_team_subject_combination_coverage.json).
Do not confuse this subjects-only coverage with the separate joint
subjects-and-affiliation coverage measure.

## Step 6 Keep ordered PI–Co-PI results separate

The prior ordered analysis counts one PI–Co-PI–project observation, not one
project per unordered subject pair. It has 28,038 observations; 21,653 have
broad tags on both people and 20,736 of those share a tag. Its eight leading
cells are in [RQ1_leading_ordered_tag_cells.csv](../results/rq1/RQ1_leading_ordered_tag_cells.csv).
These cells can overlap and include same-subject pairs. Do not merge this
table with the new top ten or give them the same denominator.

## Step 7 Recompute and cross-check offline

```shell
python analysis/analyze_rqs.py
python scripts/export_rq1.py
python analysis/test_subject_combinations.py
python scripts/check_repository.py
```

The first command writes `results/rq_analysis.json`; the exporter writes the
subject CSVs and coverage JSON. Tests check reversed pairs, repeated roster
entries, former roles, same-subject exclusion, single-person multi-tag
exclusion, denominators and ties. The repository checker compares the full
ranking and complete RQ analysis against the delivered reference JSON.
Profile subjects describe investigators' publication profiles and do not
establish the funded project's topic or direct collaboration.
