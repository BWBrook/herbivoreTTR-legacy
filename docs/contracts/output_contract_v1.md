# Output Contract v1 (`schema_version = 1.0.0`)

Output contract v1 extends v0 with explicit run/cohort identifiers required for
multi-herbivore and scenario-traceable experiments.

This low-level snapshot contract remains in use for parity-oriented
`plants_day*.csv` / `herb_day*.csv` outputs.

Scenario-run bundle outputs such as `herbivore_daily.csv` and
`pressure_daily.csv` are documented separately in
`docs/contracts/scenario_run_output_contract_v2.md`.

## Version mechanism

- Schema version: `1.0.0`
- Source of truth: `R/output_contract.R` (`OUTPUT_SCHEMA_VERSION`)
- Required propagation:
  - `SchemaVersion` column in output CSVs
  - `schema_version` field in `run_manifest.json`

## New required identifiers

- `RunID`: deterministic run identifier, present in all required output tables.
- `HerbivoreID`: per-individual identifier, required in herbivore outputs.
- `run_id`: required top-level field in run manifests.

## Required table schemas

## `plants_day<DDD>.csv` (semicolon-delimited)

Required columns (in order):
- `RunID`
- `SchemaVersion`
- `Year`
- `Day`
- `Plant`
- `VegType`
- `Height`
- `BLeaf`
- `BStem`
- `BDef`
- `Ms`
- `Ns`
- `Cs`
- `Mr`
- `Cr`
- `Nr`

## `herb_day<DDD>.csv` (semicolon-delimited)

Required columns (in order):
- `RunID`
- `HerbivoreID`
- `SchemaVersion`
- `Year`
- `Day`
- `HerbType`
- `Mass`
- `xcor`
- `ycor`
- `DailyDistMoved`
- `DailyPEI`
- `DailyNPEI`
- `DailyDMI`
- `DailyForageWater`
- `TotalDMI`
- `WaterBalance`
- `EnergyBalance`

## Manifest schema (`run_manifest.json`)

Required top-level fields:
- `schema_version`
- `run_id`
- `package_version`
- `git_sha`
- `seed`
- `scenario_slug`
- `scenario_parameters_hash`
- `outputs`
- `created_utc`

## Migration from v0 (`0.1.0`) to v1 (`1.0.0`)

Migration helpers:
- `migrate_plants_output_v0_to_v1()`
- `migrate_herbivore_output_v0_to_v1()`
- `migrate_output_csv_v0_to_v1()`

Migration behavior:
- adds required identifier columns (`RunID`, `HerbivoreID` where required),
- updates `SchemaVersion` to `1.0.0`,
- preserves v0 payload columns and ordering semantics under v1 contract.

Legacy fixture inputs used for migration tests are stored in:
- `inst/extdata/migration_v0/`

## Deprecation note

v0 output tables remain supported only as migration input format. New canonical
runs and manifests are required to emit v1 schema.
