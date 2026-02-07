# Roadmap v2 execution log (WP-2.1.x to WP-2.5.x)

Date: 2026-02-07
Scope: complete all work packages in `docs/roadmap_v2.md` in strict order.

## Commands run (quality/evidence gates)

- `NOT_CRAN=true make test`
- `make lint`
- `TARGETS_PROFILE=ci make smoke`
- `make check`
- `make repro-check-v2`
- `make release-bundle-v2`
- `R -q -e "renv::status()"`

## Gate outcome summary

- Tests: pass (`796` pass, `2` skip for optional perf/coverage toggles).
- Lint: pass (no lints).
- Targets smoke (`TARGETS_PROFILE=ci`): pass.
- `R CMD check --as-cran`: pass with known non-blocking environment notes:
  - `qpdf` not installed on host.
  - standard non-submission top-level notes.
- External reproducibility v2: pass.
  - `artefacts/reproducibility/external_run_v2/repro_check_summary.csv`
- `renv` status: synchronized.
- v1.1 RC bundle: pass.
  - `artefacts/release_candidates/v1.1.0-rc1/release_checklist_status.csv`

## Artefact review cycle summary

Built artefacts:

- Source tarball: `artefacts/release_candidates/v1.1.0-rc1/package/herbivoreTTR_1.1.0.tar.gz`
- Canonical v2 experiments:
  - `artefacts/canonical_runs/experiment_a_presence_removal_v2/`
  - `artefacts/canonical_runs/experiment_c_aridity_gradient_v2/`
- Validation and stress suites:
  - `artefacts/validation/pilot_benchmark_v1/`
  - `artefacts/stability/long_horizon_v1/`
  - `artefacts/benchmarks/post_v1_scaling_v1/`
- Report artefacts:
  - `artefacts/reports_v2/paper_pipeline_v2.html`
  - `artefacts/reports_v2/figure_table_manifest_v2.csv`

Domain sanity review:

- No NaN/Inf in required state summaries under stability suite.
- No negative biomass violations in stability summary.
- Gut-capacity violations remained zero.
- Long-horizon stress flags were present and reported as ecological stress signal (not hidden).

Interpretation highlights:

- Experiment A v2 directional outcomes are now consistently supported across the default 30-seed ensemble in current baseline.
- Experiment C v2 still reports an unsupported monotonic-intake claim and one partially supported intake-delta claim; these are explicitly retained in claims output as limitations.
- Pilot validation metrics show substantial absolute error for some metrics; contract wiring is correct, but scientific fit remains an open modelling task.

---

## WP completion notes

### WP-2.1.1 - Paired-contrast protocol v2

- Implemented paired-contrast metadata and parity enforcement in scenario compilation.
- Added explicit mismatch failure for seed/climate/runtime parity rules.
- Evidence:
  - `R/scenario_contract_v1.R`
  - `config/scenarios/reference_presence_present_v1.yaml`
  - `config/scenarios/reference_presence_removed_v1.yaml`
  - `tests/testthat/test_scenario_contract_v1.R`

### WP-2.1.2 - Ensemble execution layer v1

- Added deterministic seed-normalized ensemble runner and summary outputs.
- Evidence:
  - `R/ensemble_runner_v1.R`
  - `tests/testthat/test_post_v1_hardening_v2.R`

### WP-2.1.3 - Experiment A v2 rerun

- Added Experiment A v2 ensemble pipeline and report outputs.
- Evidence:
  - `R/reference_experiments_v2.R`
  - `artefacts/canonical_runs/experiment_a_presence_removal_v2/experiment_a_summary_v2.csv`
  - `artefacts/canonical_runs/experiment_a_presence_removal_v2/experiment_a_delta_ensemble_v2.csv`
  - `artefacts/canonical_runs/experiment_a_presence_removal_v2/experiment_a_report_v2.md`

### WP-2.1.4 - Claim-to-evidence registry and report gating

- Added claim registry ingestion, evaluation, and required-claim gate.
- Evidence:
  - `R/claims_v1.R`
  - `config/claims/claim_registry_v1.csv`
  - `artefacts/canonical_runs/experiment_a_presence_removal_v2/experiment_a_claims_v2.csv`

### WP-2.2.1 - Herbivore energetic/water diagnostics contract v2

- Extended daily outputs with maintenance/requirement/ratio/streak diagnostics.
- Evidence:
  - `R/calc_daily_energy_balance.R`
  - `R/check_daily_water_balance.R`
  - `R/scenario_runner_v1.R`
  - `tests/testthat/test_post_v1_hardening_v2.R`

### WP-2.2.2 - Body-condition feedback v1

- Added body-condition feedback controls and physiological stress flag propagation.
- Evidence:
  - `R/herbivore_diagnostics_v2.R`
  - `R/init_herbivore.R`
  - `R/run_daily_herbivore_simulation.R`
  - `tests/testthat/test_post_v1_hardening_v2.R`

