# RQ2 result files

See [the RQ2 guide](../../docs/RQ2_STEP_BY_STEP.md).

- [RQ2_verified_research_classification.csv](RQ2_verified_research_classification.csv):
  archived live Q07 counts, using the reviewed identity mapping.
- [offline_recipient_join.csv](offline_recipient_join.csv): independently
  repeated workbook join, one row per recipient identity with award weight.
- [offline_classification_summary.json](offline_classification_summary.json):
  four official class totals, 612 identities, 18,267 classified awards,
  6,481 awards outside the subset, and the workbook exception.

Run `python analysis/analyze_rq2.py` from the repository root to reproduce
the last two files without Neo4j. The original crosswalk and workbook remain
in `data/reference/`; the optional live query runner uses that reviewed mapping.
