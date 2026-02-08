# Agent Notes

## 2025-10-20 – Codex session
- Reworked `_targets.R` to rely on `targets::tar_source("R")` and fixed project seed handling.
- Updated `R/packages.R::lib()` to ensure namespaces are loaded without attaching packages.
- Replaced `library()` calls in docs and helper scripts with explicit `herbivoreTTR::` references.
- Synced `renv` using in-repo caches (`.cache/`) and disabled `{pak}` during restore to work within the sandbox permissions.
- Added `.cache/` to `.gitignore` and verified `renv::snapshot(prompt = FALSE)` plus `renv::clean(confirm = FALSE)` complete without errors.
- Ran `testthat::test_dir()` (fails: missing `tarchetypes` detection, transport tolerance) and `targets::tar_make(names = "conditions")` to smoke-test the toolchain.
- Added `scripts/run-r` and `scripts/run-rscript` wrappers so CLI calls automatically pick up the project-local cache env vars.
- Captured `renv` workflow lessons learned in `docs/development/AGENT_WORKING_WITH_R_RENV.md` for future agents.
- Switched root `Makefile` recipes to call the wrapper scripts, keeping cache redirects consistent during automation.
- Disabled the renv sandbox in wrapper scripts to expose base packages (e.g., `parallel`), added a sanity check for it, and documented the fix in `docs/development/AGENT_WORKING_WITH_R_RENV.md`.
- Clarified in `docs/development/AGENT_WORKING_WITH_R_RENV.md` that cache directories are repo-scoped via the wrapper scripts.
- Installed `lintr`, corrected the legacy `.lintr` config syntax, and updated `make lint` with a fail-on-lint helper that prints results.
- Added `XDG_CACHE_HOME` routing in wrapper scripts and docs so Quarto/Deno caches stay within the repo.
- Updated wrapper scripts to prefer shared caches under `$HOME/.cache` when writable, falling back to repo-local caches only if necessary; docs updated accordingly.
- Retired the wrapper scripts (restored direct `R` invocations), rewrote the renv how-to for full-access defaults, and reverted Makefile targets accordingly; `.Renviron` now disables the renv sandbox so base packages remain visible during tests.
- `tests/testthat/test_sanity.R` now once again checks `requireNamespace()` quietly for `targets`, `parallel`, and `tarchetypes`.

## 2025-10-20 – Codex housekeeping pass
- Added `docs/archive/CHANGELOG.md` (Keep a Changelog scaffold) and `docs/development/PIPELINE.md` summarising the current DAG after auditing repo hygiene.
- Synced `.gitignore`/`.Rbuildignore` with data outputs, docs artefacts, and support directories expected by the workflow.
- Replaced `stop()` calls in CSV writers and `init_conditions()` with typed `rlang::abort()` messages; renamed internal nitrogen state to `soil_n`.
- Moved pipeline file writes into `write_plants_snapshot_target()` / `write_herbivore_snapshot_target()` helpers and updated `_targets.R` to call them.
- Ran `targets::tar_make()` and the full `testthat` suite; pipeline succeeds, while two pre-existing tests fail (spin-up distance moved, tauN tolerance).
- Attempted to adopt `import::from()` but reverted to direct `rlang::abort()` after it introduced runtime errors during tests.

## 2025-10-21 – Codex test planning
- Drafted `docs/development/test_battery.md` outlining comprehensive coverage goals, module-specific test plans, and logging requirements.
- Specified structured `data/outputs/test_log_<timestamp>.csv` schema and integration touchpoints for unit/integration/perf suites.
- Implemented test logging reporter and extended testthat suite across initialisation, behaviour, energy/water balance, utilities, parity, and pipeline manifest coverage.
- Added `inst/extdata/parity/` snapshots, full test battery script, and Makefile target; configured optional performance (`RUN_PERF_TESTS`) and coverage (`RUN_COVERAGE`) switches.
- Installed `covr`/`pryr` via renv for coverage and memory profiling tests; snapshot updated lockfile.

## 2025-10-21 – Codex multi-day demo
- Updated `init_plants()` to publish `xcor` / `ycor` columns so grazing logic can detect candidates post spin-up.
- Added `run_herbivore_days()` helper plus `tests/testthat/test_run_herbivore_days.R` to exercise a three-day window and assert biomass intake.
- Created `scripts/run_single_herbivore_demo.R` to run the wrapper, emit timestamped daily/endpoint CSVs, and append a structured log entry.
- Extended `_targets.R` with `sim_day3_demo` and refreshed `docs/development/PIPELINE.md` / `docs/archive/CHANGELOG.md` to document the workflow.

## 2025-10-22 – Codex hourly logging
- Captured additional per-minute herbivore state (distance moved, intake, water fluxes) to allow hourly aggregation.
- Implemented `summarise_hourly_herbivore_record()` / `write_hourly_herbivore_log()` utilities with regression coverage in `tests/testthat/test_hourly_summary.R`.
- Added `scripts/run_single_day_hourly_log.R` and generated a sample log at `data/outputs/herbivore_hourly_day1826_<timestamp>.csv`.

## 2025-11-11 – Codex forensic logging
- Added diagnostics capture to `run_daily_herbivore_simulation()` so start/end plant and herbivore states are available for auditing workflows.
- Introduced `summarise_plant_day_states()` and `build_daily_record_table()` helpers for plant delta summaries and tidy minute-level logs.
- Created `scripts/run_single_day_forensics.R`, which writes per-minute herbivore traces, eaten vs. uneaten plant snapshots, herbivore start/end states, summary metrics, and a diagnostic PNG plot to `data/outputs/day/<timestamp>/`.
