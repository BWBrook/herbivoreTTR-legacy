# External Reproducibility Run-through (v1)

This runbook validates that a third party can restore dependencies and
regenerate core artefacts from a clean library and targets store.

## Preconditions

- Linux or macOS shell with R installed
- Repository checkout at project root
- Network access to the configured CRAN mirror

## One-command run-through

```bash
make repro-check
```

The bare target generates a unique UTC/process run ID and creates three fresh,
non-overlapping sibling paths under `artefacts/reproducibility/`:

- `external_run_v1_<run-id>` for logs and manifests;
- `external_run_v1_<run-id>_library` for the isolated `renv` library;
- `external_run_v1_<run-id>_targets` for the fresh targets store.

For a reviewed run with stable names, set all three Make variables explicitly:

```bash
make repro-check \
  REPRO_V1_OUT_DIR=artefacts/reproducibility/reviewed_v1 \
  REPRO_V1_LIB_DIR=artefacts/reproducibility/reviewed_v1_library \
  REPRO_V1_TARGETS_STORE=artefacts/reproducibility/reviewed_v1_targets
```

Every destination must be absent or empty before the run starts.

## What the script does

1. Confirms the selected R and Rscript resolve to the same R home.
2. Runs `renv::restore(prompt = FALSE, clean = TRUE)` in the isolated library
   with `RENV_CONFIG_PAK_ENABLED=FALSE`, then requires synchronized status.
3. Runs the CI-profile pipeline in the fresh targets store and requires readable
   non-empty targets metadata.
4. Captures pre-run file metadata and a same-tree run marker.
5. Requires every named output and every canonical `plants_day*.csv` and
   `herb_day*.csv` snapshot to be regenerated after that marker.
6. Validates finite numeric state, non-negative plant biomass, finite herbivore
   balances, and non-negative herbivore mass using the existing output contract.

## Evidence files

The unique output directory contains:

- `01_restore.log`
- `02_targets_smoke.log`
- `03_verify_outputs.log`
- `pre_run_file_snapshot.rds`
- `repro_check_summary.csv`
- `repro_check_report.md`
- `repro_check_manifest.json`

The manifest records the exact R executable/home/version, isolated library,
targets store, snapshot, marker, report, summary, and aggregate pass state.

## Success criteria

- The command exits zero.
- Every summary row has `passed == TRUE`.
- The manifest has `all_pass == true` and names the three fresh run paths.
- Required outputs are newer than the run marker and satisfy their contracts.

## Troubleshooting

- Restore failure: inspect `01_restore.log` and required system libraries.
- Pipeline failure: inspect `02_targets_smoke.log` for target diagnostics.
- Verification failure: inspect `03_verify_outputs.log`, the pre-run snapshot,
  and the marker before considering any rerun.
- Never reuse a failed or successful run directory; choose new sibling paths.
