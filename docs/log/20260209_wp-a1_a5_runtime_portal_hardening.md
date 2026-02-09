# WP-A1 to WP-A5 — Runtime and Portal Hardening Log

Date: 2026-02-09  
Scope: `WP-A1` through `WP-A5` from `docs/roadmap_v2.md` Line 3.2.x

## Work package completion summary

- `WP-A1` completed: minute-level kernel diagnostics are now opt-in (`capture_diagnostics = TRUE`).
- `WP-A2` completed: sensitivity outputs now include baseline-centered deltas and parameter-isolated effect plots.
- `WP-A3` completed: added balanced/stress demo templates and profile-based ecological acceptance summaries.
- `WP-A4` completed: removed runtime side effect that could mutate global `%>%` state.
- `WP-A5` completed (local verification): full local quality gates green; CI health status assessed and documented.

## Commands run

### Targeted implementation tests

- `R -q -e "testthat::test_file('tests/testthat/test_runtime_kernel_hardening_v1.R'); testthat::test_file('tests/testthat/test_hourly_summary.R'); testthat::test_file('tests/testthat/test_run_herbivore_days.R')"`
- `R -q -e "testthat::test_file('tests/testthat/test_portal_plan_v1.R')"`
- `R -q -e "testthat::test_file('tests/testthat/test_portal_runner_v1.R')"`

### Portal execution and artefact generation

- `Rscript portal/run_plan.R portal/plans/templates/balanced_demo_template.yaml`
- `Rscript portal/run_plan.R portal/plans/templates/stress_demo_template.yaml`
- `Rscript portal/run_sensitivity.R portal/plans/templates/sensitivity_template.yaml`

### Kernel capture benchmark (A1)

- `R -q -e '<benchmark script>'` (240-minute and 1440-minute minute-loop micro-benchmarks)
- Wrote:
  - `artefacts/performance/kernel_diagnostics_capture_benchmark_v1.csv`
  - `artefacts/performance/kernel_diagnostics_capture_benchmark_summary_v1.csv`
  - `artefacts/performance/kernel_diagnostics_capture_benchmark_v1_1440.csv`
  - `artefacts/performance/kernel_diagnostics_capture_benchmark_summary_v1_1440.csv`

### Full quality gates

- `make lint`
- `make test`
- `make smoke-fast`
- `R -q -e "targets::tar_unblock_process(store = '_targets')"` (stale lock cleanup after concurrent smoke invocation)
- `make smoke-deep`
- `make check`

## Artefact Review Cycle (domain and interpretation)

### Built artefacts inspected

- Balanced demo bundle:
  - `artefacts/portal_runs/balanced_demo_canonical/`
- Stress demo bundle:
  - `artefacts/portal_runs/stress_demo_canonical/`
- Sensitivity bundle:
  - `artefacts/portal_runs/sensitivity_demo_canonical/`

Reviewed tables and reports:

- `tables/ecological_acceptance_summary.csv`
- `tables/sensitivity_ecological_acceptance_summary.csv`
- `tables/sensitivity_endpoint_summary.csv`
- `tables/sensitivity_design.csv`
- `reports/ecologist_report_v1.html`
- `reports/report_render_notes.md`

Reviewed figures:

- `figures/sensitivity_endpoint_comparison.png`
- `figures/sensitivity_effects.png`
- `figures/sensitivity_effects_runtime_days.png`
- `figures/sensitivity_effects_runtime_forage_access_scale.png`
- single-run time/spatial snapshots for balanced and stress templates

### Sanity checks

- No NaN/Inf violations in portal sanity outputs (`herbivore_non_finite_count = 0`, `structure_non_finite_count = 0`).
- No negative biomass violations (`negative_biomass_violations = 0`).
- No gut-capacity violations (`gut_capacity_violations = 0`).

### Interpretation highlights

- Balanced demo (`balanced_demo_template.yaml`) now reports profile-specific acceptance checks and passes all configured checks:
  - final body condition threshold met,
  - bounded energy deficit threshold met,
  - all critical numerical sanity checks passed.
- Stress demo (`stress_demo_template.yaml`) reports expected high-stress profile and passes all configured stress checks.
- Sensitivity endpoint table now includes:
  - `parameter_path`, `parameter_value`,
  - `delta_final_total_shoot_biomass_kg`, `delta_mean_daily_dmi`,
  enabling direct baseline-relative interpretation.
- Sensitivity effect visuals are now parameter-isolated, preventing mixed-parameter x-axis artefacts.

## Performance notes (A1 benchmark)

From `kernel_diagnostics_capture_benchmark_summary_v1_1440.csv`:

- diagnostics off (`capture_diagnostics = FALSE`): median `1.4070 s`
- diagnostics on (`capture_diagnostics = TRUE`): median `1.4255 s`

Interpretation:

- Opt-in capture avoids persistent minute-record allocation in production paths and yields a small but consistent runtime reduction in the long minute-loop benchmark.
- Ecological outputs remain identical for fixed seeds (regression-tested).

## CI health notes (A5)

- Latest PR CI run in repository history before this WP set remained green (`CI PR`, run `21792668384`).
- Most recent scheduled nightly before this hardening cycle showed a historical failure (`Nightly Deep Checks`, run `21792606443`, older commit).
- This WP execution validated local equivalents of nightly gates (`test`, `smoke-deep`, `check`) as green on current workspace state.

