// @query CYPHER_EIGENVECTOR_PATH_FIXTURE
WITH [[1],[0,2],[1]] AS adjacency,range(0,2) AS positions
WITH reduce(state={x:[j IN positions | 1.0],delta:1.0,iterations:0},step IN range(1,1000) |
 CASE WHEN state.delta<1e-13 THEN state ELSE
 head([next IN [[j IN positions | state.x[j]+reduce(total=0.0,k IN adjacency[j] | total+state.x[k])]] |
 head([scale IN [reduce(largest=0.0,v IN next | CASE WHEN v>largest THEN v ELSE largest END)] |
 head([normalized IN [[v IN next | v/scale]] |
 {x:normalized,iterations:step,
  delta:reduce(error=0.0,j IN positions |
    CASE WHEN abs(normalized[j]-state.x[j])>error THEN abs(normalized[j]-state.x[j]) ELSE error END)}])])]) END) AS state
RETURN state.iterations AS iterations,state.delta AS max_iteration_change,
 state.x AS scores,state.delta<1e-13 AND abs(state.x[0]-1/sqrt(2.0))<1e-10
 AND state.x[1]=1.0 AND abs(state.x[2]-1/sqrt(2.0))<1e-10 AS passed;
