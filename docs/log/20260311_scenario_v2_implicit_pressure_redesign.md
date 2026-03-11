# Scenario v2 / implicit-pressure redesign

Date: 2026-03-11

## Summary
- Introduced scenario contract v2 as the primary first-party run surface.
- Redefined implicit mode from `implicit_representative` to `implicit_pressure`.
- Added `run_scenario_v2()` and pressure-only daily output semantics (`pressure_daily.csv`).
- Migrated first-party scenario YAMLs, portal plan templates, targets, user-facing docs, and portal/report summaries to the v2 surface.
- Bumped package version to `2.0.0` to make the contract break explicit.

## Commands executed
- Metadata regeneration:
  - `R -q -e "roxygen2::roxygenise('.')"`
- Focused redesign tests:
  - `R -q -e "testthat::test_dir('tests/testthat', filter = 'scenario_contract|cohort_and_implicit|portal_runner_v1|portal_plan_v1')"`
  - `R -q -e "testthat::test_dir('tests/testthat', filter = 'api_surface|release_pipeline|output_contract|output_migration|scenario_contract|cohort_and_implicit|portal_plan_v1|portal_runner_v1|pipeline_targets|canonical_run_bundle|parity_outputs|post_v1_hardening_v2')"`
- Full quality gates:
  - `make test`
  - `make lint`
  - `make smoke-fast`
  - `make check`
- Artefact review:
  - `R -q -e 'pkgload::load_all(".", quiet = TRUE); out <- run_scenario_v2("config/scenarios/reference_presence_removed_v1.yaml", base_dir = "artefacts/canonical_runs", write_outputs = TRUE); cat(out$pressure_daily_path, "\n")'`
  - `R -q -e '... read.csv("artefacts/canonical_runs/implicit_stocking_v1/pressure_daily.csv") ...'`
  - `R -q -e '... read.csv("artefacts/canonical_runs/reference_presence_removed_v1/pressure_daily.csv") ...'`
  - `R -q -e '... read.csv("artefacts/canonical_runs/implicit_stocking_v1/structure_fuel_daily.csv") ...'`
  - `R -q -e '... read.csv("artefacts/canonical_runs/reference_presence_removed_v1/structure_fuel_daily.csv") ...'`

## Artefacts inspected
- `artefacts/canonical_runs/implicit_stocking_v1/pressure_daily.csv`
- `artefacts/canonical_runs/reference_presence_removed_v1/pressure_daily.csv`
- `artefacts/canonical_runs/implicit_stocking_v1/structure_fuel_daily.csv`
- `artefacts/canonical_runs/reference_presence_removed_v1/structure_fuel_daily.csv`
- `artefacts/canonical_runs/implicit_stocking_v1/run_manifest.json`
- `artefacts/canonical_runs/reference_presence_removed_v1/run_manifest.json`

## Sanity notes
- `implicit_stocking_v1/pressure_daily.csv`
  - rows: `5`
  - numeric non-finite count: `0`
  - `PopulationMode = implicit_pressure` for all rows
  - `EffectiveVisitsPerDay = 0.24` across the run, matching `60 * 0.01 * 0.4`
  - pressure totals are finite and non-negative
- `reference_presence_removed_v1/pressure_daily.csv`
  - rows: `7`
  - numeric non-finite count: `0`
  - `EffectiveVisitsPerDay = 0` for all rows
  - `TotalPressureDMI = 0`, `TotalPressureDistMoved = 0`, and `TotalPressureVisitMinutes = 0` for all rows
- `structure_fuel_daily.csv` for both inspected implicit-pressure scenarios
  - numeric non-finite count: `0`
  - key biomass/fuel metrics remain non-negative

## Interpretation
- The redesigned implicit mode now behaves as intended: it records vegetation pressure directly instead of emitting faux individual physiology.
- The zero-visitation removal counterfactual is now especially clear: pressure tables are all-zero while plant structure/fuel trajectories still evolve.
- Explicit single/cohort workflows remained green under the full test/check stack, so the break is concentrated in the intended contract/semantic layer rather than the explicit physiology engine.
