# Roadmap — Autonomous Work Queue (herbivoreTTR)

This roadmap is a strict, testable work-queue designed for long autonomous execution by Codex CLI.
It defines the engineering arc **and** the scientific arc (the “paper story”) via reference scenarios and artefacts.

---

## 1) Opening contract

When the human maintainer says **“Follow the roadmap”**, Codex must:

1. Select the **first unchecked** Work Package (WP) in the **Priority Queue** (top to bottom).
2. Complete that WP **end-to-end** (code + tests + docs + artefacts + log evidence), satisfying the WP-DoD and WP-specific acceptance criteria.
3. Mark that WP checkbox as complete (`[x]`) and add/append a log entry in `docs/log/`.
4. Proceed to the next unchecked WP.

**Reordering rules**
- Reordering, inserting, removing, or changing scope/acceptance criteria of WPs is allowed **only** if:
  - A rationale is recorded in `docs/decisions.md`, and
  - A dated log entry is created in `docs/log/` explaining what changed and why.

**Empty queue rule**
- If the Priority Queue is empty (all checked), Codex must **stop** and report that more work must be promoted into the queue by the PI.

---

## 2) Work Package Definition of Done (WP‑DoD)

A WP is “Done” only when all are true:

- **Acceptance criteria** for the WP are met and enforced by **tests** (unit/integration/regression as appropriate).
- **Docs updated** (minimum):
  - configuration/parameters reference relevant to the WP, and
  - interpretation notes describing outputs and assumptions touched by the WP.
- **Artefact Review Cycle completed and logged**:
  - build artefacts produced (at least a source package build),
  - a canonical run artefact folder exists (see below),
  - sanity inspection notes are written (what was inspected; what looked sane/odd).
- **Schema discipline**:
  - If *any* schema changes: bump `schema_version`, write migration notes, and add migration tests.
  - If output schema changes: document the schema (column meanings/units) and add regression/sanity tests.
- **Evidence trail**:
  - A log entry exists under `docs/log/` referencing:
    - the WP ID,
    - what artefacts were produced,
    - what was inspected,
    - any output changes vs prior fixtures.

**Canonical run artefact folder (required for most WPs)**
- Must exist under: `artefacts/canonical_runs/<scenario_slug>/`
- Must contain:
  - a run manifest (includes `schema_version`, package version, git SHA, seed, scenario parameters hash),
  - output tables (CSV or RDS) referenced by the manifest,
  - optionally small plots (PNG) if they materially support sanity.

---

## 3) Priority Queue (strict order)

### Line 0.3.x — Production backbone + contracts (make the model trustworthy to run)
- [x] **WP-0.3.1 — Baseline audit log + triage register**
- [ ] **WP-0.3.2 — CI gates (Linux): check + tests + lint + targets smoke**
- [ ] **WP-0.3.3 — Cross-platform strategy (macOS/Windows) implemented or explicitly deferred**
- [ ] **WP-0.3.4 — Output contract v0: schema_version + run manifest + schema docs**
- [ ] **WP-0.3.5 — Canonical smoke scenario artefacts: reproducible + targets-integrated**
- [ ] **WP-0.3.6 — Determinism contract: seed plumbing + regression test**
- [ ] **WP-0.3.7 — Domain sanity suite v0: invariants for plants + herbivores**
- [ ] **WP-0.3.8 — Parameter & units reference: allometries + defaults + citations**
- [ ] **WP-0.3.9 — TTR stability & defence controls: guardrails + tests**

### Line 0.4.x — Herbivore behavioural realism (make the ecology defensible)
- [ ] **WP-0.4.1 — Functional types validated: grazer vs browser are measurably distinct**
- [ ] **WP-0.4.2 — Mixed feeder policy validated: explicit interpolation with measurable outcomes**
- [ ] **WP-0.4.3 — Plant selection contract: tastiness scoring + stochastic choice documented & tested**
- [ ] **WP-0.4.4 — Movement contract: torus geometry + disruption probability parameterised & tested**
- [ ] **WP-0.4.5 — Foraging rate & defence handling penalty validated & documented**
- [ ] **WP-0.4.6 — Digestion model v1: hourly queues + realistic init + MRT parameter policy**
- [ ] **WP-0.4.7 — Water balance v1: metabolic water + drinking penalty + outputs**
- [ ] **WP-0.4.8 — Nutrient targeting vs energy-only comparison + “day-in-life” artefact report**

### Line 0.5.x — Beta coupling (multi-herbivore + scenarios + hybrid plant backend)
- [ ] **WP-0.5.1 — Scenario contract v1: scenario object + YAML compile + docs/tests**
- [ ] **WP-0.5.2 — Output schema v1 migration: run_id/herbivore_id + migration tests**
- [ ] **WP-0.5.3 — Cohort state model v1: initialise N herbivores with unique IDs**
- [ ] **WP-0.5.4 — Multi-herbivore runner v1: deterministic ordering rules + tests**
- [ ] **WP-0.5.5 — Implicit stocking-density mode v1 (representative herbivore visitation)**
- [ ] **WP-0.5.6 — Performance budget gate + profiling evidence**
- [ ] **WP-0.5.7 — Plant backend interface boundary (internal TTR behind interface, no behaviour change)**
- [ ] **WP-0.5.8 — TTR.PGM optional benchmark harness + conditional tests**

