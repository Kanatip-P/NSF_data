# NSF enriched graph: reconciliation and post-import audit

**Status:** Created and audited on 2026-10-27 (Chicago time). `nsf-project-workon-enriched` is online. Existing source databases retain their audited counts.

## Cause and scope

The current `nsf-project-workon-originalpi` cohort has fewer `WORK_ON` links than the investigator roster stored in MongoDB `nsf_awards.grants2.original_pi`. The proposed graph keeps the existing 2015–2025 selected Standard Grant projects and joins their source awards and recipient nodes from `original`. One selected graph project outside this year window is excluded.

The read-only Neo4j Browser check found 17,503 selected projects, 48,509 expected person–project positions, and 36,027 recorded `WORK_ON` links. The Mongo ID-level audit found all 24,748 linked awards, exactly matched every project's stored unique source-team count, and found 12,482 missing and zero extra `WORK_ON` pairs. There are 30,239 distinct source investigator IDs. Fifty-six `original_pi` entries use nine-character alphanumeric IDs, representing 42 people. Their roster positions are retained; they are not matched to numeric NSF profiles.

## Proposed changes in the separate database

| Unit | Current / source evidence | Prepared `nsf-project-workon-enriched` |
| --- | ---: | ---: |
| Selected Project nodes | 17,503 | 17,503 |
| Linked Award nodes | 24,748 in `original` | 24,748 |
| Source investigators | 30,239 distinct IDs | 30,239 Person nodes |
| Person–Project links | 36,027 recorded; 48,509 source positions | 48,509 `WORK_ON` |
| Person–Award roles | Mongo `original_pi` | 73,212 `INVESTIGATOR_ON`, with award-specific role and dates |
| Recipient organizations | 1,374 distinct `original.University` nodes | 1,374 University nodes and 24,748 `HOSTED_BY` links |
| Program elements | 552 codes in the selected source | 552 nodes and 23,296 `HAS_PROGRAM_ELEMENT` links |
| Program references | 959 codes in the selected source | 959 nodes and 40,626 `HAS_PROGRAM_REFERENCE` links |

The new graph also has 24,748 `HAS_AWARD` links. Source-award role lists are retained on investigator links, with a single priority role on project links. Raw award and recipient properties are preserved. `University` is the source label; some recipients are individuals or other organizations. We keep their exact source identity and avoid asserting that every recipient is a degree-granting university.

## PI detail and project eligibility

| Measure | Selected graph only | After exact-ID `original.PI` supplementation |
| --- | ---: | ---: |
| Eligible projects | 17,454 / 17,503 | 17,487 / 17,503 |
| Ineligible: more than half source team lacks subjects or affiliation | 49 | 16 |
| Exactly half usable, therefore eligible | 6,401 | 2,242 |
| Recovered usable person–project positions | — | 7,386 |

The prepared graph has 25,978 / 30,239 people with both subjects and affiliation. It has department data for 8,302 / 30,239 people and 14,412 / 48,509 person–project positions; department is **not** part of the eligibility rule. The remaining 16 ineligible project IDs are `1512667`, `1522532`, `1535337`, `1700585`, `1713567`, `1748132`, `1761842`, `1800657`, `1826144`, `1833502`, `1917545`, `1933679`, `2001568`, `2048940`, `2111150`, and `2331582`. They remain in the proposed graph with `analysis_eligible=false`.

Selected Person fields take precedence. Missing subjects and affiliation are filled only by the same nine-digit NSF ID in `original.PI`; field sources are stored on each Person. The selected-vs-original audit found zero field conflicts. Affiliation from `original.PI.current_affiliation` is a recorded current affiliation, not proven to be affiliation at award time. No profile was accepted from `nsf-csv2` because its exact ID overlap and field conflicts were not successfully exported from the connected Browser; its aggregate counts alone are insufficient for a safe join. It may fill further gaps after an ID-level export and a new report.

## Recipient classification

All 24,748 source awards have one `HOSTED_BY` recipient in the archived `original` graph. The 2025 Carnegie UnitID audit verifies 612 / 1,374 recipient nodes, covering 18,267 / 24,748 awards. Other recipients remain unresolved and keep the raw original properties. The raw `research2025_value` has a recorded research tier for 293 recipient nodes / 11,549 awards, an explicit **no research designation** code (`-2`) for 271 nodes / 473 awards, and a missing-in-source code (`-99`) for 810 nodes / 12,726 awards. The prepared University nodes store these distinctions in `research2025_status` and retain the raw value and description. A source recipient with a person-like name is kept as an unresolved recipient, not matched to a Carnegie institution.

## Verification and limits

The source cohort is 24,748 / 126,282 in-window `original` awards (19.6%); 17,503 is a count of grouped selected projects, not awards. The prepared package passed hash, unique-node-key, unique-relationship, endpoint, exactly-one-award-owner, exactly-one-recipient, project-roster, eligibility, and classification-status checks. The load script defaults to dry-run, refuses an existing target, and checked live source counts and project, edge, award, and recipient IDs before creating the target. The package uses hash-checked Neo4j extracts and a fresh Mongo roster digest.

The post-import audit passed. It compared the exact node-ID sets, exact relationship pairs, every node property, all PI-to-award role and date properties, profile provenance, eligibility flags, and recipient classification properties with the prepared package. It found 17,503 projects, 30,239 people, 24,748 awards, 1,374 recipients, 48,509 `WORK_ON`, 24,748 `HAS_AWARD`, 73,212 `INVESTIGATOR_ON`, and 24,748 `HOSTED_BY` relationships. All 17,487 eligible project flags matched. The target is online; a second read-only source check found the selected-project, selected-`WORK_ON`, original-University, and original in-window award counts unchanged.

After the user identified missing program data, an exact source snapshot added 552 `ProgramElement` nodes and 23,296 links covering 17,473 selected projects, plus 959 `ProgramReference` nodes and 40,626 links covering 15,646 selected projects. Source program-element pairs matched the older hash-checked archive exactly; both program types were also checked against the live selected graph before the patch. The final target audit passed again for all six node types and six relationship types, including every property. Projects without source program links remain without them.

The `nsf-csv2` exact-ID audit remains open. Its Browser query editor did not accept input during the final check. A terminal attempt to read an existing Neo4j password from a project file was rejected by automatic approval review. After the user specifically directed a Jupyter-notebook check, a password in `Compare.ipynb` was verified against the local DBMS and used in memory for this import; it was not printed or stored in the audit outputs.

## ID-level files

- `audit_results/project_eligibility.csv`: baseline by project, including expected, observed, missing, and extra roster counts.
- `audit_results/pi_gaps.csv`: person–project gaps with source roles and missing-field flags.
- `audit_results/project_eligibility_after_original.csv`: proposed eligibility by project.
- `audit_results/original_profile_fills.csv` and `profile_conflicts_original.csv`: exact-ID fills and conflicts.
- `audit_results/award_recipients_original.csv`: each award, original recipient ID, name, and raw research classification.
- `audit_results/prepared_validation.json`: package validation counts.
- `prepared/manifest.json`: package files, row counts, hashes, and roster digest.
- `prepared/load_validation.json`: loader count and live-source checks.
- `prepared/target_audit.json`: final exact-ID, relationship, and property audit.
- `audit_results/program_source/manifest.json`: exact program snapshot files and hashes.
- `prepared/program_patch_validation.json`: incremental program patch result.

The created graph uses the reviewed `original.PI` supplement and retains all 16 flagged projects. `nsf-csv2` can be evaluated later as a separate, exact-ID supplement; its aggregate counts were not used to infer any profile matches.
