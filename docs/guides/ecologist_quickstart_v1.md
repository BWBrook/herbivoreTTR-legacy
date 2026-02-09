# Ecologist Quickstart v1 (No Coding Required)

This quickstart is for users who only want to edit a YAML file and run commands.

## 1. Pick a plan template

Templates are in:
- `portal/plans/templates/`

Start with:
- `single_scenario_template.yaml` for one scenario run.
- `balanced_demo_template.yaml` for a short-horizon lower-stress demo.
- `stress_demo_template.yaml` for an explicit high-stress contrast demo.
- `sensitivity_template.yaml` for sensitivity analysis.
- `laptop_safe_template.yaml` for conservative laptop-friendly runs.
- `workstation_balanced_template.yaml` for a balanced multicore profile.
- `throughput_max_template.yaml` for high-throughput hosts.

## 2. Edit the YAML only

You usually only change:
- `plan_id`
- scenario overrides under `scenario.overrides`
- sensitivity settings under `sensitivity.parameters`
- optional runtime controls under `execution.backend` and `execution.compiled`

Keep `schema_version` unchanged.

## 3. Validate before running (dry-run)

```bash
Rscript portal/run_plan.R portal/plans/templates/single_scenario_template.yaml --dry-run
```

For sensitivity:

```bash
Rscript portal/run_sensitivity.R portal/plans/templates/sensitivity_template.yaml --dry-run
```

## 4. Execute

Single scenario:

```bash
Rscript portal/run_plan.R portal/plans/templates/single_scenario_template.yaml
```

Sensitivity:

```bash
Rscript portal/run_sensitivity.R portal/plans/templates/sensitivity_template.yaml
```

### Runtime tuning by machine type

Use profile templates directly:

- Laptop-safe:

```bash
Rscript portal/run_plan.R portal/plans/templates/laptop_safe_template.yaml
```

- Workstation-balanced:

```bash
Rscript portal/run_plan.R portal/plans/templates/workstation_balanced_template.yaml
```

- Throughput-max:

```bash
Rscript portal/run_plan.R portal/plans/templates/throughput_max_template.yaml
```

Or tune manually in the YAML under `execution.parallel`:

- Laptop (<=8 cores): `hardware_tier: laptop`, `workers: null`, `reserve_cores: 1`
- Workstation (9-32 cores): `hardware_tier: workstation`, `workers: null`, `reserve_cores: 2`
- Server (>32 cores): `hardware_tier: server`, `workers: null`, `reserve_cores: 4`

Keep `execution_mode: auto` unless you need strict serial runs (`serial`) or fixed multicore behavior (`multicore`).

### Optional compiled acceleration (YAML-first)

Control compiled usage in YAML under `execution.compiled`:

- `enabled: false` forces pure R.
- `enabled: true` requests compiled kernels.
- `enabled: auto` requests compiled kernels when `execution.backend: internal_ttr_compiled`.
- `kernel_policy: resistance_only` requests compiled resistance kernel only.
- `kernel_policy: all_available` requests resistance + minute-loop kernels.
- `strict: true` fails early if requested compiled kernels are unavailable.

Default safe recommendation for most users:
- `execution.backend: internal_ttr_compiled`
- `execution.compiled.enabled: auto`
- `execution.compiled.kernel_policy: resistance_only`
- `execution.compiled.strict: false`

If compilation is unavailable, fallback metadata is recorded in
`manifests/portal_run_manifest.json` under `execution_context`.

## 5. Inspect outputs

Outputs are written to:
- `artefacts/portal_runs/<plan_id_slug>/`

Key files:
- `run_index.csv` (all runs and IDs)
- `tables/*.csv` (summaries and sanity checks)
- `tables/ecological_acceptance_summary.csv` or
  `tables/sensitivity_ecological_acceptance_summary.csv` (interpretation checks)
- `figures/*.png` (time, spatial, and comparison plots)
- `reports/*.html` (run report)
- `manifests/portal_run_manifest.json` (provenance)

Check compiled/parallel runtime context in manifest fields:
- `execution_context.backend_used`
- `execution_context.compiled_last_engine`
- `execution_context.compiled_minute_loop_last_engine`
- `execution_context.parallel_mode`

## 6. Optional GUI

```bash
Rscript portal/launch_gui_stub.R
```

Use the GUI to edit/save YAML and trigger the same backend run functions.

## Troubleshooting

- YAML errors:
  - check indentation (spaces, no tabs)
  - ensure list items use `-`
- Unknown sensitivity path:
  - use dot paths from scenario structure, e.g. `runtime.days`
- Missing report output:
  - Quarto may be missing from PATH; check `reports/report_render_notes.md`
- Interpreting demo profile checks:
  - `outputs.acceptance_profile: balanced_demo` expects moderate body condition
    and less severe energy deficits over short runs.
  - `outputs.acceptance_profile: stress_demo` expects strong stress signals and
    severe energy deficits as an intentional contrast.
- Slow large sensitivity runs:
  - reduce values in `sensitivity.parameters`
  - set `execution.parallel.execution_mode` to `multicore` on local workstation