### Line 0.6.x — Reference experiments (paper-ready narrative via reproducible scenarios)
- [ ] **WP-0.6.1 — Vegetation structure & fuel metrics output contract**
- [ ] **WP-0.6.2 — Reference scenario library v1 (curated scenarios + expected outcomes)**
- [ ] **WP-0.6.3 — LARGE: Experiment A (presence vs removal) with report + artefacts**
- [ ] **WP-0.6.4 — LARGE: Experiment B (grazer vs browser vs mixed) with report + artefacts**
- [ ] **WP-0.6.5 — LARGE: Experiment C (aridity/productivity limits) with report + artefacts**
- [ ] **WP-0.6.6 — Benchmark appendix: internal TTR vs TTR.PGM overlap case (report + artefacts)**
- [ ] **WP-0.6.7 — Paper pipeline skeleton: Quarto report renders from scenario artefacts**

### Line 1.0.0 — Stabilisation + release readiness
- [ ] **WP-1.0.1 — API freeze + deprecation policy + final user docs**
- [ ] **WP-1.0.2 — Release artefact pipeline: build + reference outputs + changelog**
- [ ] **WP-1.0.3 — External reproducibility run-through documented (clean restore → run)**
- [ ] **WP-1.0.4 — v1.0 RC bundle prepared for PI sign-off**

---

## 4) Detailed WP specs

### WP-0.3.1 — Baseline audit log + triage register
**Outcome**  
The repository has a single, authoritative “baseline state” record of what currently passes/fails (check/test/lint/targets), plus a triage register of blockers. This anchors all subsequent work and prevents silent regressions.

**Scope**
- In: record current status; enumerate blockers; classify by severity (CI blocker / correctness / performance / docs).
- Out: fixing everything discovered (fixes happen in later WPs unless trivial and clearly unblockers).

**Acceptance criteria**
- A dated log exists with: package check outcome, test outcome, lint outcome, targets smoke outcome.
- All failures are captured verbatim and summarised in plain language.
- A triage section lists blockers mapped to upcoming WPs (or proposes a new WP, with rationale).

**Artefact evidence**
- `docs/log/YYYYMMDD_baseline_audit.md` exists and references WP-0.3.1.
- If baseline artefacts were produced, they are referenced (paths).

**Stop condition**
- The log exists, is complete, and a next-blocker path is explicit.

---

### WP-0.3.2 — CI gates (Linux): check + tests + lint + targets smoke
**Outcome**  
CI enforces a minimal production bar on every PR/push: package checks, tests, lint, and a reproducible smoke pipeline run.

**Scope**
- In: CI workflow(s) that run on Linux; caching acceptable; failure is blocking.
- Out: heavy/full targets pipelines; long-running benchmarks; optional dependencies not required for MVP.

**Acceptance criteria**
- On a clean CI runner, the workflow completes successfully for main and PRs.
- CI fails if:
  - R CMD check fails,
  - any tests fail,
  - any lints fail,
  - targets smoke run fails.
- CI logs are readable and include session info (R version, OS, package versions).

**Artefact evidence**
- `.github/workflows/` contains the CI workflow(s).
- `docs/log/` entry documents one successful CI run and links the WP ID to the observed outcomes.
- A smoke artefact folder exists (may be small) and is referenced in the log.

**Stop condition**
- CI gate is green and demonstrably blocks failures.

---

### WP-0.3.3 — Cross-platform strategy (macOS/Windows) implemented or explicitly deferred
**Outcome**  
Cross-platform support is made explicit: either implemented in CI (preferred) or consciously deferred with documented rationale and risk.

**Scope**
- In: at minimum, a decision and a test of installability on macOS/Windows (CI or documented procedure).
- Out: guaranteeing bitwise identical floating-point outputs across OS (not required).

**Acceptance criteria**
- Either:
  - CI includes macOS and Windows jobs and they pass, **or**
  - `docs/decisions.md` contains a dated decision to defer one/both OS with a mitigation plan and a review trigger.
- Package installation succeeds on the supported OS set.

**Artefact evidence**
- CI workflows updated **or** decision record written.
- `docs/log/` entry summarises observed results and any OS-specific issues.

**Stop condition**
- Cross-platform posture is unambiguous and recorded.

---

### WP-0.3.4 — Output contract v0: schema_version + run manifest + schema docs
**Outcome**  
Outputs become a stable product: every run can be interpreted and compared across versions via explicit schemas and manifests.

**Scope**
- In:
  - define `schema_version` for outputs,
  - define required output tables for a minimal coupled run,
  - document columns, units, and meanings.
- Out:
  - expanding to every conceivable output (keep it minimal but stable),
  - large binary dumps as the default.

**Acceptance criteria**
- A documented output contract exists, including:
  - required output tables (names and purpose),
  - required columns and units,
  - a defined `schema_version` mechanism.
- Tests enforce at least:
  - presence of required outputs for the canonical smoke run,
  - presence and validity of `schema_version`,
  - absence of NaNs/Infs in required numeric outputs.

**Artefact evidence**
- A schema documentation file exists (location is up to the repo conventions, but must be stable).
- Canonical run manifest exists and includes schema metadata.
- Tests exist that fail if schema is violated.
- `docs/log/` entry records schema_version chosen and why.

**Stop condition**
- A new user can open the canonical outputs and interpret them using only repo docs.

---

### WP-0.3.5 — Canonical smoke scenario artefacts: reproducible + targets-integrated
**Outcome**  
There is a single, small “canonical smoke scenario” used for regression, sanity inspection, and paper-figure scaffolding.

