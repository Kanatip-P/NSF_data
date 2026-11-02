"""Unordered different-subject combinations supported by distinct active members."""
from collections import Counter
from itertools import combinations


def project_subject_pairs(roster, people):
    members = sorted({person for person, role in roster if role in {'PI', 'Co-PI'}})
    tags = {person: {s for s in people[person].get('subjects', [])
                     if s.endswith('(all)')} for person in members}
    tagged = [person for person in members if tags[person]]
    pairs = set()
    for first, second in combinations(tagged, 2):
        for a in tags[first]:
            for b in tags[second]:
                if a != b:
                    pairs.add(tuple(sorted((a, b))))
    return pairs, len(tagged) >= 2


def rank_subject_combinations(projects, rosters, people):
    counts = Counter()
    covered = 0
    with_combination = 0
    for project in projects:
        pairs, usable = project_subject_pairs(rosters.get(project, []), people)
        counts.update(pairs)
        covered += usable
        with_combination += bool(pairs)
    ranking = [dict(rank=i, subject_1=a, subject_2=b,
                    subject_combination=f'{a} + {b}', projects=n,
                    percent_all_projects=round(100 * n / len(projects), 1))
               for i, ((a, b), n) in enumerate(
                   sorted(counts.items(), key=lambda item: (-item[1], item[0])), 1)]
    return {'all_projects': len(projects),
            'projects_with_two_broad_tagged_active_members': covered,
            'projects_with_different_subject_combination': with_combination,
            'ranking': ranking}
