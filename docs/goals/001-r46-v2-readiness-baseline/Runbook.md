# Goal 001 Runbook

Run all commands from `/Users/bwbrook/git/herbivoreTTR` on
`codex/herbivore-ttr-goal-001`.

## Stop Rules

- Stop before any scientific, public-API, output-contract, package-version, or
  restore-policy trade-off not already decided in `docs/decisions.md`.
- Stop if a required gate fails and the fix would exceed Goal 001 scope.
- Do not reset, clean, stash, force, merge, tag, push, or publish.
- Do not stage ignored generated artefacts.

## 1. State And Runtime Preflight

```sh
pwd
git status --short --branch
git rev-parse --short HEAD
git diff --stat
R --version
Rscript --version
command -v R
command -v Rscript
r_home="$(R --vanilla --slave -e 'cat(normalizePath(R.home(), winslash = "/", mustWork = TRUE))')"
rscript_home="$(Rscript --vanilla -e 'cat(normalizePath(R.home(), winslash = "/", mustWork = TRUE))')"
test "$r_home" = "$rscript_home"
make assert-r-runtime
R -q -e 'cat(R.version.string, "\n"); cat("renv ", as.character(utils::packageVersion("renv")), "\n", sep = ""); print(.libPaths())'
```

Expected: Goal 001 branch at base `872fb20` before commit; host R 4.6.x;
`renv` available; R and Rscript resolve one R home; only the inherited and
Goal 001 scoped paths are dirty.

## 2. Environment Synchronization

```sh
R -q -e 'status <- renv::status(); if (!isTRUE(status$synchronized)) quit(status = 1, save = "no")'
```

Expected: exit 0 and synchronized project state.

## 3. Required Engineering Gates

Run separately so each outcome is attributable:

```sh
make test
make test-memory
make lint
make smoke
make check
test -s herbivoreTTR.Rcheck/00check.log
if rg -n '(^Status:.*(ERROR|WARNING)|[.][.][.] (ERROR|WARNING)$)' herbivoreTTR.Rcheck/00check.log; then exit 1; fi
```

Expected:

- tests: zero failures, including the dedicated retained-heap gate;
- lint: zero lints;
- smoke: CI-profile targets complete;
- check: zero errors and warnings; any notes must be copied exactly into
  `Log.md` and independently accepted as non-actionable.

The final package-portability proof must also build and check the source
tarball from a fresh directory outside the checkout. Goal 001's accepted run
used `/tmp/herbivoreTTR-standalone-final13.GqIlqG`: package tests reported 1,158
passes, 38 intentional skips, and zero warnings; the outer check reported only
the same two accepted notes.

## 4. Required v2 Report And Release Evidence

```sh
make render-v2
test ! -e artefacts/release_candidates/v2.0.0-rc1-goal001-20260711-attempt6
make release-bundle-v2 RELEASE_V2_LABEL=v2.0.0-rc1-goal001-20260711-attempt6
```

Expected:

- `artefacts/reports_v2/paper_pipeline_v2.html` exists and is non-empty;
- `artefacts/release_candidates/v2.0.0-rc1-goal001-20260711-attempt6/release_manifest.json`
  exists;
- every row in
  `artefacts/release_candidates/v2.0.0-rc1-goal001-20260711-attempt6/release_checklist_status.csv`
  passes; and the builder refused any inherited non-empty destination before
  expensive work.

## 5. Required Clean-Library Reproducibility Gates

```sh
test ! -e artefacts/reproducibility/external_run_v1_goal001_20260711_attempt7
test ! -e artefacts/reproducibility/external_run_v1_goal001_20260711_attempt7_library
test ! -e artefacts/reproducibility/external_run_v1_goal001_20260711_attempt7_targets
test ! -e artefacts/reproducibility/external_run_v2_goal001_20260711_attempt6
test ! -e artefacts/reproducibility/external_run_v2_goal001_20260711_attempt6_library
test ! -e artefacts/reproducibility/external_run_v2_goal001_20260711_attempt6_targets
make repro-check \
  REPRO_V1_OUT_DIR=artefacts/reproducibility/external_run_v1_goal001_20260711_attempt7 \
  REPRO_V1_LIB_DIR=artefacts/reproducibility/external_run_v1_goal001_20260711_attempt7_library \
  REPRO_V1_TARGETS_STORE=artefacts/reproducibility/external_run_v1_goal001_20260711_attempt7_targets
make repro-check-v2 \
  REPRO_V2_OUT_DIR=artefacts/reproducibility/external_run_v2_goal001_20260711_attempt6 \
  REPRO_V2_LIB_DIR=artefacts/reproducibility/external_run_v2_goal001_20260711_attempt6_library \
  REPRO_V2_TARGETS_STORE=artefacts/reproducibility/external_run_v2_goal001_20260711_attempt6_targets
```

Expected:

