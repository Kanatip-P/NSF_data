// Read-only. In Neo4j Browser, run this selection command separately:
// :use `nsf-project-workon-enriched`
// Run each query below separately. No database changes are made.

// Top ten unordered different-subject combinations across PI/Co-PI teams.
// Two distinct people must support the combination. Each project counts once
// per combination. The denominator includes every Project in this database.
// Expected snapshot: 17,503 projects; Engineering + Medicine leads with 9,351.
MATCH (p:Project)
WITH count(p) AS totalProjects
MATCH (first:Person)-[r1:WORK_ON]->(project:Project)<-[r2:WORK_ON]-(second:Person)
WHERE r1.role IN ['PI', 'Co-PI']
  AND r2.role IN ['PI', 'Co-PI']
  AND elementId(first) < elementId(second)
UNWIND [s IN coalesce(first.subjects, []) WHERE s ENDS WITH '(all)'] AS a
UNWIND [s IN coalesce(second.subjects, []) WHERE s ENDS WITH '(all)'] AS b
WITH totalProjects, project, a, b
WHERE a <> b
WITH totalProjects, project,
     CASE WHEN a < b THEN a ELSE b END AS subject1,
     CASE WHEN a < b THEN b ELSE a END AS subject2
WITH totalProjects, subject1, subject2, count(DISTINCT project) AS projects
ORDER BY projects DESC, subject1 ASC, subject2 ASC
LIMIT 10
WITH totalProjects,
     collect({subject1: subject1, subject2: subject2, projects: projects}) AS rows
UNWIND CASE WHEN size(rows) > 0 THEN range(0, size(rows) - 1) ELSE [] END AS i
WITH totalProjects, i, rows[i] AS row
RETURN i + 1 AS rank,
       replace(row.subject1, ' (all)', '') + ' + ' +
       replace(row.subject2, ' (all)', '') AS subject_combination,
       row.projects AS projects,
       round(1000.0 * row.projects / totalProjects) / 10.0 AS percent_all_projects
ORDER BY rank;

// Coverage: projects with two distinct broad-tagged active members.
// Expected snapshot: 17,503 total; 14,329 with two tagged active members.
MATCH (project:Project)
OPTIONAL MATCH (person:Person)-[r:WORK_ON]->(project)
WHERE r.role IN ['PI', 'Co-PI']
  AND any(s IN coalesce(person.subjects, []) WHERE s ENDS WITH '(all)')
WITH project, count(DISTINCT person) AS taggedMembers
RETURN count(*) AS all_projects,
       sum(CASE WHEN taggedMembers >= 2 THEN 1 ELSE 0 END)
       AS projects_with_two_broad_tagged_active_members;

// Coverage: projects supporting at least one different-subject combination.
// Expected snapshot: 14,217. A larger team can support multiple combinations.
MATCH (first:Person)-[r1:WORK_ON]->(project:Project)<-[r2:WORK_ON]-(second:Person)
WHERE r1.role IN ['PI', 'Co-PI']
  AND r2.role IN ['PI', 'Co-PI']
  AND elementId(first) < elementId(second)
  AND any(a IN coalesce(first.subjects, []) WHERE a ENDS WITH '(all)'
      AND any(b IN coalesce(second.subjects, [])
              WHERE b ENDS WITH '(all)' AND a <> b))
RETURN count(DISTINCT project) AS projects_with_different_subject_combination;

// To export all combinations, copy the first query and remove LIMIT 10.
// Percentages overlap. Profile tags do not establish project topics or direct
// collaboration. These queries have not been executed against the live graph
// as part of this file-only update; expected counts come from prepared files.
