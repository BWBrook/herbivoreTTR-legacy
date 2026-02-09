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

## 2. Edit the YAML only

You usually only change:
- `plan_id`
- scenario overrides under `scenario.overrides`
- sensitivity settings under `sensitivity.parameters`

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
