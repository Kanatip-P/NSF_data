// Only the four named in-memory graphs from this workflow are removed.
// No database nodes, properties or relationships are deleted.
// Run after exporting every result; repeat projection/algorithm steps to rerun.
// @query CLEANUP_MEMORY_GRAPHS
UNWIND ['nsf_cypher_award_lcc','nsf_cypher_grouped_lcc',
        'nsf_cypher_award','nsf_cypher_grouped'] AS graph
CALL gds.graph.drop(graph,false) YIELD graphName
RETURN graphName;
