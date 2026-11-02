// Read-only. Run :use `nsf-project-workon-enriched` separately in Browser.
// Run one numbered query block at a time. See docs/RQ3_STEP_BY_STEP.md.

// @query Q04_PERSON_ACTIVITY
MATCH (person:Person)
OPTIONAL MATCH (person)-[:WORK_ON]->(p:Project)
WITH person,count(DISTINCT p) AS projects
RETURN projects,count(*) AS people ORDER BY projects;

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
