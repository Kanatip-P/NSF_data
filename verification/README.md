# Verification records

[ASSEMBLY_CHECK_RESULTS.json](ASSEMBLY_CHECK_RESULTS.json) records the offline
content check at assembly time. `FILE_MANIFEST.json` at the repository root
records the final published file inventory, sizes and hashes, including this
assembly report but excluding the manifest itself.

Run `python scripts/check_repository.py` from the root to verify that manifest
and the scientific result relationships. The checker prints a fresh report
to standard output. To save a local report without changing the delivered
inventory:

```shell
python scripts/check_repository.py > verification/local_check.json
```

`local_` reports are ignored by Git and by the manifest inventory check.
The graph-analysis verification is separately recorded in
[results/rq3/verification.json](../results/rq3/verification.json).
No manuscript or paper-layout checks are included here; those documents are
kept in a separate folder.
