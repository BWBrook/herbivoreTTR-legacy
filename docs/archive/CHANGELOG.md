# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
whenever release tags are published.

## [Unreleased]
### Added
- `docs/development/PIPELINE.md` describing the minimal {targets} DAG and execution profile.
- Pipeline helper functions that write parity CSVs with directory management for targets.
- `docs/development/test_battery.md` detailing the planned comprehensive test suite and logging spec.
- Structured test logger (`tests/testthat/helper-test_log.R`) and full test battery harness (`scripts/run_test_battery.R`).
- Extensive testthat coverage for initialisation, energy/water balance, behaviour, utilities, parity, and pipeline manifest checks.
- `run_herbivore_days()` helper, automated CLI demo (`scripts/run_single_herbivore_demo.R`), and `_targets.R::sim_day3_demo` for multi-day smoke tests.
- Integration test `tests/testthat/test_run_herbivore_days.R` validating the three-day demo summary output.
- Hourly summarisation utilities (`summarise_hourly_herbivore_record()`, `write_hourly_herbivore_log()`) plus CLI entry point `scripts/run_single_day_hourly_log.R` and regression coverage via `tests/testthat/test_hourly_summary.R`.
- Single-day forensic logger (`scripts/run_single_day_forensics.R`) capturing per-minute herbivore activity, plant start/end snapshots, summary stats, and a diagnostic map.
- Optional diagnostics capture in `run_daily_herbivore_simulation()` and supporting helpers (`summarise_plant_day_states()`, `build_daily_record_table()`) for detailed auditing workflows.

### Changed
- `init_conditions()` and the CSV writers now emit typed `rlang::abort()` errors and use clearer nitrogen naming.
- `_targets.R` delegates file creation to the new helpers to keep the pipeline declarative.
- `.gitignore` and `.Rbuildignore` include data output, docs, and tooling directories required by the workflow.
- `init_plants()` now exposes `xcor`/`ycor` columns so herbivore foraging helpers can locate plants without extra mapping.
- Minute-level daily records now capture additional state (distance moved, intake, water) to support hourly logging.

### Fixed
- Strengthened CSV writer validations so header mismatches surface with structured errors.
