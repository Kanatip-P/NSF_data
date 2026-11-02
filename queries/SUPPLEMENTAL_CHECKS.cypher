// Read-only; run each block separately.

// @query AWARDS_PER_PROJECT
MATCH (p:Project)-[:HAS_AWARD]->(a:Award)
WITH p,count(DISTINCT a) AS awards
RETURN awards,count(*) AS projects ORDER BY awards;

// @query PERSON_ROLE_GROUPS
MATCH (p:Person)
OPTIONAL MATCH (p)-[w:WORK_ON]->(:Project)
WITH p,collect(DISTINCT w.role) AS roles
RETURN CASE WHEN 'PI' IN roles AND 'Co-PI' IN roles THEN 'Both PI and Co-PI'
WHEN 'PI' IN roles THEN 'PI only' WHEN 'Co-PI' IN roles THEN 'Co-PI only'
ELSE 'Former roles only' END AS role_group,count(*) AS people ORDER BY role_group;

// @query PROJECT_ROLE_POSITIONS
MATCH (:Person)-[w:WORK_ON]->(:Project)
RETURN w.role AS role,count(*) AS positions ORDER BY role;

// @query MULTI_PI_STRUCTURE
MATCH (p:Project)-[:HAS_AWARD]->(a:Award)
WITH p, count(DISTINCT a) AS awards
MATCH (person:Person)-[w:WORK_ON]->(p)
WITH p, awards, count(DISTINCT CASE WHEN w.role='PI' THEN person END) AS pi
WHERE pi>1
RETURN CASE WHEN awards=1 THEN 'single_award' ELSE 'multi_award' END AS structure,
count(*) AS projects ORDER BY structure;
