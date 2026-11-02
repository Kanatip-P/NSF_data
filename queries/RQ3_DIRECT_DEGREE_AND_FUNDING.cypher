// Optional direct checks. Select nsf-project-workon-enriched first.
// These queries are supplied for reruns; their live execution was not part
// of repository assembly. Compare returns against results/rq3 CSVs.

// @query RQ3_TOP10_AWARD_DEGREE
MATCH (all:Person)
WITH count(all) AS population
MATCH (person:Person)
OPTIONAL MATCH (person)-[:INVESTIGATOR_ON]->(award:Award)
OPTIONAL MATCH (award)<-[:INVESTIGATOR_ON]-(other:Person)
WHERE other <> person
WITH population, person, count(DISTINCT other) AS neighbors,
     count(DISTINCT award) AS awards
RETURN person.source_person_key AS source_person_key, person.name AS name,
       neighbors AS distinct_collaborators,
       toFloat(neighbors) / (population - 1) AS degree_centrality, awards
ORDER BY distinct_collaborators DESC, source_person_key ASC
LIMIT 10;

// @query RQ3_ASSOCIATED_POSITIVE_AWARD_FUNDING
// DISTINCT removes duplicate memberships BEFORE summing award amounts.
// Distinct awards with equal dollar values must each contribute.
MATCH (person:Person)
OPTIONAL MATCH (person)-[:INVESTIGATOR_ON]->(award:Award)
WITH DISTINCT person, award
WITH person, count(award) AS awards,
     count(award.total_amount) AS known_amount_awards,
     count(CASE WHEN award.total_amount > 0 THEN award END) AS positive_amount_awards,
     sum(CASE WHEN award.total_amount > 0 THEN award.total_amount ELSE 0 END) AS amount
RETURN person.source_person_key AS source_person_key, person.name AS name,
       awards, positive_amount_awards, awards - known_amount_awards AS missing_amount_awards,
       CASE WHEN known_amount_awards = 0 THEN null ELSE amount END
       AS associated_positive_award_funding_usd
ORDER BY source_person_key;
