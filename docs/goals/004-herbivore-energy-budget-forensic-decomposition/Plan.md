# Goal 004 Herbivore Energy-Budget Forensic Decomposition Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use a bounded, test-driven
> execution workflow and obtain independent scientific review before
> acceptance. This plan is not execution or publication authority.

**Goal:** Produce an exact mass-energy-time decomposition of the accepted Goal
003 herbivore deficit and one evidence-backed correction decision without
changing production semantics or parameters.

**Architecture:** Use a Goal 004-only profile, pure ledger helpers, and a
non-exported diagnostic runner. Reproduce the three accepted Goal 003 machine-
readable outputs first, prove exact state/RNG identity between Goal 004's bare
control and observer branches, expose a minute-720 pre-closure clone point,
then run only the predeclared one-factor probes. Classify mechanisms through
the decision tree in `Goal.md` and stop before implementation of any
correction.

**Tech stack:** existing R package and `renv`; base R, `testthat`, `yaml`,
`jsonlite`, and `digest`; no new dependency or remote compute.

## Global Constraints

- Work only in `/Users/bwbrook/git/herbivoreTTR`.
- Do not execute until Goal 003 is committed as the immutable comparator and
  Barry separately authorizes Goal 004 execution.
- Preserve Goal 003 seed, state, forage, forcing, feedback, horizon, and
  production functions exactly in the observer baseline.
- Use no production `R/` edit, exported API change, default change, parameter
  change, or output-contract change.
- Stable BCI is not a target; do not tune toward it.
- One intervention per probe; record exact invariants and first divergence.
- Generated scientific evidence stays ignored.
- Do not stage, commit, push, or publish without separate explicit authority.

## Intended File Map

Create during authorized execution:

- `inst/extdata/scenarios/goal004_energy_decomposition_v1.yaml`
- `scripts/goal004_energy_ledger_helpers.R`
- `scripts/run_goal004_energy_decomposition.R`
- `tests/testthat/test_goal004_energy_decomposition.R`
- `docs/log/20260714_goal004_energy_budget_decomposition.md`

Update only during authorized execution:

- `docs/goals/004-herbivore-energy-budget-forensic-decomposition/Goal.md`
- `docs/goals/004-herbivore-energy-budget-forensic-decomposition/Plan.md`
- `docs/goals/004-herbivore-energy-budget-forensic-decomposition/Runbook.md`
- `docs/goals/004-herbivore-energy-budget-forensic-decomposition/Log.md`

Generate but do not stage:

- `artefacts/goal004_energy_decomposition/run-a/`
- `artefacts/goal004_energy_decomposition/run-b/`

Any needed production `R/`, package metadata, lockfile, Goal 003, unrelated
test, public documentation, or additional source path is a stop-and-escalate
event.

## Task 1: Authority, Comparator, And Contract Lock

- [x] Record Barry's authorization for a local commit of the exact accepted
  Goal 003 footprint and the resulting immutable baseline commit; push or
  publication is neither required nor authorized.
- [x] Record Barry's separate Goal 004 execution authorization.
- [x] Verify Goal 003 commit, eight-path tree/content digest, profile, runner,
  test, manifest, configuration, content, and frozen-state hashes without
  regenerating Goal 003; require no comparator-path worktree modification.
- [x] Implement exactly the production-state projection, serialization,
  comparator artefacts, RNG vectors, exclusions, and first-divergence order
  predeclared in `Goal.md`; do not select fields during execution.
- [x] Lock the Goal 003 initial state, 120-day schedule, daily seeds, forcing,
  plant reset, non-binding evidence, and 720-minute semantics in the Goal 004
  profile.
- [x] Encode the eight probe definitions, single interventions, invariants,
  responses, and allowed inferences from `Goal.md`.
- [x] Reject any profile requesting a parameter change, production mode, extra
  seed, alternative taxon, plant change, or stability target.

Deliverable: an inspectable configuration whose only changes are observer
capture and predeclared diagnostic counterfactuals.

## Task 2: Focused RED/GREEN Contract

- [x] Write focused tests before helper or runner implementation and retain RED
  evidence caused only by absent Goal 004 functions/contracts.
- [x] Test exact production-projection and caller/exit RNG equality between
  Goal 004 bare-control and observer branches, plus exact reproduction of Goal
  003 daily, plant, and summary outputs; do not claim direct Goal 003 RNG
  equality because Goal 003 did not retain those vectors.
- [x] Test queue ledger transitions for all eight queues, including insertion,
  normalization/resizing adjustment, terminal release, and closing inventory.
- [x] Test independent dry matter, digestible-carbohydrate, digestible-protein,
  and released-energy reconciliation at the scale-aware tolerance.
