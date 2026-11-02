# RQ2 Verified recipient research classifications

RQ2 counts **individual selected awards** by recipient research classification.
The graph label `University` is inherited and does not prove that every
recipient name represents a separate degree-granting campus.

## Step 1 Inspect stored codes

Run Q05 in [RQ2_STEPS.cypher](../queries/RQ2_STEPS.cypher).
It describes stored `research2025_value` values, including `-99` or missing
values. Stored codes are retained as provenance and are not the final
reviewed classification result.

## Step 2 Separate identity matching from raw-code completeness

Run Q06. A populated `verified_unitid` can coexist with a missing raw code.
In this snapshot 56 verified recipients account for 6,260 awards whose
classification can be recovered through the official workbook.

School, department, campus, and legal-awardee names can differ from parent
institution names. Do not promote approximate name candidates automatically.
Use reviewed identities and the verified UnitID field.

## Step 3 Supply the reviewed parameter object

Open [classifications.json](../queries/parameters/classifications.json).
The complete object contains 612 entries with source recipient key, verified
UnitID and official research code. It is generated from the archived
[recipient crosswalk](../data/reference/live_recipient_classification.csv).

In Browser, use its `:params` command with the complete JSON object, then run
Q07 as a separate query. Alternatively, the environment-based runner supplies
the parameter automatically:

```shell
python scripts/run_live_checks.py --rq 2
```

This requires an existing matching database and the connection environment
variables described in [Setup](SETUP.md). No credentials are enclosed.

## Step 4 Aggregate awards through recipient identity

Run Q07. It matches both the stored source recipient key and verified UnitID,
then counts distinct Award nodes. It does not count recipient nodes as awards
or classify investigators by their profile affiliations.

| Classification | Awards | Share of 18,267 classified awards |
| --- | ---: | ---: |
| R1 | 16,137 | 88.3% |
| R2 | 1,088 | 6.0% |
| Research Colleges and Universities | 568 | 3.1% |
| Explicit no research designation | 474 | 2.6% |

Result: [RQ2_verified_research_classification.csv](../results/rq2/RQ2_verified_research_classification.csv).
The four rows sum to **18,267 awards**, linked to **612 recipient identities**.
The other **6,481 awards** remain in the overall 24,748-award cohort but are
outside this identity-based classification subset. Explicit no designation
(`-2`) is an official category, not missing data.

## Step 5 Reproduce the workbook join without Neo4j

```shell
python analysis/analyze_rq2.py
```

Inputs are the prepared recipient nodes, individual award-to-recipient links,
and [2025 Carnegie workbook](../data/reference/2025-Public-Data-File.xlsx).
The script joins verified UnitIDs to the workbook's `data` sheet, weights each
recipient by its distinct selected awards, and compares every recipient's
official classification to the archived crosswalk.

One audited workbook exception is preserved: UT Austin has `F` in the
workbook's UnitID cell. Its already verified UnitID `228778` is accepted only
with the unique exact institution-name match after normalization. The script
does not create new unreviewed name matches.

Outputs: [offline_recipient_join.csv](../results/rq2/offline_recipient_join.csv)
and [offline_classification_summary.json](../results/rq2/offline_classification_summary.json).

## Step 6 Cross-check the result

```shell
python scripts/check_repository.py
python scripts/check_repository.py --full
```

The first checks workbook and crosswalk hashes, the 612 parameter identities,
the four classification totals, and both denominators. `--full` additionally
repeats the workbook join and graph-library checks.
The nine-block historical live evidence is in
[paper_query_verification.json](../evidence/paper_query_verification.json).
The exception and recovery counts are in
[verified_recovery_analysis.json](../data/reference/verified_recovery_analysis.json).
The 2025 classifications are applied retrospectively to older awards; they
do not describe historical institution status at each award date.
