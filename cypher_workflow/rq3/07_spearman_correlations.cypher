// @query RQ3_SPEARMAN_CORRELATIONS

UNWIND [{name:'award',graph:'nsf_cypher_award',lcc:'nsf_cypher_award_lcc'},
        {name:'grouped_project',graph:'nsf_cypher_grouped',lcc:'nsf_cypher_grouped_lcc'}] AS network
CALL {
  WITH network
  CALL gds.graph.nodeProperty.stream(network.graph,'component') YIELD propertyValue
  WITH propertyValue AS component,count(*) AS people
  RETURN apoc.map.fromPairs(collect([toString(component),people])) AS sizes
}
CALL {
  WITH network
  CALL gds.graph.nodeProperty.stream(network.lcc,'component') YIELD propertyValue
  RETURN head(collect(propertyValue)) AS largestComponent
}
MATCH (person:Person)
CALL {
  WITH person
  OPTIONAL MATCH (person)-[w:INVESTIGATOR_ON]->(a:Award)
  WITH a,collect(coalesce(w.roles,CASE WHEN w.role IS NULL THEN [] ELSE [w.role] END)) AS roles
  WITH collect(a) AS awards,collect(roles) AS roleGroups
  WITH awards,reduce(allRoles=[],groups IN roleGroups |
    allRoles+reduce(flat=[],r IN groups | flat+r)) AS roles
  RETURN size(awards) AS awardCount,
    size([a IN awards WHERE a.total_amount IS NOT NULL]) AS known,
    size([a IN awards WHERE a.total_amount>0]) AS positive,
    size([a IN awards WHERE a.total_amount=0]) AS zeros,
    size([a IN awards WHERE a.total_amount<0]) AS negatives,
    reduce(amount=0.0,a IN awards | amount+CASE WHEN a.total_amount>0 THEN a.total_amount ELSE 0 END) AS amount,
    apoc.coll.sort(apoc.coll.toSet(roles)) AS roles
}
CALL {
  WITH person
  OPTIONAL MATCH (person)-[:WORK_ON]->(p:Project)
  RETURN count(DISTINCT p) AS projectCount
}
WITH network,sizes,largestComponent,person,awardCount,known,positive,zeros,negatives,amount,roles,projectCount,
     gds.util.nodeProperty(network.graph,person,'degree') AS degree,
     gds.util.nodeProperty(network.graph,person,'betweenness') AS between,
     gds.util.nodeProperty(network.graph,person,'component') AS component
WITH network,{id:person.source_person_key,name:person.name,roles:roles,
  award_participation:awardCount,projects:projectCount,
  funding:CASE WHEN known=0 THEN null ELSE amount END,
  positive_amount_awards:positive,zero_amount_awards:zeros,negative_amount_awards:negatives,
  missing_amount_awards:awardCount-known,funding_complete:awardCount>0 AND known=awardCount,
  distinct_collaborators:degree,degree:degree/(30239.0-1),
  betweenness_raw:between,betweenness:between*2.0/((30239.0-1)*(30239.0-2)),
  eigenvector:CASE WHEN component=largestComponent
    THEN gds.util.nodeProperty(network.lcc,person,'eigenvector') ELSE null END,
  component_id:toInteger(component),component_size:sizes[toString(toInteger(component))],
  in_largest_component:component=largestComponent} AS r

WITH network,collect(r) AS population
UNWIND [{x:'degree',y:'betweenness'},{x:'degree',y:'eigenvector'},
 {x:'degree',y:'award_participation'},{x:'degree',y:'funding'},
 {x:'betweenness',y:'eigenvector'},{x:'betweenness',y:'award_participation'},
 {x:'betweenness',y:'funding'},{x:'eigenvector',y:'award_participation'},
 {x:'eigenvector',y:'funding'},{x:'award_participation',y:'funding'}] AS pair
UNWIND population AS r
WITH network,pair,r WHERE r[pair.x] IS NOT NULL AND r[pair.y] IS NOT NULL
 AND (NOT 'funding' IN [pair.x,pair.y] OR r.funding_complete)
WITH network,pair,collect({x:round(toFloat(r[pair.x]),12),y:round(toFloat(r[pair.y]),12)}) AS rows

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

RETURN network.name AS network,pair.x AS measure_1,pair.y AS measure_2,people,
  CASE WHEN varianceProduct>0 THEN numerator/sqrt(varianceProduct) ELSE null END AS spearman_rho
ORDER BY network,measure_1,measure_2;
