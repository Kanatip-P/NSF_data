// @query RQ2_EVERY_RECIPIENT_CROSSCHECK
LOAD CSV WITH HEADERS FROM 'file:///carnegie_2025_research.csv' AS ref
WITH collect(ref) AS workbook
LOAD CSV WITH HEADERS FROM 'file:///reviewed_recipient_ids.csv' AS mapping
MATCH (u:University {source_university_id:mapping.source_key})
OPTIONAL MATCH (a:Award)-[:HOSTED_BY]->(u)
WITH workbook,mapping,u,count(DISTINCT a) AS awards
WITH mapping,awards,[r IN workbook WHERE coalesce(mapping.verified_unitid,'')<>'' AND
  (r.unitid=mapping.verified_unitid OR (mapping.verified_unitid='228778' AND r.unitid='F'
    AND replace(toLower(trim(r.instnm)),'the ','')=replace(toLower(trim(u.name)),'the ','')))] AS matches
WITH mapping,awards,
     CASE WHEN size(matches)=1 THEN toInteger(matches[0].research2025) ELSE null END AS calculated_code
RETURN count(*) AS compared_recipients,
       sum(CASE WHEN awards<>toInteger(mapping.expected_awards) THEN 1 ELSE 0 END) AS award_count_mismatches,
       sum(CASE WHEN coalesce(toString(calculated_code),'')<>coalesce(mapping.expected_research,'')
                THEN 1 ELSE 0 END) AS classification_mismatches,
       sum(CASE WHEN calculated_code IS NOT NULL THEN awards ELSE 0 END) AS classified_awards;
