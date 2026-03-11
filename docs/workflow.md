# Workflow — How we build and verify herbivoreTTR

This workflow is designed to keep the project scientifically trustworthy and engineering-clean.

## The iteration loop
1. **Choose a milestone task** from the active roadmap (`docs/roadmap.md`, `docs/roadmap_v2.md`, or `docs/roadmap_v3.md`).
2. **Make a small implementation change** (aim for a single concept per commit).
3. **Run quality gates** relevant to the change:
   - tests, lint, targets smoke, and package check as appropriate
4. **Perform the Artefact Review Cycle** (below) for any model/pipeline/output change.
5. **Document**:
   - update `docs/decisions.md` if assumptions changed
   - add a short entry under `docs/log/` describing results and outputs inspected
6. Repeat until milestone acceptance criteria are met.

## Artefact Review Cycle (scientific-style result checking)
For changes that affect model logic, outputs, or orchestration:

### 1) Build artefacts
Produce at least:
- A built package artefact (source tarball)
- A targets smoke run (CI profile)
- A small simulation output set (e.g., day-1 snapshot CSVs and/or hourly log)

### 2) Sanity (domain-level checks)
Inspect outputs and confirm:
- All numeric state is finite (no NaNs/Infs)
- Biomass pools and gut contents are non-negative
- Gut capacity constraints are respected
- Energy/water balances behave plausibly (no explosive drift in a tiny demo run)

Runtime note:
- Daily runners now fail fast with `herbivoreTTR_domain_sanity_violation` errors that include day/minute/phase and offending component. Treat these as first-class model faults.

### 3) Interpretation
Write down:
- What changed and why
- What artefacts were produced (paths)
- What you inspected (tables/plots/summaries)
- Whether outputs changed vs previous fixtures, and why that’s acceptable

Record this in `docs/log/YYYYMMDD_<topic>.md`.

### 4) Iteration
If any sanity check fails, fix and rerun the same artefact set until coherent.

## Default commands (local)
The repo provides a Makefile; use it where available:
- `make setup` — restore dependencies and set up hooks
- `make test` — run unit/integration tests
- `make lint` — run lintr
- `make smoke` — run a minimal targets pipeline under CI profile
- `make test-battery` — run the full battery (pipeline + tests + optional coverage)
- `make render-v2` — render the post-1.0 paper pipeline report
- `make repro-check-v2` — run v2 clean-library reproducibility run-through
- `make release-bundle-v2` — build the v1.1 RC bundle with v2 artefacts
- `R -q -e "for (f in list.files('R', pattern = '\\\\.R$$', full.names = TRUE)) sys.source(f, envir = globalenv()); run_post_v1_scaling_profile(scenario_slug = 'post_v1_scaling_v2')"` — refresh scaling + kernel + break-even benchmark artefacts
- `Rscript portal/run_plan.R portal/plans/templates/single_scenario_template.yaml` — non-coder single-run portal workflow
- `Rscript portal/run_sensitivity.R portal/plans/templates/sensitivity_template.yaml` — non-coder sensitivity workflow
- `Rscript portal/run_plan.R portal/plans/templates/laptop_safe_template.yaml` — conservative laptop profile
- `Rscript portal/run_plan.R portal/plans/templates/workstation_balanced_template.yaml` — balanced workstation profile
- `Rscript portal/run_plan.R portal/plans/templates/throughput_max_template.yaml` — high-throughput profile
- `Rscript portal/launch_gui_stub.R` — optional GUI stub over the same YAML+runner backend
- `R -q -e "for (f in list.files('R', pattern = '\\\\.R$$', full.names = TRUE)) sys.source(f, envir = globalenv()); run_compiled_candidate_selection_v1()"` — generate compiled-candidate ranking + parity artefacts (roadmap v3.4)
- `R -q -e "for (f in list.files('R', pattern = '\\\\.R$$', full.names = TRUE)) sys.source(f, envir = globalenv()); run_compiled_throughput_appendix_v1(scenario_slug = 'compiled_throughput_appendix_v1')"` — compiled on/off throughput + break-even appendix bundle (roadmap v3.5)
- `R -q -e "for (f in list.files('R', pattern = '\\\\.R$$', full.names = TRUE)) sys.source(f, envir = globalenv()); out <- run_performance_guard_v1(enforce_guard = FALSE); utils::write.csv(out$report, file = 'artefacts/benchmarks/performance_guard_v1/performance_guard_report_v1.csv', row.names = FALSE)"` — lightweight regression guard evidence

