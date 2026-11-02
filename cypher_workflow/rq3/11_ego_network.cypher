// @query RQ3_EGO_NODE_TABLE
CALL gds.graph.nodeProperty.stream('nsf_cypher_award','betweenness')
YIELD nodeId,propertyValue
WITH gds.util.asNode(nodeId) AS focal,propertyValue
ORDER BY propertyValue DESC,focal.source_person_key LIMIT 1
MATCH (focal)-[:INVESTIGATOR_ON]->(:Award)<-[:INVESTIGATOR_ON]-(neighbor:Person)
WHERE neighbor<>focal
WITH focal,collect(DISTINCT neighbor)+[focal] AS members
UNWIND members AS p
WITH focal,p ORDER BY p.source_person_key
WITH focal,collect(p) AS members
UNWIND range(0,size(members)-1) AS i
WITH focal,i,members[i] AS p
RETURN i+1 AS figure_node,p.source_person_key AS source_person_key,p.name AS name,p=focal AS focal,
       gds.util.nodeProperty('nsf_cypher_award',p,'degree') AS distinct_collaborators,
       gds.util.nodeProperty('nsf_cypher_award',p,'betweenness')*2.0/((30239.0-1)*(30239.0-2)) AS betweenness_normalized
ORDER BY figure_node;

// @query RQ3_EGO_EDGE_TABLE
CALL gds.graph.nodeProperty.stream('nsf_cypher_award','betweenness')
YIELD nodeId,propertyValue
WITH gds.util.asNode(nodeId) AS focal,propertyValue
ORDER BY propertyValue DESC,focal.source_person_key LIMIT 1
MATCH (focal)-[:INVESTIGATOR_ON]->(:Award)<-[:INVESTIGATOR_ON]-(neighbor:Person)
WHERE neighbor<>focal
WITH focal,collect(DISTINCT neighbor)+[focal] AS members
UNWIND members AS source
MATCH (source)-[:INVESTIGATOR_ON]->(a:Award)<-[:INVESTIGATOR_ON]-(target:Person)
WHERE target IN members AND source.source_person_key<target.source_person_key
RETURN source.source_person_key AS person_1,target.source_person_key AS person_2,
       count(DISTINCT a) AS shared_awards
ORDER BY person_1,person_2;

// @query RQ3_EGO_GRAPH_VIEW
// Virtual nodes/relationships exist in the result only; nothing is written.
CALL gds.graph.nodeProperty.stream('nsf_cypher_award','betweenness')
YIELD nodeId,propertyValue
WITH gds.util.asNode(nodeId) AS focal,propertyValue
ORDER BY propertyValue DESC,focal.source_person_key LIMIT 1
MATCH (focal)-[:INVESTIGATOR_ON]->(:Award)<-[:INVESTIGATOR_ON]-(neighbor:Person)
WHERE neighbor<>focal
WITH focal,collect(DISTINCT neighbor)+[focal] AS members
UNWIND members AS p
WITH focal,members,collect([p.source_person_key,apoc.create.vNode(['Investigator'],
 {source_person_key:p.source_person_key,name:p.name,focal:p=focal,
  degree:gds.util.nodeProperty('nsf_cypher_award',p,'degree'),
  betweenness:gds.util.nodeProperty('nsf_cypher_award',p,'betweenness')*2.0/((30239.0-1)*(30239.0-2))})]) AS pairs
WITH members,apoc.map.fromPairs(pairs) AS virtualNodes
UNWIND members AS source
MATCH (source)-[:INVESTIGATOR_ON]->(a:Award)<-[:INVESTIGATOR_ON]-(target:Person)
WHERE target IN members AND source.source_person_key<target.source_person_key
WITH virtualNodes,source,target,count(DISTINCT a) AS sharedAwards
RETURN virtualNodes[source.source_person_key] AS source,
 apoc.create.vRelationship(virtualNodes[source.source_person_key],'SHARED_AWARD',
   {shared_awards:sharedAwards},virtualNodes[target.source_person_key]) AS relationship,
 virtualNodes[target.source_person_key] AS target;
