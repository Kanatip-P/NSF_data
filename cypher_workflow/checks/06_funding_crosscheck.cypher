// @query EVERY_PERSON_FUNDING_CROSSCHECK
LOAD CSV WITH HEADERS FROM 'file:///expected_award_centrality.csv' AS expected
MATCH (p:Person {source_person_key:expected.source_person_key})
CALL {
 WITH p
 OPTIONAL MATCH (p)-[:INVESTIGATOR_ON]->(a:Award)
 WITH DISTINCT a
 RETURN count(a) AS awards,count(a.total_amount) AS known,
   count(CASE WHEN a.total_amount>0 THEN 1 END) AS positive,
   sum(CASE WHEN a.total_amount>0 THEN a.total_amount ELSE 0 END) AS total
}
CALL {
 WITH p
 OPTIONAL MATCH (p)-[:WORK_ON]->(project:Project)
 RETURN count(DISTINCT project) AS projects
}
RETURN count(*) AS compared_people,
 sum(CASE WHEN awards<>toInteger(expected.awards) THEN 1 ELSE 0 END) AS award_count_mismatches,
 sum(CASE WHEN projects<>toInteger(expected.projects) THEN 1 ELSE 0 END) AS project_count_mismatches,
 sum(CASE WHEN positive<>toInteger(expected.positive_amount_awards) THEN 1 ELSE 0 END) AS positive_count_mismatches,
 sum(CASE WHEN awards-known<>toInteger(expected.missing_amount_awards) THEN 1 ELSE 0 END) AS missing_count_mismatches,
 sum(CASE WHEN known=0 AND expected.associated_positive_award_funding_usd<>'' THEN 1
          WHEN known>0 AND abs(total-toFloat(expected.associated_positive_award_funding_usd))>0.005 THEN 1
          ELSE 0 END) AS funding_mismatches;