**Scope**
- In:
  - one small scenario (minutes limited, few plants) that runs fast and deterministically,
  - targets pipeline produces the artefact folder.
- Out:
  - large parameter sweeps,
  - long multi-day benchmarks.

**Acceptance criteria**
- The canonical smoke scenario produces a canonical run folder with:
  - manifest,
  - required outputs per Output Contract v0.
- Targets smoke run produces the same outputs under CI profile.
- A log entry documents sanity inspection (what was inspected; what looked reasonable).

**Artefact evidence**
- `artefacts/canonical_runs/<scenario_slug>/` exists with manifest + outputs.
- Targets pipeline references/produces the same artefact set.
- `docs/log/` entry includes the scenario slug and what was inspected.

**Stop condition**
- Canonical smoke run is reproducible and becomes the default sanity artefact.

---

### WP-0.3.6 — Determinism contract: seed plumbing + regression test
**Outcome**  
Determinism is guaranteed for supported workflows: fixed seed → reproducible outputs (within defined tolerance), enabling meaningful regression tests and paper reproducibility.

**Scope**
- In:
  - define where RNG is used and how it is controlled,
  - ensure canonical runs are deterministic,
  - define tolerance policy for floating-point comparisons.
- Out:
  - guaranteeing identical results across different BLAS implementations or CPUs.

**Acceptance criteria**
- Canonical smoke scenario outputs are reproducible under fixed seed.
- A regression test exists that fails on unintended output drift.
- Any tolerated numeric drift has a documented tolerance policy.

**Artefact evidence**
- Test files explicitly asserting determinism for at least one scenario.
- `docs/log/` entry documents determinism verification method and observed outcome.

**Stop condition**
- Determinism test is stable in CI and locally.

---

### WP-0.3.7 — Domain sanity suite v0: invariants for plants + herbivores
**Outcome**  
The model fails fast and transparently when it enters non-physical/undefined states, preventing silent scientific nonsense.

**Scope**
- In: invariants and guardrails for:
  - plant pools (non-negative, finite),
  - herbivore gut capacity constraints,
  - energy/water bookkeeping sanity (finite, no explosive jumps in canonical run).
- Out: full ecological validation/calibration.

**Acceptance criteria**
- Tests enforce non-negativity and finiteness for core state variables in canonical outputs.
- Runtime checks produce clear error messages that identify the offending component and timestep.
- Sanity checks are documented (what they check and why).

**Artefact evidence**
- Test coverage includes invariants (not just happy path).
- Docs describe invariants and expected ranges for key outputs.
- `docs/log/` entry records results of sanity inspection on canonical outputs.

**Stop condition**
- A broken state is caught immediately by tests and/or clear runtime errors.

---

### WP-0.3.8 — Parameter & units reference: allometries + defaults + citations
**Outcome**  
All key parameters and units are explicit, traceable, and aligned with the intended scientific story (e.g., allometric scaling, NPE:PE targeting).

**Scope**
- In:
  - a single authoritative parameter reference for herbivore allometries and core constants,
  - units table and conventions (mass, energy, time, distance),
  - citations for the key relationships.
- Out:
  - full parameter calibration machinery.

**Acceptance criteria**
- Documentation enumerates:
  - herbivore allometric relationships (coefficients/exponents and units),
  - default parameter values used in canonical scenarios,
  - meaning of “nutrient target” in code terms.
- Tests ensure parameter references remain in sync with exposed defaults (at least for canonical runs).

**Artefact evidence**
- Parameter reference doc exists and is linked from README and/or architecture.
- `docs/log/` entry documents any changes from prior defaults and why.

**Stop condition**
- A reviewer can read parameters/units without reading code.

---

### WP-0.3.9 — TTR stability & defence controls: guardrails + tests
**Outcome**  
The TTR subsystem is robust against known instability modes (runaway C/N pools, runaway defence allocation), and those risks are explicitly controlled and tested.

**Scope**
- In:
  - numeric guardrails for plant pool blow-ups (NaNs/Infs, runaway growth),
  - a clear semantic decision for defence biomass representation,
  - tests that reproduce prior instability and confirm mitigation.
- Out:
  - changing the scientific model to match external packages,
  - implementing full aDGVM2 soil cycling.

**Acceptance criteria**
- There is an explicit documented decision on defence pool semantics and constraints.
- Canonical and stress scenarios do not exhibit runaway C/N or defence pools under documented ranges.
- Tests exist that fail if:
  - plant pools diverge to non-finite values,
  - defence biomass violates defined bounds/relationships.

**Artefact evidence**
- Decision recorded in `docs/decisions.md`.
- Stress-test artefacts exist (small, fast) and are referenced in a log entry.
- Regression tests cover the guarded failure modes.

**Stop condition**
- The model either behaves stably under documented conditions or fails fast with a diagnostic.

---

### WP-0.4.1 — Functional types validated: grazer vs browser are measurably distinct
**Outcome**  
The “three functional types” claim is defensible: grazers and browsers differ in reachable biomass and resulting diet/impacts.

**Scope**
- In:
  - explicit behavioural differences reflected in outputs,
  - tests that detect those differences.
- Out:
  - full realism of mixed diets across heterogeneous plant communities (handled in later WPs).

**Acceptance criteria**
- In a controlled scenario containing grass + trees:
  - grazer diet composition differs from browser diet composition in a measurable, asserted way,
  - browser respects browse-height/reach constraints.
