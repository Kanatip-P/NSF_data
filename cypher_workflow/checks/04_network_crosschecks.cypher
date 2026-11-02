// @query NETWORK_STRUCTURE_CROSSCHECKS
UNWIND [{graph:'nsf_cypher_award',people:30239,edges:50882,components:4355,lcc:15433},
        {graph:'nsf_cypher_grouped',people:30239,edges:51672,components:4304,lcc:15572}] AS expected
CALL gds.graph.list(expected.graph) YIELD nodeCount,relationshipCount
CALL {
 WITH expected
 CALL gds.graph.nodeProperty.stream(expected.graph,'degree') YIELD propertyValue
 RETURN sum(propertyValue) AS degreeSum,count(CASE WHEN propertyValue=0 THEN 1 END) AS isolated
}
CALL {
 WITH expected
 CALL gds.graph.nodeProperty.stream(expected.graph,'component') YIELD propertyValue
 WITH propertyValue,count(*) AS people
 RETURN count(*) AS components,max(people) AS largestComponent,sum(people) AS componentPopulation
}
RETURN expected.graph AS graph,nodeCount AS people,relationshipCount/2 AS edges,components,
 largestComponent,isolated,degreeSum=relationshipCount AS degree_sum_matches_arcs,
 nodeCount=expected.people AND relationshipCount=2*expected.edges AND components=expected.components
 AND largestComponent=expected.lcc AND componentPopulation=nodeCount AND degreeSum=relationshipCount AS passed;
