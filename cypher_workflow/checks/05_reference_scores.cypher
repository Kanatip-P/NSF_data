// @query ALL_PERSON_REFERENCE_SCORE_CROSSCHECKS
UNWIND [{name:'award',graph:'nsf_cypher_award',lcc:'nsf_cypher_award_lcc',file:'file:///expected_award_centrality.csv'},
        {name:'grouped_project',graph:'nsf_cypher_grouped',lcc:'nsf_cypher_grouped_lcc',file:'file:///expected_grouped_centrality.csv'}] AS network
CALL {
 WITH network
 CALL gds.graph.nodeProperty.stream(network.lcc,'component') YIELD propertyValue
 RETURN head(collect(propertyValue)) AS largestComponent
}
LOAD CSV WITH HEADERS FROM network.file AS expected
MATCH (p:Person {source_person_key:expected.source_person_key})
WITH network,largestComponent,expected,p,
 gds.util.nodeProperty(network.graph,p,'degree') AS degree,
 gds.util.nodeProperty(network.graph,p,'betweenness')*2.0/((30239.0-1)*(30239.0-2)) AS betweenness,
 gds.util.nodeProperty(network.graph,p,'component')=largestComponent AS inLcc
WITH network,expected,degree,betweenness,inLcc,
 CASE WHEN inLcc THEN gds.util.nodeProperty(network.lcc,p,'eigenvector') ELSE null END AS eigenvector
WITH network,count(*) AS compared_people,
 sum(CASE WHEN degree<>toFloat(expected.distinct_collaborators) THEN 1 ELSE 0 END) AS degree_mismatches,
 max(abs(betweenness-toFloat(expected.betweenness_normalized))) AS max_betweenness_error,
 sum(CASE WHEN abs(betweenness-toFloat(expected.betweenness_normalized))>1e-8 THEN 1 ELSE 0 END) AS betweenness_mismatches,
 sum(CASE WHEN inLcc<>(expected.in_largest_component='True') THEN 1 ELSE 0 END) AS component_membership_mismatches,
 max(CASE WHEN inLcc THEN abs(eigenvector-toFloat(expected.eigenvector_centrality)) END) AS max_eigenvector_error,
 sum(CASE WHEN inLcc AND abs(eigenvector-toFloat(expected.eigenvector_centrality))>1e-6 THEN 1 ELSE 0 END) AS eigenvector_mismatches
RETURN network.name AS network,compared_people,degree_mismatches,betweenness_mismatches,
 component_membership_mismatches,eigenvector_mismatches,max_betweenness_error,max_eigenvector_error,
 compared_people=30239 AND degree_mismatches=0 AND betweenness_mismatches=0
 AND component_membership_mismatches=0 AND eigenvector_mismatches=0 AS passed;
