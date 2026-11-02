# NSF enriched graph data dictionary

Database: `nsf-project-workon-enriched`. This inventory is generated from the hash-checked package whose exact IDs and properties passed the target audit.

**Stored** is the count of nodes or relationships carrying the property. **Nonempty** counts nonblank strings and nonempty lists; coded sentinel values such as `-99` still count as stored and nonempty. Use the status fields and paired descriptions for classification meaning.

## Project (17,503 nodes)

| Property | Type | Stored | Nonempty | Meaning |
| --- | --- | ---: | ---: | --- |
| `abstract` | string | 17,503 | 17,503 | Abstract selected for the grouped project from source awards. |
| `amount` | float | 17,503 | 17,503 | Project-level amount from the selected source; use Award.total_amount for individual awards. |
| `analysis_eligible` | boolean | 17,503 | 17,503 | True when at least half the source roster has usable subjects and affiliation. |
| `collab` | integer | 17,503 | 17,503 | Source flag: 1 when the distinct original PI roster has more than one person. |
| `combined_project` | integer | 17,503 | 17,503 | Legacy SPSS flag: 1 when multiple Standard Grant awards were grouped by title. |
| `csv_pi_found` | integer | 17,503 | 17,503 | Legacy PI-found count from the SPSS selection data. |
| `csv_pi_found_share` | float | 17,503 | 17,503 | Legacy PI-found share from the SPSS selection data. |
| `csv_pi_missing` | integer | 17,503 | 17,503 | Legacy PI-missing count from the SPSS selection data. |
| `csv_pi_total` | integer | 17,503 | 17,503 | Legacy PI total from the SPSS selection data; not the reconciled roster size. |
| `duration_years` | float | 17,503 | 17,503 | Project duration recorded in the selected source. |
| `end_year` | integer | 17,503 | 17,503 | Selected project end year. |
| `expected_team_size` | integer | 17,503 | 17,503 | Audited distinct original_pi roster size across selected linked awards. |
| `full_linked_award_count` | integer | 17,503 | 17,503 | Number of broader full_linked_award_ids. |
| `full_linked_award_ids` | list<string> | 17,503 | 17,503 | Broader same-title award IDs across instrument types; many are outside this graph. |
| `lead_state` | string | 17,503 | 17,503 | First state value recorded for the selected project. |
| `linked_award_count` | integer | 17,503 | 17,503 | Number of selected linked_award_ids. |
| `linked_award_ids` | list<string> | 17,503 | 17,503 | Selected Standard Grant award IDs represented by HAS_AWARD links. |
| `org_code` | string | 17,503 | 17,503 | Source NSF organization code, stored as text. |
| `primary_award_id` | string | 17,503 | 17,503 | Primary source award ID for the selected project. |
| `profile_coverage` | float | 17,503 | 17,503 | usable_team_count divided by expected_team_size. |
| `project_id` | string | 17,503 | 17,503 | Selected project key; the primary award ID, stored as text. |
| `roster_source` | string | 17,503 | 17,503 | Provenance of the roster used for eligibility and WORK_ON links. |
| `states` | list<string> | 17,503 | 17,503 | State values recorded for the selected project. |
| `team_complete` | integer | 17,503 | 17,503 | Legacy selected-source team-complete flag; not analysis_eligible. |
| `team_majority` | integer | 17,503 | 17,503 | Legacy selected-source majority flag; not analysis_eligible. |
| `title` | string | 17,503 | 17,503 | Title selected for the grouped project from source awards. |
| `unique_original_pi_found` | integer | 17,503 | 17,503 | Legacy count of source PI IDs found in the selected Scopus profile IDs. |
| `unique_original_pi_found_share` | float | 17,503 | 17,503 | Legacy found share; not the current subjects-and-affiliation coverage. |
| `unique_original_pi_missing` | integer | 17,503 | 17,503 | Legacy source PI IDs absent from the selected Scopus profile IDs. |
| `unique_original_pi_total` | integer | 17,503 | 17,503 | Distinct original_pi IDs across the project's selected linked awards. |
| `usable_team_count` | integer | 17,503 | 17,503 | Roster members with nonempty subjects and affiliation after exact-ID supplementation. |
| `work_on_edge_count_expected` | integer | 17,503 | 17,503 | Legacy expected distinct PI-project link count. |
| `year` | integer | 17,503 | 17,503 | Selected project year; use Award.start_date for an award's start year. |

