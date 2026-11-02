// @query RQ3_AWARD_LARGEST_COMPONENT
CALL gds.graph.nodeProperty.stream('nsf_cypher_award','component')
YIELD propertyValue
WITH toInteger(propertyValue) AS component,count(*) AS people
ORDER BY people DESC,component LIMIT 1
MATCH (source:Person)
WHERE gds.util.nodeProperty('nsf_cypher_award',source,'component')=component
OPTIONAL MATCH (source)-[:INVESTIGATOR_ON]->(award:Award)<-[:INVESTIGATOR_ON]-(target:Person)
WHERE source.source_person_key<target.source_person_key
WITH source,target,component,count(DISTINCT award) AS sharedUnits
WITH component,gds.graph.project('nsf_cypher_award_lcc',source,target,
 {sourceNodeProperties:{component:component},targetNodeProperties:{component:component},
  relationshipType:'CO_AWARD',relationshipProperties:{sharedUnits:sharedUnits}},
 {undirectedRelationshipTypes:['*']}) AS graph
RETURN graph.graphName AS graphName,graph.nodeCount AS nodeCount,
 graph.relationshipCount AS relationshipCount,component;

// @query RQ3_AWARD_EIGENVECTOR
// Explicit normalized power iteration in Cypher; no stored graph writes.
// (A+I) has the same principal eigenvector as A and avoids bipartite oscillation.
CALL gds.graph.nodeProperty.stream('nsf_cypher_award_lcc','component') YIELD propertyValue
WITH toInteger(head(collect(propertyValue))) AS component
MATCH (p:Person)
WHERE gds.util.nodeProperty('nsf_cypher_award',p,'component')=component
CALL {
 WITH p
 MATCH (p)-[:INVESTIGATOR_ON]->(:Award)<-[:INVESTIGATOR_ON]-(q:Person) WHERE q<>p
 RETURN collect(DISTINCT q) AS neighbors
}
WITH component,p,neighbors ORDER BY p.source_person_key
WITH component,collect({p:p,neighbors:neighbors}) AS rows
WITH component,rows,range(0,size(rows)-1) AS positions,
 apoc.map.fromPairs([i IN range(0,size(rows)-1) | [rows[i].p.source_person_key,i]]) AS indices
WITH component,rows,positions,[r IN rows | [q IN r.neighbors | indices[q.source_person_key]]] AS adjacency
WITH component,rows,positions,reduce(state={x:[j IN positions | 1.0],delta:1.0,iterations:0},step IN range(1,1000) |
 CASE WHEN state.delta<1e-13 THEN state ELSE
 head([next IN [[j IN positions | state.x[j]+reduce(total=0.0,k IN adjacency[j] | total+state.x[k])]] |
 head([scale IN [reduce(largest=0.0,v IN next | CASE WHEN v>largest THEN v ELSE largest END)] |
 head([normalized IN [[v IN next | v/scale]] |
 {x:normalized,iterations:step,
  delta:reduce(error=0.0,j IN positions |
    CASE WHEN abs(normalized[j]-state.x[j])>error THEN abs(normalized[j]-state.x[j]) ELSE error END)}])])]) END) AS state
WITH component,rows,state,apoc.map.fromPairs([i IN range(0,size(rows)-1) |
 [rows[i].p.source_person_key,state.x[i]]]) AS scores
WITH component,rows,state.iterations AS iterations,state.delta AS delta,scores
CALL gds.graph.drop('nsf_cypher_award_lcc') YIELD graphName
UNWIND rows AS row
WITH component,iterations,delta,scores,row.p AS source,row.neighbors AS neighbors
UNWIND neighbors AS target
WITH component,iterations,delta,scores,source,target WHERE source.source_person_key<target.source_person_key
WITH component,iterations,delta,gds.graph.project('nsf_cypher_award_lcc',source,target,
 {sourceNodeProperties:{component:component,eigenvector:scores[source.source_person_key]},
  targetNodeProperties:{component:component,eigenvector:scores[target.source_person_key]},
  relationshipType:'CO_MEMBER'}, {undirectedRelationshipTypes:['*']}) AS graph
RETURN delta<1e-13 AS didConverge,iterations AS ranIterations,
 delta AS max_iteration_change,graph.nodeCount AS nodePropertiesWritten;
