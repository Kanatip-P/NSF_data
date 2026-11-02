// @query RQ1_TAGGED_MEMBER_COVERAGE
MATCH (p:Project)
OPTIONAL MATCH (person:Person)-[w:WORK_ON]->(p)
WHERE w.role IN ['PI','Co-PI']
  AND any(s IN coalesce(person.subjects,[]) WHERE s ENDS WITH '(all)')
WITH p, count(DISTINCT person) AS tagged
RETURN count(*) AS all_projects,
       sum(CASE WHEN tagged>=2 THEN 1 ELSE 0 END) AS projects_with_two_broad_tagged_active_members;

// @query RQ1_DIFFERENT_SUBJECT_COVERAGE
MATCH (a:Person)-[wa:WORK_ON]->(p:Project)<-[wb:WORK_ON]-(b:Person)
WHERE wa.role IN ['PI','Co-PI'] AND wb.role IN ['PI','Co-PI']
  AND a.source_person_key < b.source_person_key
  AND any(x IN coalesce(a.subjects,[]) WHERE x ENDS WITH '(all)'
    AND any(y IN coalesce(b.subjects,[]) WHERE y ENDS WITH '(all)' AND x<>y))
RETURN count(DISTINCT p) AS projects_with_different_subject_combination;
