// @query RQ3_TOP_TEN_OVERLAPS

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
UNWIND ['degree','betweenness','eigenvector','award_participation','funding'] AS metric
CALL {
 WITH population,metric
 UNWIND population AS r
 WITH r,metric WHERE r[metric] IS NOT NULL AND (metric<>'funding' OR r.funding_complete)
 WITH r,round(toFloat(r[metric]),12) AS score
 ORDER BY score DESC,r.id LIMIT 10
 RETURN collect({row:r,score:score}) AS leaders
}
UNWIND range(0,size(leaders)-1) AS i
WITH network,metric,leaders[i].row AS r,leaders[i].score AS ranked_score,i+1 AS position,
 1+size([v IN leaders WHERE v.score>leaders[i].score]) AS rank

WHERE position<=10
WITH network,metric,collect(r.id) AS ids
WITH network,collect({metric:metric,ids:ids}) AS lists
UNWIND range(0,size(lists)-2) AS i
UNWIND range(i+1,size(lists)-1) AS j
RETURN network.name AS network,lists[i].metric AS ranking_1,lists[j].metric AS ranking_2,
  size([id IN lists[i].ids WHERE id IN lists[j].ids]) AS shared_top10_people
ORDER BY network,ranking_1,ranking_2;
