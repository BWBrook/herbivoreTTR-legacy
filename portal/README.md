# Ecologist Portal (YAML + One-Command Runs)

This folder is the non-coder entrypoint for running herbivoreTTR.

Primary portal plans now use `schema_version: "2.0.0"` and scenario v2.

## Quickstart

1. Copy a template plan YAML from `portal/plans/templates/`.
2. Edit only the YAML values and comments.
3. Run from repo root:

```bash
Rscript portal/run_plan.R portal/plans/templates/single_scenario_template.yaml
```

For sensitivity analysis:

```bash
Rscript portal/run_sensitivity.R portal/plans/templates/sensitivity_template.yaml
```

Run artefacts are written to:
- `artefacts/portal_runs/<plan_id_slug>/`

Key outputs:
- `run_index.csv`
- `tables/*.csv`
- single-run tables depend on `daily_output_kind`:
  - explicit runs: individual-oriented summaries
  - implicit pressure runs: pressure-oriented summaries
- `tables/ecological_acceptance_summary.csv` (single mode) or
  `tables/sensitivity_ecological_acceptance_summary.csv` (sensitivity mode)
- `figures/*.png`
- `reports/*.html` (and optional PDF)
- `manifests/portal_run_manifest.json`

Template set:
- `single_scenario_template.yaml` for generic single runs
- `balanced_demo_template.yaml` for short-horizon lower-stress demonstrations
- `stress_demo_template.yaml` for expected high-stress contrast demonstrations
- `sensitivity_template.yaml` for one-at-a-time sensitivity runs
- `laptop_safe_template.yaml` for conservative laptop runs
- `workstation_balanced_template.yaml` for balanced multicore runs
- `throughput_max_template.yaml` for high-throughput hosts

## Runtime guidance by hardware tier

Set these in `execution.parallel` inside the plan YAML:

- Laptop (<=8 cores): `execution_mode: auto`, `hardware_tier: laptop`, `workers: null`, `reserve_cores: 1`
- Workstation (9-32 cores): `execution_mode: auto`, `hardware_tier: workstation`, `workers: null`, `reserve_cores: 2`
- Server (>32 cores): `execution_mode: auto`, `hardware_tier: server`, `workers: null`, `reserve_cores: 4`

Trade-off notes:
- Lower `reserve_cores` gives more throughput but can make the host less responsive.
- Explicit `workers` overrides tier defaults and is useful for reproducible benchmarking.
- CI remains serial by default to reduce timing variance.

## Optional compiled resistance kernel

Compiled controls are YAML-first under `execution.backend` and
`execution.compiled`:

- `execution.backend`: `internal_ttr` or `internal_ttr_compiled`
- `execution.compiled.enabled`: `auto`, `true`, or `false`
- `execution.compiled.kernel_policy`: `resistance_only` or `all_available`
- `execution.compiled.strict`: fail if requested kernels unavailable
- `execution.compiled.verbose`: print runtime config diagnostics

Typical safe setting:
- backend compiled-capable with `enabled: auto`, `kernel_policy: resistance_only`, `strict: false`.

If compilation is unavailable, runs automatically fall back to pure R when
`strict: false`. Fallback state is recorded in
`manifests/portal_run_manifest.json` under `execution_context`.

## One-command profiles

```bash
Rscript portal/run_plan.R portal/plans/templates/laptop_safe_template.yaml
Rscript portal/run_plan.R portal/plans/templates/workstation_balanced_template.yaml
Rscript portal/run_plan.R portal/plans/templates/throughput_max_template.yaml
```

## Optional GUI stub

```bash
Rscript portal/launch_gui_stub.R
```

The GUI is intentionally lightweight and calls the same backend logic as the CLI.
CLI remains the authoritative workflow for reproducibility.