- both commands exit 0;
- both fresh `repro_check_manifest.json` files contain `"all_pass": true` and
  record the selected R executable, R home, R version, isolated library, and
  targets store;
- every row in both `repro_check_summary.csv` files has `passed` true.

Earlier release and replay paths are preserved as diagnostic evidence. The
original v1 path exposed the pre-fix verifier's incorrect use of a
scenario-runner output that the targets graph does not own. Later attempts
were superseded when final-review corrections changed tracked code. None may
be reused or treated as final evidence.

## 6. Workflow And Diff Gates

```sh
actionlint
git diff --check
```

Expected: both exit 0 with no actionable output.

## 7. Structured Artefact Inspection

```sh
for manifest in \
  artefacts/reproducibility/external_run_v1_goal001_20260711_attempt7/repro_check_manifest.json \
  artefacts/reproducibility/external_run_v2_goal001_20260711_attempt6/repro_check_manifest.json; do
  test -s "$manifest"
  jq -e '
    .all_pass == true and
    (.r_executable | type == "string" and length > 0) and
    (.r_home | type == "string" and length > 0) and
    (.r_version | type == "string" and length > 0) and
    (.isolated_library | type == "string" and length > 0) and
    (.targets_store | type == "string" and length > 0) and
    (.pre_run_snapshot | type == "string" and length > 0) and
    (.run_marker | type == "string" and length > 0)
  ' "$manifest"
  test -x "$(jq -r '.r_executable' "$manifest")"
  test -s "$(jq -r '.summary_csv' "$manifest")"
  test -s "$(jq -r '.report_md' "$manifest")"
  test -s "$(jq -r '.pre_run_snapshot' "$manifest")"
  test -s "$(jq -r '.run_marker' "$manifest")"
done
R -q -e 'for (p in c("artefacts/reproducibility/external_run_v1_goal001_20260711_attempt7/repro_check_summary.csv", "artefacts/reproducibility/external_run_v2_goal001_20260711_attempt6/repro_check_summary.csv")) { x <- read.csv(p); stopifnot(nrow(x) > 0L, all(x$passed)); cat(p, nrow(x), "passing rows\n") }'
release_manifest=artefacts/release_candidates/v2.0.0-rc1-goal001-20260711-attempt6/release_manifest.json
test -s "$release_manifest"
jq -e --arg label 'v2.0.0-rc1-goal001-20260711-attempt6' '
  .release_label == $label and
  .all_checks_pass == true and
  (.checklist_path | type == "string" and length > 0)
' "$release_manifest"
release_checklist="$(jq -r '.checklist_path' "$release_manifest")"
package_tarball="$(jq -r '.package_tarball' "$release_manifest")"
test -s "$release_checklist"
test -s "$package_tarball"
R -q -e "x <- read.csv('$release_checklist'); stopifnot(nrow(x) > 0L, all(x\$pass)); cat(nrow(x), 'release checklist rows pass\n')"
test -s artefacts/reports_v2/paper_pipeline_v2.html
test -s artefacts/reports_v2/figure_table_manifest_v2.csv
R -q -e 'x <- read.csv("artefacts/reports_v2/figure_table_manifest_v2.csv"); stopifnot(nrow(x) > 0L, !any(x$artifact_id == "figure_table_manifest_v2.csv"), all(file.exists(x$path))); stopifnot(identical(unname(tools::md5sum(x$path)), x$checksum_md5), identical(as.numeric(file.info(x$path)$size), as.numeric(x$bytes)))'
R -q -e 'sys.source("R/report_manifest_v2.R", envir = globalenv()); stopifnot(check_report_content_v2("artefacts/reports_v2/paper_pipeline_v2.html"))'
rg -n '<title>|Figure|Table|herbivoreTTR' artefacts/reports_v2/paper_pipeline_v2.html | head -20
```

Expected: manifests identify successful current runs; all summary/checklist
rows pass; rendered report is non-empty and contains expected report content.

The ignored controller record
`.superpowers/sdd/validation/final-replay-output-manifest.tsv` must match every
recorded SHA-256 hash, byte count, and UTC modification time. Every
`verified_output` entry must be strictly newer than the v2 run marker.

Representative model-output inspection must use the output paths verified by
the reproducibility scripts. It must confirm finite numeric state and
non-negative biomass using existing field contracts, and record exact paths
and commands in `Log.md`.

## 8. Final Pre-Commit Gate

```sh
R -q -e 'status <- renv::status(); if (!isTRUE(status$synchronized)) quit(status = 1, save = "no")'
git diff --check
git status --short --branch
git diff --name-status
git diff --stat
```

After independent final review, stage exact accepted paths only. Then inspect:

```sh
git diff --cached --name-status
git diff --cached --check
git status --short --branch
```

If and only if every gate passes, create the authorized local commit:

```sh
git commit -m 'chore: consolidate R 4.6 readiness baseline'
git status --short --branch
git rev-parse --short HEAD
git log -1 --oneline
```

Do not push.
