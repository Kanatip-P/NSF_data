"""Regression checks for the project-level counting definition."""
import unittest
from subject_combinations import project_subject_pairs, rank_subject_combinations

A, B, C = 'Engineering (all)', 'Medicine (all)', 'Chemistry (all)'


class SubjectCombinationTests(unittest.TestCase):
    def test_distinct_people_and_missing_tags(self):
        people = {'a': {'subjects': [A, B]}, 'b': {'subjects': []}}
        self.assertEqual(project_subject_pairs([('a', 'PI'), ('b', 'Co-PI')], people),
                         (set(), False))

    def test_reversed_and_repeated_members_merge(self):
        people = {'a': {'subjects': [A, B]}, 'b': {'subjects': [B, A]}}
        roster = [('a', 'PI'), ('b', 'Co-PI'), ('a', 'Co-PI'), ('b', 'Co-PI')]
        self.assertEqual(project_subject_pairs(roster, people), ({(A, B)}, True))

    def test_same_subjects_and_former_roles_excluded(self):
        people = {'a': {'subjects': [A]}, 'b': {'subjects': [A]},
                  'c': {'subjects': [B]}, 'd': {'subjects': ['Detailed subject']}}
        self.assertEqual(project_subject_pairs(
            [('a', 'PI'), ('b', 'Co-PI'), ('c', 'Former PI'), ('d', 'Co-PI')], people),
            (set(), True))

    def test_project_deduplication_denominator_and_ties(self):
        people = {'a': {'subjects': [A, C]}, 'b': {'subjects': [B]}}
        result = rank_subject_combinations(['p', 'q'],
            {'p': [('a', 'PI'), ('b', 'PI'), ('b', 'Co-PI')]}, people)
        self.assertEqual(result['projects_with_two_broad_tagged_active_members'], 1)
        self.assertEqual(result['projects_with_different_subject_combination'], 1)
        self.assertEqual([(r['subject_1'], r['subject_2']) for r in result['ranking']],
                         [(C, B), (A, B)])
        self.assertTrue(all(r['projects'] == 1 and r['percent_all_projects'] == 50.0
                            for r in result['ranking']))


if __name__ == '__main__':
    unittest.main()
