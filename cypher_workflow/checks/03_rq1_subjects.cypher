// @query RQ1_FULL_SUBJECT_REFERENCE_CROSSCHECK
CALL {
 MATCH (a:Person)-[wa:WORK_ON]->(p:Project)<-[wb:WORK_ON]-(b:Person)
 WHERE wa.role IN ['PI','Co-PI'] AND wb.role IN ['PI','Co-PI']
   AND a.source_person_key<b.source_person_key
 UNWIND [s IN coalesce(a.subjects,[]) WHERE s ENDS WITH '(all)'] AS x
 UNWIND [s IN coalesce(b.subjects,[]) WHERE s ENDS WITH '(all)'] AS y
 WITH p,x,y WHERE x<>y
 WITH p,CASE WHEN x<y THEN x ELSE y END AS first,
        CASE WHEN x<y THEN y ELSE x END AS second
 WITH first,second,count(DISTINCT p) AS projects ORDER BY projects DESC,first,second
 WITH collect({first:first,second:second,projects:projects}) AS rows
 RETURN [i IN range(0,size(rows)-1) | {rank:i+1,first:rows[i].first,second:rows[i].second,
                                     projects:rows[i].projects}] AS actual
}
LOAD CSV WITH HEADERS FROM 'file:///expected_rq1_subjects.csv' AS expected
WITH actual,expected,[r IN actual WHERE r.first=expected.subject_1 AND r.second=expected.subject_2] AS found
RETURN size(actual) AS actual_combinations,count(*) AS compared_combinations,
 sum(CASE WHEN size(found)<>1 OR found[0].projects<>toInteger(expected.projects)
           OR found[0].rank<>toInteger(expected.rank) THEN 1 ELSE 0 END) AS mismatches;
