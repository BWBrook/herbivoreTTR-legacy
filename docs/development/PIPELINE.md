# herbivoreTTR Pipeline Overview

This document summarises the `_targets.R` pipeline and release/reproducibility automation.

## Targets pipeline

Command:

```r
Sys.setenv(TARGETS_PROFILE = "ci")
targets::tar_make(callr_function = NULL)
```

Primary outputs:
- canonical scenario bundles (`canonical_smoke_v1`, `cohort_smoke_v1`, `implicit_stocking_v1`)
- behavioural contract bundles (selection, movement, foraging, digestion, water, day-in-life)
- reference scenario library and experiments A/B/C
- benchmark appendix and performance budget bundle
- rendered paper skeleton report at `artefacts/reports/paper_pipeline.html`

All canonical run bundles are written under:
- `artefacts/canonical_runs/<scenario_slug>/`

Each run folder contains:
- `run_manifest.json` (schema version, run ID, package version, git SHA, seed, parameter hash)
- schema-versioned CSV outputs documented in `docs/contracts/output_contract_v1.md`

## Release candidate pipeline

Command:

```bash
make release-bundle
```

This runs `scripts/build_release_bundle.R`, which:
- builds a source tarball (`R CMD build .`)
- regenerates reference artefacts via scenario/experiment runners
- renders the paper pipeline report
- assembles a release folder under `artefacts/release_candidates/<release_label>/`
- writes `release_manifest.json` and `release_checklist_status.csv`

## External reproducibility run-through

Command:

```bash
make repro-check
```

This runs `scripts/run_external_repro_check.R`, which:
- creates fresh sibling output, isolated-library, and targets-store paths with a
  unique run ID;
- restores with `clean = TRUE` and `RENV_CONFIG_PAK_ENABLED=FALSE`;
- executes the CI-profile targets pipeline in the fresh store;
- verifies marker-based freshness plus plant/herbivore snapshot contracts;
- writes logs, a pre-run snapshot, summaries, and a manifest under the unique
  output path.

Set `REPRO_V1_OUT_DIR`, `REPRO_V1_LIB_DIR`, and
`REPRO_V1_TARGETS_STORE` when a reviewed run needs stable path names. Never
reuse a populated destination.

## Full release gate command

```bash
make rc-gates
```

This executes:
- `make test`
- `make lint`
- `make smoke`
- `make check`
