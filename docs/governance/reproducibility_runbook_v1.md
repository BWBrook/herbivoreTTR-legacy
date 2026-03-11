# External Reproducibility Run-through (v1)

This runbook validates that a third party can restore dependencies and regenerate core artefacts from a clean library.

## Preconditions
- Linux/macOS shell with R installed
- Repository checkout at project root
- Network access to CRAN mirror for package restore

## One-command run-through

```bash
make repro-check
```

This executes `scripts/run_external_repro_check.R`.

## What the script does
1. Creates an isolated library at `artefacts/reproducibility/external_run_v1/renv_library`.
2. Runs `renv::restore(prompt = FALSE)` with that isolated library and `RENV_CONFIG_PAK_ENABLED=FALSE`.
3. Runs CI-profile pipeline:

```r
Sys.setenv(TARGETS_PROFILE = "ci")
targets::tar_make(callr_function = NULL)
```

4. Verifies required outputs exist:
- `artefacts/canonical_runs/smoke_v0/run_manifest.json`
- `artefacts/canonical_runs/experiment_a_presence_removal_v1/experiment_a_summary.csv`
- `artefacts/canonical_runs/experiment_b_functional_types_v1/experiment_b_summary.csv`
- `artefacts/canonical_runs/experiment_c_aridity_gradient_v1/experiment_c_summary.csv`
- `artefacts/reports/paper_pipeline.html`

5. Runs basic sanity checks on canonical smoke outputs:
- finite and non-negative `Ms` in plant snapshot
- finite `EnergyBalance` and `WaterBalance` in herbivore daily output

## Evidence files
Generated under `artefacts/reproducibility/external_run_v1/`:
- `01_restore.log`
- `02_targets_smoke.log`
- `03_verify_outputs.log`
- `repro_check_summary.csv`
- `repro_check_report.md`
- `repro_check_manifest.json`

## Success criteria
- All rows in `repro_check_summary.csv` have `passed == TRUE`
- `repro_check_manifest.json` has `all_pass == true`

## Troubleshooting
- If restore fails: inspect `01_restore.log` and ensure system libraries are available.
- If pipeline fails: inspect `02_targets_smoke.log` for target-level diagnostics.
- If verification fails: inspect `03_verify_outputs.log` and check for missing or malformed artefacts.
