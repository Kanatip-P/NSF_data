// Small graph checks use virtual integer node IDs in GDS memory only.
// @query FIXTURE_PATH_AND_ISOLATE_PROJECT
UNWIND [[0,1],[1,2],[3,null]] AS edge
RETURN gds.graph.project('nsf_cypher_fixture_path',edge[0],edge[1],{},
 {undirectedRelationshipTypes:['*']}) AS projection;

// @query FIXTURE_PATH_BETWEENNESS
CALL gds.betweenness.stream('nsf_cypher_fixture_path',{samplingSize:4,concurrency:1})
YIELD nodeId,score
RETURN nodeId,score,CASE WHEN nodeId=1 THEN abs(score-1)<1e-9 ELSE abs(score)<1e-9 END AS passed
ORDER BY nodeId;

// @query FIXTURE_PATH_DEGREE
CALL gds.degree.stream('nsf_cypher_fixture_path',{concurrency:1}) YIELD nodeId,score
RETURN nodeId,score,score=CASE WHEN nodeId=1 THEN 2 WHEN nodeId=3 THEN 0 ELSE 1 END AS passed
ORDER BY nodeId;

// @query FIXTURE_TRIANGLE_PROJECT
UNWIND [[0,1],[1,2],[0,2]] AS edge
RETURN gds.graph.project('nsf_cypher_fixture_triangle',edge[0],edge[1],{},
 {undirectedRelationshipTypes:['*']}) AS projection;

// @query FIXTURE_TRIANGLE_EIGENVECTOR
CALL gds.eigenvector.stream('nsf_cypher_fixture_triangle',
 {maxIterations:10000,tolerance:1e-12,scaler:'Max',concurrency:1}) YIELD nodeId,score
RETURN nodeId,score,abs(score-1)<1e-9 AS passed ORDER BY nodeId;

// @query FIXTURE_TRIANGLE_BETWEENNESS
CALL gds.betweenness.stream('nsf_cypher_fixture_triangle',{samplingSize:3,concurrency:1})
YIELD nodeId,score RETURN nodeId,score,abs(score)<1e-9 AS passed ORDER BY nodeId;

// @query FIXTURE_STAR_PROJECT
UNWIND [[0,1],[0,2],[0,3],[0,4]] AS edge
RETURN gds.graph.project('nsf_cypher_fixture_star',edge[0],edge[1],{},
 {undirectedRelationshipTypes:['*']}) AS projection;

// @query FIXTURE_STAR_BETWEENNESS
CALL gds.betweenness.stream('nsf_cypher_fixture_star',{samplingSize:5,concurrency:1})
YIELD nodeId,score
RETURN nodeId,score,CASE WHEN nodeId=0 THEN abs(score-6)<1e-9 ELSE abs(score)<1e-9 END AS passed
ORDER BY nodeId;

// @query FIXTURE_DISCONNECTED_PROJECT
UNWIND [[0,1],[1,2],[3,4],[5,null]] AS edge
RETURN gds.graph.project('nsf_cypher_fixture_disconnected',edge[0],edge[1],{},
 {undirectedRelationshipTypes:['*']}) AS projection;

// @query FIXTURE_DISCONNECTED_COMPONENTS
CALL gds.wcc.stream('nsf_cypher_fixture_disconnected',{concurrency:1}) YIELD componentId
WITH componentId,count(*) AS people
RETURN count(*) AS components,sum(people) AS total_people,max(people) AS largest_component,
 count(*)=3 AND sum(people)=6 AND max(people)=3 AS passed;

// @query FIXTURE_COMPETITION_RANKS
UNWIND [{id:'a',score:10},{id:'b',score:10},{id:'c',score:5}] AS r
WITH r ORDER BY r.score DESC,r.id
WITH r.score AS score,collect(r) AS members ORDER BY score DESC
WITH collect({score:score,members:members}) AS groups
WITH groups,apoc.coll.runningTotal([g IN groups | size(g.members)]) AS ends
UNWIND range(0,size(groups)-1) AS i
WITH groups[i].members AS members,ends[i]-size(groups[i].members)+1 AS rank
UNWIND members AS r
RETURN r.id AS id,rank,rank=CASE WHEN r.id='c' THEN 3 ELSE 1 END AS passed ORDER BY id;

// @query FIXTURE_TIED_SPEARMAN
WITH {name:'fixture'} AS network,{x:'x',y:'y'} AS pair,
 [{x:1.0,y:2.0},{x:1.0,y:1.0},{x:2.0,y:3.0}] AS rows

WITH network,pair,rows
UNWIND rows AS sample
WITH network,pair,sample.x AS x,collect(sample) AS members
ORDER BY network.name,pair.x,pair.y,x
WITH network,pair,collect({members:members}) AS groups
WITH network,pair,groups,apoc.coll.runningTotal([g IN groups | size(g.members)]) AS ends
UNWIND range(0,size(groups)-1) AS i
WITH network,pair,groups[i].members AS members,
     ends[i]-(size(groups[i].members)-1)/2.0 AS xRank
UNWIND members AS sample
WITH network,pair,sample.y AS y,collect({xRank:xRank}) AS members
ORDER BY network.name,pair.x,pair.y,y
WITH network,pair,collect({members:members}) AS groups
WITH network,pair,groups,apoc.coll.runningTotal([g IN groups | size(g.members)]) AS ends
UNWIND range(0,size(groups)-1) AS i
WITH network,pair,groups[i].members AS members,
     ends[i]-(size(groups[i].members)-1)/2.0 AS yRank
UNWIND members AS sample
WITH network,pair,count(*) AS people,sum(sample.xRank) AS sx,sum(yRank) AS sy,
     sum(sample.xRank*yRank) AS sxy,sum(sample.xRank*sample.xRank) AS sxx,sum(yRank*yRank) AS syy
WITH network,pair,people,people*sxy-sx*sy AS numerator,
     (people*sxx-sx*sx)*(people*syy-sy*sy) AS varianceProduct

RETURN people,numerator/sqrt(varianceProduct) AS rho,
 abs(numerator/sqrt(varianceProduct)-sqrt(3.0)/2)<1e-9 AS passed;

// @query FIXTURE_CLEANUP
UNWIND ['nsf_cypher_fixture_path','nsf_cypher_fixture_triangle',
 'nsf_cypher_fixture_star','nsf_cypher_fixture_disconnected'] AS graph
CALL gds.graph.drop(graph,false) YIELD graphName RETURN graphName;
