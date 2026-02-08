# Test Battery Plan

## Objectives
- Achieve deterministic, high-coverage validation for every exported and internal helper under `R/`.
- Provide fast unit/property tests plus slower integration and pipeline checks, with explicit logging of each run.
- Ensure regressions surface with actionable context via a structured `data/outputs/test_log_*.csv`.

## Test Logging Specification
- **Location**: `data/outputs/test_log_<timestamp>.csv` (timestamp `YYYYMMDD-HHMMSS`).
- **Schema**: `timestamp, suite, test_name, context, status, duration_ms, notes, artifacts`.
- **Lifecycle**:
  - `tests/testthat/helper-test_log.R` initialises the logger, registering a `testthat::Reporter` to append rows.
  - Each `test_that()` call writes a pass/fail entry; failures capture the error message and pointer to snapshots.
  - Integration scripts (`targets`, Quarto, profiling) append summary rows with aggregated stats.
- **Artefacts**: longer-running tests emit supporting CSV/JSON files under `data/outputs/test_artifacts/<suite>/…` and link via the `artifacts` column.

## Module Coverage

### 1. Core Configuration (`constants.R`, `options.R`, `globals.R`)
- **CONSTANTS integrity**: snapshot tests verifying derivable values, units, monotonic relationships, and absence of `NULL`. Error when keys missing.
- **Option helpers**: tests for `init_project_options()` ensuring options are set/restored using `withr::local_options()`.
- **Global variables**: validate `utils::globalVariables()` covers each NSE symbol referenced in dplyr mutate/select calls.

### 2. Initialisation (`init_conditions.R`, `init_plants.R`, `init_herbivore.R`, `init_simulation.R`, `calc_foraging_traits.R`)
- **`init_conditions()`**: parameterised tests for each mode; check periodicity, bounds, deterministic output with fixed seed; error path for invalid mode (already `rlang::abort()`).
- **`init_plants()`**: table-driven tests for vegetation type permutations, ensuring structural masses > 0, ID uniqueness, optional seeding.
- **`init_herbivore()`**: verify field defaults, unit consistency, and error on negative mass.
- **`init_simulation()`**: integration test combining conditions/plants/herbivore ensuring output fields align with expectations and optional spin-up parameters behave.
- **Trait calculators**: targeted tests for `calc_foraging_traits()` or similar helpers verifying derived rates fall within ecological bounds.

### 3. TTR Math Primitives
- **Resistance functions (`calc_Rs*`, `calc_Rr*`, `calc_Rd*`)**: property tests covering vectorisation, zero/negative mass handling, and bounded outputs.
- **Transport (`calc_tau*`)**: ensure symmetry, zero-mass returns zero, monotonic responses to resistance changes; tolerances for floating-point comparisons.
- **Uptake & Growth (`calc_U*`, `calc_G*`)**: tests with known input-output pairs, guard rails for invalid parameters, sign assertions.
- **Differential updates (`calc_d*C/N_dt`)**: confirm mass balance (sum of deltas equals source minus sink) and response to toggling defence channels.
- **Phenology/trap helpers**: check piecewise response curves, behaviour at breakpoints, guards against division by zero.
- **Tolerance audits**: curated set of deterministic fixtures compared to C++ outputs (existing parity data) with relative-error thresholds recorded in logs.

### 4. Herbivore Behaviour & Movement
- **`get_plants_within_range()`, `pick_a_plant()`**: geometry checks (toroidal distance), tie-breaking randomness with seeded determinism, empty candidate handling.
- **`make_foraging_decision()`**: scenario matrix covering energy vs. defence trade-offs, ensuring decisions align with tastiness scores; error on missing plant attributes.
- **`herbivore_move()` / `herbivore_step()`**: track position updates, wrap-around correctness, and cumulative distance; ensure pathfinding respects `CONSTANTS$MAX_DAILY_DISTANCE`.
- **`herbivore_eat()` / `update_gut_content()` / `hourly_digestion_step()`**: conservation of biomass, gut capacity constraints, water/energy balance updates, regression tests for boundary conditions (empty gut, full gut, dehydration).