- [x] Test raw slot capture, bite-derived insertions, unique ordered tick keys,
  exact queue shifting, within-day interval chaining, and applicable day-
  boundary continuity without trusting stored residuals.
- [x] Test impulse release immediately before and after an hourly boundary.
- [x] Test that exactly 12 additional pre-closure ticks consume no RNG and
  alter no feeding, movement, plant, requirement, or pre-closure drinking
  state.
- [x] Test the exact 720-call, plant-1, no-tick/no-closure deterministic
  capacity replay predeclared in `Goal.md`, with separate identical plants and
  no RNG.
- [x] Test raw bite-limit attribution, tie bitmask, positive bite identity, and
  classified eligible no-bite reasons.
- [x] Test feedback projection equality rules and direct minute-720 endpoint
  clone semantics.
- [x] Test raw probe-invariant evidence against the fixed per-probe allowed-
  path table, including the capacity replay entry read-set and exact 720
  ordered opportunities in both branches.
- [x] Test exact raw snapshot record coverage and complete recursive changed-
  path reconstruction; reject omitted paths, partial hashes, empty equality
  values, schema drift, or a forbidden difference.
- [x] Test manifest hashes, stable artefact names, absent output directories,
  first-divergence fields, and scientific stop failures.
- [x] Reach GREEN with no failures or warnings before canonical execution.

Deliverable: executable acceptance criteria that fail on diagnostic
interference, accounting drift, confounded probes, and overbroad configuration.

## Task 3: Pure Ledger Helpers

- [x] Implement pure helpers that never consume RNG or mutate caller objects.
- [x] Represent each queue transition as raw slot rows with interval opening,
  bite-derived insertion, pre-tick state, adjustment, unmodified terminal
  slot, post-tick state, residual, scale, and tolerance fields.
- [x] Reconstruct released carbohydrate, protein, protein energy, non-protein
  energy, metabolic water, and total energy directly from terminal slots.
- [x] Require zero normalization/resizing adjustments in valid canonical
  states and preserve any non-zero adjustment as an explicit scientific stop.
- [x] Implement the complete production projection and exact `identical()`
  state/RNG comparator plus version-3 serialization hashes.
- [x] Implement the predeclared phase/root/path traversal order and raw first-
  divergence record.
- [x] Implement bite-limit calculations using the production formula and raw
  pre-step state, with handling, capacity, forage, mechanical, winning-limit,
  and tie fields.
- [x] Implement exactly 720 direct `herbivore_eat()` calls from unticked and
  +12-tick minute-720 clones, each with an exact frozen plant copy, fixed plant
  1 target, no early stop, and no tick, behaviour, movement, closure, reset,
  feedback, or RNG path.
- [x] Emit raw probe invariant rows and compare the capacity branches' complete
  intake-determining `herbivore_eat()` read sets, allowing only valid gut-
  content/digestion differences at replay entry.
- [x] Emit deterministic version-3 `probe_state_snapshots.rds` records with
  complete paired projections and immutable feeding constants; do not store an
  allowed-path list or pass flag in place of raw states.
- [x] Implement first state/RNG divergence reporting for carried comparisons.

Deliverable: small, separately testable accounting functions independent of
the orchestration harness.

## Task 4: Observer-Equivalent Baseline Harness

- [x] Reproduce Goal 003 daily orchestration in a Goal 004-only runner while
  calling production feeding, digestion, water, energy, and BCI functions
  unchanged.
- [x] Capture pre-step and post-step herbivore/plant state, bite insertion,
  hourly tick transition, day-boundary checkpoint, and exit RNG.
- [x] Expose the minute-720 checkpoint before plant finalisation, water/energy
  closure, and BCI update.
- [x] Produce baseline daily and plant outputs exactly equal to Goal 003 and
  prove observer-only capture leaves the Goal 004 bare-control projection and
  exit RNG unchanged.
- [x] Abort before semantic probes if equality fails at any day; report the
  first field and transition divergence.
- [x] Emit the baseline projection, hourly queue ledger, daily budget, and
  minute intake-limit evidence without timestamps or unstable paths.

Deliverable: observer-only evidence exactly equal to the Goal 004 bare-control
projection/RNG, with both branches reproducing accepted Goal 003 outputs.

## Task 5: Orthogonal Mechanical Probes

- [x] Run the tick-phase impulse probe with identical queue mass and tick count.
- [x] At each minute-720 checkpoint, clone state and apply exactly 12
  digestion-only ticks before a common closure; assign every release to the
  correct accounting day.
- [x] Reconcile the completed-clock branch before interpreting energy, water,
  gut content, or queue differences.
- [x] Run the predeclared fixed-opportunity replay and report only incremental
  intake relative to each branch's opening counters, limit sequence, final gut
  vacancy, and plant drawdown.
