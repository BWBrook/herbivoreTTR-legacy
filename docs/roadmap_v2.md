# Roadmap v2 - Post-1.0 Hardening and Ecological Validation Queue (herbivoreTTR)

This is the canonical post-1.0 roadmap for autonomous implementation.
It is derived from the evidence and risks in:

- `docs/log/20260207_independent_ecological_review.md`
- `docs/roadmap.md` (completed through `WP-1.0.4`)
- `docs/product_brief.md`
- `docs/workflow.md`

Primary goal:
Move from "mechanistically working and reproducible" to "ecologically defensible, uncertainty-aware, data-facing, and publication-hardened."

---

## 1) Opening contract (v2)

When the maintainer says **"Follow roadmap_v2"**, Codex must:

1. Select the **first unchecked** work package (WP) in the Priority Queue.
2. Complete that WP end-to-end:
   - code,
   - tests,
   - docs,
   - artefacts,
   - interpretation log.
3. Perform WP-DoD and Artefact Review Cycle checks.
4. Mark the WP checkbox as complete (`[x]`) in this file.
5. Continue to the next unchecked WP without waiting for additional prompts unless blocked.

Reordering policy:

- Reordering/inserting/removing WPs is allowed only if both are recorded:
  - rationale in `docs/decisions.md`,
  - dated rationale log in `docs/log/YYYYMMDD_<topic>.md`.

Blocker policy:

- Only stop for hard blockers that cannot be solved inside repo constraints.
- If blocked, propose a default in `docs/questions_for_human.md`, continue non-blocked WPs, and record assumptions.

---

## 2) Work Package Definition of Done (WP-DoD v2)

A WP is done only when all are true:

1. **Implementation complete**
   - All required code paths are implemented.
   - Public interfaces are documented if changed.

2. **Tests complete**
   - Unit tests for changed functions/components.
   - Integration tests for end-to-end behavior where applicable.
   - Regression tests for bugs addressed by the WP.

3. **Documentation complete**
   - User-facing docs updated for behavior/schema changes.
   - Scientific assumptions and units documented.
   - Non-trivial assumptions recorded in `docs/decisions.md`.

4. **Artefact Review Cycle complete**
   - package build artefact created,
   - targets smoke run completed,
   - at least one canonical output bundle generated and inspected,
   - domain sanity notes written in log.

5. **Evidence trail complete**
   - a dated log entry exists under `docs/log/` with:
     - WP ID,
     - commands run,
     - artefacts inspected,
     - interpretation,
     - deviations from expected outcomes.

6. **Queue maintenance complete**
   - WP checkbox marked `[x]`,
   - downstream impact noted if acceptance criteria changed.

---

## 3) Quality-gate profiles (v2 operating model)

These profiles are mandatory defaults for v2:

### `pr` profile (fast, blocking)

Must run on each PR/push:

- `R CMD check` (or equivalent),
- `testthat` suite,
- `lintr::lint_package()`,
- `TARGETS_PROFILE=ci` smoke pipeline.

Target duration objective:

- under 15 minutes on standard CI runner.

### `nightly` profile (deep, scheduled)

Must run at least once daily on default branch:

- full tests,
- long-horizon stability suite,
- ensemble experiment smoke (subset),
- report render smoke.

### `weekly_repro` profile (clean-environment reproducibility)

Must run at least weekly:

- clean `renv` restore in fresh library,
- canonical experiment rerun subset,
- reproducibility checklist write-out under `artefacts/reproducibility/`.

Failure semantics:

- `pr` failures are release-blocking.
- `nightly` and `weekly_repro` failures must open actionable issues in `docs/log/` and be triaged in next WP.

---

## 4) Priority Queue (strict order)

### Line 2.1.x - Evidence integrity and uncertainty baseline
- [x] **WP-2.1.1 - Paired-contrast protocol v2 (seed and climate parity enforcement)**
- [x] **WP-2.1.2 - Ensemble execution layer v1 (multi-seed deterministic orchestration)**
- [x] **WP-2.1.3 - Experiment A v2 rerun (paired-seed + ensemble uncertainty)**
- [x] **WP-2.1.4 - Claim-to-evidence registry and report gating**

### Line 2.2.x - Mechanistic realism and ecological interpretation hardening
- [x] **WP-2.2.1 - Herbivore energetic/water diagnostics contract v2**
- [x] **WP-2.2.2 - Body-condition feedback v1 (no demography)**
- [x] **WP-2.2.3 - Aridity stressor matrix expansion for intake-limitation testing**
- [x] **WP-2.2.4 - Experiment C v2 rerun with revised interpretation rules**

### Line 2.3.x - Data-facing validation readiness
- [x] **WP-2.3.1 - Units and metric metadata layer (outputs + reports)**
- [x] **WP-2.3.2 - Observational dataset contract and adapters v1**
- [x] **WP-2.3.3 - Validation metrics battery and pilot ecological benchmark**

### Line 2.4.x - Scale reliability and CI hardening
- [x] **WP-2.4.1 - Long-horizon stability suite (365-day stress runs)**
- [x] **WP-2.4.2 - Throughput and scaling profile on multicore targets**
- [x] **WP-2.4.3 - Tiered CI implementation (PR lean + nightly deep + weekly repro)**

### Line 2.5.x - Publication hardening and v1.1 release track
- [x] **WP-2.5.1 - Report pipeline v2 (uncertainty-aware ecological narrative)**
- [x] **WP-2.5.2 - Deterministic figures/tables manifest and checksum policy**
- [x] **WP-2.5.3 - External reproducibility run-through v2**
- [x] **WP-2.5.4 - v1.1 RC bundle and next-queue promotion**

