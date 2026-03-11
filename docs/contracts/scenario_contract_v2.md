# Scenario Contract v2 (`schema_version = 2.0.0`)

This document defines the primary experiment-entry contract used by
`compile_scenario_yaml_v2()`, `validate_scenario_v2()`, and `run_scenario_v2()`.

Scenario contract v1 remains supported only as a migration input.

## Purpose

Scenario contract v2 preserves the explicit single/cohort workflows while
redefining the implicit mode as **pressure-only**, not faux individual
physiology.

## Top-level fields

Required top-level fields:
- `schema_version` (must equal `"2.0.0"`)
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

Optional:
- `runtime$forage_access_scale` in `(0, 1]`

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
- `implicit_pressure`

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

### `implicit_pressure`

Required:
- `population$template_herbivore` herbivore spec.
- `population$stocking_density_per_km2` (`>= 0`)
- `population$visitation_rate_per_day` (`>= 0`)

Meaning:
- effective visits are computed from stocking density, plot area, and visitation rate,
- those visits represent vegetation pressure events,
- the mode does **not** imply a coherent individual trajectory across days.

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

## Migration from v1

`migrate_scenario_v1_to_v2()` performs the canonical migration:
- `schema_version: "1.0.0"` -> `"2.0.0"`
- `population.mode: implicit_representative` -> `implicit_pressure`
- `population.representative` -> `population.template_herbivore`

Explicit v1 scenarios migrate structurally without changing intended behavior.

## Determinism

YAML compilation is deterministic:
- same YAML input -> identical validated scenario object,
- same scenario + same seed -> deterministic run outputs under supported runtime.

## Error classes

Validation failures raise structured v2 classes, for example:
- `herbivoreTTR_scenario_v2_schema_version_invalid`
- `herbivoreTTR_scenario_v2_days_invalid`
- `herbivoreTTR_scenario_v2_herbivore_id_duplicate`
- `herbivoreTTR_scenario_v2_stocking_density_invalid`

These classes are contract-tested in `tests/testthat/test_scenario_contract_v1.R`.
