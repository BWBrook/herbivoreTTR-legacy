# Architecture — herbivoreTTR

## Overview

`herbivoreTTR` is a coupled plant-herbivore simulator with deterministic artefact workflows.
It now supports three population execution modes behind a shared scenario contract:
- `explicit_single`
- `explicit_cohort`
- `implicit_representative`

Public API freeze status:
- Scenario-first v1 entrypoints are now the primary stable user surface.
- Full export inventory is documented in `docs/api_surface_v1.md`.
- Deprecation and compatibility guarantees are documented in `docs/deprecation_policy.md`.

Canonical execution path:
1. Compile scenario YAML (`compile_scenario_yaml()`).
2. Validate and normalize (`validate_scenario_v1()`).
3. Build conditions and initial state.
4. Run daily coupling loops.
5. Emit schema-versioned outputs + run manifest.

## Scenario Contract Boundary

Scenario contract v1 (`schema_version = 1.0.0`) is the run-entry boundary.
See `docs/scenario_contract_v1.md`.

Core scenario sections:
- `runtime`: seed, minute budget, day range.
- `plot`: geometry + vegetation composition.
- `climate`: forcing mode and scaling controls.
- `population`: explicit cohort or implicit representative semantics.
- `outputs`: scenario slug for artefact layout.

Reference scenario files:
- `config/scenarios/` (source checkout)
- `inst/extdata/scenarios/` (installed fallback)

## State Objects

### `conditions`

A daily forcing table with at least:
- `day`
- `temp_mean`
- `sw`
- `N`

### `plants`

A per-plant state table including:
- identity and position (`plant_id`, `xcor`, `ycor`, `veg_type`, `height`)
- biomass pools (`ms`, `mr`, `bleaf`, `bstem`, `bdef`, `md`)
- C/N pools (`cs`, `cr`, `ns`, `nr`, `cd`, `nd`)
- transport/state intermediates (`tau*`, `r*`, `u*`)

### `herbivore`

A per-individual state list including:
- `herbivore_id`
- strategy (`herb_type`, `foraging_mode`, preference controls)
- spatial state (`xcor`, `ycor`, `selected_plant_id`, `behaviour`)
- physiology (`mass`, `gut_capacity`, `bite_size`, `handling_time`, `fv_max`)
- digestion queues (hourly vectors)
- daily counters (`intake_*`, `distance_moved`, balances)

## Plant Backend Interface

Plant dynamics are encapsulated via backend interface contract:
- `init(veg_types)`
- `step_day(plants, conditions, day_index)`
- `apply_herbivory(plants)`
- `observe(plants)`

Current backend:
- `internal_ttr` (default), resolved by `resolve_plant_backend()`.

This boundary allows optional benchmark backends without changing herbivore orchestration.

## Simulation Orchestration

### Single Herbivore

`run_daily_herbivore_simulation()`:
- optional plant growth (`apply_growth = TRUE/FALSE`)
- minute-loop behavior and feeding
- hourly digestion updates
- end-of-day water/energy closure

### Cohort Runner

`run_daily_herbivore_cohort()` and `run_herbivore_cohort_days()`:
- deterministic update order by sorted `herbivore_id`
- shared plant state updated sequentially within day
- one growth step per day before first herbivore

### Implicit Representative Mode

`run_daily_implicit_representative()`:
- computes effective visits from:
  - stocking density (`per km2`)
  - plot area
  - visitation rate
- executes full + fractional representative visits deterministically
- outputs explicit visitation metadata for interpretation

## Output Contracts

Current canonical output schema: `1.0.0`.
See `docs/output_contract_v1.md`.

Key requirements:
- `RunID` on plant/herbivore outputs
- `HerbivoreID` on herbivore outputs
- `run_id` in manifest
- deterministic run-id generation via `build_run_id()`

Derived structure/fuel metrics:
- `total_shoot_biomass_kg`
- `grass_shoot_biomass_kg`
- `woody_shoot_biomass_kg`
- `fine_fuel_proxy_kg`
- `browseable_biomass_kg`
- `defended_shoot_biomass_kg`
- `mean_height_m`, `p90_height_m`

## Determinism and Guards

Determinism:
- scenario seed controls stochastic climate (if used), movement, and selection.
- cohort ordering is deterministic (`herbivore_id` sort).

Runtime guardrails:
- domain sanity checks at growth/start/minute/end phases
- gut-capacity invariants
- finite/non-negative plant/energy/water constraints
- TTR-specific numeric guardrails

## Reference Experiment Layer

Reference library and experiment builders:
- `run_reference_scenario_library()`
- `run_experiment_a_presence_removal()`
- `run_experiment_b_functional_types()`
- `run_experiment_c_aridity_gradient()`
- `run_benchmark_appendix_v1()`

Paper pipeline:
- Quarto skeleton in `reports/paper_pipeline.qmd`
- rendered by `render_paper_pipeline_report()` from artefacts.

## Performance Intent

- keep minute-loop logic free of heavy data wrangling
- enforce small-scenario runtime budget in tests
- maintain CI-appropriate smoke pipeline under `TARGETS_PROFILE=ci`
