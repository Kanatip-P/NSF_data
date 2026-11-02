"""Independent graph fixtures and funding/ranking regression checks."""
import unittest
import igraph as ig
import networkx as nx
import numpy as np
from analyze_award_centrality import build_graph, measure_graph, funding_exposure, add_ranks


class AwardCentralityTests(unittest.TestCase):
    def check_graph(self, n, edges):
        graph = ig.Graph(n=n, edges=edges)
        graph.vs['person_key'] = [str(i) for i in range(n)]
        graph.es['shared_units'] = [1] * len(edges)
        values, summary = measure_graph(graph)
        reference = nx.Graph()
        reference.add_nodes_from(range(n))
        reference.add_edges_from(edges)
        degree = nx.degree_centrality(reference)
        between = nx.betweenness_centrality(reference, normalized=True, endpoints=False)
        for i, row in enumerate(values):
            self.assertAlmostEqual(row['degree_centrality'], degree[i])
            self.assertAlmostEqual(row['betweenness_normalized'], between[i])
        self.assertEqual(summary['degree_sum'], 2 * len(edges))
        self.assertEqual(summary['component_size_sum'], n)
        self.assertLess(summary['eigenvector_relative_residual'], 1e-9)
        return values

    def test_path(self):
        values = self.check_graph(3, [(0, 1), (1, 2)])
        self.assertEqual(values[1]['betweenness_raw'], 1)
        self.assertAlmostEqual(values[0]['eigenvector_centrality'], 1 / np.sqrt(2))
        self.assertAlmostEqual(values[1]['eigenvector_centrality'], 1)

    def test_triangle(self):
        values = self.check_graph(3, [(0, 1), (1, 2), (0, 2)])
        self.assertTrue(all(r['betweenness_raw'] == 0 for r in values))
        self.assertTrue(all(abs(r['eigenvector_centrality'] - 1) < 1e-10 for r in values))

    def test_star(self):
        values = self.check_graph(5, [(0, i) for i in range(1, 5)])
        self.assertEqual(values[0]['betweenness_raw'], 6)
        self.assertAlmostEqual(values[1]['eigenvector_centrality'], .5)

    def test_disconnected_and_isolated(self):
        values = self.check_graph(6, [(0, 1), (1, 2), (3, 4)])
        self.assertEqual(values[5]['degree_centrality'], 0)
        self.assertEqual(values[5]['component_size'], 1)
        self.assertTrue(all(values[i]['eigenvector_centrality'] is None for i in [3, 4, 5]))

    def test_duplicate_links_former_roles_and_repeat_strength(self):
        links = [{'person_key': p, 'award_id': a, 'props': {'role': 'Former Principal Investigator'}}
                 for p, a in [('a', 'x'), ('b', 'x'), ('a', 'x'), ('a', 'y'), ('b', 'y')]]
        graph = build_graph(['a', 'b', 'c'], links, 'award_id')
        self.assertEqual(graph.vcount(), 3)
        self.assertEqual(graph.get_edgelist(), [(0, 1)])
        self.assertEqual(graph.es['shared_units'], [2])
        self.assertTrue(graph.is_simple())

    def test_funding_deduplication_zero_missing_negative(self):
        awards = {key: {'total_amount': value} for key, value in
                  [('a', 100), ('b', 0), ('c', None), ('d', -10), ('e', float('nan'))]}
        result = funding_exposure(['a', 'a', 'b', 'c', 'd', 'e'], awards)
        self.assertEqual(result['associated_positive_award_funding_usd'], 100)
        self.assertEqual(result['positive_amount_awards'], 1)
        self.assertEqual(result['zero_amount_awards'], 1)
        self.assertEqual(result['negative_amount_awards'], 1)
        self.assertEqual(result['missing_amount_awards'], 2)
        self.assertFalse(result['funding_complete'])
        self.assertIsNone(funding_exposure(['c'], awards)['associated_positive_award_funding_usd'])
        self.assertEqual(funding_exposure(['b'], awards)['associated_positive_award_funding_usd'], 0)

    def test_ties_person_key_cutoff_and_unavailable_scores(self):
        rows = [{'source_person_key': f'{i:02}', 'degree_centrality': .5,
                 'betweenness_normalized': 0, 'eigenvector_centrality': None,
                 'awards': 1, 'associated_positive_award_funding_usd': 100,
                 'funding_complete': True} for i in reversed(range(12))]
        top = add_ranks(rows)
        self.assertEqual([r['source_person_key'] for r in top['degree']], [f'{i:02}' for i in range(10)])
        self.assertTrue(all(r['degree_rank'] == 1 for r in rows))
        self.assertEqual(top['eigenvector'], [])
        self.assertTrue(all(r['eigenvector_rank'] is None for r in rows))


if __name__ == '__main__':
    unittest.main()
