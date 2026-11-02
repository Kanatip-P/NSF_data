// Copy inputs/*.csv to the Neo4j import directory before running LOAD CSV.
// @query RQ2_REVIEWED_IDS_CHECK
LOAD CSV WITH HEADERS FROM 'file:///reviewed_recipient_ids.csv' AS row
OPTIONAL MATCH (u:University {source_university_id:row.source_key})
RETURN count(*) AS input_rows, count(DISTINCT row.source_key) AS distinct_source_keys,
       sum(CASE WHEN u IS NULL THEN 1 ELSE 0 END) AS missing_graph_recipients,
       sum(CASE WHEN coalesce(toString(u.verified_unitid),'')<>coalesce(row.verified_unitid,'')
                THEN 1 ELSE 0 END) AS verified_id_mismatches;

// @query RQ2_WORKBOOK_EXCEPTION_CHECK
LOAD CSV WITH HEADERS FROM 'file:///carnegie_2025_research.csv' AS row
WITH collect(row) AS workbook
MATCH (u:University) WHERE toString(u.verified_unitid)='228778'
WITH u, [r IN workbook WHERE r.unitid='F'
  AND replace(toLower(trim(r.instnm)),'the ','')=replace(toLower(trim(u.name)),'the ','')] AS matches
RETURN u.name AS recipient, u.verified_unitid AS verified_unitid,
       size(matches) AS exact_exception_rows,
       size(matches)=1 AS passed;
