import os
"""Descriptive paper tables from the hash-checked enriched-graph package."""

from collections import Counter, defaultdict
from statistics import median
from pathlib import Path
import gzip
import json

ROOT = Path(__file__).resolve().parents[1] / 'data'
DATA = ROOT / "prepared"
OUT = Path(os.environ.get('NSF_ANALYSIS_OUTPUT', str(ROOT.parent/'results/cohort_analysis.json')))


def rows(name):
    with gzip.open(DATA / f"{name}.jsonl.gz", "rt", encoding="utf-8") as stream:
        for line in stream:
            yield json.loads(line)


projects = {r["key"]: r["props"] for r in rows("projects")}
people = {r["key"]: r["props"] for r in rows("people")}
awards = {r["key"]: r["props"] for r in rows("awards")}
recipients = {r["key"]: r["props"] for r in rows("universities")}
team = defaultdict(list)
person_projects = defaultdict(set)
role_counts = Counter()
for r in rows("work_on"):
    role = r["props"]["role"]
    team[r["project_id"]].append((r["person_key"], role))
    person_projects[r["person_key"]].add(r["project_id"])
    role_counts[role] += 1

project_awards = defaultdict(list)
for r in rows("has_award"):
    project_awards[r["project_id"]].append(r["award_id"])
award_recipient = {r["award_id"]: r["university_key"] for r in rows("hosted_by")}
program_element = defaultdict(set)
for r in rows("has_program_element"):
    program_element[r["project_id"]].add(r["code"])
program_reference = defaultdict(set)
for r in rows("has_program_reference"):
    program_reference[r["project_id"]].add(r["code"])

shape = Counter()
shape_eligible = Counter()
shape_single = Counter()
shape_multi = Counter()
project_award_count = Counter()
year_count = Counter()
for project_id, pr in projects.items():
    roles = [role for _, role in team[project_id]]
    key = (roles.count("PI"), roles.count("Co-PI"))
    shape[key] += 1
    (shape_single if len(project_awards[project_id]) == 1 else shape_multi)[key] += 1
    if pr["analysis_eligible"]:
        shape_eligible[key] += 1
    project_award_count[len(project_awards[project_id])] += 1
    year_count[pr["year"]] += 1

award_role_counts = Counter()
award_team = defaultdict(list)
for r in rows("investigator_on"):
    role = r["props"]["role"]
    award_role_counts[role] += 1
    award_team[r["award_id"]].append((r["person_key"], role))
award_shape = Counter((sum(role == "PI" for _, role in roster), sum(role == "Co-PI" for _, role in roster)) for roster in award_team.values())

status_awards = Counter()
tier_awards = Counter()
verified_awards = 0
verified_tier_awards = Counter()
amount_by_status = defaultdict(list)
for award_id, aw in awards.items():
    rec = recipients[award_recipient[award_id]]
    status = rec["research2025_status"]
    status_awards[status] += 1
    if status == "research_tier_recorded":
        tier_awards[str(rec["research2025_value"])] += 1
    if rec.get("verified_unitid"):
        verified_awards += 1
        if status == "research_tier_recorded":
            verified_tier_awards[str(rec["research2025_value"])] += 1
    amount = aw.get("total_amount")
    if isinstance(amount, (int, float)) and amount > 0:
        amount_by_status[status].append(amount)

usable = {key for key, p in people.items() if p["profile_usable"]}
usable_positions = sum(person in usable for roster in team.values() for person, _ in roster)
project_class = Counter()
for pr in projects.values():
    project_class["eligible" if pr["analysis_eligible"] else "ineligible"] += 1

subject_count = Counter(len(p.get("subjects") or []) for p in people.values())
source_subjects = Counter(p.get("subjects_source", "") for p in people.values())
source_affiliation = Counter(p.get("affiliation_source", "") for p in people.values())
amounts = [a["total_amount"] for a in awards.values() if isinstance(a.get("total_amount"), (int, float)) and a["total_amount"] > 0]
participation = Counter(len(person_projects[key]) for key in people)

result = {
    "counts": {"projects": len(projects), "people": len(people), "awards": len(awards), "recipients": len(recipients), "work_on": sum(len(v) for v in team.values()), "investigator_on": sum(award_role_counts.values()), "eligible_projects": project_class["eligible"], "usable_people": len(usable), "usable_person_project_positions": usable_positions, "verified_recipient_awards": verified_awards},
    "project_role_shape": {f"{pi} PI / {co} Co-PI": n for (pi, co), n in shape.most_common()},
    "single_award_project_role_shape": {f"{pi} PI / {co} Co-PI": n for (pi, co), n in shape_single.most_common()},
    "multi_award_project_role_shape": {f"{pi} PI / {co} Co-PI": n for (pi, co), n in shape_multi.most_common()},
    "eligible_project_role_shape": {f"{pi} PI / {co} Co-PI": n for (pi, co), n in shape_eligible.most_common()},
    "award_role_shape": {f"{pi} PI / {co} Co-PI": n for (pi, co), n in award_shape.most_common()},
    "project_role_positions": dict(role_counts), "award_role_positions": dict(award_role_counts),
    "awards_per_project": dict(sorted(project_award_count.items())), "projects_by_year": dict(sorted(year_count.items())),
    "award_recipient_status": dict(status_awards), "award_recipient_tier_code": dict(tier_awards),
    "verified_recipient_tier_code_awards": dict(verified_tier_awards),
    "median_positive_award_amount_by_status": {k: median(v) for k, v in amount_by_status.items()},
    "positive_award_amount_count_by_status": {k: len(v) for k, v in amount_by_status.items()},
    "positive_award_amount_median": median(amounts), "positive_award_amount_n": len(amounts),
    "program_element_project_coverage": len(program_element), "program_reference_project_coverage": len(program_reference),
    "subjects_source": dict(source_subjects), "affiliation_source": dict(source_affiliation),
    "nonempty_subject_people": sum(n for count, n in subject_count.items() if count > 0),
    "person_project_participation": dict(sorted(participation.items())),
}
OUT.write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
print(OUT)
