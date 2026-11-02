// Read-only. Run :use `nsf-project-workon-enriched` separately in Browser.
// Run one numbered query block at a time. See docs/RQ2_STEP_BY_STEP.md.

// Q07 needs the classifications parameter from queries/parameters/classifications.json.
// scripts/run_live_checks.py supplies it automatically. Raw codes are not the final classification.

// @query Q05_RAW_RECIPIENT_CODES
MATCH (a:Award)-[:HOSTED_BY]->(u:University)
RETURN u.research2025_value AS raw_code,count(DISTINCT a) AS awards
ORDER BY raw_code;

// @query Q06_VERIFIED_ID_RECOVERY
MATCH (a:Award)-[:HOSTED_BY]->(u:University)
WITH u,count(DISTINCT a) AS awards
RETURN CASE WHEN u.verified_unitid IS NOT NULL AND trim(toString(u.verified_unitid))<>''
THEN 'verified_id' ELSE 'outside_classified_subset' END AS identity,
CASE WHEN u.research2025_value IS NULL OR u.research2025_value=-99
THEN 'unpopulated_raw_code' ELSE 'populated_raw_code' END AS raw_status,
count(*) AS recipients,sum(awards) AS awards
ORDER BY identity,raw_status;

// @query Q07_VERIFIED_OFFICIAL_CLASSIFICATION
UNWIND $classifications AS mapping
MATCH (a:Award)-[:HOSTED_BY]->(u:University)
WHERE u.source_university_id=mapping.source_key
AND toString(u.verified_unitid)=mapping.verified_unitid
RETURN toInteger(mapping.official_research) AS research_code,
count(DISTINCT a) AS awards,count(DISTINCT u) AS recipients
ORDER BY research_code;
