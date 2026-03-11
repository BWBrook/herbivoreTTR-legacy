# Portal Plan Contract v2 (`schema_version = 2.0.0`)

Portal plan v2 is the primary non-coder YAML surface for running scenario v2
and sensitivity workflows from `portal/`.

Portal plan v1 remains supported only as migration input.

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
- `schema_version` (must be `"2.0.0"`)
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
- `execution.backend` in `{internal_ttr, internal_ttr_compiled}`
- `execution.compiled.enabled` in `{auto, true, false}` (logical also accepted)
- `execution.compiled.kernel_policy` in `{resistance_only, all_available}`
- `execution.compiled.strict` (logical)
- `execution.compiled.verbose` (logical)
- `execution.parallel.execution_mode` in `{auto, serial, multicore}`
- `execution.parallel.hardware_tier` in `{auto, laptop, workstation, server}`
- `execution.parallel.workers` (integer or null)
- `execution.parallel.reserve_cores` (integer >= 0)

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
  through `validate_scenario_v2()`.

## `sensitivity`

Fields:
- `sensitivity.enabled` (logical)
- `sensitivity.design` in `{one_at_a_time, grid}`
- `sensitivity.keep_baseline` (logical)
- `sensitivity.parameters` (list)

Each parameter entry requires:
- `path` (dot path into scenario object, e.g. `runtime.days`)
- `values` (vector/list of one or more values)

## `outputs`

Fields:
- `outputs.render_report` (logical)
- `outputs.report_formats` subset of `{html, pdf}`
- `outputs.acceptance_profile` in `{standard, balanced_demo, stress_demo}`
- `outputs.include_interactive` (logical)

## Artefact layout

Portal outputs are written under:
- `artefacts/portal_runs/<plan_id_slug>/`

Standard subfolders:
- `canonical_runs/`
- `tables/`
- `figures/`
- `reports/`
- `manifests/`

Single-run tables may differ by scenario `daily_output_kind`:
- explicit runs emit daily/endpoint summaries built from individual herbivore output,
- implicit pressure runs emit daily/endpoint summaries built from pressure-only metrics.

## Error semantics

Validation and execution raise structured classes, including:
- `herbivoreTTR_portal_plan_invalid`
- `herbivoreTTR_portal_plan_path_invalid`
- `herbivoreTTR_portal_plan_sensitivity_invalid`

These are intended to provide actionable feedback to non-coder users.