- Differences are stable under fixed seed and documented.

**Artefact evidence**
- Canonical functional-type scenario artefacts exist with outputs showing diet split.
- Tests assert expected qualitative differences.
- Log entry explains what “distinct” means and what was inspected.

**Stop condition**
- A reviewer can see and reproduce the grazer vs browser behavioural split.

---

### WP-0.4.2 — Mixed feeder policy validated: explicit interpolation with measurable outcomes
**Outcome**  
Mixed feeders are a real strategy (not a label), behaving as an explicit interpolation/mixture between grazer and browser preferences.

**Scope**
- In:
  - a documented mixed-feeder policy (inputs/parameters and intended behaviour),
  - tests demonstrating mixed outcomes sit between grazer and browser under controlled conditions.
- Out:
  - adaptive learning or dynamic strategy switching.

**Acceptance criteria**
- Mixed feeder produces diet composition and/or movement pattern distinct from both pure grazer and pure browser.
- Under controlled conditions, mixed outcomes are directionally intermediate (where expected) and documented.

**Artefact evidence**
- Scenario artefacts comparing three types exist (side-by-side outputs).
- Tests assert mixed-feeder behaviour is not identical to either extreme.

**Stop condition**
- Mixed-feeder behaviour is demonstrably and reproducibly meaningful.

---

### WP-0.4.3 — Plant selection contract: tastiness scoring + stochastic choice documented & tested
**Outcome**  
Plant choice is interpretable and matches the intended factors: plant type, browse height, nutrient mismatch, defence, and distance, with stochastic selection among options.

**Scope**
- In:
  - documentation of selection scoring inputs and their direction of effect,
  - stochastic selection contract (not always choosing the single best).
- Out:
  - sophisticated perception/error models beyond stochastic weighted choice.

**Acceptance criteria**
- Documentation defines the plant selection factors and how they combine into a “tastiness” / selection weight.
- Tests demonstrate:
  - plants outside constraints get zero/near-zero selection probability,
  - increasing defence decreases expected selection frequency (all else equal),
  - increasing distance decreases expected selection frequency (all else equal),
  - selection is stochastic but deterministic under fixed seed.

**Artefact evidence**
- A focused selection test scenario artefact exists (small set of plants with controlled attributes).
- Tests assert ordering/probability behaviour.
- Log entry includes inspection of selection frequency outputs.

**Stop condition**
- Plant selection is both explainable and test-verified.

---

### WP-0.4.4 — Movement contract: torus geometry + disruption probability parameterised & tested
**Outcome**  
Movement is scientifically interpretable (continuous space on a torus) and operationally stable, with a configurable disruption probability controlling target switching.

**Scope**
- In:
  - toroidal distance/edge behaviour is explicit,
  - disruption probability is parameterised and documented,
  - tests cover edge wrapping and disruption behaviour.
- Out:
  - terrain, predation landscapes, or memory effects.

**Acceptance criteria**
- Tests demonstrate:
  - movement across plot edges wraps correctly,
  - maximum movement per minute is respected,
  - disruption probability affects frequency of retargeting as expected.

**Artefact evidence**
- A movement-focused scenario artefact exists (e.g., herbivore near edge).
- Tests assert wrap behaviour and movement limits.
- Log entry records what was inspected and confirms plausibility.

**Stop condition**
- Movement rules are stable, configurable, and test-backed.

---

### WP-0.4.5 — Foraging rate & defence handling penalty validated & documented
**Outcome**  
Within-minute intake is controlled by handling time and plant defence fraction, matching the intended ecological mechanism (defence imposes a time penalty).

**Scope**
- In:
  - foraging rate contract documented,
  - defence reduces intake rate in a measurable way,
  - minimum residual plant biomass rule documented and enforced.
- Out:
  - detailed bite mechanics per plant organ beyond proportional removal (unless already present).

**Acceptance criteria**
- Under controlled conditions:
  - higher defence fraction reduces intake per unit time (asserted in tests),
  - gut capacity and time constraints cap intake,
  - plants retain a non-zero minimum residual biomass as documented.
- Outputs report intake and removal in interpretable units.

**Artefact evidence**
- Foraging-focused canonical artefacts exist comparing low- vs high-defence plants.
- Tests assert intake-rate differences and residual biomass rule.
- Log entry includes sanity inspection of intake tables.

**Stop condition**
- Intake mechanics are robust, parameterised, and defensible.

---

### WP-0.4.6 — Digestion model v1: hourly queues + realistic init + MRT parameter policy
**Outcome**  
Digestion is stable and biologically plausible across herbivore body sizes by:
- tracking digestion on an hourly queue (not minute-by-minute),
- initialising digestion state realistically (not all zeros),
- adopting a clear policy for MRT (mean retention time) parameterisation suitable for large herbivores.

**Scope**
- In:
  - a documented digestion state model,
  - MRT treated as explicit parameter (not forced allometric default where it breaks),
  - tests ensuring no pathological starvation due to unrealistic MRT defaults.
- Out:
  - explicit hindgut/ruminant physiology differentiation unless already planned.

**Acceptance criteria**
- Digestion queues are initialised in a documented, realistic manner.
- For a large-herbivore canonical scenario, energy absorption timing is plausible (no systematic starvation caused by MRT mis-scaling).
- Tests cover:
  - queue shifting/advancement behaviour,
  - conservation-style checks (ingested material eventually processed),
  - sensitivity sanity (reasonable changes with MRT adjustments).

