# Upload this folder to GitHub

Upload the contents of **NSF_Graph_Reproducibility_GitHub**, so its README is
at the repository root. The sibling **NSF_Paper_Documents_2026-11-01** folder
contains the manuscript and Word/PDF guide and should remain outside this
research-data repository. Original working documents were preserved as well.

## 1 Check the folder locally

```shell
python scripts/check_repository.py
```

The included manifest and assembly report record the delivered snapshot.
The checker verifies that manuscript/office files and embedded credential
assignments are absent and each file is below 25 MiB. `.gitignore` excludes
local credentials, environments, cache files, live rerun outputs, and paper
document extensions. `.env.example` contains blank credentials only.

## 2 Create an empty repository in your own GitHub account

Choose the repository name and visibility in GitHub. This package does not
create a remote repository, choose its visibility, or push anything.

## 3 Upload using Git or GitHub Desktop

From this folder, the standard Git sequence is:

```shell
git init -b main
git add .
git commit -m "Add NSF graph data queries results and reproducibility guides"
git remote add origin YOUR_REPOSITORY_URL
git push -u origin main
```

Replace `YOUR_REPOSITORY_URL` with the URL of the empty repository you created.
These are publishing instructions for the owner, not commands already run by
the package assembler. GitHub Desktop's Add local repository and Publish
repository flow is an alternative.

For browser uploads, upload the folder contents in batches if necessary.
GitHub documents a 25 MiB per-file browser limit and up to 100 files per
upload. See [GitHub's upload instructions](https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository).
Do not upload a ZIP as a substitute for the actual repository contents.

## 4 Inspect the published repository

Check that the README and all three RQ guides render, relative result links
open, the RQ3 PNG displays, and the prepared `.jsonl.gz` files retain their
names. Keep the reference evidence intact. Run analysis changes in a working
checkout and review result differences before committing refreshed files.
