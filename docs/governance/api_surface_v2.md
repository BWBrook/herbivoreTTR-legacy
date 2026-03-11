# API Surface — v2.0

This document defines the primary public API surface for `herbivoreTTR` v2.0.

Policy:
- The exported function set is intentional and treated as stable for the v2 line.
- Breaking changes follow `docs/governance/deprecation_policy.md`.

## Tier 1: Scenario-first entry points
- `scenario_contract_version()`
- `scenario_contract_version_v2()`
- `scenario_contract_reference_path()`
- `validate_scenario_v1()` (compatibility wrapper to v2 validation)
- `validate_scenario_v2()`
- `compile_scenario_yaml()`
- `compile_scenario_yaml_v2()`
- `run_scenario_v1()` (compatibility wrapper to v2 execution)
- `run_scenario_v2()`

## Tier 1: Reference experiments and report pipeline
- `run_reference_scenario_library()`
- `run_experiment_a_presence_removal()`
- `run_experiment_b_functional_types()`
- `run_experiment_c_aridity_gradient()`
- `run_benchmark_appendix_v1()`
- `render_paper_pipeline_report()`

## Tier 2: Advanced state-level simulation API
- `init_conditions()`
- `init_plants()`
- `init_herbivore()`
- `init_simulation()`
- `run_daily_herbivore_simulation()`
- `run_herbivore_days()`
- `herbivore_step()`
- `herbivore_move()`
- `hourly_digestion_step()`
- `reset_daily_variables()`
- `update_gut_content()`

## Tier 2: Behaviour and physiology helpers
- `calc_bite_size()`
- `calc_daily_energy_balance()`
- `calc_foraging_traits()`
- `calc_foraging_velocity()`
- `calc_gut_capacity()`
- `calc_handling_time()`
- `calc_plant_tastiness()`
- `calc_toroidal_distance()`
- `calc_water_requirement()`
- `check_daily_water_balance()`
- `get_plants_within_range()`
- `pick_a_plant()`
- `select_randomly()`
- `summarise_hourly_herbivore_record()`
- `write_hourly_herbivore_log()`

## Notes
- Scenario v2 is the primary first-party surface.
- Scenario v1 remains supported only as migration input.
- Output and scenario schemas are versioned contracts and are part of the public surface.