### Line 2.6.x - Parallel throughput and kernel performance hardening
- [x] **WP-2.6.1 - Across-run deterministic parallel execution controls**
- [x] **WP-2.6.2 - Kernel hotspot profiler and evidence artefacts**
- [x] **WP-2.6.3 - Serial-vs-parallel break-even benchmark and default policy**

### Line 3.1.x - Ecologist-facing usability portal and reporting UX
- [x] **WP-3.1.1 - Portal plan YAML contract v1 (single-source-of-truth run file)**
- [x] **WP-3.1.2 - Non-coder CLI entrypoints (single run + sensitivity + report render)**
- [x] **WP-3.1.3 - Portal runner and sensitivity orchestration with deterministic indexing**
- [x] **WP-3.1.4 - Rich ecologist output bundle (time/spatial/comparison plots + CSV tables)**
- [x] **WP-3.1.5 - Quarto ecologist report template (HTML/PDF best-effort)**
- [x] **WP-3.1.6 - GUI stub (Shiny wrapper over YAML + CLI backend)**
- [x] **WP-3.1.7 - Ecologist docs and vignette workflow updates**
- [x] **WP-3.1.8 - Validation gates, artefact interpretation log, and queue closure**

---

## 5) Milestone gates (commit and progress control)

Milestones are line-level completion points:

- **Milestone M2.1:** all `WP-2.1.x` complete
- **Milestone M2.2:** all `WP-2.2.x` complete
- **Milestone M2.3:** all `WP-2.3.x` complete
- **Milestone M2.4:** all `WP-2.4.x` complete
- **Milestone M2.5:** all `WP-2.5.x` complete
- **Milestone M2.6:** all `WP-2.6.x` complete
- **Milestone M3.1:** all `WP-3.1.x` complete

At each milestone:

1. Ensure all quality gates required by completed WPs are green.
2. Ensure each WP has a corresponding dated log.
3. Create a clean commit series for milestone scope (no junk/interim commits).
4. Continue immediately into next line unless blocked.

---

## 6) Detailed WP specifications

### WP-2.1.1 - Paired-contrast protocol v2 (seed and climate parity enforcement)

**Outcome**

Paired ecological contrasts (example: herbivore present vs removed) are guaranteed to be comparable by construction, with seed/climate parity explicitly enforced.

**Why now**

Independent review found seed mismatch in Experiment A paired scenarios, creating avoidable stochastic confounding.

**Scope**

- In:
  - scenario contract extension for paired contrasts,
  - compile-time validation of parity constraints,
  - docs updates.
- Out:
  - changing non-paired scenario behavior.

**Required implementation**

1. Extend scenario config schema to include:
   - `contrast_id` (string),
   - `paired_with` (scenario_id),
   - `pairing_rules` (defaults: `seed`, `climate`, `runtime.days`, `runtime.minute_limit` parity required).
2. Add scenario compiler validation:
   - fail with clear error if required parity fields mismatch.
3. Add opt-out flag for explicitly unpaired sensitivity experiments:
   - `paired_contrast_required: false` (default true for reference contrasts).
4. Document the new contract in:
   - `docs/contracts/scenario_contract_v1.md` (or v2 if schema bump is chosen),
   - `docs/reference/reference_scenarios_v1.md`.

**Acceptance criteria**

- Any paired reference scenario compilation fails when seed or required parity fields differ.
- Existing non-paired scenarios continue to compile unchanged.
- A fixed version of the Experiment A paired configs compiles cleanly.

**Required tests**

- Unit test: parity validator catches seed mismatch.
- Unit test: parity validator catches climate mismatch.
- Integration test: valid paired scenarios compile and run.

**Artefact evidence**

- Updated scenario config files for paired contrasts.
- Log entry showing before/after parity validation behavior.

**Stop condition**

Paired-contrast confounding by seed/climate mismatch is structurally impossible unless explicitly opted out.

---

### WP-2.1.2 - Ensemble execution layer v1 (multi-seed deterministic orchestration)

**Outcome**

Experiments can run as deterministic multi-seed ensembles with reproducible summaries and seed manifests.

**Scope**

- In:
  - ensemble runner,
  - target(s) for ensemble execution,
  - standard ensemble summary outputs.
- Out:
  - Bayesian calibration and parameter inference.

**Required implementation**

1. Add ensemble config fields:
   - `ensemble.enabled` (bool),
   - `ensemble.seeds` (integer vector),
   - `ensemble.label` (string).
2. Implement deterministic ordering:
   - iterate seeds in ascending order,
   - stable row ordering in output summaries.
3. Write ensemble artefacts under:
   - `artefacts/canonical_runs/<scenario_slug>/ensemble_v1/`.
4. Emit:
   - `seed_manifest.csv`,
   - `replicate_summary.csv` (one row per seed),
   - `ensemble_summary.csv` with `median`, `p05`, `p95`, `n`.
5. Ensure run manifests carry:
   - `ensemble_label`,
   - `seed_index`,
   - `seed_value`.

**Acceptance criteria**

- Re-running the same seed vector produces byte-identical summary CSVs (excluding timestamps where present).
- Ensemble summary contains all requested seeds exactly once.
- Existing single-seed workflows remain supported.

**Required tests**

- Unit test: deterministic row ordering irrespective of internal parallel execution.
- Integration test: ensemble artefact folder and required files created.
- Regression test: same input seeds yield identical summary outputs.

**Artefact evidence**

- One example ensemble run for a reference scenario.
- Log with seed manifest inspection and summary quantiles.

**Stop condition**

Ensemble runs are first-class, deterministic, and reproducible.

---

### WP-2.1.3 - Experiment A v2 rerun (paired-seed + ensemble uncertainty)

**Outcome**

Experiment A is rerun as a valid paired contrast with uncertainty bounds and no seed confounding.

