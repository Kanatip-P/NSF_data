import os
"""RQ-level descriptive summaries from the audited enriched-graph export."""
from collections import Counter, defaultdict
from statistics import median
from pathlib import Path
import gzip, json
from subject_combinations import rank_subject_combinations

root = Path(__file__).resolve().parents[1] / 'data'
def read(name):
    with gzip.open(root / 'prepared' / (name + '.jsonl.gz'), 'rt', encoding='utf-8') as f:
        for line in f: yield json.loads(line)

projects={r['key']:r['props'] for r in read('projects')}
people={r['key']:r['props'] for r in read('people')}
awards={r['key']:r['props'] for r in read('awards')}
recipients={r['key']:r['props'] for r in read('universities')}
rosters=defaultdict(list); activity=defaultdict(set); roles=defaultdict(set)
for r in read('work_on'):
    person,project=r['person_key'],r['project_id']
    role=r['props']['role']; rosters[project].append((person,role))
    activity[person].add(project); roles[person].add(role)
host={r['award_id']:r['university_key'] for r in read('hosted_by')}
programs=defaultdict(set)
for r in read('has_program_element'): programs[r['project_id']].add(r['code'])

groups=Counter(); amount=defaultdict(list); duration=defaultdict(list)
pair_instances=0; broad_pair_instances=0; broad_cells=Counter(); shared_tag=0
collaborators=defaultdict(set); repeated_pairs=Counter()
for project, roster in rosters.items():
    pi=[p for p,role in roster if role=='PI']; co=[p for p,role in roster if role=='Co-PI']
    group=('one PI no Co-PI' if len(pi)==1 and len(co)==0 else
           'one PI one Co-PI' if len(pi)==1 and len(co)==1 else
           'one PI multiple Co-PIs' if len(pi)==1 and len(co)>1 else
           'multiple PIs no Co-PI' if len(pi)>1 and len(co)==0 else
           'multiple PIs and Co-PIs' if len(pi)>1 else 'no active PI')
    groups[group]+=1
    a=projects[project].get('amount'); y=projects[project].get('duration_years')
    if isinstance(a,(int,float)) and a>0: amount[group].append(a)
    if isinstance(y,(int,float)) and y>0: duration[group].append(y)
    for p in pi:
        for q in co:
            pair_instances+=1; repeated_pairs[(p,q)]+=1
            ps={s for s in people[p].get('subjects',[]) if s.endswith('(all)')}
            qs={s for s in people[q].get('subjects',[]) if s.endswith('(all)')}
            if ps and qs:
                broad_pair_instances+=1
                if ps & qs: shared_tag+=1
                for x in ps:
                    for z in qs: broad_cells[(x,z)]+=1
    persons=[p for p,_ in roster]
    for p in persons: collaborators[p].update(q for q in persons if q!=p)

recipient_dims={field:Counter() for field in ['research2025_status','research2025_value','control_description','ic2025size_description','setting2025_description']}
verified_dims={field:Counter() for field in ['control_description','ic2025size_description','setting2025_description']}
for award,rid in host.items():
    rec=recipients[rid]
    for field in recipient_dims: recipient_dims[field][str(rec.get(field,''))]+=1
    if rec.get('verified_unitid'):
        for field in verified_dims: verified_dims[field][str(rec.get(field,''))]+=1

activity_hist=Counter(len(activity[p]) for p in people)
role_people=Counter()
for p in people:
    if 'PI' in roles[p]: role_people['any PI']+=1
    if 'Co-PI' in roles[p]: role_people['any Co-PI']+=1
    if 'PI' not in roles[p] and 'Co-PI' not in roles[p]: role_people['former only']+=1

out={
 'rq1':{'team_categories':dict(groups),'median_positive_project_amount':{k:median(v) for k,v in amount.items()},'positive_amount_n':{k:len(v) for k,v in amount.items()},'median_positive_duration_years':{k:median(v) for k,v in duration.items()},'pi_copi_pair_instances':pair_instances,'pair_instances_both_broad_tags':broad_pair_instances,'pair_instances_any_shared_broad_tag':shared_tag,'leading_ordered_broad_tag_cells':[{'PI':a,'CoPI':b,'instances':n} for (a,b),n in broad_cells.most_common(8)],'repeated_pi_copi_pairs_at_least_two':sum(v>=2 for v in repeated_pairs.values())},
 'rq2':{'award_recipient_dimensions':{k:dict(v) for k,v in recipient_dims.items()},'verified_recipient_dimensions':{k:dict(v) for k,v in verified_dims.items()}},
 'rq3':{'person_activity_histogram':dict(sorted(activity_hist.items())),'person_role_coverage':dict(role_people),'median_distinct_collaborators':median(len(collaborators[p]) for p in people),'people_with_more_than_one_project':sum(n for k,n in activity_hist.items() if k>1),'people_with_program_element_in_any_project':sum(any(programs[x] for x in activity[p]) for p in people)},
}
out['rq1']['team_subject_combinations'] = rank_subject_combinations(projects, rosters, people)
path=Path(os.environ.get('NSF_ANALYSIS_OUTPUT', str(root.parent/'results/rq_analysis.json')));path.write_text(json.dumps(out,indent=2,ensure_ascii=False),encoding='utf-8');print(path)
