// @query RQ1_ORDERED_PAIR_COVERAGE
MATCH (pi:Person)-[wp:WORK_ON]->(p:Project)<-[wc:WORK_ON]-(co:Person)
WHERE wp.role='PI' AND wc.role='Co-PI'
WITH p,pi,co,[s IN coalesce(pi.subjects,[]) WHERE s ENDS WITH '(all)'] AS a,
             [s IN coalesce(co.subjects,[]) WHERE s ENDS WITH '(all)'] AS b
RETURN count(*) AS pi_copi_pair_instances,
       sum(CASE WHEN size(a)>0 AND size(b)>0 THEN 1 ELSE 0 END) AS pair_instances_both_broad_tags,
       sum(CASE WHEN any(s IN a WHERE s IN b) THEN 1 ELSE 0 END) AS pair_instances_any_shared_broad_tag;

// @query RQ1_ORDERED_TAG_CELLS
MATCH (pi:Person)-[wp:WORK_ON]->(p:Project)<-[wc:WORK_ON]-(co:Person)
WHERE wp.role='PI' AND wc.role='Co-PI'
UNWIND [s IN coalesce(pi.subjects,[]) WHERE s ENDS WITH '(all)'] AS pi_subject
UNWIND [s IN coalesce(co.subjects,[]) WHERE s ENDS WITH '(all)'] AS copi_subject
RETURN pi_subject AS PI, copi_subject AS CoPI, count(*) AS instances
ORDER BY instances DESC, PI, CoPI LIMIT 8;

// @query RQ1_REPEAT_ORDERED_PAIRS
MATCH (pi:Person)-[wp:WORK_ON]->(p:Project)<-[wc:WORK_ON]-(co:Person)
WHERE wp.role='PI' AND wc.role='Co-PI'
WITH pi,co,count(DISTINCT p) AS projects WHERE projects>=2
RETURN count(*) AS repeated_pi_copi_pairs_at_least_two;
