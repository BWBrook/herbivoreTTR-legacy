# Goal 003 Herbivore-Only Daily-Clamped Forage Reference Plan

> **For later executors:** This plan is not execution authority. Work from the
> completed-state contract in `Goal.md`, use focused test-driven development,
> and stop at every authority or scientific boundary below.

**Goal:** Produce a fixed-seed 120-day herbivore trajectory against the exact
Goal 002 plant snapshot restored daily, with growth disabled and all existing
within-day mechanisms unchanged.

**Architecture:** Use a new non-exported Goal 003 runner rather than modifying
or generalizing Goal 002. Load and validate a Goal 003 profile that reproduces
the accepted Goal 002 invariants. Resolve the initial herbivore and frozen
plant snapshot through existing semantics. At each day boundary, copy the
frozen plant object, prove the copy is exact without consuming RNG, pass it to
the existing daily model with `apply_growth = FALSE`, retain the returned
herbivore, record complete opening/closing plant evidence, and discard the
returned plant. Interpret only after the mechanical non-binding and accounting
gates pass.

**Scientific design:** One fixed-seed computational reference and one frozen
descriptive comparator. The unit is the single trajectory; days are dependent
repeated observations. The contrast removes both growth and inter-day plant
carryover and has no clean causal estimand.

## Global Constraints

- Work only in `/Users/bwbrook/git/herbivoreTTR`.
- Do not begin until the three publication/authority gates in `Goal.md` pass.
- Preserve the exact Goal 002 herbivore state, plant snapshot, forcing,
  locations, feedback, 720-minute loop, days 6--125, seed 2002, and daily seed
  offset 100000.
- Use `apply_growth = FALSE`; add no digestion-only ticks.
- Do not tune, inflate forage, change composition, calibrate, add sensitivity
  runs, run a plant-only model, or alter a mechanism/API.
- Use no new dependency and no remote compute.
- Goal 002 is read-only and is not regenerated.
- Generated Goal 003 evidence remains ignored.
- Do not stage, commit, or push without separate explicit authority.

## Intended File Map

Create during authorized implementation:

- `inst/extdata/scenarios/goal003_herbivore_reference_v1.yaml`
- `scripts/run_goal003_herbivore_reference.R`
- `tests/testthat/test_goal003_herbivore_reference.R`
- `docs/log/20260714_goal003_herbivore_reference.md`

Update only during authorized implementation:

- `docs/goals/003-herbivore-only-daily-clamped-forage-reference/Goal.md`
- `docs/goals/003-herbivore-only-daily-clamped-forage-reference/Plan.md`
- `docs/goals/003-herbivore-only-daily-clamped-forage-reference/Runbook.md`
- `docs/goals/003-herbivore-only-daily-clamped-forage-reference/Log.md`

Generate but do not stage:

- `artefacts/goal003_herbivore_reference/run-a/`
- `artefacts/goal003_herbivore_reference/run-b/`

No production `R/` file, Goal 002 file, or other tracked path may change. If
one appears necessary, stop and request Barry's decision.

## Task 1: Publication Gate And Invariant Lock

- [x] Record Barry's exact authorization to publish the accepted Goal 002
  eight-path footprint.
- [x] Confirm those eight paths, and only those paths, are committed as the
  baseline; record branch, commit, and clean/known working-tree state.
- [x] Record Barry's separate authorization to execute Goal 003.
- [x] Verify the frozen Goal 002 manifest, configuration, and output-set hashes
  against the accepted values without rerunning Goal 002.
- [x] Transcribe and validate the complete Goal 002 initial herbivore state,
  all digestion queues, complete initial plant snapshot, forcing, feedback,
  horizon, model-day mapping, active-loop duration, and seed schedule into the
  Goal 003 contract.
- [x] Assert the design-specific values `apply_growth = FALSE`, daily plant
  restoration, `MIN_SHOOT = 0.001 kg`, `M_REF = 10 kg`, and numerical
  composition tolerance `1e-10`.

Deliverable: a recorded authority chain and an inspectable configuration whose
only scientific intervention is the accepted daily plant clamp plus disabled
growth.

## Task 2: Focused RED/GREEN Runner Contract

- [x] Write focused tests before the runner exists and retain RED evidence
  caused only by the absent Goal 003 contract.
- [x] Test that the reset helper returns a plant object exactly identical to
  the frozen snapshot and leaves a sentinel herbivore object and `.Random.seed`
  exactly unchanged.
- [x] Test with a synthetic altered closing plant that day 2 opens from the
  frozen snapshot rather than day 1 closing state.
- [x] Test exact initial herbivore and digestion-queue equality with Goal 002,
  daily seeds `2002 + i * 100000`, days 6--125, 720 minutes, constant forcing,
  and unchanged feedback/foraging settings.
- [x] Test that the runner passes `apply_growth = FALSE` and rejects any
  profile enabling growth, changing biomass/composition, or requesting extra
  ticks.
- [x] Test required complete opening/closing plant columns, state hashes,
  non-binding fields, accounting fields, manifest provenance, absent output
  directory, and stable artefact names.
- [x] Reach GREEN with zero failures and warnings, then inspect the exact diff.

Deliverable: focused executable acceptance criteria for the reset boundary and
diagnostic evidence, without changing production code.