**Scope**

- In:
  - paired scenario correction,
  - ensemble execution for present vs removal,
  - revised report and summaries.
- Out:
  - expanding experiment A into new ecological treatments.

**Required implementation**

1. Create v2 Experiment A scenario set using WP-2.1.1 protocol.
2. Run ensemble with default 30 seeds:
   - `301:330` unless overridden.
3. Produce v2 artefacts under:
   - `artefacts/canonical_runs/experiment_a_presence_removal_v2/`.
4. Produce:
   - per-seed deltas (`removal - present`) for key metrics,
   - ensemble delta summary with interval statistics,
   - report text that explicitly states sample size and intervals.

**Acceptance criteria**

- Seed sets for present/removal are identical.
- Median deltas for primary vegetation metrics remain directionally consistent with v1:
   - `total_shoot_biomass_kg` higher in removal,
   - `fine_fuel_proxy_kg` higher in removal.
- At least 80 percent of seed replicates show expected direction for each primary metric.

**Required tests**

- Integration test: paired seeds are identical across treatments in output manifest.
- Regression test: v2 report generation succeeds and references ensemble statistics.

**Artefact evidence**

- `experiment_a_summary_v2.csv`
- `experiment_a_delta_ensemble_v2.csv`
- `experiment_a_report_v2.md`

**Stop condition**

Experiment A claims are uncertainty-aware and no longer confounded by mismatched seeds.

---

### WP-2.1.4 - Claim-to-evidence registry and report gating

**Outcome**

Every ecological claim in experiment reports is linked to explicit supporting metrics and thresholds; unsupported claims fail report gating.

**Scope**

- In:
  - claims registry format,
  - validation step in report pipeline,
  - failure semantics.
- Out:
  - natural-language quality editing of manuscript prose.

**Required implementation**

1. Create `docs/claim_registry_v1.md` (or CSV/JSON companion) with entries:
   - `claim_id`,
   - `experiment_id`,
   - `metric_name`,
   - `expected_direction_or_threshold`,
   - `support_rule`,
   - `status`.
2. Add a report check that computes claim status:
   - `supported`,
   - `partially_supported`,
   - `not_supported`.
3. Fail pipeline when a claim marked "required" is `not_supported`.
4. Include claim table in experiment reports.

**Acceptance criteria**

- Experiment reports cannot silently state unsupported directional claims.
- Claim status is visible in generated reports and machine-readable output.
- Existing v1 claims are backfilled with status.

**Required tests**

- Unit test: support rule evaluator.
- Integration test: report render fails on unsupported required claim.

**Artefact evidence**

- claim status table output for experiments A/B/C.
- log entry showing one pass case and one intentionally failed gate case.

**Stop condition**

Interpretive claims are auditable and mechanically linked to evidence.

---

### WP-2.2.1 - Herbivore energetic/water diagnostics contract v2

**Outcome**

Daily herbivore outputs include explicit diagnostics needed for ecological interpretation of stress trajectories.

**Scope**

- In:
  - output contract extension,
  - new diagnostic columns,
  - schema docs and migration logic.
- Out:
  - demographic transitions (birth/death).

**Required implementation**

1. Add diagnostic columns to herbivore daily outputs:
   - `MaintenanceEnergyReq`,
   - `EnergyBalanceRatio`,
   - `WaterRequirement`,
   - `WaterBalanceRatio`,
   - `EnergyDeficitStreakDays`,
   - `WaterDeficitStreakDays`,
   - `PhysiologicalStressFlag`.
2. Define calculations in docs with units and sign conventions.
3. Bump output schema version if required and add migration tests.
4. Update `docs/contracts/output_contract_v1.md` (or introduce v1.1 contract doc).

**Acceptance criteria**

- New columns populated with finite numeric values for canonical runs.
- Ratios and streak counters behave monotonically and reset correctly.
- Backward compatibility path documented.

**Required tests**

- Unit tests for ratio and streak calculations.
- Integration tests validating columns exist and are finite in canonical outputs.

**Artefact evidence**

- updated `herbivore_daily.csv` example with diagnostic columns,
- schema doc update and migration evidence.

**Stop condition**

Energetic and hydric stress can be interpreted from outputs without reverse engineering.

---

### WP-2.2.2 - Body-condition feedback v1 (no demography)

**Outcome**

Herbivores respond to sustained energetic stress through a body-condition state variable and behavior modulation, without introducing demography.

**Scope**

- In:
  - body condition state update,
  - feedback on foraging behavior parameters,
  - scenario toggles and documentation.
- Out:
  - mortality and reproduction.

**Required implementation**

1. Add state variable:
   - `BodyConditionIndex` (BCI), bounded [0,1], default initial 0.8.
2. Daily update default rule:
   - `BCI_next = clamp(BCI + 0.05 * max(EnergyBalanceRatio, 0) - 0.08 * abs(min(EnergyBalanceRatio, 0)), 0, 1)`.
3. Feedback defaults:
   - if `BCI < 0.4`, increase foraging effort up to +15 percent within daily minute cap;
   - if `BCI < 0.2`, set `PhysiologicalStressFlag = 1`.
4. Make feedback configurable:
   - `feedback.enabled` default true for reference scenarios,
   - coefficients configurable in scenario/runtime config.
5. Record assumption rationale in `docs/decisions.md`.

**Acceptance criteria**

- BCI remains bounded and numerically stable.
- Under sustained negative energy balance, BCI declines and stress flag triggers.
- Under neutral/positive balance, BCI stabilizes or recovers.

**Required tests**

- Unit test: BCI update equation and bounds.
- Integration test: stress scenario triggers flag and effort modulation.
- Regression test: disabling feedback restores v1-like behavior.

