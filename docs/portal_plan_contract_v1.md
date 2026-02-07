# Portal Plan Contract v1 (`schema_version = 1.0.0`)

The portal plan is the non-coder single-source-of-truth YAML for running
scenarios and sensitivity analyses from the `portal/` entrypoint.

## Purpose

A portal plan unifies:
- scenario selection,
- scenario overrides,
- sensitivity settings,
- output/report options,
- execution/parallel defaults.

The same plan can be run from CLI scripts and the GUI stub.

## Top-level fields

Required:
- `schema_version` (must be `"1.0.0"`)
- `plan_id` (string)
- `execution` (list)
- `scenario` (list)
- `sensitivity` (list)
- `outputs` (list)

Optional:
- `description` (string)

## `execution`

Required:
- `execution.mode` in `{single, sensitivity}`
- `execution.base_dir` (output root)
- `execution.dry_run` (logical)
- `execution.write_outputs` (logical)
- `execution.parallel.execution_mode` in `{auto, serial, multicore}`
- `execution.parallel.workers` (integer or null)
- `execution.parallel.reserve_cores` (integer >= 0)

Behavior:
- `auto` parallel mode uses serial on CI and multicore locally.
- output root is `artefacts/portal_runs/<plan_id_slug>/` by default.

## `scenario`

Required:
- `scenario.source` in `{reference, path}`

If `source: reference`:
- `scenario.reference` must resolve with `scenario_contract_reference_path()`.

If `source: path`:
- `scenario.path` must resolve to an existing scenario YAML.

Optional:
- `scenario.overrides` nested list of overrides to apply before validation.

Override behavior:
- overrides are applied path-wise to the compiled scenario and revalidated
  through `validate_scenario_v1()`.

## `sensitivity`

Fields:
- `sensitivity.enabled` (logical)
- `sensitivity.design` in `{one_at_a_time, grid}`
- `sensitivity.keep_baseline` (logical)
- `sensitivity.parameters` (list)

Each parameter entry requires:
- `path` (dot path into scenario object, e.g. `runtime.days`)
- `values` (vector/list of one or more values)

Rules:
- sensitivity mode requires at least one parameter definition.
- parameter paths are validated against the base scenario before execution.

## `outputs`

Fields:
- `outputs.render_report` (logical)
- `outputs.report_formats` subset of `{html, pdf}`
- `outputs.include_interactive` (logical)

Notes:
- HTML report render is the default.
- PDF render is best-effort and depends on local Quarto/PDF toolchain.

## Artefact layout

Portal outputs are written under:
- `artefacts/portal_runs/<plan_id_slug>/`

Standard subfolders:
- `canonical_runs/`
- `tables/`
- `figures/`
- `reports/`
- `manifests/`

Standard index/manifest files:
- `run_index.csv`
- `manifests/portal_run_manifest.json`
- `manifests/plan_input.yaml` (if run from file)
- `manifests/plan_resolved.yaml`

## Error semantics

Validation and execution raise structured classes, including:
- `herbivoreTTR_portal_plan_invalid`
- `herbivoreTTR_portal_plan_path_invalid`
- `herbivoreTTR_portal_plan_sensitivity_invalid`

These are intended to provide actionable feedback to non-coder users.
