# Data provenance and interpretation

This repository accompanies the enriched-graph revision dated 1 November 2026.
It preserves the audited selected graph snapshot and the subsequent analyses;
it does not claim to represent all NSF awards or investigator careers.

| Material | Origin and purpose |
| --- | --- |
| NSF projects, awards and rosters | Selected 2015–2025 Standard Grant records reconciled into grouped projects and individual awards |
| Investigator subject and affiliation fields | Existing Scopus-derived profile enrichment, with provenance fields retained |
| Carnegie classifications | Enclosed 2025 public workbook, joined through reviewed verified UnitIDs |
| Recipient crosswalk | Source recipient IDs, reviewed institution identities and official workbook values |
| Prepared manifest and audit JSONs | Historical row/hash and post-import reconciliation evidence |
| Analysis outputs | Deterministic descriptive calculations on those inputs, including exact graph centrality |

Prepared source files are copied without changing their contents. The
manifest records their original SHA-256 hashes. Historical `source_db`
properties and labels describe provenance; every supplied live query targets
`nsf-project-workon-enriched` rather than selecting an older database.

Source person keys identify records and are not guaranteed to resolve all
real-world identity ambiguity. Names alone are not unique identifiers.
Profile subjects and affiliations can be undated and may not reflect the
award period. Grouped-project membership can combine several award rosters.
Individual-award membership also does not establish overlapping appointment
dates. Recipient nodes are inherited `University` labels and are not all
necessarily separate eligible campuses.

## What was adapted for this repository

Copied analysis calculations retain their original logic. Input and output
paths were changed to the portable `data/`, `results/`, and `evidence/`
structure. RQ/cohort analyses support temporary output redirection for checks.
The figure's PNG is retained while its standalone PDF export is omitted.
The new RQ2 offline join independently reproduces the existing verified
crosswalk using the workbook and prepared recipient/award data.

No original connection settings, database passwords, MongoDB credentials,
notebooks, local virtual environments, paper builders, manuscript files or
Word/PDF methods documents were included. The optional live runner uses only
environment variables and saves new results separately from archived evidence.

No new license has been assigned by this assembly. Code licensing remains
with the repository owner; NSF, Carnegie and profile-derived material retain
their applicable upstream terms. Preserve provenance and reviewed identity
decisions when reusing the data.

Source references: [NSF Award Search](https://www.nsf.gov/funding/award-search),
[Carnegie data center](https://carnegieclassifications.acenet.edu/data-center/),
[Carnegie 2025 research designations](https://carnegieclassifications.acenet.edu/carnegie-classification/classification-methodology/2025-research-activity-designations/).
