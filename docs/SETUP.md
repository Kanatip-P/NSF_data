# Setup and execution order

## 1 Open the repository root

The root contains `README.md`, `analysis/`, `data/`, `queries/`, `results/`,
`scripts/`, and `evidence/`. Run terminal commands from that directory.
Commands use relative paths and do not require the original computer.

## 2 Verify the delivered snapshot before rerunning

```shell
python scripts/check_repository.py
```

Use Python 3.12 or later. This first check requires no additional packages.
`FILE_MANIFEST.json` lists every delivered file and its SHA-256 hash.
`data/prepared/manifest.json` independently identifies the graph export rows
and hashes. A mismatch after a deliberate rerun is a comparison to the
delivered baseline, not automatically evidence of a broken calculation.

## 3 Install the analysis environment

Windows PowerShell:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

macOS or Linux:

```shell
python3.12 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
```

Use that environment's Python for the subsequent commands. The guides write
`python` as shorthand. Dependencies are pinned to the recorded analysis
versions. Optional live checks additionally need `requirements-live.txt`.

## 4 Execute the RQs offline

| Order | Command | Reads | Writes |
| --- | --- | --- | --- |
| 1 | `python analysis/analyze_rqs.py` | Prepared JSONL graph files | `results/rq_analysis.json` |
| 2 | `python scripts/export_rq1.py` | That RQ analysis JSON | RQ1 subject CSVs and coverage JSON |
| 3 | `python analysis/analyze_cohort.py` | Prepared JSONL graph files | `results/cohort_analysis.json` |
| 4 | `python analysis/analyze_rq2.py` | Recipient/award links and Carnegie workbook | RQ2 offline join and summary |
| 5 | `python analysis/analyze_award_centrality.py` | All people, awards and memberships | Both networks, five rankings, correlations and figure |
| 6 | `python analysis/verify_award_centrality.py` | Prepared data and RQ3 exports | RQ3 verification JSON |

`evidence/` holds the unchanged reference calculations and historical live
returns. Do not overwrite those files with a changed dataset. The graph
analysis overwrites its corresponding `results/rq3/` files intentionally;
retain a pristine checkout for byte-for-byte comparisons.

## 5 Optionally run live Cypher

The database must already contain this selected enriched snapshot and its
source-key properties. Neo4j connection settings come only from environment
variables. `.env.example` is a template; scripts do not automatically load it.
No password is supplied or stored in the repository.

PowerShell example:

```powershell
$env:NEO4J_URI = 'bolt://127.0.0.1:7687'
$env:NEO4J_USER = 'neo4j'
$env:NEO4J_DATABASE = 'nsf-project-workon-enriched'
$env:NEO4J_PASSWORD = Read-Host 'Neo4j password' -MaskInput
python scripts/run_live_checks.py --rq all
```

The password prompt requires PowerShell 7. Older shells can set the variable
using their normal local secret mechanism. Do not place a real password in a
committed file. In Neo4j Browser, run the following command separately:

```cypher
:use `nsf-project-workon-enriched`
```

Then run one numbered Cypher block at a time. RQ2 Q07 needs the full reviewed
classification parameter object; the Python runner supplies it automatically.
It verifies the original nine core blocks, or the selected RQ's core blocks.
Supplemental query files and RQ1/RQ3 direct checks are separate manual reruns.

## 6 Interpret drift correctly

A live database is mutable. The delivered counts are tied to the enclosed
snapshot, not guaranteed for a later database state. If a comparison fails,
inspect database selection, person/source IDs, graph totals, workbook hashes,
classification parameters, and counting units before changing expected values.
All optional database operations here are read-only; no loader or migration is
run by the analysis commands.
