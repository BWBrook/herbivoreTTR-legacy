# Scenario Run Output Contract v2

This document defines the scenario-run bundle surface produced by
`run_scenario_v2()`.

It is distinct from the low-level snapshot parity contract documented in
`docs/contracts/output_contract_v1.md`.

## Manifest additions

`run_manifest.json` now records:
- `daily_output_kind`

Allowed values:
- `explicit_individual`
- `implicit_pressure`

## Explicit individual runs

Explicit runs keep the existing scenario-run daily table:
- `herbivore_daily.csv`

Meaning:
- one row per herbivore per day,
- physiology and diagnostics columns represent coherent individual trajectories.

## Implicit pressure runs

Implicit pressure runs now emit:
- `pressure_daily.csv`
- optional `implicit_visit_detail.csv`

Meaning:
- `pressure_daily.csv` is an aggregate pressure table, not an individual trajectory,
- `implicit_visit_detail.csv` is diagnostic per synthetic visit,
- body condition, deficit streaks, stress flags, maintenance requirements, and
  other individual-physiology outputs are intentionally absent from
  `pressure_daily.csv`.

## `pressure_daily.csv`

Required columns:
- `RunID`
- `SchemaVersion`
- `ScenarioID`
- `ScenarioSlug`
- `PopulationMode`
- `TemplateHerbivoreID`
- `Day`
- `HerbType`
- `VisitCount`
- `FullVisits`
- `FractionalVisit`
- `EffectiveVisitsPerDay`
- `TotalPressurePEI`
- `TotalPressureNPEI`
- `TotalPressureDMI`
- `TotalPressureDistMoved`
- `TotalPressureForageWater`
- `TotalPressureDrinkingWater`
- `TotalPressureVisitMinutes`
- `stocking_density_per_km2`
- `visitation_rate_per_day`

## Migration note

Old implicit-mode `herbivore_daily.csv` outputs must not be interpreted as if
they were directly comparable to `pressure_daily.csv`.

The v2 redesign makes this break explicit instead of averaging synthetic visit
physiology into a faux representative individual.
