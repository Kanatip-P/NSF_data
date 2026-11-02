// @query SUBJECT_COUNTING_FIXTURE
// A repeated roster row, reversed subjects, and one multiply-tagged person.
UNWIND [{project:'team',id:'a',subjects:['Engineering (all)','Medicine (all)']},
        {project:'team',id:'a',subjects:['Engineering (all)','Medicine (all)']},
        {project:'team',id:'b',subjects:['Medicine (all)']},
        {project:'alone',id:'c',subjects:['Engineering (all)','Medicine (all)']}] AS row
WITH collect(row) AS roster
UNWIND roster AS a
UNWIND roster AS b
WITH a,b WHERE a.project=b.project AND a.id<b.id
UNWIND a.subjects AS x
UNWIND b.subjects AS y
WITH a.project AS project,x,y WHERE x<>y
WITH project,CASE WHEN x<y THEN x ELSE y END AS first,
             CASE WHEN x<y THEN y ELSE x END AS second
WITH first,second,count(DISTINCT project) AS projects
RETURN first,second,projects,
 first='Engineering (all)' AND second='Medicine (all)' AND projects=1 AS passed;

// @query DISTINCT_AWARD_FUNDING_FIXTURE
UNWIND [{id:'a',amount:100.0},{id:'a',amount:100.0},{id:'b',amount:0.0},
 {id:'c',amount:null},{id:'d',amount:-5.0}] AS row
WITH row.id AS id,head(collect(row)) AS award
WITH collect(award) AS awards
RETURN size(awards) AS distinct_awards,
 size([a IN awards WHERE a.amount IS NULL]) AS missing,
 size([a IN awards WHERE a.amount=0]) AS zeros,
 reduce(total=0.0,a IN awards | total+CASE WHEN a.amount>0 THEN a.amount ELSE 0 END) AS positive_total,
 size(awards)=4 AND size([a IN awards WHERE a.amount IS NULL])=1
 AND size([a IN awards WHERE a.amount=0])=1
 AND reduce(total=0.0,a IN awards | total+CASE WHEN a.amount>0 THEN a.amount ELSE 0 END)=100 AS passed;
