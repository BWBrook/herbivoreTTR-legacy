# Goal 003: Herbivore-Only Daily-Clamped Forage Reference

Status: accepted on 2026-07-14 after implementation, canonical evidence, full
validation, independent Sol High audit, one narrow interpretation correction,
and independent Sol Medium acceptance recheck. No staging, commit, push, or
publication is authorized by this execution request.

Owner: Herbivore TTR orchestrator.

Repository: `/Users/bwbrook/git/herbivoreTTR`.

Current branch: `codex/herbivore-ttr-goal-002`.

Current HEAD at execution start: `e45a6b79b4fb5474609e916aa91e49b4ccc878e2`.

## Scientific Question

What 120-day herbivore trajectory does the existing model produce when
inter-day vegetation dynamics are removed, while current plant selection,
bite handling, gut capacity, digestion, energetics, water closure, feedback,
and stochastic schedule remain unchanged?

The target estimand is the descriptive difference between:

- the accepted Goal 002 fixed-seed coupled trajectory; and
- one fixed-seed Goal 003 trajectory in which the exact Goal 002 complete
  pre-growth initial plant snapshot is restored at the start of every day and
  plant growth is disabled.

This is a computational reference contrast, not a causal effect estimate.
Goal 003 jointly removes plant growth and inter-day plant-state carryover, so
it cannot isolate depletion from growth or identify an ultimate physiological
cause.

## Accepted Design A

At the start of each diagnostic day, construct the plant argument as an exact
copy of the frozen Goal 002 complete pre-growth initial plant snapshot. Call
`run_daily_herbivore_simulation()` with `apply_growth = FALSE`. Preserve normal
within-day selection, eating, proportional shoot-pool depletion, qshoot
depletion, gut filling, digestion, energetics, water closure, feedback,
movement, and RNG schedule. Record the complete opening and closing plant
states and their within-day drawdown. Discard the altered closing plant state
after diagnostics, restore the exact frozen snapshot for the next day, and
carry the returned herbivore state forward normally.

This is a **finite but demonstrably non-binding daily forage reference**. It
must never be described as literally unlimited forage.

## Data-Generating And Observation Process

- One semi-synthetic 50,000 g herbivore and one homogeneous grass-like plant
  occupy the Goal 002 locations.
- The complete Goal 002 initial herbivore state, including all digestion
  queues, is retained; only the daily plant carryover rule and `apply_growth`
  setting differ.
- Seed `2002` constructs the initial state. Diagnostic day `i` uses seed
  `2002 + i * 100000`, exactly as in Goal 002.
- The model runs 120 temporally ordered diagnostic days corresponding to model
  days 6--125, with a 720-minute active loop each day.
- Temperature is 25 C, soil water is 0.5, and soil nitrogen is 0.5 throughout.
- Daily model outputs are deterministic under this fixed implementation,
  configuration, and seed schedule, but the process retains stochastic
  decisions. Two executions test computational repeatability.
- The experimental unit is the single simulated herbivore trajectory. Days
  are repeated, autocorrelated observations of that unit, not 120 independent
  replicates. Inference is restricted to this configuration, code revision,
  fixed stochastic schedule, and 120-day window.

Primary responses are daily intake, gut content, digested energy, energy
requirement and balance, water inputs and balance, body-condition index,
deficit streaks, stress flag, movement, and behaviour. The manipulated model
inputs are daily plant restoration and disabled growth. Fixed covariates are
the Goal 002 herbivore, forage composition and location, forcing, seed
schedule, horizon, active-loop duration, foraging mode, feedback, and all core
mechanisms. Day is the temporal index; there is no offset or independent
grouping factor. Uncertainty includes stochastic-schedule dependence,
temporal dependence, numerical tolerance, model structural assumptions, the
BCI floor, automatic water closure, and the unresolved 12-of-24 digestion
queue timing observed in Goal 002.

## Fixed Invariants

- Exact complete Goal 002 initial herbivore state and digestion queues.
- Seed 2002 and Goal 002 daily seed offsets.
- 120 days, model days 6--125, and a 720-minute active loop.
- Temperature 25 C, soil water 0.5, and soil nitrogen 0.5.
- Goal 002 water rule, body-condition feedback, plant composition and
  location, foraging mode, movement, selection, eating, digestion, and
  energetics.
- Exactly one plant and one herbivore.
- No 12 digestion-only ticks and no other overnight process.
- No tuning, calibration, plant-only run, sensitivity analysis, new mechanism,
  public API change, or production default change.

## Non-Binding Forage Contract

The reference is accepted only if the current model semantics establish the
following mechanical bound on every day:

1. `herbivore_eat()` sets potential intake to the minimum of the handling
   limit, remaining gut capacity, plant shoot available above
   `CONSTANTS$MIN_SHOOT`, and the mechanical cap.
2. Closing shoot is the within-day minimum because `apply_growth = FALSE` and
   shoot depletion is monotone. Therefore
   `closing_ms - CONSTANTS$MIN_SHOOT > gut_capacity_g / 1000` proves that
   plant availability cannot be the minimum: every other bite limit is no
   larger than total gut capacity.
3. Closing shoot must also be strictly greater than
   `CONSTANTS$M_REF = 10 kg`, keeping the persistence size term saturated, and
   strictly greater than `CONSTANTS$MIN_SHOOT = 0.001 kg`.