### WP-2.2.3 - Aridity stressor matrix expansion

- Implemented 3x3 aridity-access stress matrix with forage access scaling.
- Evidence:
  - `R/reference_experiments_v2.R` (`build_aridity_access_matrix_v2`)
  - `artefacts/canonical_runs/experiment_c_aridity_gradient_v2/experiment_c_matrix_v2.csv`

### WP-2.2.4 - Experiment C v2 rerun and interpretation rules

- Added Experiment C v2 orchestration, expected-direction summary, claims, and report.
- Evidence:
  - `artefacts/canonical_runs/experiment_c_aridity_gradient_v2/experiment_c_summary_v2.csv`
  - `artefacts/canonical_runs/experiment_c_aridity_gradient_v2/experiment_c_claims_v2.csv`
  - `artefacts/canonical_runs/experiment_c_aridity_gradient_v2/experiment_c_report_v2.md`

### WP-2.3.1 - Units and metric metadata layer

- Added metric-units registry and CSV sidecar writers.
- Evidence:
  - `R/metric_units_v1.R`
  - `config/units/metric_units_v1.csv`
  - v2 units sidecars in experiment outputs.

### WP-2.3.2 - Observational dataset contract and adapters

- Added contract validators and adapter functions for observed-series schema.
- Evidence:
  - `R/observational_contract_v1.R`
  - `docs/observational_data_contract_v1.md`
  - `inst/extdata/validation/vegetation_timeseries_example.csv`
  - `inst/extdata/validation/herbivore_timeseries_example.csv`

### WP-2.3.3 - Validation metrics battery and pilot benchmark

- Added metric computations and pilot benchmark run/report.
- Evidence:
  - `R/validation_metrics_v1.R`
  - `artefacts/validation/pilot_benchmark_v1/pilot_metrics_summary_v1.csv`
  - `artefacts/validation/pilot_benchmark_v1/pilot_validation_report_v1.md`

### WP-2.4.1 - Long-horizon stability suite

- Added long-horizon scenario set, replicate summary, and report outputs.
- Implemented deterministic scenario-level RNG seeding in `run_scenario_v1` to remove order-dependent instability.
- Evidence:
  - `R/stability_suite_v1.R`
  - `R/scenario_runner_v1.R`
  - `artefacts/stability/long_horizon_v1/stability_summary_v1.csv`
  - `tests/testthat/test_stability_scaling_v2.R`

### WP-2.4.2 - Throughput and scaling profile

- Added scaling workloads, throughput summary, and regression check logic.
- Evidence:
  - `R/scaling_profile_v1.R`
  - `artefacts/benchmarks/post_v1_scaling_v1/scaling_summary_v1.csv`
  - `artefacts/benchmarks/post_v1_scaling_v1/scaling_regression_check_v1.csv`

### WP-2.4.3 - Tiered CI implementation

- Implemented PR/nightly/weekly workflow split.
- Evidence:
  - `.github/workflows/ci.yml`
  - `.github/workflows/nightly.yml`
  - `.github/workflows/weekly_repro.yml`
  - `docs/workflow.md` (tier mapping + failure handling policy)

### WP-2.5.1 - Report pipeline v2

- Added v2 paper report render path and target integration.
- Evidence:
  - `reports/paper_pipeline_v2.qmd`
  - `R/paper_pipeline.R`
  - `artefacts/reports_v2/paper_pipeline_v2.html`

### WP-2.5.2 - Deterministic figures/tables manifest

- Added v2 figure/table manifest generation and determinism checker.
- Evidence:
  - `R/report_manifest_v2.R`
  - `artefacts/reports_v2/figure_table_manifest_v2.csv`
  - `tests/testthat/test_report_pipeline_v2.R`

### WP-2.5.3 - External reproducibility run-through v2

- Added clean-library reproducibility script and checklist outputs.
- Evidence:
  - `scripts/run_external_repro_check_v2.R`
  - `artefacts/reproducibility/external_run_v2/repro_check_summary.csv`
  - `artefacts/reproducibility/external_run_v2/repro_check_report.md`

### WP-2.5.4 - v1.1 RC bundle and next-queue promotion

- Added v2 release pipeline and generated RC bundle.
- Updated version/changelog to `1.1.0`.
- Evidence:
  - `R/release_pipeline_v2.R`
  - `scripts/build_release_bundle_v2.R`
  - `artefacts/release_candidates/v1.1.0-rc1/`
  - `artefacts/release_candidates/v1.1.0-rc1/release_manifest.json`

## Known limitations carried forward

- `qpdf` remains unavailable on host, so `R CMD check` warns during PDF size reduction check.
- Experiment C and pilot validation outputs include explicitly unsupported/weak claims, retained for transparent interpretation rather than hidden or force-fit.
