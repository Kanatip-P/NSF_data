// @query RQ1_INDEPENDENT_SUBJECT_MATRIX
// Enumerate each project's subject universe first, then test distinct-member support.
CALL {
 MATCH (p:Project)<-[w:WORK_ON]-(person:Person)
 WHERE w.role IN ['PI','Co-PI']
 WITH p,collect(DISTINCT {id:person.source_person_key,
  subjects:[s IN coalesce(person.subjects,[]) WHERE s ENDS WITH '(all)']}) AS members
 WITH p,members,reduce(tags=[],m IN members |
  tags+[s IN m.subjects WHERE NOT s IN tags]) AS subjects
 UNWIND range(0,size(subjects)-2) AS i
 UNWIND range(i+1,size(subjects)-1) AS j
 WITH p,members,subjects[i] AS x,subjects[j] AS y
 WHERE x<>y AND any(a IN members WHERE x IN a.subjects
  AND any(b IN members WHERE b.id<>a.id AND y IN b.subjects))
 WITH p,CASE WHEN x<y THEN x ELSE y END AS first,
  CASE WHEN x<y THEN y ELSE x END AS second
 WITH first,second,count(DISTINCT p) AS projects
 RETURN collect({first:first,second:second,projects:projects}) AS actual
}
LOAD CSV WITH HEADERS FROM 'file:///expected_rq1_subjects.csv' AS expected
WITH actual,expected,[r IN actual WHERE r.first=expected.subject_1 AND r.second=expected.subject_2] AS found
WITH size(actual) AS actual_combinations,count(*) AS compared_combinations,
 sum(CASE WHEN size(found)<>1 OR found[0].projects<>toInteger(expected.projects) THEN 1 ELSE 0 END) AS mismatches
RETURN actual_combinations,compared_combinations,mismatches,
 actual_combinations=435 AND compared_combinations=435 AND mismatches=0 AS passed;
