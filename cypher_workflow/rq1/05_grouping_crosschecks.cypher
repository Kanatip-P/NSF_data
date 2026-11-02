// @query RQ1_AWARDS_PER_PROJECT
MATCH (p:Project)-[:HAS_AWARD]->(a:Award)
WITH p,count(DISTINCT a) AS awards
RETURN awards,count(*) AS projects ORDER BY awards;

// @query RQ1_MULTI_PI_STRUCTURE
MATCH (p:Project)-[:HAS_AWARD]->(a:Award)
WITH p,count(DISTINCT a) AS awards
MATCH (person:Person)-[w:WORK_ON]->(p)
WITH p,awards,count(DISTINCT CASE WHEN w.role='PI' THEN person END) AS pi
WHERE pi>1
RETURN CASE WHEN awards=1 THEN 'single_award' ELSE 'multi_award' END AS structure,
       count(*) AS projects ORDER BY structure;