**Artefact evidence**

- side-by-side canonical run comparison with feedback on/off.
- interpretation notes on how feedback changes trajectories.

**Stop condition**

Persistent deficits now have explicit biological state consequences in the model outputs.

---

### WP-2.2.3 - Aridity stressor matrix expansion for intake-limitation testing

**Outcome**

Experiment C design is expanded to test intake limitation explicitly, not only water-demand response.

**Scope**

- In:
  - expanded scenario matrix,
  - controlled stress axes likely to influence intake,
  - expected outcome table update.
- Out:
  - new herbivore functional types.

**Required implementation**

1. Keep existing aridity gradient (`low/mid/high`).
2. Add second stress axis with three levels that directly affects intake opportunity:
   - `forage_access_scale` (`1.0`, `0.8`, `0.6`) or equivalent handling-time constraint.
3. Build 3x3 matrix scenarios with stable naming convention:
   - `reference_aridity_<level>_access_<level>_v2`.
4. Update expected-direction contracts:
   - water-demand monotonicity expected across aridity;
   - intake limitation expected across reduced access within fixed aridity.

**Acceptance criteria**

- Matrix compiles and runs through pipeline.
- At least one intake-linked axis yields detectable monotonic effect on `mean_daily_dmi` in summaries.
- If effect absent, report explicitly states non-detection and does not claim limitation.

**Required tests**

- Integration test: 3x3 scenario matrix generation and execution.
- Regression test: expected-direction evaluation logic handles multi-axis designs.

**Artefact evidence**

- matrix summary CSV,
- expected-direction evaluation table.

**Stop condition**

Experiment C can discriminate water-demand effects from intake-limitation effects.

---

### WP-2.2.4 - Experiment C v2 rerun with revised interpretation rules

**Outcome**

Experiment C is rerun and reported with claim discipline aligned to observed signals.

**Scope**

- In:
  - full v2 rerun (ensemble optional but recommended),
  - report update,
  - interpretation guardrails.
- Out:
  - manuscript final polish.

**Required implementation**

1. Run Experiment C v2 scenarios (from WP-2.2.3), default 20 seeds each.
2. Produce artefacts under:
   - `artefacts/canonical_runs/experiment_c_aridity_gradient_v2/`.
3. Report must separate:
   - supported findings,
   - non-supported hypotheses,
   - limitations.
4. Include claim registry outputs in report body.

**Acceptance criteria**

- No unsupported "intake limitation" claim appears in report.
- Water-demand gradient remains quantified with uncertainty intervals.
- Report includes explicit ecological interpretation boundaries.

**Required tests**

- Integration test: v2 report render with claim gate.
- Regression test: unsupported claim triggers failure when forced.

**Artefact evidence**

- `experiment_c_summary_v2.csv`
- `experiment_c_claims_v2.csv`
- `experiment_c_report_v2.md`

**Stop condition**

Experiment C narrative is evidence-aligned and robust against over-claiming.

---

### WP-2.3.1 - Units and metric metadata layer (outputs + reports)

**Outcome**

All primary output metrics have explicit machine-readable units and human-readable unit annotations in reports.

**Scope**

- In:
  - unit dictionary,
  - metadata propagation to summaries/reports,
  - docs updates.
- Out:
  - wholesale renaming of existing columns.

**Required implementation**

1. Create a central units registry file (CSV or YAML), including:
   - metric name,
   - unit symbol,
   - description,
   - sign convention where relevant.
2. Attach units metadata to experiment summary outputs:
   - via sidecar metadata file or standard metadata table.
3. Ensure report tables show units in headers or captions.
4. Update parameter and output docs accordingly.

**Acceptance criteria**

- Every metric in experiments A/B/C summaries has an associated unit entry.
- Reports display units for all primary metrics.
- Unit dictionary is referenced in docs and version-controlled.

**Required tests**

- Unit test: each summary metric has a units lookup.
- Integration test: report render fails if units metadata missing for required metric.

**Artefact evidence**

- units registry file,
- one rendered report showing unit-annotated tables.

**Stop condition**

Ecological readers can interpret every reported metric without ambiguity.

---

### WP-2.3.2 - Observational dataset contract and adapters v1

**Outcome**

A stable, documented contract exists for mapping external ecological datasets into model-comparison inputs.

**Scope**

- In:
  - observational input schema definition,
  - adapter functions for at least two common dataset forms,
  - validation and unit-conversion checks.
- Out:
  - automated downloading of third-party data.

**Required implementation**

1. Define `observational_data_contract_v1` with required fields:
   - site identifier,
   - date/day index,
   - metric name,
   - value,
   - unit,
   - uncertainty (optional).
2. Implement adapters for:
   - vegetation biomass time series,
   - herbivore intake/water-use time series.
3. Add strict validation:
   - required columns present,
   - units recognized,
   - missingness policy enforced.
4. Provide small synthetic example datasets under `inst/extdata/validation/`.

**Acceptance criteria**

- Adapters convert raw examples to contract format deterministically.
- Invalid unit/column structure produces informative errors.
- Documentation includes mapping examples.

**Required tests**

- Unit tests for adapter conversion and validation failures.
- Integration test for end-to-end adapter + validation pipeline.

**Artefact evidence**

- example adapted datasets,
- validation logs.

**Stop condition**

External ecological data can be ingested consistently for model checks.

---

### WP-2.3.3 - Validation metrics battery and pilot ecological benchmark

**Outcome**

A reusable metrics battery exists for comparing simulation outputs to observational datasets, with one pilot benchmark completed.

**Scope**

- In:
  - metrics functions,
  - benchmark pipeline target,
  - pilot results artefacts.
- Out:
  - full calibration optimization routines.

**Required implementation**

