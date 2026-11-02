// @query RQ3_ALL_PERSON_SCORES_AND_RANKS

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
WITH network,population,apoc.map.fromPairs([r IN population | [r.id,r]]) AS byKey
UNWIND ['degree','betweenness','eigenvector','award_participation','funding'] AS metric
CALL {
WITH network,population,metric
UNWIND population AS r
WITH network,metric,r WHERE r[metric] IS NOT NULL AND (metric<>'funding' OR r.funding_complete)
WITH network,metric,r.id AS personKey,round(toFloat(r[metric]),12) AS score
ORDER BY network.name,metric,score DESC,personKey
WITH network,metric,score,collect(personKey) AS members
ORDER BY network.name,metric,score DESC
WITH network,metric,collect({score:score,members:members}) AS groups
WITH network,metric,groups,apoc.coll.runningTotal([g IN groups | size(g.members)]) AS ends
UNWIND range(0,size(groups)-1) AS i
WITH network,metric,groups[i] AS g,ends[i]-size(groups[i].members) AS previous
UNWIND range(0,size(g.members)-1) AS j
WITH network,metric,g.members[j] AS personKey,g.score AS ranked_score,previous+1 AS rank,previous+j+1 AS position
RETURN personKey,ranked_score,rank,position
}
WITH network,metric,byKey[personKey] AS r,ranked_score,rank,position

WITH network,r.id AS personKey,head(collect(r)) AS r,
     apoc.map.fromPairs(collect([metric+'_rank',rank])) AS ranks
RETURN network.name AS network,r.id AS source_person_key,r.name AS name,r.roles AS roles,
  r.award_participation AS awards,r.projects AS projects,r.funding AS associated_positive_award_funding_usd,
  r.positive_amount_awards AS positive_amount_awards,r.zero_amount_awards AS zero_amount_awards,
  r.negative_amount_awards AS negative_amount_awards,r.missing_amount_awards AS missing_amount_awards,
  r.funding_complete AS funding_complete,r.distinct_collaborators AS distinct_collaborators,
  r.degree AS degree_centrality,r.betweenness_raw AS betweenness_raw,r.betweenness AS betweenness_normalized,
  r.eigenvector AS eigenvector_centrality,r.component_id AS component_id,r.component_size AS component_size,
  r.in_largest_component AS in_largest_component,
  ranks.degree_rank AS degree_rank,ranks.betweenness_rank AS betweenness_rank,
  ranks.eigenvector_rank AS eigenvector_rank,ranks.award_participation_rank AS award_participation_rank,
  ranks.funding_rank AS funding_rank
ORDER BY network,source_person_key;
