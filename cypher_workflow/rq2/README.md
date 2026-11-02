# RQ2: recipient research classifications

Run numbered files and their query blocks in order; download each result table as CSV.

1. [Raw codes](01_raw_codes.cypher): summarize stored recipient classifications and award weights. These are descriptive source fields, not verified identities.
2. [Input cross-checks](02_input_crosschecks.cypher): reconcile reviewed recipient keys and verified UnitIDs with the graph; inspect the exact UT Austin exception.
3. [Verified classification](03_verified_classification.cypher): use `LOAD CSV` to join the supplied Carnegie reference to reviewed recipient identities and distinct awards. This calculation reads reference codes independently rather than using expected result codes.
4. [Crosswalk cross-check](04_crosswalk_crosscheck.cypher): compare all 1,374 recipients and their award counts with the reviewed reference. Require zero mismatches.

The verified subset has **612 recipient nodes and 18,267 awards**: R1 16,137 awards, R2 1,088, RCU 568, and explicit non-designation (`-2`) 474. The other 6,481 awards are outside this verified subset. Unverified identities and missing reference matches must not be interpreted as non-research institutions.

The provided reference retains the workbook's raw UT Austin UnitID `F`. The query accepts it only with verified UnitID `228778` and the exact normalized institution-name check. It does not silently repair other identity mismatches. See [input provenance](../inputs/README.md).