1. Implement metrics:
   - RMSE,
   - normalized RMSE,
   - mean bias,
   - directional agreement score,
   - interval coverage (if uncertainty available).
2. Build pilot benchmark target combining:
   - one adapted vegetation dataset,
   - one adapted herbivore metric dataset.
3. Produce benchmark artefacts under:
   - `artefacts/validation/pilot_benchmark_v1/`.
4. Add interpretation template:
   - what agreement means,
   - what mismatch implies,
   - what parameter classes are implicated.

**Acceptance criteria**

- Metrics battery executes end-to-end from adapted datasets.
- Benchmark report renders with clear metric definitions and units.
- Re-running benchmark with same inputs is deterministic.

**Required tests**

- Unit tests for metric formula correctness on known toy vectors.
- Integration test for pilot benchmark target and report.

**Artefact evidence**

- benchmark summary CSV,
- benchmark report markdown/html.

**Stop condition**

The project can quantitatively evaluate fit against external ecological data.

---

### WP-2.4.1 - Long-horizon stability suite (365-day stress runs)

**Outcome**

Model reliability is tested over long horizons and stress scenarios, with explicit domain sanity outputs and failure tagging.

**Scope**

- In:
  - 365-day scenario suite,
  - stability metrics and thresholds,
  - automated sanity result summaries.
- Out:
  - adding new biological modules beyond scope.

**Required implementation**

1. Define long-horizon scenario set:
   - baseline climate,
   - high aridity,
   - high herbivory pressure,
   - low-forage-access stress.
2. Run default 10 seeds per long scenario.
3. Compute stability summaries:
   - NaN/Inf occurrence count,
   - negative biomass violations,
   - gut capacity violations,
   - prolonged stress incidence.
4. Write outputs under:
   - `artefacts/stability/long_horizon_v1/`.

**Acceptance criteria**

- No NaN/Inf in required state outputs.
- No negative biomass pool values below allowed numeric tolerance.
- Gut capacity violations are zero.
- Any prolonged stress is reported and interpreted, not hidden.

**Required tests**

- Integration test for stability suite target completion.
- Regression test for domain sanity summary format and fields.

**Artefact evidence**

- stability summary CSV and run manifest.
- log interpretation of any flagged scenarios.

**Stop condition**

Long-horizon behavior is quantified and monitored with reproducible evidence.

---

### WP-2.4.2 - Throughput and scaling profile on multicore targets

**Outcome**

Performance profile is updated for post-1.0 workload, with measured scaling behavior and regression thresholds.

**Scope**

- In:
  - profiling harness updates,
  - multicore targets profile,
  - performance budget thresholds.
- Out:
  - low-level rewrites solely for micro-optimizations.

**Required implementation**

1. Add/refresh targets profile for multicore execution.
2. Benchmark representative workloads:
   - single-seed baseline,
   - 30-seed ensemble,
   - long-horizon stress suite subset.
3. Record:
   - wall-clock time,
   - peak memory,
   - throughput (herbivore-days per second).
4. Define regression budget:
   - fail if runtime degrades >20 percent relative to baseline artefact without documented rationale.

**Acceptance criteria**

- Performance baseline artefact exists and is reproducible.
- Profiling can be rerun by command documented in workflow.
- Regression threshold check is automated in pipeline.

**Required tests**

- Integration test for performance summary target.
- Regression check test for threshold enforcement logic.

**Artefact evidence**

- `artefacts/benchmarks/post_v1_scaling_v1/` with summary and manifests.

**Stop condition**

Performance regressions become visible and enforceable.

---

### WP-2.4.3 - Tiered CI implementation (PR lean + nightly deep + weekly repro)

**Outcome**

CI is intentionally tiered: fast blocking checks for PRs plus deeper scheduled checks for scientific robustness and reproducibility.

**Scope**

- In:
  - CI workflow definitions for three tiers,
  - clear failure ownership and triage conventions.
- Out:
  - adding optional heavyweight checks to PR path.

**Required implementation**

1. Implement or update workflows:
   - `pr` workflow: check/tests/lint/smoke only,
   - `nightly` workflow: deep ecological suites,
   - `weekly_repro` workflow: clean-restore reproducibility.
2. Add clear workflow naming and status descriptions.
3. Add docs section mapping failures to response expectations.
4. Ensure all workflows are reproducible and non-interactive.

**Acceptance criteria**

- PR CI remains lean and blocking.
- Scheduled CI executes deeper suites and stores artefacts.
- Workflow docs clearly explain what each tier validates.

**Required tests**

- CI lint/check for workflow syntax.
- Manual dry-run evidence from one successful run per tier.

**Artefact evidence**

- links or logs of one passing run for each tier,
- updated CI documentation.

**Stop condition**

CI complexity is controlled by purpose-built tiers, reducing dev-time friction without losing safeguards.

---

### WP-2.5.1 - Report pipeline v2 (uncertainty-aware ecological narrative)

**Outcome**

The paper pipeline reports A/B/C outcomes with uncertainty intervals, claim-status tables, and explicit limitations.

**Scope**

- In:
  - Quarto/report updates,
  - uncertainty visualization,
  - standardized interpretation templates.
- Out:
  - journal-specific formatting polish.

**Required implementation**

1. Upgrade report templates to include:
   - median and interval summaries,
   - claim registry outputs,
   - units in table captions/headers,
   - limitation statements for unsupported hypotheses.
2. Ensure report build is pipeline-driven and deterministic.
3. Store v2 reports under:
   - `artefacts/reports_v2/`.

**Acceptance criteria**

- Report build completes from canonical artefacts without manual editing.
- Unsupported claims are visually and textually marked.
- A/B/C sections share consistent structure and units.

**Required tests**

