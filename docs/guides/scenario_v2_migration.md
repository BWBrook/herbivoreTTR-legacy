# Scenario v2 Migration Notes

## What changed

- Primary scenario schema is now `2.0.0`.
- `implicit_representative` has been replaced by `implicit_pressure`.
- `population.representative` has been replaced by `population.template_herbivore`.
- Primary entrypoints are now:
  - `validate_scenario_v2()`
  - `compile_scenario_yaml_v2()`
  - `run_scenario_v2()`

## Why implicit mode changed

The old implicit mode used synthetic visits to represent vegetation pressure,
but then averaged visit-level physiology into a table that looked like a real
individual trajectory. That interpretation was not scientifically coherent.

Scenario v2 makes the semantics explicit:
- implicit mode is pressure-only,
- explicit modes remain the correct path for individual physiology.

## Output changes

Explicit runs still write:
- `herbivore_daily.csv`

Implicit pressure runs now write:
- `pressure_daily.csv`
- optional `implicit_visit_detail.csv`

Do **not** treat `pressure_daily.csv` as a direct replacement for
`herbivore_daily.csv` in downstream joins or analyses.

## Migration helpers

Use `migrate_scenario_v1_to_v2()` to convert legacy v1 scenario objects into
scenario v2 shape before validation or execution.