### 5. Simulation Orchestrators
- **`run_daily_herbivore_simulation()`**: multi-minute table-driven runs verifying minute-level state transitions, logging key summaries to test_log; error handling when plants exhausted.
- **`ttr_daily()`**: structural mass updates vs. expected C++ parity values, enabling/disabling defence branch;, verifying that negative masses are prevented and conservation holds.
- **`ttr_daily` + herbivore loops**: run 7-day simulation with deterministic inputs, comparing states to stored reference snapshots with tolerance bands.
- **`calc_daily_energy_balance()` / water balance**: confirm cost equations respond to mass/distance parameters and maintain reproducibility.

### 6. IO & Reporting
- **CSV writers (`write_plants_daily()`, `write_herbivores_daily()`)**: confirm directory creation via helper wrappers, header order, NA/Inf rejection, and idempotent rewrites.
- **Snapshot helpers**: tests verifying error path when directory creation fails (use temp dir with read-only), and correct return value for pipeline targets.
- **Parity CSV diff**: golden-master tests comparing `data/outputs` files from controlled runs to stored expected outputs (subset of columns for stability).

### 7. Utility Helpers (`utils.R`, `herbivore_utils.R`, `trap*.R`, `calc_plant_tastiness.R`, `make_foraging_decision.R`)
- **Math utilities**: boundary tests for random sampling helpers, toroidal distance, Monod/trap functions; ensure determinism with set seed.
- **Taste/defence scoring**: property tests verifying monotone response to defence biomass and water stress.
- **Import/export helpers**: confirm `packages.R::ensure_packages_installed()` short-circuits when pkgs installed; use mock to avoid actual downloads.

### 8. Targets Pipeline & Profiles
- **`_targets.R`**: pipeline smoke tests per profile (`default`, `ci`) ensuring file targets flagged as `"file"` exist and metadata records log their hashes.
- **DAG integrity**: validate no cycles and each target has documented description; check `tar_manifest()` vs. docs alignment.
- **Test log integration**: `tar_make()` wrapper writes summary entry with counts of skipped/completed targets to log file.

### 9. Documentation & Vignettes
- **Quarto / vignette rendering**: optional CI test running `quarto::quarto_render()` and `devtools::build_vignettes()` writing status to log; skip on CRAN.
- **README examples**: `devtools::run_examples()` gating to ensure sample code doesn’t regress.

### 10. Performance & Regression Monitoring
- **Benchmarks**: microbench for key hotspots (`calc_tau*`, `make_foraging_decision`) with thresholds recorded; log warns if exceeding baseline by >20%.
- **Memory usage**: integration test capturing peak memory for 7-day run using `pryr::mem_change()`; log to track regressions.

## Execution Strategy
- **Test Phases**:
  1. **Unit** (fast, deterministic) – default `testthat` run, writes per-test log rows.
  2. **Integration** – scripted via `scripts/run_integration_tests.R`, calling multi-day simulations, pipeline runs, Quarto render.
  3. **Parity** – compares outputs against C++ reference snapshots, stored under `inst/extdata/parity/`.
  4. **Performance** – optional, gated behind env var `RUN_PERF_TESTS=1`.
- **Automation**: extend `Makefile` with `test-all`, `test-integration`, `test-parity`, each ensuring `data/outputs/test_log_*.csv` appended.
- **CI**: GitHub Actions matrix executing phases with log artefacts uploaded for inspection.

### Current Implementation Notes
- `scripts/run_test_battery.R` orchestrates pipeline execution, unit tests, and optional coverage.
- `RUN_COVERAGE=1` enables coverage checks, while `RUN_PERF_TESTS=1` turns on performance assertions.
- Test logs are emitted automatically via `tests/testthat/helper-test_log.R` to `data/outputs/test_log_<timestamp>.csv`.

## Coverage Tracking
- Use `covr::package_coverage()` to ensure each function in `R/` touched; threshold target ≥85% lines, 100% for critical math modules.
- Include coverage summary in test log, and fail CI when below threshold.

## Next Steps
- Implement `tests/testthat/helper-test_log.R` with a custom reporter.
- Draft new test files mirroring section headings (e.g., `test_init_conditions.R`, `test_herbivore_move.R`).
- Populate parity fixtures and performance baselines.
- Update developer docs (`docs/development/DEVELOPMENT.qmd`) with instructions for running the full battery and interpreting log outputs.