- Integration test: full report render target.
- Regression test: missing claim/units metadata fails render.

**Artefact evidence**

- rendered v2 report files and dependency manifest.

**Stop condition**

Narrative outputs are publication-ready in structure and evidence discipline.

---

### WP-2.5.2 - Deterministic figures/tables manifest and checksum policy

**Outcome**

Figure and table outputs are reproducibility-tracked with checksums and provenance manifests.

**Scope**

- In:
  - manifest format,
  - checksum generation,
  - provenance capture in report outputs.
- Out:
  - image style redesign.

**Required implementation**

1. Create artefact manifest file containing:
   - figure/table identifier,
   - source inputs,
   - seed context,
   - checksum.
2. Emit manifest on each report build.
3. Add check that unchanged inputs produce unchanged checksums.
4. Document expected nondeterministic exceptions if any.

**Acceptance criteria**

- Manifest generated for all published figures/tables.
- Rebuild with unchanged inputs yields unchanged checksums.
- Any checksum drift must be explainable via changed inputs or code.

**Required tests**

- Integration test: manifest generation includes all expected outputs.
- Regression test: deterministic rebuild checksum comparison.

**Artefact evidence**

- figure/table manifest files in `artefacts/reports_v2/`.

**Stop condition**

Publication artefacts are traceable and reproducibility-auditable.

---

### WP-2.5.3 - External reproducibility run-through v2

**Outcome**

A clean-machine reproduction of key post-1.0 outputs is documented and evidenced.

**Scope**

- In:
  - fresh-library run-through for selected v2 experiments,
  - reproducibility checklist and logs.
- Out:
  - full exhaustive reruns of every scenario.

**Required implementation**

1. Execute run-through from clean library/environment:
   - restore dependencies,
   - run minimal canonical suite,
   - render report v2 subset.
2. Capture:
   - command transcript,
   - versions,
   - output checksums.
3. Write outputs under:
   - `artefacts/reproducibility/external_run_v2/`.
4. Update runbook docs.

**Acceptance criteria**

- External run-through completes without manual patching.
- Expected artefacts are generated and match documented checksums where applicable.
- Reproducibility checklist status is fully populated.

**Required tests**

- Runbook smoke test target.

**Artefact evidence**

- `repro_check_summary.csv` for v2,
- run-through log markdown.

**Stop condition**

Post-1.0 results are independently reproducible from documentation alone.

---

### WP-2.5.4 - v1.1 RC bundle and next-queue promotion

**Outcome**

A v1.1 release-candidate bundle is assembled with hardening outputs, and a next-priority backlog is prepared.

**Scope**

- In:
  - v1.1 RC artefact bundle,
  - changelog updates,
  - promotion of next work queue.
- Out:
  - implementing new v2.0 feature modules.

**Required implementation**

1. Build RC bundle under:
   - `artefacts/release_candidates/v1.1.0-rc1/`.
2. Include:
   - package build artefacts,
   - canonical experiment v2 outputs,
   - report v2 outputs,
   - reproducibility checklists,
   - known limitations.
3. Update:
   - `docs/archive/CHANGELOG.md`,
   - `docs/release_checklist.md`,
   - this roadmap checkboxes.
4. Add roadmap handoff section:
   - what is complete,
   - what remains,
   - proposed next line (for future `roadmap_v3` or continuation).

**Acceptance criteria**

- All v2 quality gates relevant to completed lines are green.
- RC bundle is complete and navigable.
- Remaining scientific risks are explicitly listed with mitigation proposals.

**Required tests**

- Release-gate command suite (tests/lint/check/smoke/repro subset).

**Artefact evidence**

- v1.1 RC checklist and manifest,
- final milestone log for `M2.5`.

**Stop condition**

v1.1 hardening cycle is packaged, evidenced, and ready for maintainer sign-off.

---

### WP-2.6.1 - Across-run deterministic parallel execution controls

**Outcome**

Reference ensemble and stability workloads can execute across CPU cores while preserving deterministic ordering and reproducible summaries.

**Scope**

- In:
  - process-level across-run parallelism for seed/scenario replicates,
  - explicit execution-mode controls (`auto`/`serial`/`multicore`),
  - deterministic row-order guarantees in outputs.
- Out:
  - within-run timestep parallelism (minute/day kernels remain sequential).

**Required implementation**

1. Add a shared execution-plan resolver for:
   - worker-count validation,
   - CI-aware defaults,
   - deterministic fallback behavior.
2. Update ensemble runner to:
   - execute seeds via the execution plan,
   - preserve deterministic seed-index ordering in manifests and summaries,
   - record resolved execution settings in run manifests.
3. Update long-horizon stability suite to:
   - execute scenario-seed jobs using the same execution plan,
   - preserve deterministic scenario/seed row order,
   - expose execution metadata in outputs/manifests.

**Acceptance criteria**

- Serial and multicore modes produce equivalent replicate summaries for fixed seeds.
- Output row ordering is stable and deterministic regardless of worker count.
- Existing callers remain backward compatible (defaults continue to work without new arguments).

**Required tests**

- Unit test: execution-plan worker bounds and fallback behavior.
- Integration test: ensemble serial vs multicore result parity.
- Integration test: scaling/stability suite still writes required artefacts under parallel controls.

**Artefact evidence**

- Updated `seed_manifest.csv`/`replicate_summary.csv` outputs with deterministic ordering.
- Stability suite replicate and summary artefacts produced under the updated execution controls.

**Stop condition**

Across-run parallel execution is available, deterministic, and reproducible for core multi-run workflows.

---

### WP-2.6.2 - Kernel hotspot profiler and evidence artefacts

**Outcome**

Each scaling run emits a reproducible hotspot profile identifying dominant runtime kernels, so speed-up work is evidence-led rather than guess-based.

