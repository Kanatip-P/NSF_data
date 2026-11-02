# RQ1 result files

See [the RQ1 guide](../../docs/RQ1_STEP_BY_STEP.md) for counting rules and commands.

| File | Meaning | Source and check |
| --- | --- | --- |
| [RQ1_project_team_funding.csv](RQ1_project_team_funding.csv) | Five team categories, project counts, positive-amount medians/denominators, positive duration medians | Live Q03 plus offline duration calculation |
| [RQ1_awards_per_project.csv](RQ1_awards_per_project.csv) | Number of selected awards per grouped project | Archived supplemental live query |
| [RQ1_team_subject_combinations_top10.csv](RQ1_team_subject_combinations_top10.csv) | Ten leading unordered different-subject combinations | Offline subject calculation, supplied Cypher equivalent |
| [RQ1_team_subject_combinations_all.csv](RQ1_team_subject_combinations_all.csv) | All 435 combinations | Full recomputation compared to reference JSON |
| [RQ1_team_subject_combination_coverage.json](RQ1_team_subject_combination_coverage.json) | Broad-tagged-member and combination coverage | 14,329 and 14,217 projects respectively |
| [RQ1_leading_ordered_tag_cells.csv](RQ1_leading_ordered_tag_cells.csv) | Eight prior ordered PI–Co-PI subject cells | Different observation unit; kept separate |

Regenerate the RQ analysis with `python analysis/analyze_rqs.py`, then export
the subject tables with `python scripts/export_rq1.py`, from the repository root.
The project funding table combines archived live Q03 values and offline
duration medians; its derivation is checked by the full RQ JSON recomputation.