## Person (30,239 nodes)

| Property | Type | Stored | Nonempty | Meaning |
| --- | --- | ---: | ---: | --- |
| `affiliation` | string | 25,980 | 25,980 | Recorded affiliation text; not proof of award-time appointment. |
| `affiliation_source` | string | 30,239 | 25,980 | Database/field supplying affiliation; empty string means unavailable. |
| `department` | string | 8,302 | 8,302 | Department text from the selected Person when available. |
| `department_source` | string | 30,239 | 8,302 | Database/label supplying department; empty string means unavailable. |
| `has_scopus_json` | boolean | 19,681 | 19,681 | Legacy selected-source flag for a Scopus JSON profile. |
| `name` | string | 30,239 | 30,239 | Investigator name, preferring selected, then original, then Mongo source. |
| `nsf_id` | string | 30,197 | 30,197 | Nine-digit numeric NSF ID; absent for alphanumeric source keys. |
| `profile_usable` | boolean | 30,239 | 30,239 | True when subjects is nonempty and affiliation is nonblank. |
| `source_id_alphanumeric` | boolean | 30,239 | 30,239 | True when source_person_key is alphanumeric rather than numeric. |
| `source_person_key` | string | 30,239 | 30,239 | Unique source investigator key; nine characters, numeric or alphanumeric. |
| `subjects` | list<string> | 30,239 | 25,978 | Multi-valued Scopus-derived subject tags; not a unique field or award-year label. |
| `subjects_source` | string | 30,239 | 25,978 | Database/label supplying subjects; empty string means unavailable. |

## Award (24,748 nodes)

| Property | Type | Stored | Nonempty | Meaning |
| --- | --- | ---: | ---: | --- |
| `Funding Levels` | string | 24,748 | 24,748 | Original funding-level band; quote this key with backticks in Cypher. |
| `abstract` | string | 24,748 | 24,748 | Original source award abstract. |
| `cfda` | string | 24,748 | 24,748 | Original CFDA program code, stored as text. |
| `end_date` | string | 24,748 | 24,748 | Original award end date as YYYY-MM-DD text. |
| `funding_level_code` | string | 24,748 | 24,748 | Original funding-level code. |
| `id` | string | 24,748 | 24,748 | Original NSF award ID, stored as text. |
| `source_db` | string | 24,748 | 24,748 | Database from which raw award properties came. |
| `start_date` | string | 24,748 | 24,748 | Original award start date as YYYY-MM-DD text. |
| `title` | string | 24,748 | 24,748 | Original source award title. |
| `total_amount` | float | 24,748 | 24,748 | Original individual award amount. |
| `tran_type` | string | 24,748 | 24,748 | Original funding instrument/transaction type. |
| `type` | string | 24,748 | 24,748 | Original award type. |

## University (1,374 nodes)