## Task 3: Diagnostic Runner

- [x] Implement only the new non-exported runner and profile using existing
  model functions and dependencies.
- [x] Resolve the frozen snapshot once from the Goal 003 profile, using the
  complete accepted Goal 002 values; record its canonical state digest.
- [x] At every day start, make an exact fresh copy, assert identity to the
  frozen object, and call `run_daily_herbivore_simulation()` with the existing
  herbivore, exact daily seed, `capture_diagnostics = TRUE`,
  `apply_growth = FALSE`, `plant_backend = "internal_ttr"`, and forage access
  scale 1.
- [x] Carry only the returned herbivore into the next day. Record and then
  discard the returned plant state.
- [x] Emit stable manifest, daily herbivore diagnostics, complete prefixed
  opening/closing plant diagnostics, summary, and trajectory figure with no
  timestamps in repeatability-tested content.
- [x] Record daily state hashes, within-day dry-matter and qshoot drawdown,
  component proportions, nutrient ratio, eligibility, minimum distance,
  gut-capacity bound, and all energy/water/plant accounting residuals using
  existing state and minute diagnostics rather than bite-level instrumentation.
- [x] Abort before writing a complete manifest if any stop rule fails.

Deliverable: the smallest auditable daily-clamp harness; no production code or
public interface change.

## Task 4: Two Authorized Clean Realizations

- [x] Reconfirm authority and an absent `run-a`/`run-b` before execution.
- [x] Execute the one profile into fresh `run-a` and `run-b` directories using
  the exact commands in `Runbook.md`.
- [x] Require byte-identical scientific outputs and matching configuration and
  output-set digests; describe this only as fixed-seed computational
  repeatability.
- [x] Inspect every CSV, JSON, manifest, and rendered figure directly.
- [x] Run no additional seed, horizon, scenario, counterfactual, plant-only
  model, digestion-only ticks, or sensitivity analysis.

Deliverable: two clean deterministic realizations of the same stochastic
schedule, or a stopped run with the failed gate preserved.

## Task 5: Nonlimitation, Accounting, And Frozen Comparison

- [x] Prove for every day that closing shoot is the within-day minimum,
  closing shoot exceeds `M_REF` and `MIN_SHOOT`, and closing available shoot
  above `MIN_SHOOT` exceeds that day's gut capacity in kg.
- [x] Require positive qshoot; stable qshoot/shoot, leaf/shoot, stem/shoot,
  defence/shoot, and selection nutrient ratios within absolute tolerance
  `1e-10`; and exact identity of all non-consumed plant fields.
- [x] Prove the single plant remains present, eligible, detectable, reachable,
  positively scored, and co-located for eating throughout the active loop.
- [x] Prove all 120 opening hashes equal the frozen hash and that altered daily
  closing states are not next-day opening states.
- [x] Reconcile dry-matter drawdown to herbivore intake, qshoot drawdown to
  forage-water intake, component sums to shoot mass, and daily/cumulative
  energy and water identities within documented floating-point tolerances.
- [x] Require finite values, non-negative pools, BCI in [0,1], gut content not
  above capacity, complete 120-day coverage, and the unchanged seed schedule.
- [x] Compare Goal 003 descriptively with the frozen accepted Goal 002 daily
  evidence: trajectory direction, magnitude, persistence, timing of BCI floor,
  energy deficit, intake/gut alternation, water closure, movement, and plant
  drawdown. Do not rerun or edit Goal 002.
- [x] Stop without adjustment on any failed bound or accounting check.

Deliverable: an evidence-backed classification of whether plant availability
was non-binding and a descriptive, non-causal contrast with Goal 002.

## Task 6: Scientific Synthesis And Independent Review

- [x] Write `docs/log/20260714_goal003_herbivore_reference.md` with explicit
  observation/code-trace/inference labels, the complete reset/carryover map,
  numerical checks, result, assumptions, and uncertainties.
- [x] Apply the interpretation contract in `Goal.md` regardless of whether the
  decline persists or changes; make no equilibrium, viability, taxon-realism,
  causal, or long-run claim.
- [x] Obtain independent profile-bound scientific review of design fidelity,
  non-binding proof, accounting, comparator integrity, and interpretation.
- [x] Resolve every Critical or Important finding within the intended file
  map, or stop if resolution broadens the goal.

Deliverable: an ecologist-readable synthesis with no open Critical or
Important review issue.

## Task 7: Validation And No-Publish Closeout

- [x] Run the focused test, full unit suite, lint, `renv`, structured evidence,
  hash/diff, and artefact-review gates in `Runbook.md`.
- [x] Run `make smoke` or `make check` only if a production/installed-package
  surface was touched; because that condition violates the preferred design,
  stop and obtain scope authority before those commands.
- [x] Confirm only the intended Goal 003 tracked paths changed and generated
  evidence is ignored.
- [x] Record final branch, HEAD, paths, validation results, artefact findings,
  independent verdict, and all retained review provenance.
- [x] Do not stage, commit, or push unless Barry separately authorizes that
  specific action after reviewing the result.

Deliverable: reviewed Goal 003 evidence ready for Barry's decision, or a clear
stopped-state report preserving the first failed scientific gate.
