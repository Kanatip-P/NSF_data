// @query RQ1_ALL_SUBJECT_COMBINATIONS
// For the top ten, append LIMIT 10 after ORDER BY rank, before the semicolon.
MATCH (p:Project)
WITH count(p) AS total
MATCH (a:Person)-[wa:WORK_ON]->(p:Project)<-[wb:WORK_ON]-(b:Person)
WHERE wa.role IN ['PI','Co-PI'] AND wb.role IN ['PI','Co-PI']
  AND a.source_person_key < b.source_person_key
UNWIND [s IN coalesce(a.subjects,[]) WHERE s ENDS WITH '(all)'] AS x
UNWIND [s IN coalesce(b.subjects,[]) WHERE s ENDS WITH '(all)'] AS y
WITH total, p, x, y WHERE x<>y
WITH total, p, CASE WHEN x<y THEN x ELSE y END AS subject_1,
               CASE WHEN x<y THEN y ELSE x END AS subject_2
WITH total, subject_1, subject_2, count(DISTINCT p) AS projects
ORDER BY projects DESC, subject_1, subject_2
WITH total, collect({subject_1:subject_1,subject_2:subject_2,projects:projects}) AS rows
UNWIND range(0,size(rows)-1) AS i
WITH total, i, rows[i] AS r
RETURN i+1 AS rank, r.subject_1 AS subject_1, r.subject_2 AS subject_2,
       r.subject_1+' + '+r.subject_2 AS subject_combination, r.projects AS projects,
       round(100.0*r.projects/total,1) AS percent_all_projects
ORDER BY rank;