| Property | Type | Stored | Nonempty | Meaning |
| --- | --- | ---: | ---: | --- |
| `aanapisi_description` | string | 1,374 | 1,374 | Raw original explanation for aanapisi_value; read together with the code. |
| `aanapisi_value` | integer | 1,374 | 1,374 | Raw original aanapisi classification code; read with aanapisi_description. -99 means not found. |
| `annhsi_description` | string | 1,374 | 1,374 | Raw original explanation for annhsi_value; read together with the code. |
| `annhsi_value` | integer | 1,374 | 1,374 | Raw original annhsi classification code; read with annhsi_description. -99 means not found. |
| `basic2021_description` | string | 1,374 | 1,374 | Raw original explanation for basic2021_value; read together with the code. |
| `basic2021_value` | integer | 1,374 | 1,374 | Raw original basic2021 classification code; read with basic2021_description. -99 means not found. |
| `cce_description` | string | 1,374 | 1,374 | Raw original explanation for cce_value; read together with the code. |
| `cce_value` | integer | 1,374 | 1,374 | Raw original cce classification code; read with cce_description. -99 means not found. |
| `city` | string | 1,374 | 1,374 | Raw original recipient city. |
| `control_description` | string | 1,374 | 1,374 | Raw original explanation for control_value; read together with the code. |
| `control_value` | integer | 1,374 | 1,374 | Raw original control classification code; read with control_description. -99 means not found. |
| `hbcu_description` | string | 1,374 | 1,374 | Raw original explanation for hbcu_value; read together with the code. |
| `hbcu_value` | integer | 1,374 | 1,374 | Raw original hbcu classification code; read with hbcu_description. -99 means not found. |
| `highest_degree_2025_description` | string | 1,374 | 1,374 | Raw original explanation for highest_degree_2025_value; read together with the code. |
| `highest_degree_2025_value` | integer | 1,374 | 1,374 | Raw original highest_degree_2025 classification code; read with highest_degree_2025_description. -99 means not found. |
| `hsi_description` | string | 1,374 | 1,374 | Raw original explanation for hsi_value; read together with the code. |
| `hsi_value` | integer | 1,374 | 1,374 | Raw original hsi classification code; read with hsi_description. -99 means not found. |
| `ic2025_description` | string | 1,374 | 1,374 | Raw original explanation for ic2025_value; read together with the code. |
| `ic2025_value` | integer | 1,374 | 1,374 | Raw original ic2025 classification code; read with ic2025_description. -99 means not found. |
| `ic2025alf_description` | string | 1,374 | 1,374 | Raw original explanation for ic2025alf_value; read together with the code. |
| `ic2025alf_value` | integer | 1,374 | 1,374 | Raw original ic2025alf classification code; read with ic2025alf_description. -99 means not found. |
| `ic2025size_description` | string | 1,374 | 1,374 | Raw original explanation for ic2025size_value; read together with the code. |
| `ic2025size_value` | integer | 1,374 | 1,374 | Raw original ic2025size classification code; read with ic2025size_description. -99 means not found. |
| `institution_match_status` | string | 1,374 | 1,374 | Result of the institution identity audit: verified or unresolved category. |
| `landgrant_description` | string | 1,374 | 1,374 | Raw original explanation for landgrant_value; read together with the code. |
| `landgrant_value` | integer | 1,374 | 1,374 | Raw original landgrant classification code; read with landgrant_description. -99 means not found. |
| `lpp_description` | string | 1,374 | 1,374 | Raw original explanation for lpp_value; read together with the code. |
| `lpp_value` | integer | 1,374 | 1,374 | Raw original lpp classification code; read with lpp_description. -99 means not found. |
| `medical_description` | string | 1,374 | 1,374 | Raw original explanation for medical_value; read together with the code. |
| `medical_value` | integer | 1,374 | 1,374 | Raw original medical classification code; read with medical_description. -99 means not found. |
| `name` | string | 1,374 | 1,374 | Raw original recipient name; the University label can include other organizations or individuals. |
| `nasnti_description` | string | 1,374 | 1,374 | Raw original explanation for nasnti_value; read together with the code. |
| `nasnti_value` | integer | 1,374 | 1,374 | Raw original nasnti classification code; read with nasnti_description. -99 means not found. |
| `pbi_description` | string | 1,374 | 1,374 | Raw original explanation for pbi_value; read together with the code. |
| `pbi_value` | integer | 1,374 | 1,374 | Raw original pbi classification code; read with pbi_description. -99 means not found. |
| `research2025_description` | string | 1,374 | 1,374 | Raw original explanation for research2025_value; read together with the code. |
| `research2025_status` | string | 1,374 | 1,374 | Raw research code interpretation: tier recorded, no designation, or missing in source. |
| `research2025_value` | integer | 1,374 | 1,374 | Raw original research2025 classification code; read with research2025_description. -99 means not found. |
| `rpu_description` | string | 1,374 | 1,374 | Raw original explanation for rpu_value; read together with the code. |
| `rpu_value` | integer | 1,374 | 1,374 | Raw original rpu classification code; read with rpu_description. -99 means not found. |
| `saec2025_description` | string | 1,374 | 1,374 | Raw original explanation for saec2025_value; read together with the code. |
| `saec2025_value` | integer | 1,374 | 1,374 | Raw original saec2025 classification code; read with saec2025_description. -99 means not found. |
| `setting2025_description` | string | 1,374 | 1,374 | Raw original explanation for setting2025_value; read together with the code. |
| `setting2025_value` | integer | 1,374 | 1,374 | Raw original setting2025 classification code; read with setting2025_description. -99 means not found. |
| `source_db` | string | 1,374 | 1,374 | Database from which the recipient node was copied. |
| `source_university_id` | string | 1,374 | 1,374 | Original University node's snapshot elementId; not stable across source rebuilds. |
| `tribal_description` | string | 1,374 | 1,374 | Raw original explanation for tribal_value; read together with the code. |
| `tribal_value` | integer | 1,374 | 1,374 | Raw original tribal classification code; read with tribal_description. -99 means not found. |
| `unitid_match_status` | string | 612 | 612 | Verification method for verified_unitid; absent when unresolved. |
| `verified_unitid` | string | 612 | 612 | 2025 Carnegie UnitID only when the institution match was verified. |
| `womenonly_description` | string | 1,374 | 1,374 | Raw original explanation for womenonly_value; read together with the code. |
| `womenonly_value` | integer | 1,374 | 1,374 | Raw original womenonly classification code; read with womenonly_description. -99 means not found. |
| `zip` | string | 1,374 | 1,374 | Raw original recipient ZIP text. |

