// @query RQ3_AWARD_ACTIVITY_AND_FUNDING
MATCH (person:Person)
CALL {
  WITH person
  OPTIONAL MATCH (person)-[:INVESTIGATOR_ON]->(a:Award)
  WITH DISTINCT a
  RETURN count(a) AS awards, count(a.total_amount) AS known_amount_awards,
         count(CASE WHEN a.total_amount>0 THEN a END) AS positive_amount_awards,
         count(CASE WHEN a.total_amount=0 THEN a END) AS zero_amount_awards,
         count(CASE WHEN a.total_amount<0 THEN a END) AS negative_amount_awards,
         sum(CASE WHEN a.total_amount>0 THEN a.total_amount ELSE 0 END) AS positive_total
}
CALL {
  WITH person
  OPTIONAL MATCH (person)-[:WORK_ON]->(p:Project)
  RETURN count(DISTINCT p) AS projects
}
RETURN person.source_person_key AS source_person_key, person.name AS name, awards, projects,
       CASE WHEN known_amount_awards=0 THEN null ELSE positive_total END AS associated_positive_award_funding_usd,
       positive_amount_awards, zero_amount_awards, negative_amount_awards,
       awards-known_amount_awards AS missing_amount_awards,
       awards>0 AND known_amount_awards=awards AS funding_complete
ORDER BY source_person_key;

// @query RQ3_PROJECT_ACTIVITY_HISTOGRAM
MATCH (person:Person)
OPTIONAL MATCH (person)-[:WORK_ON]->(p:Project)
WITH person,count(DISTINCT p) AS projects
RETURN projects,count(*) AS people ORDER BY projects;

// @query RQ3_EXCLUSIVE_ROLE_GROUPS
MATCH (person:Person)
OPTIONAL MATCH (person)-[w:WORK_ON]->(:Project)
WITH person,collect(DISTINCT w.role) AS roles
RETURN CASE WHEN 'PI' IN roles AND 'Co-PI' IN roles THEN 'Both PI and Co-PI'
            WHEN 'PI' IN roles THEN 'PI only' WHEN 'Co-PI' IN roles THEN 'Co-PI only'
            ELSE 'Former roles only' END AS role_group, count(*) AS people ORDER BY role_group;
