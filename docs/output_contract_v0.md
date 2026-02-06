# Output Contract v0 (`schema_version = 0.1.0`)

This document defines the minimum stable output schema for canonical smoke runs.
Any incompatible change to required tables/columns must bump `schema_version`
and include migration notes and tests.

## Schema version mechanism
- Canonical schema version: `0.1.0`
- Source of truth in code: `R/output_contract.R` via `OUTPUT_SCHEMA_VERSION`
- Required propagation:
  - `SchemaVersion` column in required CSV tables
  - `schema_version` field in `run_manifest.json`

## Canonical run folder
- Path: `artefacts/canonical_runs/smoke_v0/`
- Required files:
  - `run_manifest.json`
  - `plants_day1826.csv`
  - `herb_day1826.csv`
  - `plants_day1832.csv`
  - `herb_day1832.csv`

## Required table schemas

## `plants_day<DDD>.csv` (semicolon-delimited)
- `SchemaVersion`: schema tag for this row set (character)
- `Year`: simulation year (integer)
- `Day`: simulation day index (integer)
- `Plant`: plant identifier (integer)
- `VegType`: vegetation functional type code (integer)
- `Height`: plant height (model units)
- `BLeaf`: leaf biomass pool (kg DM)
- `BStem`: stem biomass pool (kg DM)
- `BDef`: defence biomass pool (kg DM)
- `Ms`: shoot structural biomass (kg DM)
- `Ns`: shoot nitrogen pool (model units)
- `Cs`: shoot carbon pool (model units)
- `Mr`: root structural biomass (kg DM)
- `Cr`: root carbon pool (model units)
- `Nr`: root nitrogen pool (model units)

## `herb_day<DDD>.csv` (semicolon-delimited)
- `SchemaVersion`: schema tag for this row set (character)
- `Year`: simulation year (integer)
- `Day`: simulation day index (integer)
- `HerbType`: herbivore functional type code (`0=grazer`, `1=browser`, `2=mixed`)
- `Mass`: body mass (grams)
- `xcor`: x-coordinate in toroidal space (meters)
- `ycor`: y-coordinate in toroidal space (meters)
- `DailyDistMoved`: daily movement distance (meters/day)
- `DailyPEI`: daily protein-equivalent intake (model energy units)
- `DailyNPEI`: daily non-protein-equivalent intake (model energy units)
- `DailyDMI`: daily dry matter intake (grams/day)
- `DailyForageWater`: daily water intake from forage (model water units)
- `TotalDMI`: cumulative dry matter intake (grams)
- `WaterBalance`: daily net water balance (model water units)
- `EnergyBalance`: daily net energy balance (kJ/day)

## Manifest schema (`run_manifest.json`)
Required top-level fields:
- `schema_version`: contract version string
- `package_version`: package version from `DESCRIPTION`
- `git_sha`: git commit SHA of producing workspace
- `seed`: scalar integer seed used for canonical run
- `scenario_slug`: canonical scenario identifier (`smoke_v0`)
- `scenario_parameters_hash`: deterministic hash of scenario parameter list
- `outputs`: named mapping from output ids to relative output paths
- `created_utc`: UTC timestamp for manifest creation

## Validation rules
- Required output files must exist and match the required columns above.
- Required numeric columns in required outputs must not contain `NA`, `NaN`, or `Inf`.
- `SchemaVersion` must equal the manifest `schema_version`.
