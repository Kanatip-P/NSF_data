# RQ3 result files

See [the RQ3 guide](../../docs/RQ3_STEP_BY_STEP.md) for the complete construction,
normalizations, interpretation, commands and cross-checks.

## Primary award network

- [award_investigator_centrality.csv](award_investigator_centrality.csv):
  all 30,239 investigators, roles, award/project counts, funding, scores, ranks
  and components. IDs must remain text.
- [award_edges.csv](award_edges.csv): all 50,882 source-key endpoint pairs;
  `shared_units` counts distinct shared awards. Paths remain unweighted.
- [Degree top ten](award_top10_degree.csv),
  [betweenness top ten](award_top10_betweenness.csv),
  [eigenvector top ten](award_top10_eigenvector.csv),
  [award participation top ten](award_top10_award_participation.csv),
  [funding top ten](award_top10_funding.csv).
- [Correlations](award_spearman_correlations.csv) and
  [top-ten overlaps](award_top10_overlaps.csv).

Degree and betweenness retain the full population. Eigenvector scores and
ranks are available only in the 15,433-person largest component. Full award
amounts are associated exposure, not personal allocations; they overlap across
investigators. Competition ranks use 12-decimal-rounded scores with shared
ranks for ties and person-key display tie breaks. No combined score is used.

## Grouped-project sensitivity

Files starting `grouped_project_` provide the same outputs for the sensitivity
projection: 51,672 edges and a 15,572-person largest component. Individual award
activity and funding stay identical in both projections.

[network_sensitivity.csv](network_sensitivity.csv) compares the two networks.
All three centrality top tens retain the same displayed people, with some
rank changes. The eigenvector comparison states its common component subset.

## Verification and figure

- [summary.json](summary.json): input hashes, software versions, network
  sizes, rankings, correlations and solver diagnostics.
- [verification.json](verification.json): 31 graph-analysis checks, including
  seven synthetic regression tests.
- [ego_node_legend.csv](ego_node_legend.csv) and [ego_edges.csv](ego_edges.csv):
  the numbered investigators and all edges in the plotted local neighborhood.
- [Network figure](figures/rq3_award_betweenness_ego.png): Ian Foster (node 5)
  and 28 immediate neighbors, with all 78 induced edges. The picture is local;
  degree and betweenness values used for styling come from the full network.

The baseline `RQ3_*.csv` files retain the earlier full-cohort project activity,
mutually exclusive person-role groups, and project role-position counts.
The unchanged earlier grouped centrality export is archived under
`evidence/historical_centrality/`.

Run `python analysis/analyze_award_centrality.py`, then
`python analysis/verify_award_centrality.py` from the repository root.
Both use prepared files only. Eigenvector scores are concentrated: 6,004
award-component values are below 1e-12 despite verified connectivity and a
small equation residual. Low-score differences are not interpreted finely.
