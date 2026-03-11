# Scenario Contract v1 (`schema_version = 1.0.0`)

Superseded by `docs/contracts/scenario_contract_v2.md` for first-party runs.
v1 remains supported only as migration input.

This document defines the canonical experiment-entry contract used by `compile_scenario_yaml()`,
`validate_scenario_v1()`, and `run_scenario_v1()`.

## Purpose

Scenario contract v1 provides a stable, deterministic run specification for:
- targets pipeline execution,
- reference experiment reproducibility,
- migration-safe scenario authoring via YAML.

## Top-level fields

Required top-level fields:
- `schema_version` (must equal `"1.0.0"`)
- `scenario_id` (string; defaults to `outputs$scenario_slug` if missing)
- `runtime`
- `plot`
- `climate`
- `population`
- `outputs`

## Runtime

Required:
- `runtime$seed` (finite integer)
- `runtime$minute_limit` (`>= 1`)
- `runtime$days` (`>= 1`)
- `runtime$start_day` (`>= 1`)

## Plot

Required:
- `plot$veg_types` (non-empty integer vector in `{0,1,2}`)
- `plot$plot_size_m2` (`> 0`)
- `plot$plants_in_x` (`>= 1`)
- `plot$plants_in_y` (`>= 1`)

## Climate

Required:
- `climate$mode` in `{flat, stochastic, seasonal}`

Optional (validated when present):
- `climate$mean_temp` (finite)
- `climate$amplitude` (finite, `>= 0`)
- `climate$sw_scale` (finite, `>= 0`)
- `climate$n_scale` (finite, `>= 0`)

## Population

Supported modes:
- `explicit_single`
- `explicit_cohort`
- `implicit_representative`

### Herbivore spec

Each herbivore entry requires:
- `herbivore_id` (non-empty, unique in explicit cohort)
- `mass_g` (`> 0`)
- `herb_type` in `{0,1,2}`
- `MRT_hours` (`>= 1`)
- `foraging_mode` in `{nutrient_targeting, energy_only}` (optional; defaults to `nutrient_targeting`)

### `explicit_single`

Required:
- `population$cohort` containing exactly one herbivore spec.

### `explicit_cohort`

Required:
- `population$cohort` containing one or more herbivore specs.
- all `herbivore_id` values must be unique.

### `implicit_representative`

Required:
- `population$representative` herbivore spec.
- `population$stocking_density_per_km2` (`>= 0`)
- `population$visitation_rate_per_day` (`>= 0`)

## Outputs

Required:
- `outputs$scenario_slug` (non-empty string)

`scenario_slug` controls artefact folder location:
- `artefacts/canonical_runs/<scenario_slug>/`

## Canonical references

Reference scenario YAML files live in:
- `config/scenarios/`

Installed-package fallback copies live in:
- `inst/extdata/scenarios/`

`scenario_contract_reference_path()` resolves either source-checkout or installed paths.

## Determinism

YAML compilation is deterministic:
- same YAML input -> identical validated scenario object,
- same scenario + same seed -> deterministic run outputs under supported runtime.

## Error classes

Validation failures raise structured classes, for example:
- `herbivoreTTR_scenario_v1_schema_version_invalid`
- `herbivoreTTR_scenario_v1_days_invalid`
- `herbivoreTTR_scenario_v1_herbivore_id_duplicate`
- `herbivoreTTR_scenario_v1_stocking_density_invalid`

These classes are contract-tested in `tests/testthat/test_scenario_contract_v1.R`.