## ProgramElement (552 nodes)

| Property | Type | Stored | Nonempty | Meaning |
| --- | --- | ---: | ---: | --- |
| `code` | string | 552 | 552 | Exact ProgramElement code from the selected source graph; text, not a name. |

## ProgramReference (959 nodes)

| Property | Type | Stored | Nonempty | Meaning |
| --- | --- | ---: | ---: | --- |
| `code` | string | 959 | 959 | Exact ProgramReference code from the selected source graph; text, not a name. |

## WORK_ON (48,509 relationships)

| Property | Type | Stored | Nonempty | Meaning |
| --- | --- | ---: | ---: | --- |
| `role` | string | 48,509 | 48,509 | Priority project-level role chosen across source awards. |
| `roles` | list<string> | 48,509 | 48,509 | All source roles held on the selected project's linked awards. |
| `source_award_ids` | list<string> | 48,509 | 48,509 | Selected award IDs on which this person appears in original_pi. |

## HAS_AWARD (24,748 relationships)

No relationship properties. The endpoints carry the identity and detail.

## INVESTIGATOR_ON (73,212 relationships)

| Property | Type | Stored | Nonempty | Meaning |
| --- | --- | ---: | ---: | --- |
| `pi_end_dates` | list<string> | 73,212 | 2,937 | Source original_pi end dates for this person on this award. |
| `pi_start_dates` | list<string> | 73,212 | 73,212 | Source original_pi start dates for this person on this award. |
| `role` | string | 73,212 | 73,212 | Priority role for this specific award. |
| `roles` | list<string> | 73,212 | 73,212 | All original_pi role strings for this person on this award. |

## HOSTED_BY (24,748 relationships)

No relationship properties. The endpoints carry the identity and detail.

## HAS_PROGRAM_ELEMENT (23,296 relationships)

No relationship properties. The endpoints carry the identity and detail.

## HAS_PROGRAM_REFERENCE (40,626 relationships)

No relationship properties. The endpoints carry the identity and detail.
