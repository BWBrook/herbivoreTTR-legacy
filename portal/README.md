# Ecologist Portal (YAML + One-Command Runs)

This folder is the non-coder entrypoint for running herbivoreTTR.

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

## Optional GUI stub

```bash
Rscript portal/launch_gui_stub.R
```

The GUI is intentionally lightweight and calls the same backend logic as the CLI.
CLI remains the authoritative workflow for reproducibility.