**Scope**

- In:
  - profiling harness for representative scenario execution,
  - machine-readable hotspot tables (`by_self`, `by_total`),
  - report integration of top hotspots.
- Out:
  - low-level algorithm rewrites in this WP.

**Required implementation**

1. Add a profiling helper that:
   - executes a representative canonical scenario under `Rprof`,
   - writes raw profile output and summarized CSV tables.
2. Integrate profiling into `run_post_v1_scaling_profile()` output bundle.
3. Include hotspot summary lines in `scaling_report_v1.md`.

**Acceptance criteria**

- Scaling profile artefact directory contains raw and summarized hotspot outputs.
- Hotspot summaries are parseable and include top self-time calls.
- Profiling run is deterministic in setup (seeded scenario) and non-interactive.

**Required tests**

- Integration test: scaling profile run emits kernel profile artefacts.

**Artefact evidence**

- `kernel_profile_v1.out`
- `kernel_profile_v1_by_self.csv`
- `kernel_profile_v1_by_total.csv`
- hotspot section in `scaling_report_v1.md`

**Stop condition**

Kernel hotspot evidence is generated automatically with each scaling profile run.

---

### WP-2.6.3 - Serial-vs-parallel break-even benchmark and default policy

**Outcome**

The project quantifies when parallel orchestration helps versus hurts, and records a defensible default policy for workstation and CI use.

**Scope**

- In:
  - benchmark matrix over replicate counts and worker tiers,
  - speedup/efficiency calculations versus serial baseline,
  - break-even summary and optional gate.
- Out:
  - enforcing strict speedup failures on PR CI by default.

**Required implementation**

1. Add benchmark-design helper (replicate sizes x worker tiers) with serial baseline coverage.
2. Execute benchmark matrix within scaling profile and compute:
   - elapsed/cpu/memory,
   - speedup versus serial,
   - efficiency versus serial,
   - break-even replicate count by worker tier.
3. Add break-even gate summary output:
   - pass/fail detail table,
   - optional enforcement flag (default non-blocking).
4. Record recommended worker tier from observed break-even summary.

**Acceptance criteria**

- Benchmark and break-even CSV artefacts are produced for each scaling run.
- Break-even summary identifies threshold crossing where present; otherwise reports explicit non-detection.
- Default gate posture remains CI-safe (non-blocking unless explicitly enabled).

**Required tests**

- Unit test: benchmark-design helper invariants.
- Unit test: break-even summarizer and gate logic on toy data.
- Integration test: scaling profile writes benchmark + break-even + gate artefacts.

**Artefact evidence**

- `parallel_overhead_benchmark_v1.csv`
- `parallel_break_even_summary_v1.csv`
- `parallel_break_even_gate_v1.csv`
- break-even section in `scaling_report_v1.md`

**Stop condition**

Parallelization overhead and benefit are measured and documented with reproducible break-even outputs.

---

### WP-3.1.1 - Portal plan YAML contract v1 (single-source-of-truth run file)

**Outcome**

Non-coder users can define scenario settings, sensitivity parameters, output preferences, and execution mode in one editable YAML plan.

**Implementation summary**

- Added plan schema/validation/compiler utilities in:
  - `R/portal_plan_v1.R`
- Added contract documentation:
  - `docs/contracts/portal_plan_contract_v1.md`
- Added editable templates:
  - `portal/plans/templates/single_scenario_template.yaml`
  - `portal/plans/templates/sensitivity_template.yaml`

**Acceptance notes**

- Invalid schema, missing fields, or bad path references fail with structured portal error classes.
- Sensitivity parameter paths are pre-validated against the resolved scenario object.

---

### WP-3.1.2 - Non-coder CLI entrypoints (single run + sensitivity + report render)

**Outcome**

Users can run the full workflow from shell commands without writing R code.

**Implementation summary**

- Added CLI scripts:
  - `portal/run_plan.R`
  - `portal/run_sensitivity.R`
  - `portal/render_report.R`
- Added entrypoint documentation:
  - `portal/README.md`

**Acceptance notes**

- Single-run and sensitivity workflows each execute from one command.
- Dry-run mode validates YAML and resolves settings without running simulations.

---

### WP-3.1.3 - Portal runner and sensitivity orchestration with deterministic indexing

**Outcome**

Portal runs produce reproducible run indices and manifests for both single runs and sensitivity designs.

**Implementation summary**

- Added orchestration helpers in:
  - `R/portal_runner_v1.R`
- Added deterministic run indexing and per-run summaries:
  - `run_index.csv`
  - `tables/*_summary.csv`
- Added scenario return enrichment for downstream portal tooling:
  - `R/scenario_runner_v1.R` now returns `first_day_plants` and `final_plants` for write-output runs.

**Acceptance notes**

- One-at-a-time and grid sensitivity designs are both supported.
- Deterministic ordering is preserved for sensitivity result rows.

---

### WP-3.1.4 - Rich ecologist output bundle (time/spatial/comparison plots + CSV tables)

**Outcome**

Each portal run produces a coherent set of tables and figures suitable for ecological sanity checks and communication.

**Implementation summary**

- Added table/figure builders:
  - `R/portal_visuals_v1.R`
- Added outputs:
  - daily summary tables,
  - endpoint summaries,
  - domain sanity summary tables,
  - time-series figures,
  - spatial snapshot figures,
  - sensitivity comparison/effect figures.

**Acceptance notes**

- Domain sanity tables expose NaN/Inf, biomass-negativity, and gut-capacity violation diagnostics.
- Plot/table outputs are deterministic for fixed inputs.

---

### WP-3.1.5 - Quarto ecologist report template (HTML/PDF best-effort)

**Outcome**

