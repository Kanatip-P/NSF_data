// @query RQ1_TEAM_FUNDING
MATCH (p:Project)
OPTIONAL MATCH (:Person)-[w:WORK_ON]->(p)
WITH p, sum(CASE WHEN w.role='PI' THEN 1 ELSE 0 END) AS pi,
        sum(CASE WHEN w.role='Co-PI' THEN 1 ELSE 0 END) AS co
WITH p, CASE WHEN pi=1 AND co=0 THEN 'one PI no Co-PI'
            WHEN pi=1 AND co=1 THEN 'one PI one Co-PI'
            WHEN pi=1 AND co>1 THEN 'one PI multiple Co-PIs'
            WHEN pi>1 AND co=0 THEN 'multiple PIs no Co-PI'
            WHEN pi>1 AND co>0 THEN 'multiple PIs and Co-PIs'
            ELSE 'no active PI' END AS team
RETURN team, count(*) AS projects,
       count(CASE WHEN p.amount>0 THEN 1 END) AS positive_amount_n,
       percentileCont(CASE WHEN p.amount>0 THEN toFloat(p.amount) END,0.5) AS median_positive_amount_usd,
       count(CASE WHEN p.duration_years>0 THEN 1 END) AS positive_duration_n,
       percentileCont(CASE WHEN p.duration_years>0 THEN toFloat(p.duration_years) END,0.5) AS median_positive_duration_years
ORDER BY team;
