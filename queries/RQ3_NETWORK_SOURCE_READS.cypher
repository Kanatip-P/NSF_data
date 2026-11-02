// Optional source inspection only. Run each block separately after selecting:
// :use `nsf-project-workon-enriched`
// These queries do not run centrality or write graph properties.
// Published RQ3 centralities are calculated offline by
// analyze_centrality.py --prepared, using the hashed prepared files.

// Every investigator is retained, including those with no projected neighbors.
MATCH (person:Person)
RETURN person.source_person_key AS person_key, person.name AS name;

// Award-specific membership; include all roles and deduplicate offline.
MATCH (person:Person)-[r:INVESTIGATOR_ON]->(award:Award)
RETURN person.source_person_key AS person_key, award.id AS award_id,
       r.role AS role, r.roles AS roles;

// Individual award amount; do not use Project.amount as an award allocation.
MATCH (award:Award)
RETURN award.id AS award_id, award.total_amount AS total_amount;

// Project membership for the sensitivity projection and project activity.
MATCH (person:Person)-[r:WORK_ON]->(project:Project)
RETURN person.source_person_key AS person_key, project.project_id AS project_id,
       r.role AS role, r.roles AS roles;

// Award-to-project ownership used to reconcile the two roster layers.
MATCH (project:Project)-[:HAS_AWARD]->(award:Award)
RETURN project.project_id AS project_id, award.id AS award_id;
