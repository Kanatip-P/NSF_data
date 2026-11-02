// @query RQ2_RAW_CODES
MATCH (a:Award)-[:HOSTED_BY]->(u:University)
RETURN u.research2025_value AS raw_code, count(DISTINCT a) AS awards ORDER BY raw_code;

// @query RQ2_IDENTITY_AND_RAW_CODES
MATCH (a:Award)-[:HOSTED_BY]->(u:University)
WITH u, count(DISTINCT a) AS awards
RETURN CASE WHEN u.verified_unitid IS NOT NULL AND trim(toString(u.verified_unitid))<>''
            THEN 'verified_id' ELSE 'outside_classified_subset' END AS identity,
       CASE WHEN u.research2025_value IS NULL OR u.research2025_value=-99
            THEN 'unpopulated_raw_code' ELSE 'populated_raw_code' END AS raw_status,
       count(*) AS recipients, sum(awards) AS awards ORDER BY identity,raw_status;