Portal runs generate a human-readable report that collates tables/figures and interpretation guardrails.

**Implementation summary**

- Added Quarto report template:
  - `portal/reports/ecologist_report_v1.qmd`
- Added report render helper integration:
  - `render_portal_report_v1()` in `R/portal_runner_v1.R`

**Acceptance notes**

- HTML render is default when Quarto is available.
- PDF render is best-effort and logged in `reports/report_render_notes.md`.

---

### WP-3.1.6 - GUI stub (Shiny wrapper over YAML + CLI backend)

**Outcome**

A lightweight GUI is available for users who prefer form-based editing and click-run interaction.

**Implementation summary**

- Added Shiny stub app:
  - `portal/gui/app.R`
- Added launcher script:
  - `portal/launch_gui_stub.R`

**Acceptance notes**

- GUI edits/saves YAML and runs the same backend runner functions as CLI.
- GUI remains optional and does not replace reproducible CLI workflows.

---

### WP-3.1.7 - Ecologist docs and vignette workflow updates

**Outcome**

Non-coder onboarding docs are explicit, minimal-friction, and aligned to portal entrypoints.

**Implementation summary**

- Added quickstart docs:
  - `docs/guides/ecologist_quickstart_v1.md`
- Added vignette:
  - `vignettes/ecologist_portal_workflow.Rmd`
- Updated repo onboarding:
  - `README.md` (Non-Coder Quickstart section)
  - `docs/workflow.md` (portal commands)

**Acceptance notes**

- Users can complete first run from docs by editing YAML only.

---

### WP-3.1.8 - Validation gates, artefact interpretation log, and queue closure

**Outcome**

Portal line is complete with tests, quality gates, artefact interpretation, and roadmap closure updates.

**Implementation summary**

- Added tests:
  - `tests/testthat/test_portal_plan_v1.R`
  - `tests/testthat/test_portal_runner_v1.R`
- Added decisions/log updates:
  - `docs/decisions.md`
  - `docs/log/20260207_wp-3.1_ecologist_portal_usability.md`
- Updated queue status:
  - all `WP-3.1.x` entries checked complete in this roadmap.

---

## 7) Explicit assumptions and defaults for v2

These defaults apply unless a WP overrides them and logs a decision:

1. Ensemble defaults:
   - 30 seeds for Experiment A and B.
   - 20 seeds for Experiment C matrix unless runtime constraints require fewer.

2. Claim policy:
   - Directional ecological claims require explicit support rules and status in reports.

3. Interpretation boundary:
   - Until demographic modules exist, long-run herbivore viability claims remain mechanistic, not population-outcome claims.

4. CI operating model:
   - Keep PR CI lean; move heavier checks to scheduled tiers.

5. Documentation policy:
   - Every non-trivial ecological assumption must be logged in `docs/decisions.md`.

6. Parallel defaults:
   - `execution_mode = "auto"` resolves to serial on CI and multicore on local workstations (subject to available cores and reserve policy).
   - Break-even gate remains non-blocking by default; enable explicitly for controlled hardware baselines.

---

## 8) Definition of completion for roadmap_v2

`roadmap_v2` is complete only when:

1. All WPs in Section 4 are checked `[x]`.
2. Each WP has a corresponding dated log entry in `docs/log/`.
3. Required artefacts exist in expected directories.
4. Claims in reports are all supported or explicitly marked unsupported with limitation statements.
5. v1.1 RC bundle exists with reproducibility evidence.

If all above are true, autonomous execution stops and awaits next queue promotion.

---

## 9) Completion status and handoff (2026-02-07)

### Completion summary

- All WPs in Section 4 are completed (`[x]`).
- Quality gates executed and green:
  - `make test`
  - `make lint`
  - `TARGETS_PROFILE=ci make smoke`
  - `make check` (qpdf warning resolved; remaining notes are standard non-blocking submission/top-level notes)
- Line `3.1.x` portal usability bundle validated end-to-end:
  - portal dry-run + single-run + sensitivity-run command paths exercised,
  - portal artefacts and domain sanity tables inspected and logged in
    `docs/log/20260207_wp-3.1_ecologist_portal_usability.md`.
- v1.1 RC bundle assembled:
  - `artefacts/release_candidates/v1.1.0-rc1/`
- New WP-2.6.x artefacts generated:
  - `artefacts/benchmarks/post_v1_scaling_v1/parallel_overhead_benchmark_v1.csv`
  - `artefacts/benchmarks/post_v1_scaling_v1/parallel_break_even_summary_v1.csv`
  - `artefacts/benchmarks/post_v1_scaling_v1/kernel_profile_v1_by_self.csv`

### What remains open (scientific interpretation, not build blockers)

- Experiment C claim `exp_c_intake_monotonic` remains `not_supported` and
  `exp_c_intake_drop_low_high` remains `partially_supported` in:
  - `artefacts/canonical_runs/experiment_c_aridity_gradient_v2/experiment_c_claims_v2.csv`
- Pilot benchmark fit against synthetic observations remains weak for biomass and drinking-water absolute error in:
  - `artefacts/validation/pilot_benchmark_v1/pilot_metrics_summary_v1.csv`

### Proposed next line (roadmap_v3 seed queue)

1. Kernel hotspot reduction pass:
   - target top self-time paths (`transport_resistance`, data-frame indexing/mutation),
   - compare vectorized/data-layout alternatives with no-behaviour-drift tests.
2. Optional compiled-path experiments:
   - evaluate candidate `Rcpp` kernels for dominant pure-compute paths,
   - maintain strict parity tests against reference R implementation.
3. Hardware-profile-aware defaults:
   - benchmark laptop/server tiers and codify recommended worker defaults by profile,
   - keep CI profile conservative and deterministic.