**Artefact evidence**
- Digestion-focused artefacts exist (hourly digestion outputs for a day).
- Tests enforce digestion invariants.
- Log entry documents how digestion outputs were inspected.

**Stop condition**
- Digestion is stable and interpretable; MRT policy is documented and test-protected.

---

### WP-0.4.7 — Water balance v1: metabolic water + drinking penalty + outputs
**Outcome**  
Water balance is first-class and coupled to behaviour: forage water + metabolic water contribute; drinking occurs when needed and imposes an energetic/movement penalty.

**Scope**
- In:
  - explicit water accounting outputs,
  - metabolic water calculation documented,
  - drinking penalty mechanism documented and tested.
- Out:
  - explicit hydrology routing to watering points (use a parametric distance proxy).

**Acceptance criteria**
- Outputs include daily water requirement, water from forage, metabolic water, drinking water, and net water balance.
- Tests demonstrate:
  - drinking triggers when requirements are unmet (under controlled conditions),
  - drinking imposes a measurable energetic cost,
  - water balance remains finite and consistent.

**Artefact evidence**
- Water-focused artefacts exist (scenario where water requirement cannot be met from forage).
- Tests assert drinking triggers and costs.
- Log entry includes inspection notes on water outputs.

**Stop condition**
- Water accounting is correct, observable, and affects behaviour/costs.

---

### WP-0.4.8 — Nutrient targeting vs energy-only comparison + “day-in-life” artefact report
**Outcome**  
The project’s novelty is demonstrable: nutrient-targeting behaviour produces different diet choices and vegetation impacts compared to an energy-only baseline, captured in a reproducible “day-in-the-life” artefact.

**Scope**
- In:
  - a documented mode toggle (nutrient-targeting vs energy-only),
  - comparison scenario(s) with identical seeds/conditions differing only by mode,
  - a short interpretive report built from canonical outputs.
- Out:
  - extensive sensitivity analyses (later experiments cover that).

**Acceptance criteria**
- In the same scenario, nutrient-targeting mode yields a measurable, asserted difference in:
  - diet composition and/or
  - selected plant types and/or
  - movement pattern and/or
  - resulting vegetation removals.
- A “day-in-life” artefact exists with:
  - timeline/summary outputs (hourly or daily),
  - narrative interpretation notes explaining what happened and why.

**Artefact evidence**
- Two canonical run folders exist (energy-only and nutrient-targeting) with manifests and outputs.
- A short report document exists (location per repo conventions) referencing those artefacts.
- Tests assert that the two modes differ on at least one defined metric.

**Stop condition**
- The novelty claim is reproducibly visible and test-backed.

---

### WP-0.5.1 — Scenario contract v1: scenario object + YAML compile + docs/tests
**Outcome**  
Users and the targets pipeline can define a run via a stable scenario contract (R object) with an optional YAML front-end that compiles into that contract.

**Scope**
- In:
  - scenario schema documentation,
  - validation of required fields and units,
  - one or more reference YAML scenarios stored in-repo.
- Out:
  - interactive UI for scenario building.

**Acceptance criteria**
- Scenario schema is documented and includes:
  - plot geometry and initial plant composition,
  - climate/conditions specification,
  - herbivore cohort specification (or representative herbivore for implicit mode),
  - seed and runtime limits.
- Tests enforce schema validation and ensure YAML → scenario is deterministic.

**Artefact evidence**
- At least one reference scenario YAML exists and is used by the canonical runs.
- Scenario schema docs exist.
- Tests cover invalid scenarios (clear error messages).

**Stop condition**
- Scenarios become the canonical entry point for running experiments.

---

### WP-0.5.2 — Output schema v1 migration: run_id/herbivore_id + migration tests
**Outcome**  
Outputs support multi-herbivore cohorts and scenario tracking via explicit identifiers and versioned migration.

**Scope**
- In:
  - schema_version bump,
  - migration notes and tests,
  - introduction of `run_id` and `herbivore_id` (and other required identifiers).
- Out:
  - breaking changes without migration path.

**Acceptance criteria**
- `schema_version` is bumped and documented.
- Migration documentation explains:
  - what changed,
  - how to migrate old outputs,
  - what is deprecated.
- Tests exist that:
  - validate new schema,
  - validate migration of at least one prior fixture output set.

**Artefact evidence**
- Updated schema docs and migration notes exist.
- Migration tests exist and pass.
- Canonical run manifests include `run_id` and schema_version.

**Stop condition**
- Output schema is cohort-ready without losing reproducibility of past results.

---

### WP-0.5.3 — Cohort state model v1: initialise N herbivores with unique IDs
**Outcome**  
A cohort of herbivores can be represented and initialised reproducibly, with per-individual parameters (mass/type/targets/etc.) and unique IDs.

**Scope**
- In:
  - cohort schema in scenarios,
  - initialisation of multiple individuals,
  - invariant checks per individual.
- Out:
  - direct social interactions between herbivores.

**Acceptance criteria**
- A scenario can specify multiple individuals with heterogeneous parameters.
- Outputs contain per-herbivore rows keyed by herbivore_id.
- Tests verify:
  - correct number of herbivores initialised,
  - stable IDs,
  - deterministic initial states under fixed seed.

**Artefact evidence**
- Canonical cohort scenario artefact folder exists.
- Tests cover cohort initialisation and output presence.

**Stop condition**
- Cohort initialisation is stable and ready for multi-herbivore simulation.