- [x] Confirm the capacity read-set gate from `Goal.md`; otherwise downgrade
  the label to a completed-clock-state effect under fixed replay.
- [x] Record the baseline intake-limit distribution, ties, no-bite reasons,
  remaining capacity, and an algebraic break-even intake equal to implemented
  total requirement divided by frozen-composition scheduled kJ/g DM; label it
  a diagnostic identity, never a calibration target.
- [x] Calculate zero-locomotion energy balance algebraically without changing
  the model state.
- [x] Run the feedback-disabled matched probe and compare the predeclared
  production projection, not intervention metadata.
- [x] Evaluate endpoint-inclusive minute 720 from an identical minute-719
  clone and report only its direct consequence.
- [x] Preserve each probe's invariant table and stop on any second changed
  factor.

Deliverable: a probe table that supports conditional mechanism statements
without conflating clock, capacity, demand, feedback, or endpoint effects.

## Task 6: Optional Total Downstream Clock Contrast

Status: completed by the predeclared `not_run` path. The isolated probes
provided the required decision evidence, while a carried contrast would be
non-identifiable after behaviour or RNG topology diverged.

- [x] Decide after Tasks 1--5 whether the carried contrast adds decision value;
  record `complete` or `not_run` plus a reason. Omission is non-blocking.
- [ ] Not applicable: if run, proceed only after the pre-closure intervention
  is isolated.
- [ ] Not applicable: execute one matched 120-day control/completed-clock pair with no other
  intervention, retaining the same exogenous seed schedule.
- [ ] Not applicable: record the first state divergence and first RNG divergence.
- [ ] Not applicable: report total differences in queue inventory, intake, released energy,
  requirement, energy delta, BCI, stress, and plant removal.
- [ ] Not applicable: if RNG call topology or behaviour diverges, label the result a total
  downstream policy contrast and make no unique gut-capacity or behavioural
  attribution.
- [x] Do not add another clock convention, parameter, seed, or sensitivity run.

Deliverable: one bounded total-effect diagnostic or an explicit non-blocking
skip reason. Neither outcome changes acceptance of the isolated decomposition.

## Task 7: Classification And Correction Decision Memo

- [x] Classify every axis as implementation/contract defect,
  parameter-plausibility question, intended behaviour here, non-operative here,
  or unresolved interaction using the predeclared tree.
- [x] Separate observations, identities, counterfactuals, and literature-
  dependent judgements in both JSON and prose.
- [x] Record the 719-minute endpoint result and the locomotion unit
  contradiction without silently choosing a convention.
- [x] Identify which parameter families, if any, need a later primary-source
  review; do not validate a biological coefficient from repository citation
  text alone.
- [x] Recommend at most one next production correction or one bounded
  literature/parameter-validation goal.
- [x] Require non-empty evidence identifiers for each classification, no
  dominant-cause claim, and a mutually exclusive single recommendation; if
  alternatives remain comparable, emit no recommendation and require Barry's
  decision.
- [x] If two corrections remain comparably supported, present the trade-off to
  Barry and stop without ranking them.
- [x] State explicitly that stable BCI, viability, causal ecological effect,
  parameter realism, and generality were not estimated.

Deliverable: `docs/log/20260714_goal004_energy_budget_decomposition.md` as the
ecologist-readable correction decision memo plus machine-readable
`classification_summary.json`.

## Task 8: Repeatability, Validation, And Independent Review

- [x] Generate clean run-a and run-b bundles from absent output directories.
- [x] Require byte identity across all thirteen canonical evidence files and
  matching source/configuration/comparator/output digests.
- [x] Inspect every CSV, JSON, manifest, and rendered figure directly.
- [x] Run the focused test, full unit suite, lint, synchronized `renv`,
  structured ledger/probe checks, `git diff --check`, and exact scope checks.
- [x] Do not run smoke/check/package/repro/targets/docs-build gates unless a
  prohibited production or package surface appears; stop for scope review if
  one does.
- [x] Obtain independent Sol High scientific review of time attribution,
  identifiability, classification, and correction recommendation.
- [x] Obtain independent code/evidence review of observer equivalence,
  conservation, RNG invariants, hashes, and source scope.
- [x] Resolve all Critical and Important findings within the authorized surface
  or stop if resolution requires a production or parameter change.
- [x] Retain executor RED/GREEN and validation evidence under
  `.superpowers/sdd/goal004-agents/executor/`, scientific review under
  `scientific-review/`, and final audit under `final-audit/`.
- [x] Record final branch, HEAD, paths, evidence hashes, validations, review
  verdicts, residual uncertainty, and no-publication state.

Deliverable: reviewed Goal 004 diagnostic evidence ready for Barry's correction
decision, with no production correction, parameter change, commit, or push.
