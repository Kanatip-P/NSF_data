// Run once per session. This creates ONLY an in-memory GDS projection.
// Each unordered pair is emitted once; OPTIONAL MATCH retains every Person.
// @query RQ3_PROJECT_AWARD_NETWORK
MATCH (source:Person)
OPTIONAL MATCH (source)-[:INVESTIGATOR_ON]->(award:Award)<-[:INVESTIGATOR_ON]-(target:Person)
WHERE source.source_person_key < target.source_person_key
WITH source,target,count(DISTINCT award) AS sharedUnits
WITH gds.graph.project('nsf_cypher_award',source,target,
  {relationshipType:'CO_AWARD',relationshipProperties:{sharedUnits:sharedUnits}},
  {undirectedRelationshipTypes:['*']}) AS graph
RETURN graph.graphName AS graph_name, graph.nodeCount AS people,
       graph.relationshipCount AS stored_arcs, graph.relationshipCount/2 AS undirected_edges;

// @query RQ3_AWARD_DEGREE
CALL gds.degree.mutate('nsf_cypher_award', {mutateProperty:'degree',concurrency:1})
YIELD nodePropertiesWritten
RETURN nodePropertiesWritten;

// @query RQ3_AWARD_BETWEENNESS
// Omitting samplingSize uses ALL nodes as sources: exact, not sampled.
CALL gds.betweenness.mutate('nsf_cypher_award', {mutateProperty:'betweenness',concurrency:4})
YIELD nodePropertiesWritten
RETURN nodePropertiesWritten;

// @query RQ3_AWARD_COMPONENTS
CALL gds.wcc.mutate('nsf_cypher_award', {mutateProperty:'component',concurrency:1})
YIELD componentCount,nodePropertiesWritten
RETURN componentCount,nodePropertiesWritten;