---

### WP-0.5.4 — Multi-herbivore runner v1: deterministic ordering rules + tests
**Outcome**  
Within a day, multiple herbivores can act on the shared plant grid with explicitly documented and tested update ordering rules.

**Scope**
- In:
  - deterministic ordering (e.g., by herbivore_id) documented,
  - within-day coupling semantics defined (how plant removal is applied),
  - tests verifying determinism and basic plausibility.
- Out:
  - parallel execution (may be considered later if needed).

**Acceptance criteria**
- The same cohort scenario and seed produce identical outputs across runs.
- Ordering rules are documented in architecture/workflow docs.
- Tests assert:
  - determinism for cohort runs,
  - non-negativity of plant pools under multiple removals,
  - no herbivore sees stale/undefined plant state.

**Artefact evidence**
- Cohort canonical run artefacts exist (manifest + per-herbivore outputs + plant snapshots).
- Tests cover ordering determinism.

**Stop condition**
- Multi-herbivore simulation is reproducible and safe.

---

### WP-0.5.5 — Implicit stocking-density mode v1 (representative herbivore visitation)
**Outcome**  
An “implicit” population mode exists: one representative herbivore per type per plot can be used, with visitation/intensity parameterised by stocking density. This supports macroecological questions without simulating large explicit cohorts.

**Scope**
- In:
  - scenario fields for stocking density/visitation,
  - clear semantics for how visitation translates into herbivory pressure,
  - tests for reproducibility and interpretability.
- Out:
  - cross-plot movement networks.

**Acceptance criteria**
- Scenario can run in implicit mode and produces outputs explicitly labelled as implicit.
- Outputs include:
  - effective visitation/intensity parameters used,
  - comparable daily metrics to explicit mode (where meaningful).
- Tests confirm:
  - deterministic visitation outcomes under fixed seed (if stochastic),
  - sanity invariants (no negative pools, finite outputs).

**Artefact evidence**
- An implicit-mode reference scenario exists with canonical outputs.
- Docs describe when to use implicit vs explicit modes.
- Log entry includes interpretive notes on implicit semantics.

**Stop condition**
- Implicit mode is usable, interpretable, and clearly distinguished from explicit cohorts.

---

### WP-0.5.6 — Performance budget gate + profiling evidence
**Outcome**  
Performance is controlled and regressions are prevented. The project has an explicit “small scenario” budget suitable for CI and laptops.

**Scope**
- In:
  - define a bounded performance target (runtime + memory) for a reference scenario,
  - add a test or CI check that fails on major regressions,
  - record profiling evidence and hotspots.
- Out:
  - premature micro-optimisation that changes scientific meaning.

**Acceptance criteria**
- A reference scenario completes within a defined runtime budget on CI profile.
- A regression guard exists (test or CI check).
- A log entry records observed performance and (if needed) a short hotspot summary.

**Artefact evidence**
- Performance gate test/check exists and is documented.
- Log entry includes runtime/memory observations.

**Stop condition**
- Performance is bounded and monitored; the model remains usable.

---

### WP-0.5.7 — Plant backend interface boundary (internal TTR behind interface, no behaviour change)
**Outcome**  
The plant model is cleanly encapsulated behind a backend interface, enabling:
- internal TTR (default) for coupled multi-PFT runs, and
- optional external benchmarking backends later.

**Scope**
- In:
  - define backend interface contract (init/step/apply_herbivory/observe),
  - ensure internal TTR conforms without changing behaviour.
- Out:
  - rewriting plant maths or matching external package APIs.

**Acceptance criteria**
- The internal TTR backend passes all existing tests and canonical scenario outputs remain unchanged (except for metadata/manifest improvements if planned).
- Backend interface is documented.
- Tests confirm that swapping backend implementations is possible (even if only one backend exists at this WP).

**Artefact evidence**
- Architecture docs updated to describe backend boundary.
- Canonical runs show no unintended behavioural change (regression test passes).
- Log entry documents comparison/verification.

**Stop condition**
- Plant model is modularised without scientific drift.

---

### WP-0.5.8 — TTR.PGM optional benchmark harness + conditional tests
**Outcome**  
TTR.PGM is integrated as an optional benchmark/validation tool (not the default coupled backend), providing credibility checks in overlap cases.
Read `docs/TTR_PGM.md` for details on the R package.

**Scope**
- In:
  - optional dependency wiring (Suggests),
  - conditional tests that run only when TTR.PGM is available,
  - a benchmark scenario where “overlap” is meaningful (single species/simplified conditions).
- Out:
  - replacing the internal multi-PFT plant engine.

**Acceptance criteria**
- The package passes without TTR.PGM installed (CI remains green).
- When TTR.PGM is installed, benchmark tests run and produce:
  - a comparison artefact set (internal vs TTR.PGM),
  - documented metrics and tolerances.
- Divergences are explained in docs/logs (not silently ignored).

**Artefact evidence**
- Conditional benchmark tests exist.
- Benchmark artefact folder exists and includes a short comparison report/summary.
- Decision record clarifies: “TTR.PGM is benchmark-only unless/until it supports required multi-PFT coupling.”

**Stop condition**
- Benchmark harness is real, reproducible, and doesn’t burden default users.

---

### WP-0.6.1 — Vegetation structure & fuel metrics output contract
**Outcome**  
Outputs explicitly support “vegetation structure/community composition/fuels” questions by including stable, documented derived metrics (without requiring users to reverse-engineer from raw pools).

