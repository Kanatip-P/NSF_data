// Run :use `nsf-project-workon-enriched` separately in Neo4j Browser.
// @query PREFLIGHT_DATABASE
CALL db.info() YIELD name
RETURN name AS selected_database, name = 'nsf-project-workon-enriched' AS expected_database;

// @query PREFLIGHT_GDS
RETURN gds.version() AS gds_version, apoc.version() AS apoc_version;

// @query PREFLIGHT_COUNTS
MATCH (n)
UNWIND labels(n) AS label
RETURN label, count(*) AS nodes ORDER BY label;

// @query PREFLIGHT_IDS
MATCH (p:Person)
RETURN count(p) AS people, count(DISTINCT p.source_person_key) AS unique_person_keys,
       count(p) = 30239 AND count(DISTINCT p.source_person_key) = 30239 AS passed;

// @query PREFLIGHT_OWNERSHIP
MATCH (a:Award)
OPTIONAL MATCH (p:Project)-[:HAS_AWARD]->(a)
WITH a, count(p) AS owners
OPTIONAL MATCH (a)-[:HOSTED_BY]->(u:University)
WITH a, owners, count(u) AS recipients
RETURN count(a) AS awards,
       sum(CASE WHEN owners <> 1 THEN 1 ELSE 0 END) AS invalid_owner_count,
       sum(CASE WHEN recipients <> 1 THEN 1 ELSE 0 END) AS invalid_recipient_count;
