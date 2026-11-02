// The workbook CSV is the authoritative reference. Expected codes in the
// reviewed identity CSV are used only in the separate cross-check query.
// @query RQ2_VERIFIED_CLASSIFICATION
LOAD CSV WITH HEADERS FROM 'file:///carnegie_2025_research.csv' AS ref
WITH collect(ref) AS workbook
LOAD CSV WITH HEADERS FROM 'file:///reviewed_recipient_ids.csv' AS mapping
WITH workbook,mapping WHERE coalesce(mapping.verified_unitid,'')<>''
MATCH (u:University {source_university_id:mapping.source_key})
WHERE toString(u.verified_unitid)=mapping.verified_unitid
WITH u, [r IN workbook WHERE r.unitid=toString(u.verified_unitid)
  OR (toString(u.verified_unitid)='228778' AND r.unitid='F'
      AND replace(toLower(trim(r.instnm)),'the ','')=replace(toLower(trim(u.name)),'the ',''))] AS matches
WHERE size(matches)=1
MATCH (a:Award)-[:HOSTED_BY]->(u)
WITH toInteger(matches[0].research2025) AS research_code,
     count(DISTINCT a) AS awards, count(DISTINCT u) AS recipients
ORDER BY research_code
WITH collect({research_code:research_code,awards:awards,recipients:recipients}) AS rows,
     sum(awards) AS classified_awards
UNWIND rows AS r
RETURN r.research_code AS research_code, r.awards AS awards, r.recipients AS recipients,
       classified_awards, round(100.0*r.awards/classified_awards,1) AS percent_classified_awards
ORDER BY research_code;