**Scope**
- In:
  - define fuel-relevant metrics (e.g., herbaceous biomass pools, fine fuels proxy),
  - define structure metrics (e.g., height distributions, browseable biomass),
  - add them to output contract and tests.
- Out:
  - fire spread simulation (not required).

**Acceptance criteria**
- Output contract includes documented structure/fuel metrics with units.
- Canonical scenarios produce those metrics.
- Tests ensure metrics are present, finite, and non-negative where appropriate.

**Artefact evidence**
- Schema docs updated with metric definitions.
- Canonical run outputs include metrics columns/tables.
- Log entry includes inspection notes (do the metrics look plausible?).

**Stop condition**
- Fuel/structure questions become directly answerable from outputs.

---

### WP-0.6.2 — Reference scenario library v1 (curated scenarios + expected outcomes)
**Outcome**  
The project’s scientific arc is encoded as a small set of curated scenarios with stated hypotheses/expected qualitative outcomes and reproducible artefacts.

**Scope**
- In:
  - 3–5 curated scenarios covering key questions,
  - each has: scenario definition, expected outcomes, canonical artefacts, and interpretation notes.
- Out:
  - exhaustive scenario sweeps.

**Acceptance criteria**
- Each reference scenario has:
  - a stable scenario definition (YAML or scenario object),
  - a manifest and canonical outputs,
  - a short “expected outcomes” section (qualitative, falsifiable),
  - a short “how to interpret outputs” section.
- Tests confirm scenarios remain runnable and produce required outputs.

**Artefact evidence**
- `artefacts/canonical_runs/` contains one folder per reference scenario.
- A documentation index exists listing the scenarios and their purpose.
- Log entry summarises scenario library contents.

**Stop condition**
- The scenario library exists and makes the intended paper experiments obvious.

---

### WP-0.6.3 — LARGE: Experiment A (presence vs removal) with report + artefacts
**Outcome**  
A reproducible experiment demonstrates how herbivore presence/removal affects vegetation structure/composition and fuels, using the reference scenario system.

**Scope**
- In:
  - paired scenarios: “herbivores present” vs “herbivores removed”,
  - outputs summarised into a short experiment report with plots/tables.
- Out:
  - parameter calibration to real sites (not required).

**Acceptance criteria**
- Artefacts exist for both scenarios with manifests and stable outputs.
- The experiment report states:
  - the experimental design,
  - the expected direction of effects,
  - what was observed in outputs (with references to tables/plots),
  - limitations/assumptions.
- At least one metric changes in the expected direction and is explained.

**Artefact evidence**
- Two canonical run folders exist (present/removal).
- A report document exists referencing those folders and including plots/tables.
- Log entry records sanity inspection and notes any surprises.

**Stop condition**
- The experiment is reproducible end-to-end and interpretable without reading code.

---

### WP-0.6.4 — LARGE: Experiment B (grazer vs browser vs mixed) with report + artefacts
**Outcome**  
A reproducible experiment demonstrates functional-type differences: diet partitioning, vegetation stratification, and evidence consistent with “browser trap” dynamics in simplified form.

**Scope**
- In:
  - three scenarios or one scenario with three cohorts/strategies,
  - report focusing on diet composition, plant part removal, and structure metrics.
- Out:
  - long-term demographic tree recruitment modelling.

**Acceptance criteria**
- Artefacts exist for grazer, browser, and mixed feeder conditions.
- Report includes:
  - diet composition comparisons,
  - structure metrics comparisons (e.g., browseable biomass, height-related accessibility proxies),
  - interpretation linking observed outcomes to model mechanisms.
- Expected qualitative distinctions are observed and explained.

**Artefact evidence**
- Canonical run folders exist for all three strategies.
- Report document with plots/tables exists and references artefacts.
- Tests ensure these scenarios remain runnable.

**Stop condition**
- Functional-type story is paper-ready and reproducible.

---

### WP-0.6.5 — LARGE: Experiment C (aridity/productivity limits) with report + artefacts
**Outcome**  
A reproducible experiment demonstrates how climatic constraints (aridity/productivity) limit herbivore activity (foraging time, movement, diet composition, drinking) and thereby alter vegetation impacts.

**Scope**
- In:
  - a small gradient or factorial scenario set (few points, not a huge sweep),
  - report focusing on activity limitation and resulting vegetation effects.
- Out:
  - full climate forcing datasets and global runs.

**Acceptance criteria**
- Artefacts exist for each gradient point with manifests.
- Report documents:
  - the forcing changes across gradient points,
  - expected outcomes (e.g., increased drinking costs, reduced intake),
  - observed outputs supporting/contradicting expectations.
- Results are interpretable and connected to explicit output metrics.

**Artefact evidence**
- Canonical run folders exist for each gradient point.
- Report document exists with plots/tables and references artefacts.
- Log entry records sanity checks (no numeric instability across gradient).

**Stop condition**
- The climate-limitation story is reproducible and defensible.

---

### WP-0.6.6 — Benchmark appendix: internal TTR vs TTR.PGM overlap case (report + artefacts)
**Outcome**  
A short benchmark appendix provides credibility: where models overlap, internal TTR is compared to TTR.PGM outputs, with documented agreements/disagreements.

**Scope**
- In:
  - one overlap scenario (single species, simplified forcing),
  - a short benchmark report and artefacts.
- Out:
  - forcing the coupled model to use TTR.PGM as the default backend.