## Failure handling
- If tests fail: minimize the diff, reproduce deterministically, fix root cause, and add a regression test.
- If outputs change: treat it as a scientific event—explain the change, update fixtures only with justification.
- If CI is flaky: reduce nondeterminism (seeds, parallelism), tighten tolerances, and document.
- If parallel break-even shifts unexpectedly: inspect `artefacts/benchmarks/post_v1_scaling_v2/parallel_overhead_benchmark_v1.csv` and `artefacts/benchmarks/post_v1_scaling_v2/parallel_break_even_summary_v1.csv` before changing defaults.
- If CI perf sentinel fails: inspect `tests/testthat/test_performance_sentinel_v3.R` and recent kernel/guardrail profile artefacts before relaxing thresholds.
- If compiled appendix break-even shifts: inspect `artefacts/benchmarks/compiled_throughput_appendix_v1/compiled_throughput_matrix_v1.csv` and `compiled_break_even_summary_v1.csv` before tuning compiled defaults.

## Parallel execution defaults (v2.6)
- Across-run orchestration uses `execution_mode`:
  - `auto`: serial on CI, multicore on local hosts (subject to available cores).
  - `serial`: force one worker.
  - `multicore`: use process-level workers up to task/core limits.
- Hardware-tier defaults:
  - `laptop` (<=8 cores): reserve 1 core, cap 6 workers.
  - `workstation` (9-32 cores): reserve 2 cores, cap 24 workers.
  - `server` (>32 cores): reserve 4 cores, cap 48 workers.
- Use `workers` and `reserve_cores` arguments on ensemble/stability/scaling helpers for explicit control.
- Keep break-even gate non-blocking by default unless running on a controlled baseline machine.
- Optional compiled resistance kernel remains opt-in only via `HERBIVORETTR_USE_COMPILED_TTR=1` (or option `herbivoreTTR.use_compiled_ttr=TRUE`).
- Optional compiled minute-loop kernel is additionally available via `HERBIVORETTR_USE_COMPILED_MINUTE_LOOP=1` (or option `herbivoreTTR.use_compiled_minute_loop=TRUE`), typically through portal `execution.compiled.kernel_policy: all_available`.

## Documentation discipline
- Public API changes require:
  - updated roxygen docs
  - updated README/vignette if user-facing
  - changelog entry (for releases)
- Any scientific assumption must be written in `docs/decisions.md`.

## Release readiness commands
- `make rc-gates` — full local release gate set (tests + lint + smoke + check)
- `make release-bundle` — assemble release-candidate bundle under `artefacts/release_candidates/`
- `make repro-check` — run clean-library reproducibility run-through and write evidence logs
- `make release-bundle-v2` — assemble the post-1.0 hardening RC bundle
- `make repro-check-v2` — clean-library v2 reproducibility run-through

## CI tiers (v2)
- `PR CI` (`.github/workflows/ci.yml`): blocking gates for `check` + `test` + `lint` + `smoke`.
- Conditional PR guardrails include a targeted `Performance guard` job for runtime hotspot files.
- `Nightly Deep` (`.github/workflows/nightly.yml`): scheduled deep ecological suites and report render.
- `Weekly Repro` (`.github/workflows/weekly_repro.yml`): clean-library reproducibility replay and artefact audit.
- Failure handling policy:
  - `PR CI` failures are blocking and require immediate fix.
  - `Nightly Deep` / `Weekly Repro` failures must be logged in `docs/log/` with triage notes and a follow-up action owner.

Reference docs:
- `docs/governance/api_surface_v2.md`
- `docs/governance/deprecation_policy.md`
- `docs/governance/reproducibility_runbook_v1.md`
