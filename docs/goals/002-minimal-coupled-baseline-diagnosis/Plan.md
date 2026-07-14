# Goal 002 Minimal Coupled Baseline Diagnosis Plan

> **For agentic workers:** Work from the completed-state contract in
> `Goal.md`. Use profile-bound workers through `codex-profile-exec`; native
> task-name-only spawning is prohibited until binding is proven. Use
> test-driven development for any new runner behaviour.

**Goal:** Diagnose one fixed-seed reproducible minimal animal-forage system without
tuning it, adding physiology, or expanding into realistic calibration.

**Architecture:** Keep the diagnostic system outside production defaults. A
single non-exported runner reads a complete named profile, constructs an
explicit homogeneous plant state, records the resolved initial herbivore
state, runs 120 constant-forcing days, and emits small reproducible evidence
files. Interpretation is performed from those
files and a traced state-accounting map, not from test success alone.

**Tech Stack:** R 4.6.x, `renv` 1.2.3, existing herbivoreTTR model functions,
YAML/JSON/CSV, `testthat`, base-R graphics, Git.

## Global Constraints

- Work only in `/Users/bwbrook/git/herbivoreTTR` on
  `codex/herbivore-ttr-goal-002`.
- Start from `7ea01321b3f6db398b6b6e549d2bfc478d93e420`.
- One synthetic herbivore, one forage type, constant forcing, one seed, and
  one 120-day primary run.
- Diagnose; do not tune, calibrate, optimize, or add mechanisms.
- Do not change existing defaults, reference scenarios, public APIs, output
  contracts, package version, or scientific thresholds.
- Use no new dependency and no remote compute.
- Generated evidence is ignored and must not be staged.
- Do not commit or push.

## Authorised File Map

Create:

- `inst/extdata/scenarios/goal002_minimal_coupled_v1.yaml`
- `scripts/run_goal002_minimal_diagnosis.R`
- `tests/testthat/test_goal002_minimal_diagnosis.R`
- `docs/log/20260712_goal002_minimal_coupled_diagnosis.md`

Update:

- `docs/goals/002-minimal-coupled-baseline-diagnosis/Goal.md`
- `docs/goals/002-minimal-coupled-baseline-diagnosis/Plan.md`
- `docs/goals/002-minimal-coupled-baseline-diagnosis/Runbook.md`
- `docs/goals/002-minimal-coupled-baseline-diagnosis/Log.md`

Generate but do not stage:

- `artefacts/goal002_minimal_coupled/run-a/`
- `artefacts/goal002_minimal_coupled/run-b/`

No other tracked file may change without orchestrator approval and, where it
would alter science or public behaviour, Barry's approval.

## Task 1: Lock The Diagnostic Contract

- [x] Record branch, HEAD, status, runtime, and synchronized `renv` state in
  `Log.md` before any model command.
- [x] Use `luna_light_scout` only for read-only confirmation of existing entry
  points, fields, and tests; retain the profile-runner provenance files.
- [x] Define the complete synthetic configuration in the Goal 002 YAML,
  including fixed seed, 120 days, one explicit herbivore, one forage type,
  constant external drivers, and explicit initial plant state values or their
  manifest-linked table.
- [x] Write focused tests that fail unless the resolved diagnostic profile is
  genuinely constant and the plant state is explicit. Require the complete
  resolved herbivore state to be recorded before stepping. Assert values, not
  labels.
- [x] Record the focused RED evidence in `Log.md`.

Deliverable: one inspectable configuration contract whose intended invariants
are executable and initially fail because the Goal 002 runner does not exist.

## Task 2: Build The Smallest Diagnostic Runner

- [x] Use one `luna_high_executor` with ownership of the authorised scenario,
  script, and focused test files. It must not interpret scientific results.
- [x] Implement the exact CLI in `Runbook.md` without exporting a package API
  or modifying production defaults.
- [x] Construct the initial plant state explicitly and verify the resulting
  state before model stepping begins.
- [x] Emit the five named evidence files with stable schemas and no timestamps
  embedded in repeatability-tested CSV/JSON content.
- [x] Include the resolved configuration, seed, Git SHA, R version, input
  hashes, output hashes, row counts, and run status in `run_manifest.json`.
- [x] Reach focused GREEN, then perform worker self-review and report the exact
  changed paths.

Deliverable: a fixed-seed reproducible, non-exported harness that produces compact
diagnostic evidence from the one authorised profile.

## Task 3: Run And Diagnose The Baseline

- [x] Execute the runner into fresh `run-a` and `run-b` directories using the
  commands in `Runbook.md`.
- [x] Prove fixed-seed repeatability of the diagnostic CSV and JSON content;
  do not present this as absence of stochastic processes within the run.
- [x] Inspect daily trajectories and summarize complete-run, first-half, and
  second-half behaviour for plant biomass, intake, energy, water, movement,
  body condition, deficit streaks, and physiological stress. Label the halves
  as arbitrary descriptive windows, not formal stability tests.
- [x] Trace every interpreted field to its update location and document what
  resets daily, carries forward, accumulates, or is absent.
- [x] Use one `sol_high_specialist` for the difficult synthesis of interacting
  state and feedbacks. Require observation/inference separation, material
  assumptions, uncertainty, and checks performed.
- [x] Name the existing model thresholds behind the stress indicator, then
  classify the evidence without changing the run, choosing a biological
  threshold, or launching a counterfactual. Treat suspected parameter scale as
  a hypothesis unless an internal inconsistency proves it.
- [x] Recommend exactly one bounded next goal. If evidence is ambiguous,
  recommend the smallest discriminating experiment rather than resolving it
  inside Goal 002.

Deliverable: an ecologist-readable diagnosis backed by machine-readable daily
evidence and an explicit state-accounting map.

## Task 4: Validate And Review

- [x] Run the focused tests, full unit suite, lint, environment, and diff gates
  in `Runbook.md`.
- [x] Inspect all five generated artefacts directly, including the rendered
  trajectory figure, and record exact paths and decisive observations.
- [x] Confirm that the diff contains only the authorised Goal 002 paths and no
  generated artefact.
- [x] Use one independent `sol_medium_scientist` to review scope compliance,
  diagnostic reasoning, uncertainty, and the proposed next goal.
- [x] Resolve every Critical or Important finding within the existing write
  surface, or stop if resolution would broaden the goal.
- [x] Record final branch, HEAD, exact changed paths, validation results,
  artefact evidence, reviewer verdict, and no-commit/no-push state.

Deliverable: a reviewed Goal 002 evidence package ready for Barry's scientific
discussion and a decision on the next bounded goal.