**Acceptance criteria**
- Benchmark artefacts exist and are reproducible.
- Report explains:
  - what was compared,
  - how parameters were aligned (at a conceptual level),
  - what matches and what doesn’t, and why.

**Artefact evidence**
- Benchmark canonical folder exists (internal vs TTR.PGM outputs).
- Report document exists referencing the folder.
- Conditional tests exist (from WP-0.5.8) and are passing.

**Stop condition**
- Benchmark can be cited as a validation/consistency check.

---

### WP-0.6.7 — Paper pipeline skeleton: Quarto report renders from scenario artefacts
**Outcome**  
The repository can render a paper-style report that pulls results from canonical scenario artefacts, making the scientific narrative executable.

**Scope**
- In:
  - a Quarto report that renders without manual intervention,
  - uses artefacts as inputs (not ad hoc reruns),
  - produces figure outputs stored in a stable location.
- Out:
  - final journal-ready manuscript polish.

**Acceptance criteria**
- The report renders successfully from a clean environment after restoring dependencies and generating artefacts.
- Figures/tables are generated from scenario artefacts and include captions and references to scenario IDs.
- The report includes at least:
  - model overview,
  - “day-in-life” vignette summary,
  - experiment A/B/C summary stubs (can be brief, but real).

**Artefact evidence**
- Rendered report output exists (location per repo convention).
- Figures exist as files referenced by the report.
- Log entry records successful render and any caveats.

**Stop condition**
- The “paper story” is executable and reproducible from artefacts.

---

### WP-1.0.1 — API freeze + deprecation policy + final user docs
**Outcome**  
The user-facing API is stable and documented. Future breaking changes require explicit deprecation and versioning.

**Scope**
- In:
  - explicit list of supported entry points,
  - deprecation policy documented,
  - README/vignettes updated to match final scenario workflow.
- Out:
  - adding major new scientific modules (demography, soil cycling).

**Acceptance criteria**
- Public API is documented and stable; exports are intentional.
- Deprecation policy exists and is referenced in docs.
- README quickstart uses scenario workflow and canonical outputs.

**Artefact evidence**
- Docs updated (README, vignettes, architecture).
- Log entry records final API surface.

**Stop condition**
- The API is ready for external users and stable citations.

---

### WP-1.0.2 — Release artefact pipeline: build + reference outputs + changelog
**Outcome**  
Releases become repeatable and evidence-based: built artefacts and reference outputs accompany tags.

**Scope**
- In:
  - changelog discipline,
  - release checklist alignment,
  - generating and packaging reference outputs for release.
- Out:
  - CRAN submission (optional; not required by this WP unless explicitly decided).

**Acceptance criteria**
- Release artefacts include:
  - built package artefact,
  - reference scenario output bundle,
  - updated changelog entry for the version.
- Release checklist passes (as documented in repo).

**Artefact evidence**
- Release bundle folder exists (stable location).
- Changelog updated.
- Log entry documents checklist run and outcomes.

**Stop condition**
- A release candidate can be produced reliably.

---

### WP-1.0.3 — External reproducibility run-through documented (clean restore → run)
**Outcome**  
A third party can reproduce results: restore dependencies, run reference scenarios, and inspect outputs using only documentation.

**Scope**
- In:
  - documented run-through steps and expected outputs,
  - validation that the run-through works in a clean environment (container or CI).
- Out:
  - performance tuning for massive runs.

**Acceptance criteria**
- A documented run-through exists and is verified.
- The run-through yields the expected artefact folders and report outputs.

**Artefact evidence**
- A run-through document exists (location per repo convention).
- Log entry records the clean run-through verification.

**Stop condition**
- Reproducibility is externally credible.

---

### WP-1.0.4 — v1.0 RC bundle prepared for PI sign-off
**Outcome**  
Everything required for PI/human approval is bundled: clean checks, reference artefacts, and an executable paper-style report.

**Scope**
- In:
  - final check-clean confirmation,
  - reference artefacts,
  - report render.
- Out:
  - new feature development.

**Acceptance criteria**
- All quality gates are green.
- Reference scenarios and experiments are present as artefacts and interpretable via docs/reports.
- A PI review ZIP is ready (per review gates below).

**Artefact evidence**
- Release candidate artefacts exist.
- A final log entry summarises RC contents and any known limitations.

**Stop condition**
- Codex stops and requests PI sign-off.

---

## 5) Milestone / review gates (when Codex must stop and request a PI review ZIP)

Codex must stop and request a PI review ZIP under any of these conditions:

1. **After completing each line**:
   - After WP-0.3.9 (end of 0.3.x)
   - After WP-0.4.8 (end of 0.4.x)
   - After WP-0.5.8 (end of 0.5.x)
   - After WP-0.6.7 (end of 0.6.x)
   - After WP-1.0.4 (v1.0 RC)

2. **After any schema_version bump** (immediate stop):
   - Prepare ZIP + short summary of schema changes + migration tests added.

3. **After every 5 completed WPs**, even if a line is not finished:
   - This prevents long unreviewed drift and keeps autonomy aligned with PI intent.

4. **If a WP requires a scientific assumption change** that materially alters interpretation:
   - Codex must record the decision and stop for PI review before proceeding.

When requesting a PI review ZIP, include:
- the updated `docs/roadmap.md` with completed checkboxes,
- the latest `docs/log/` entries for the completed WPs,
- pointers to canonical run artefacts and reports produced.
