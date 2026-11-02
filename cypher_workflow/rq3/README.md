# RQ3: investigator prominence and funding exposure

Run **01 through 11**, including every query block, before cleanup. Export each table as CSV. All source persons remain in both projections, including disconnected or isolated people.

| Files | Calculation / output |
| --- | --- |
| [01](01_activity_and_funding.cypher) | Distinct awards, grouped projects, recorded roles, funding amount completeness and positive funding exposure. |
| [02](02_project_award_network.cypher), [03](03_award_eigenvector.cypher) | Primary shared-individual-award graph; degree, exact betweenness, components, largest-component eigenvector. |
| [04](04_project_grouped_network.cypher) | Same source people and roles, projected through grouped projects as sensitivity analysis. |
| [05](05_all_person_scores_and_ranks.cypher) | Complete 60,478 person/network rows, activity, funding, components, scores, ranks. |
| [06](06_top_ten_rankings.cypher) | Exactly ten rows for each of five metrics in each network: 100 rows total. |
| [07](07_spearman_correlations.cypher) | Within-network descriptive correlations using average ranks for ties. |
| [08](08_top_ten_overlaps.cypher) | Pairwise intersection of the five displayed top-ten lists. |
| [09](09_between_network_correlations.cypher), [10](10_between_network_top_tens.cypher) | Ranking stability and top-ten overlap between award and grouped-project projections. |
| [11](11_ego_network.cypher) | Highest-betweenness investigator and immediate neighbors: node table, induced edge table, and Browser virtual graph view. |

## Definitions

Two distinct people have one undirected, unweighted edge when recorded on the same selected individual Award. All recorded roles, including former roles, are included. Repeated shared awards are an edge attribute, never a path-length weight. A projection stores two directed arcs per undirected edge. No self-loops are emitted. Grouped-project sensitivity uses the same definition with Project in place of Award.

For the full population `N = 30,239`, degree centrality is `k/(N-1)`. Betweenness sums the fraction of shortest paths through a node over unordered pairs of other nodes, excludes endpoints, and is normalized by `2/((N-1)*(N-2))`. GDS is run without sampling: exact betweenness. Disconnected pairs contribute zero. The path fixture confirms the raw score convention; do not halve it a second time.

Eigenvector centrality solves `A*x = lambda*x` within each network's largest connected component and scales its maximum to one. The Cypher query explicitly iterates `(A+I)*x`, dividing by its maximum each iteration; the identity shift preserves eigenvectors and avoids oscillation on bipartite graphs. It stops when the maximum change is below `1e-13`, with a limit of 1,000 iterations. The resulting property is attached only to an in-memory projection. Scores outside that component are unavailable. Require `didConverge = true`; the equation residual is checked independently. The award LCC has 15,433 people; the grouped LCC has 15,572. Between-network eigenvector comparisons use their common LCC people and state both original populations.

The explicit Cypher iteration is intentional: in the tested GDS version, a direct eigenvector call on this dataset returned an all-zero vector despite reporting convergence. That result was rejected. Convergence flags alone are insufficient; the supplied path fixture, nonzero maximum, reference scores, and eigenvector equation must also pass.

Funding exposure sums positive `Award.total_amount` once per distinct linked Award. Positive, zero, negative, known and missing award counts are separate. Shared awards contribute their full amount to every linked investigator; totals overlap. Funding rankings/correlations exclude incomplete totals rather than treating missing amounts as zero.

Rank scores are rounded to 12 decimal places to stabilize floating-point ties. Competition ranks are preserved (1, 1, 3). Person keys order ties and select exactly ten displayed rows. Spearman uses average tied ranks, pairwise usable observations, and the LCC subset whenever eigenvector is involved. There is no composite performance score or causal inference.

## Expected structure and interpretation

The award graph has 50,882 edges and 4,355 components; the grouped graph has 51,672 edges and 4,304 components. Both retain all 30,239 people. Jennifer Zaspel leads direct connectivity and LCC eigenvector; Ian Foster leads betweenness. Degree rewards immediate neighbors, betweenness rewards shortest-path bridges, and eigenvector rewards links to other prominent nodes. These can produce different leaders without implying differences in research quality.

In the validated award graph, Spearman correlations with award participation are approximately 0.574 for degree, 0.695 for betweenness, and 0.232 for LCC eigenvector. Corresponding funding-exposure correlations are 0.574, 0.513, and 0.162. These descriptive associations do not identify causes. The grouped projection adds 790 edges and reduces the number of components by 51; each displayed top-ten list retains all ten people, while scores and some ranks change. Consult the exported between-network correlations and full scores for changes beyond the displayed leaders; the two eigenvector populations differ.

Run all [network and funding checks](../checks/README.md) before publishing. The local graph is an induced neighborhood, **not the full network**. Its virtual node properties carry degree-based size and betweenness for styling; Browser's rendering preferences determine the visual layout. Use the exported node and edge tables for a reproducible figure.
