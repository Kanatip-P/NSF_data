// @query EIGENVECTOR_EQUATION_CROSSCHECK
UNWIND [{name:'award',graph:'nsf_cypher_award',lcc:'nsf_cypher_award_lcc'},
        {name:'grouped_project',graph:'nsf_cypher_grouped',lcc:'nsf_cypher_grouped_lcc'}] AS network
CALL gds.graph.nodeProperty.stream(network.lcc,'eigenvector') YIELD nodeId,propertyValue
WITH network,gds.util.asNode(nodeId) AS p,propertyValue AS x
CALL {
 WITH network,p
 MATCH (p)-[:INVESTIGATOR_ON]->(:Award)<-[:INVESTIGATOR_ON]-(q:Person)
 WHERE network.name='award' AND q<>p
 RETURN DISTINCT q
 UNION
 WITH network,p
 MATCH (p)-[:WORK_ON]->(:Project)<-[:WORK_ON]-(q:Person)
 WHERE network.name='grouped_project' AND q<>p
 RETURN DISTINCT q
}
WITH network,p,x,sum(gds.util.nodeProperty(network.lcc,q,'eigenvector')) AS ax
WITH network,collect({x:x,ax:ax}) AS rows,sum(x*ax)/sum(x*x) AS eigenvalue
WITH network,rows,eigenvalue,
 sqrt(reduce(error=0.0,r IN rows | error+(r.ax-eigenvalue*r.x)^2)/
      reduce(denominator=0.0,r IN rows | denominator+(eigenvalue*r.x)^2)) AS relative_residual
RETURN network.name AS network,size(rows) AS largest_component_people,eigenvalue,relative_residual,
       relative_residual<1e-9 AS passed;