4. Closing qshoot must be finite and positive. The closing-to-opening
   qshoot/shoot ratio and leaf, stem, and defence fractions of shoot must each
   differ by no more than `1e-10` in absolute dimensionless units. The
   nutrient ratio used by selection must remain finite and unchanged within
   the same tolerance.
5. The one plant must retain its identity, type, location, reachability,
   detectability, positive selection score, and eligibility throughout the
   active loop. It must remain co-located with the herbivore whenever eating
   is attempted.
6. Every daily opening plant object must be exactly identical to the frozen
   snapshot, not merely equal within a tolerance. The reset helper must leave
   herbivore and caller RNG state unchanged. Tests and daily state hashes must
   show that an altered closing state is discarded rather than used as the
   next opening state.

The `1e-10` tolerance is a numerical round-off allowance, not a biological
threshold. Existing state and diagnostics should establish the bound. If they
cannot, stop; further instrumentation may be proposed only through explicit
review and must not silently inflate biomass or alter composition.

## Interpretation Contract

- If physiological decline persists while forage is proven non-binding,
  infer only that inter-day plant depletion/growth carryover is unnecessary
  for the decline under this reference. The ultimate cause remains
  unidentified.
- If the decline changes, infer only that plant growth and carryover dynamics
  are implicated collectively. This design does not separate them.
- Either result satisfies Goal 003. Never tune the reference to force
  stability.
- Make no equilibrium, viability, taxon-realism, causal, long-run stability,
  or general ecological claim.
- Treat Goal 002 as a frozen descriptive comparator, not a re-run control.

## Deliverables And Review Surface

Planning deliverables are this `Goal.md`, `Plan.md`, `Runbook.md`, and
`Log.md`.

Implemented Goal 003 paths are:

- `inst/extdata/scenarios/goal003_herbivore_reference_v1.yaml`
- `scripts/run_goal003_herbivore_reference.R`
- `tests/testthat/test_goal003_herbivore_reference.R`
- `docs/log/20260714_goal003_herbivore_reference.md`
- ignored evidence under
  `artefacts/goal003_herbivore_reference/run-a/` and `run-b/`

The preferred implementation changes no production `R/` file and does not
generalize or refactor the Goal 002 runner. A need to change production code,
an API, or another tracked path is a stop-and-escalate event.

## Acceptance Gates

1. Barry explicitly authorizes publication of the exact eight-path accepted
   Goal 002 footprint, Goal 002 is committed as the baseline, and Barry then
   separately authorizes Goal 003 execution.
2. Focused RED/GREEN tests lock every invariant, reset rule, RNG boundary,
   output schema, and non-binding criterion before clean runs.
3. Two clean executions produce byte-identical scientific CSV/JSON/figure
   outputs and matching configuration and output-set digests.
4. Every daily opening plant state is exactly the frozen snapshot; growth is
   disabled; the prior closing state is not carried forward; and the complete
   herbivore state, digestion queues, and seed schedule carry forward exactly
   under existing semantics.
5. All daily non-binding, eligibility, composition, finite-value, domain,
   gut-capacity, and accounting checks pass. Any failure stops the goal without
   adjustment.
6. The frozen Goal 002 comparator has the accepted manifest SHA
   `4c61f2c866a5b3209608b4b7d29fc82209de749e3ecbefdd324d982ca2f4fb39`,
   configuration SHA
   `46ce7fe6e467a3387ee6cc5ef027e87f315710d0b9610f805cc8864224317d89`,
   and output-set digest
   `98ad4f9da22a7b535a4bed94b12f4104293af1a0f89a02bb2b3d464b4793ac86`.
   It is not regenerated merely to change its embedded Git SHA.
7. The synthesis reports the result under the interpretation contract and an
   independent scientific reviewer reports no open Critical or Important
   issue.
8. Final status shows only the authorized Goal 003 surface and ignored run
   artefacts changed. No commit or push occurs without separate authority.

## Publication And Authority Gates

Goal 002 is scientifically accepted, committed, and unpublished at HEAD
`e45a6b7` on `codex/herbivore-ttr-goal-002`. For this bounded execution, the
orchestrator recorded Barry's authorization to publish the exact accepted Goal
002 eight-path footprint and Barry's separate authorization to execute Goal
003 on 2026-07-14. Those authorizations do not grant staging, commit, push, or
publication authority to this executor.

Before this execution, all three conditions were confirmed:

1. Barry explicitly authorized publication of the exact accepted Goal 002
   eight-path footprint.
2. Goal 002 is committed as the baseline at `e45a6b79`.
3. Barry separately authorized Goal 003 execution.

Packet approval alone granted no execution or publication authority. Barry's
later explicit 2026-07-14 execution authorization permitted this bounded Goal
003 run but granted no staging, commit, push, or publication authority.

## Stop And Escalate

Stop and report without adjustment if plant availability or `MIN_SHOOT` could
bind; closing shoot is at or below `M_REF`; qshoot or composition is invalid;
the plant becomes ineligible; the daily reset changes herbivore or RNG state;
the daily seed schedule changes; accounting fails; or nonlimitation requires
larger biomass, changed composition, new bite instrumentation beyond a
reviewed proposal, a core immutable-resource switch, or any production/API
change.

Also stop before plant-only runs, digestion-only ticks, sensitivity analysis,
calibration, mechanism changes, staging, commit, or push. If design A fails,
the later choice between a core immutable-resource mechanism and redefining
the resource belongs to Barry; Goal 003 does not pre-decide it.
