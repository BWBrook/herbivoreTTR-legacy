# Developer Quickstart (herbivoreTTR)

This guide covers bootstrap, quality gates, pipeline runs, and release/repro checks.

## 1) Bootstrap with renv

From project root:

```r
Sys.setenv(RENV_CONFIG_PAK_ENABLED = "FALSE")
renv::restore(prompt = FALSE)
renv::status()
```

## 2) Core quality gates

```bash
make test
make lint
make smoke
make check
```

Or run all at once:

```bash
make rc-gates
```

## 3) Scenario workflow sanity run

```r
library(herbivoreTTR)
scenario <- compile_scenario_yaml_v2(scenario_contract_reference_path("canonical_smoke_v1"))
run <- run_scenario_v2(scenario)
run$run_dir
```

Inspect outputs in:
- `artefacts/canonical_runs/smoke_v0/`

## 4) Targets pipeline

```r
Sys.setenv(TARGETS_PROFILE = "ci")
targets::tar_make(callr_function = NULL)
```

Pipeline output roots:
- `artefacts/canonical_runs/`
- `artefacts/reports/`

## 5) Build release candidate bundle

```bash
make release-bundle
```

Bundle location:
- `artefacts/release_candidates/<release_label>/`

Includes:
- source tarball
- copied reference output bundles
- paper report output
- `release_manifest.json`
- `release_checklist_status.csv`

## 6) External reproducibility run-through

```bash
make repro-check
```

Evidence location:
- `artefacts/reproducibility/external_run_v1/`

See also:
- `docs/governance/reproducibility_runbook_v1.md`
- `docs/governance/api_surface_v2.md`
- `docs/governance/deprecation_policy.md`
