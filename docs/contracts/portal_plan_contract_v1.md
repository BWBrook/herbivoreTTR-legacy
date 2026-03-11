# Portal Plan Contract v1 (`schema_version = 1.0.0`)

Superseded by `docs/contracts/portal_plan_contract_v2.md` for first-party
portal workflows. v1 remains supported only as migration input.

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
- `execution.backend` in `{internal_ttr, internal_ttr_compiled}`
- `execution.compiled.enabled` in `{auto, true, false}` (logical also accepted)
- `execution.compiled.kernel_policy` in `{resistance_only, all_available}`
- `execution.compiled.strict` (logical)
- `execution.compiled.verbose` (logical)
- `execution.parallel.execution_mode` in `{auto, serial, multicore}`
- `execution.parallel.hardware_tier` in `{auto, laptop, workstation, server}`
- `execution.parallel.workers` (integer or null)
- `execution.parallel.reserve_cores` (integer >= 0)

Behavior:
- `auto` parallel mode uses serial on CI and multicore locally.
- `execution.backend` controls plant backend routing:
  - `internal_ttr`: pure-R backend
  - `internal_ttr_compiled`: compiled-capable backend (still fallback-safe)
- `execution.compiled.enabled` resolves compiled request policy:
  - `false`: force pure-R kernels
  - `true`: request compiled kernels
  - `auto`: request compiled kernels only when `execution.backend` is compiled
- `execution.compiled.kernel_policy` selects which compiled kernels are requested:
  - `resistance_only`: resistance kernel only
  - `all_available`: resistance + minute-loop tastiness kernel
- `execution.compiled.strict: true` fails early if requested compiled kernels are unavailable.
- `execution.compiled.verbose: true` emits runtime config diagnostics in logs.
- `hardware_tier` selects conservative default worker caps when `workers` is null:
  - `laptop`: up to 6 workers, reserve 1 core
  - `workstation`: up to 24 workers, reserve 2 cores
  - `server`: up to 48 workers, reserve 4 cores
  - `auto`: inferred from detected core count
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
- `outputs.acceptance_profile` in `{standard, balanced_demo, stress_demo}`
- `outputs.include_interactive` (logical)

Notes:
- HTML report render is the default.
- PDF render is best-effort and depends on local Quarto/PDF toolchain.
- `acceptance_profile` controls which ecological acceptance checks are reported
  in run tables (reporting-only; it does not hard-fail runs).

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
- `tables/ecological_acceptance_summary.csv` (single mode) or
  `tables/sensitivity_ecological_acceptance_summary.csv` (sensitivity mode)

Manifest runtime metadata:
- `execution_context.backend_requested`
- `execution_context.backend_used`
- `execution_context.compiled_enabled`
- `execution_context.compiled_kernel_policy`
- `execution_context.compiled_ttr_requested`
- `execution_context.compiled_minute_loop_requested`
- `execution_context.compiled_last_engine`
- `execution_context.compiled_minute_loop_last_engine`
- `execution_context.parallel_mode`
- `execution_context.parallel_hardware_tier`

## Error semantics

Validation and execution raise structured classes, including:
- `herbivoreTTR_portal_plan_invalid`
- `herbivoreTTR_portal_plan_path_invalid`
- `herbivoreTTR_portal_plan_sensitivity_invalid`

These are intended to provide actionable feedback to non-coder users.
