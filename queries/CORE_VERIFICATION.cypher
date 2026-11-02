// Select nsf-project-workon-enriched in Browser. Run one numbered block at a time.
// All blocks are read-only. Q07 uses the verified classification parameter supplied by verify_paper_queries.py.

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

// @query Q04_PERSON_ACTIVITY
MATCH (person:Person)
OPTIONAL MATCH (person)-[:WORK_ON]->(p:Project)
WITH person,count(DISTINCT p) AS projects
RETURN projects,count(*) AS people ORDER BY projects;

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

// @query Q08_PROFILE_AND_PROGRAM_COVERAGE
MATCH (person:Person)
RETURN 'usable_people' AS metric,count(CASE WHEN person.profile_usable=true THEN 1 END) AS n
UNION ALL
MATCH (p:Project) WHERE p.analysis_eligible=true
RETURN 'eligible_projects' AS metric,count(p) AS n
UNION ALL
MATCH (p:Project)-[:HAS_PROGRAM_ELEMENT]->(:ProgramElement)
RETURN 'projects_with_element' AS metric,count(DISTINCT p) AS n
UNION ALL
MATCH (p:Project)-[:HAS_PROGRAM_REFERENCE]->(:ProgramReference)
RETURN 'projects_with_reference' AS metric,count(DISTINCT p) AS n;

// @query Q09_RELATIONSHIP_COUNTS
MATCH ()-[r]->()
RETURN type(r) AS relationship,count(*) AS n ORDER BY relationship;
