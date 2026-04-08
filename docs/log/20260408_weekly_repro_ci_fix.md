# Weekly Repro CI Fix

- Date: 2026-04-08
- Branch/sha at investigation start: `main` / `ad34091`
- Trigger: GitHub Actions `Weekly Repro Check` run failures on `main`

## Failure summary

The scheduled workflow `Weekly Repro Check` was failing in the `External reproducibility run-through v2` step. The failing GitHub Actions run inspected was:

- Workflow run: `24020865309`
- Job: `weekly-repro`
- Job URL: `https://github.com/BWBrook/herbivoreTTR/actions/runs/24020865309/job/70049376305`

The job log showed the wrapper script failing after `renv::restore()` entered the `pak` restore path and hit a known solver/subprocess error. Downstream steps then failed because the isolated library was only partially restored.

## Root cause

`scripts/run_external_repro_check_v2.R` was setting `RENV_CONFIG_PAK_ENABLED=FALSE` only in the child process environment. In this workflow path, that was insufficient to keep `renv::restore()` off the `pak` restore code path.

The result was a restore failure of the form:

```text
Error:
! error in pak subprocess
Caused by error in `if (!version_satisfies(candidate$version, resolution$remote[[1]]$atleast, …`:
! missing value where TRUE/FALSE needed
```

The legacy `scripts/run_external_repro_check.R` wrapper used the same brittle restore pattern.

## Change made

Updated both external reproducibility wrappers so the restore step disables `pak` inside the child R session as well as in the subprocess environment:

- `options(renv.config.pak.enabled = FALSE)`
- `Sys.setenv(RENV_CONFIG_PAK_ENABLED = "FALSE")`

Files changed:

- `scripts/run_external_repro_check_v2.R`
- `scripts/run_external_repro_check.R`

## Verification

Local reproduction of the failing path before the fix:

- `Rscript scripts/run_external_repro_check_v2.R artefacts/reproducibility/external_run_v2_local`
- Result: failed in `01_restore` with the `pak` subprocess solver error; subsequent steps failed due missing packages/outputs.

Local verification after the fix:

- `Rscript scripts/run_external_repro_check_v2.R artefacts/reproducibility/external_run_v2_local_fix`
- Result: full pass

Step summary from the repaired local run:

- `01_restore`: PASS
- `02_targets_smoke`: PASS
- `03_run_v2_suites`: PASS
- `04_verify_outputs`: PASS

Evidence paths:

- `artefacts/reproducibility/external_run_v2_local/01_restore.log`
- `artefacts/reproducibility/external_run_v2_local_fix/repro_check_summary.csv`
- `artefacts/reproducibility/external_run_v2_local_fix/repro_check_report.md`

## Follow-up notes

- The weekly workflow also emits a GitHub warning about Node.js 20 action deprecation. That did not cause this failure, but the workflow actions should be refreshed before the GitHub-hosted runner default changes to Node.js 24.
