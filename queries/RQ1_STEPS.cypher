// Read-only. Run :use `nsf-project-workon-enriched` separately in Browser.
// Run one numbered query block at a time. See docs/RQ1_STEP_BY_STEP.md.

// @query Q01_POPULATION
MATCH (n)
UNWIND labels(n) AS label
RETURN label, count(*) AS n ORDER BY label;

// @query Q02_AWARD_LINKS
MATCH (a:Award)
OPTIONAL MATCH (p:Project)-[:HAS_AWARD]->(a)
WITH a, count(p) AS owners
OPTIONAL MATCH (a)-[:HOSTED_BY]->(u:University)
WITH a, owners, count(u) AS recipients
RETURN count(a) AS awards,
sum(CASE WHEN owners <> 1 THEN 1 ELSE 0 END) AS invalid_owner_count,
sum(CASE WHEN recipients <> 1 THEN 1 ELSE 0 END) AS invalid_recipient_count;

// @query Q03_TEAM_AMOUNTS
MATCH (p:Project)
OPTIONAL MATCH (:Person)-[w:WORK_ON]->(p)
WITH p, sum(CASE WHEN w.role='PI' THEN 1 ELSE 0 END) AS pi,
sum(CASE WHEN w.role='Co-PI' THEN 1 ELSE 0 END) AS copi
WITH p, CASE WHEN pi=1 AND copi=0 THEN 'one PI no Co-PI'
WHEN pi=1 AND copi=1 THEN 'one PI one Co-PI'
WHEN pi=1 AND copi>1 THEN 'one PI multiple Co-PIs'
WHEN pi>1 AND copi=0 THEN 'multiple PIs no Co-PI'
WHEN pi>1 AND copi>0 THEN 'multiple PIs and Co-PIs' ELSE 'other' END AS team
RETURN team, count(*) AS projects,
count(CASE WHEN p.amount>0 THEN p.amount END) AS amount_n,
percentileCont(CASE WHEN p.amount>0 THEN toFloat(p.amount) END,0.5) AS median_amount
ORDER BY team;
