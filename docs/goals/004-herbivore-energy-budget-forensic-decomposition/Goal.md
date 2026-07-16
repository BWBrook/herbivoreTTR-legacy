# Goal 004: Herbivore Energy-Budget Forensic Decomposition

Status: completed locally on 2026-07-15 as diagnosis first, then decision.
Barry approved the design on 2026-07-14 and authorized execution on
2026-07-15. Independent code/evidence and scientific reviews accepted the
result with no Critical or Important finding. Goal 004 staging, commit, push,
publication, production-model changes, and parameter changes remain
unauthorized.

Owner: Herbivore TTR orchestrator.

Repository: `/Users/bwbrook/git/herbivoreTTR`.

Execution branch: `codex/herbivore-ttr-goal-002`. The immutable Goal 003
baseline commit is `abf68b691b4e30020625d1871dcabe56a5926bc1`; its production
base remains `e45a6b79b4fb5474609e916aa91e49b4ccc878e2`.

## Scientific Question

Under the accepted Goal 003 daily-clamped, non-binding-forage configuration,
where does the persistent herbivore energy deficit arise in the implemented
mass-energy-time pathway?

Goal 004 decomposes the deficit among:

- simulation clock and digestion-queue throughput;
- attainable dry-matter intake and the operative bite constraint;
- scheduling and release of carbohydrate and protein energy;
- maintenance and locomotion demand;
- the 719/720-minute foraging endpoint;
- body-condition feedback as an operative mechanism or censored reporter;
- biological parameter plausibility that cannot be decided mechanically.

The completed outcome is an exact ledger, a small orthogonal probe set, a
predeclared classification for each mechanism, and one correction decision
memo for Barry. Goal 004 stops before changing production semantics or any
parameter. A later bounded goal may implement one approved correction.

Stable body condition is not an acceptance target. Goal 004 must not tune a
mechanism or coefficient to make the reference appear viable.

## Frozen Starting Evidence

Goal 004 uses Goal 003 as a read-only baseline. The accepted reference has:

- one semi-synthetic 50,000 g herbivore;
- one homogeneous, finite but demonstrably non-binding daily forage snapshot;
- seed 2002 and daily offset 100000;
- 120 diagnostic days corresponding to model days 6--125;
- a 720-minute loop, 24-hour MRT queue, and 12 observed hourly digestion ticks
  per model day;
- mean dry-matter intake 555.483291 g/day;
- mean released energy 3427.569369 kJ/day;
- mean total requirement 5673.015934 kJ/day;
- mean energy deficit -2245.446565 kJ/day;
- 120/120 deficit and stress days and a BCI floor on day 25.

The accepted Goal 003 run-a manifest SHA is
`7e9ad004137e2a1c3b8a7233f183fcbbed02ef6bfdcf94f43dfded82a707538f`;
configuration digest is
`68e28c9388e99cbf4658145b9e714556803a27f66367b8a7d8aee8c3535daa82`;
content digest is
`70ab1cd72f1a0de37cbc0da6317b76cf907be183efe7737e9760f8e25dc204eb`;
and frozen plant-state digest is
`547ea977d2da05898555359051898c1453d2968907d4cb77e63382fd85d7a23f`.

The exact accepted Goal 003 source provenance is:

```text
eight-path tree/content digest = 03423aa5ec512ed4fda695a0ad55f828c3c308d1a7992ee20e09adc5af3a0d48
profile YAML SHA = 07b99b21cdb48d34eac570a246c626d2b82931126bb4173aaf298c6327b85403
runner SHA = b071096e431ee26c8e4b5946881dfcff35ec5bded0af379b267a04150722fb3b
test SHA = 1f5ea23dfea3ab379141596c9830c97715522f83b6b4be71ad9e7a140e221530
production base commit = e45a6b79b4fb5474609e916aa91e49b4ccc878e2
```

Goal 003 must be committed as an immutable source baseline before Goal 004 is
executed. This gate binds the currently untracked runner and tests to a commit;
Goal 004 must not begin from an uncommitted scientific comparator.

## Observation And Estimand Contract

The experimental unit is one fixed-seed simulated herbivore trajectory. Days
are autocorrelated repeated observations, not independent replicates. Goal 004
estimates deterministic ledger residuals and state-specific counterfactual
contrasts, not a population parameter, causal ecological effect, or empirical
viability threshold.

Every reported quantity must be labelled as one of:

1. **Observation:** directly recorded state, event, count, or canonical output.
2. **Code trace or algebraic identity:** implied exactly by the implemented
   equation and units as documented.
3. **Counterfactual diagnostic:** result of one isolated model intervention
   under explicit invariants.
4. **Literature-dependent judgement:** biological realism that cannot be
   established from internal consistency or a stable trajectory.

Daily intake and daily released energy must not be treated as contemporaneous
conversion measurements: intake enters queue slot 1, whereas energy is
released from the terminal slot. Attribution must occur at bite, tick, and
day-boundary resolution.

## Diagnostic Architecture

Implementation should use a Goal 004-only non-exported harness and pure helper
functions. It may reproduce the existing daily orchestration to expose the
minute-720 pre-closure checkpoint, but it must call existing production
feeding, digestion, closure, and diagnostic functions unchanged. No production
`R/` file, exported API, default, output contract, or parameter may change.

Observer-only baseline instrumentation is accepted only if the Goal 004 bare
control and observer branches have exactly equal predeclared production-state
projections and RNG states, and both exactly reproduce the three accepted Goal
003 machine-readable output artefacts. Goal 003 did not retain caller or
per-day exit RNG vectors, so Goal 004 must not claim direct RNG identity to
Goal 003. Diagnostic labels, hashes, and intervention fields are excluded from
the within-Goal-004 equality projection.

## Production Projection And RNG Contract

Observer equivalence uses two Goal 004 branches from the same frozen starting
state: a bare control replay with no observer records and an observer replay
with event capture enabled. Both must also reproduce the accepted Goal 003
`daily_diagnostics.csv`, `plant_diagnostics.csv`, and
`diagnostic_summary.json` exactly. Equality of the in-memory projection is
normatively tested with R `identical()` before hashes are written.

The projection includes, at daily opening, after every minute step, immediately
before and after every hourly tick, at minute-720 pre-closure, and after daily
closure, the complete herbivore object with this exact top-level name order:

```text
herbivore_id, mass, herb_type, mixed_browser_weight,
movement_disruption_prob, foraging_mode, forage_access_scale, xcor, ycor,
current_hour, last_hour, MRT, behaviour, selected_plant_id,
selected_plant_dist, gut_content, distance_moved, time_spent_foraging,
intake_total_day, intake_digest_carbs_day, intake_digest_protein_day,
intake_PE_day, intake_NPE_day, intake_defence_day, intake_total,
metabolic_water_day, intake_water_forage, intake_water_drinking,
daily_net_water_balance, daily_water_intake_total, water_requirement_day,
water_balance_ratio, maintenance_energy_requirement_day,
total_energy_requirement_day, daily_energy_intake, daily_energy_delta,
energy_balance_ratio, energy_deficit_streak_days, water_deficit_streak_days,
physiological_stress_flag, body_condition_index,
baseline_time_spent_foraging, body_condition_feedback_enabled,
body_condition_gain_coeff, body_condition_loss_coeff,
body_condition_effort_threshold, body_condition_stress_threshold,
body_condition_max_foraging_boost, energy_balance, water_balance, digestion,
gut_capacity, bite_size, handling_time, fv_max, daily_water_requirement,
feedback_settings, seeded_draws
```

`digestion` must contain, in order, `bleaf`, `bstem`, `bdef`, `dc_leaf`,
`dc_stem`, `dp_leaf`, `dp_stem`, and `dp_def`, with every queue value and
attribute included. The projection also includes the complete plant data frame
with row order, column order, classes, attributes, and these exact 36 fields:

```text
plant_id, xcor, ycor, veg_type, ms, mr, cs, cr, ns, nr, cd, nd, bleaf,
bstem, bdef, md, broot, brepr, height, qroot, qshoot, gs, gr, gd, uc, un,
rsC, rrC, rdC, rsN, rrN, rdN, tauC, tauN, tauCd, tauNd
```

After daily closure the complete accepted daily diagnostic row is included in
this exact column order:

```text
Day, model_day, HerbivoreID, day_seed, temperature, soil_water,
soil_nitrogen, opening_xcor_m, opening_ycor_m, xcor, ycor,
opening_gut_content_g, gut_content_g, gut_capacity_g, intake_total_g,
intake_PE_kJ, intake_NPE_kJ, energy_intake_kJ,
total_energy_requirement_kJ, energy_delta_kJ, EnergyBalance,
cumulative_energy_balance_kJ, metabolic_water_g, forage_water_g,
drinking_water_g, water_input_total_g, water_requirement_g,
daily_net_water_g, WaterBalance, cumulative_water_balance_g,
distance_moved_m, time_spent_foraging_h, EnergyDeficitStreakDays,
WaterDeficitStreakDays, BodyConditionIndex, PhysiologicalStressFlag,
behaviour, selected_plant_id, energy_daily_residual_kJ,
energy_cumulative_residual_kJ, water_daily_residual_g,
water_cumulative_residual_g
```

The complete plant diagnostic row and summary object are bound without field
selection to the accepted SHA-bound Goal 003 artefacts. Goal 004's
`baseline_daily_diagnostics.csv`, `baseline_plant_diagnostics.csv`, and
`baseline_diagnostic_summary.json` must be byte-identical to those accepted
files. The projection additionally includes overall caller RNG plus the seeded
per-day RNG vector captured inside each daily call immediately before return.

No production-state field, nested value, class, attribute, or name order is
excluded. Observer event rows, intervention
labels, probe classifications, source/configuration hashes, and output paths
are outside the projection. For the feedback-disabled probe only, the
deliberately changed `body_condition_feedback_enabled` flag is additionally
excluded; every other production field and the exit RNG vectors must remain
identical before feedback may be classified as non-operative here.

Starting and exit RNG are represented as the exact integer `.Random.seed`
vector, or literal `NULL` if it did not exist. Stored state/RNG digests use R
serialization version 3 and SHA-256; hashes support provenance but never
replace the in-memory `identical()` gate.

The first-divergence rule scans in `(Day, minute, phase, object root, object
path)` order. Phase rank is `daily_opening`, `minute_post_step_pre_tick`,
`hourly_tick_pre`, `hourly_tick_post`, `minute_720_preclosure`, and
`daily_closed`; phases not applicable to a minute are absent. Root rank is
`herbivore`, `plants`, `daily_output`, then `rng`. Within each root, traverse
depth-first in declared list/data-frame name order and increasing vector, row,
and column index. Record the first unequal path, expected and observed
canonical values, both state hashes, and both RNG hashes. Any observer-control
divergence is a stop; it may not be summarized only as a boolean manifest
claim.

The harness must expose one checkpoint immediately after minute 720 and before
plant finalisation, water closure, energy closure, and BCI update. A
completed-clock intervention applies exactly 12 digestion-only ticks to a
clone at that checkpoint and then performs the same closure exactly once.
Those ticks may not feed, move, alter plants, drink, consume RNG, change the
energy requirement, or add a second intervention.

## Minimum Probe Matrix

| Probe | Control | Single intervention | Required invariant | Response | Allowed inference |
|---|---|---|---|---|---|
| Observer ledger | Goal 004 bare control reproducing accepted Goal 003 outputs | Observer-only event capture | Bare-control/observer production projection and RNG unchanged; both reproduce Goal 003 outputs | Bite, tick, queue, energy and day-boundary residuals | Accounting or instrumentation fidelity only |
| Tick phase | Unit impulse just after an hourly boundary | Same impulse just before boundary | Same queue mass, composition, length and tick count | Terminal release tick and elapsed phase | Discrete phase sensitivity, not biological MRT validity |
| Completed clock | Minute-720 pre-closure clone | Exactly 12 digestion-only ticks | No feeding, movement, plant, drinking, RNG or requirement change before common closure | Immediate release, gut inventory, metabolic water and daily balance | Conditional effect of completing 24 ticks, not proof that 24 is intended |
| Capacity pathway | Unticked minute-720 pre-closure clone | Completed-clock clone | The exact fixed-opportunity replay below, separate identical plants, and no RNG | Incremental intake and bite-limit sequence | Capacity-mediated intake under that artificial fixed script only |
| Intake attribution | Baseline minute trajectory | Observer-only gate logging | Behaviour, intake, plants and RNG unchanged | Handling, remaining capacity, forage and mechanical limits, ties and no-bite reasons | Which constraints bind along this trajectory only |
| Demand decomposition | Implemented requirement | Set locomotion contribution to zero algebraically | Intake, maintenance and state unchanged | Daily and mean balance bound | Maximum contribution of implemented locomotion cost |
| BCI operability | Feedback enabled | Feedback disabled | Matched start/seed and exact adjusted projection plus exit-RNG equality | Requested and realised foraging hours, behaviour, intake and energy | Whether feedback changes this configuration |
| Endpoint eligibility | Existing foraging-window `<` gate | Evaluate an endpoint-inclusive minute 720 from an identical minute-719 clone | Exact equality through minute 719 | Direct bite, move, tick and RNG consequence | Foraging-window boundary effect only, not eating-radius semantics or long-run importance |

The capacity replay protocol is fixed as follows. For each canonical day, take
the unticked and +12-tick herbivore clones at minute 720 before closure. Give
each a separate exact copy of the frozen Goal 003 opening plant, set plant 1 as
the selected target and behaviour to `EATING` in both replay-only copies, and
apply exactly 720 direct calls to existing `herbivore_eat()`. Apply no
digestion tick, movement, selection, growth, closure, drinking, feedback,
daily reset, or RNG call. Do not stop early. Record incremental intake relative
to each clone's own opening counters, per-opportunity raw limits and winner,
final gut vacancy, and plant drawdown. Plant availability must remain
non-binding in both branches. The estimand is only the added attainable intake
caused by different opening gut vacancy under this fixed artificial sequence;
it is not predicted next-day intake.

Capacity mediation requires an additional entry gate. The two replay branches
must have identical `herbivore_eat()` intake-determining read sets except for
`gut_content` and the eight digestion queues: `selected_plant_id`,
`handling_time`, `gut_capacity`, `MRT`, `intake_total_day`,
`intake_defence_day`, `intake_water_forage`, the target plant's `plant_id`,
`bleaf`, `bstem`, `bdef`, and `qshoot`, and the relevant immutable constants.
Queue lengths, names, and validity must match; each branch's `gut_content` must
equal the sum of its three biomass queues. Energy-release and metabolic-water
counters changed by the extra ticks may differ because they are not read to
determine bite amount. If this gate fails, label the contrast a completed-
clock-state effect under fixed replay, not a capacity-mediated effect.

After all isolated probes pass, one carried 120-day completed-clock pair is
optional and non-blocking. The manifest must record `complete` or `not_run`
with a reason. If run, it estimates only the total downstream effect under the
production policy and records the first state and RNG divergence. Once call
topology diverges, the contrast may not be decomposed into a unique gut-
capacity, behavioural, or RNG-mediated effect. Omitting it does not fail Goal
004 if the correction decision is supported by the isolated probes.

## Ledger Contract

For every hourly transition and all eight queues, retain one raw row per queue
slot containing interval-opening value, bite-derived insertion, pre-tick value,
normalization/resizing adjustment, post-tick value, and the unmodified
pre-shift terminal-slot value. Bite insertions must be independently summed
from minute-level feeding events, not inferred as the residual needed to make
the queue balance. Tick keys must be unique and ordered; slots must be complete
and ordered; each pre-tick queue must reconcile to opening plus raw insertions
and explicit adjustments; each post-tick queue must equal
`c(0, pre_tick[1:(MRT - 1)])`; and the next interval opening must equal the
previous post-tick queue. Closing-to-next-opening continuity is mandatory for
the baseline and any carried branch, but not between independent daily probe
clones. The mass, digestible-carbohydrate, digestible-protein, and released-
energy ledgers must reconcile independently.

Energy release must be reconstructed as:

```text
16.7 * (dc_leaf + dc_stem)
+ 23.0 * (dp_leaf + dp_stem + dp_def)
```

where terms are terminal-slot grams immediately before queue shifting. The
canonical trajectory must have zero normalization and resizing adjustments.
The default conservation tolerance is scale-aware:

```text
64 * .Machine$double.eps * max(1, sum(abs(all ledger terms)))
```

Any wider tolerance requires explicit justification and independent review.

The intake ledger must record raw handling, remaining-gut-capacity,
plant-availability, and mechanical-cap values before each positive bite,
including ties, as well as queue-component insertions and pre/post target-plant
and gut values. Eligible no-bite minutes require a classified gate reason.

Each probe must also emit raw invariant evidence: complete pre/post projection
hashes, RNG vectors/hashes, observed changed paths, and the raw scalar values
needed to verify its stated invariant. The validation code must compare those
changed paths with a probe-specific allowed-path table fixed in the Goal 004
profile and tests; a stored `invariants_pass` boolean is never sufficient.
The mandatory equality records are named exactly:

```text
observer_projection_equal
observer_rng_equal
tick_phase_opening_queue_equal
tick_phase_tick_count_equal
completed_clock_no_feeding
completed_clock_no_movement
completed_clock_plant_equal
completed_clock_no_drinking
completed_clock_rng_equal
completed_clock_requirement_equal
capacity_entry_non_gut_read_set_equal
capacity_entry_plant_equal
capacity_entry_gut_queue_identity
capacity_rng_unchanged
demand_state_unchanged
bci_matched_start_rng
endpoint_equal_through_minute_719
```

If feedback is classified `nonoperative_here`, `bci_projection_equal` and
`bci_rng_equal` are additionally mandatory. Each row stores raw expected and
observed canonical values or version-3 serialization hashes and the expected
relation; validation recomputes equality and rejects any unlisted or forbidden
difference.

The phase-specific difference contract is fixed in the profile and tests. The
observer permits no production or RNG difference. Before common closure the
completed-clock branch may differ only in the eight digestion queues,
`gut_content`, `intake_digest_carbs_day`, `intake_digest_protein_day`,
`intake_NPE_day`, `intake_PE_day`, and `metabolic_water_day`; closure-derived
water, energy, BCI, stress, and cumulative fields may then differ downstream.
The capacity entry gate permits only those completed-clock fields before the
replay starts. The algebraic demand probe permits no model-state difference.
The BCI probe starts with only `body_condition_feedback_enabled` changed. The
endpoint branches must be identical through minute 719. The tick-phase probe
permits only release phase/timing to differ in its synthetic queue. A carried
branch may diverge after its recorded first difference but is thereby limited
to a total downstream inference.

`probe_state_snapshots.rds` is the raw source for this check. It contains only
`schema_version` and ordered `records`; each record contains `probe_id`, `Day`,
`checkpoint`, and complete `control` and `intervention` projections with roots
`herbivore`, `plants`, `daily_output`, `rng`, and `constants`. The constants
root contains the exact immutable values read by `herbivore_eat()`:
`MIN_SHOOT`, `MAX_BITE_FRACTION`, `FRACTION_C`, `PROP_DIGEST_SC`,
`FRACTION_N`, `N_TO_PROTEIN`, and `PROP_DIGEST_TP`. No field selection,
pass flag, changed-path list, or allowed-path list is stored in place of either
projection.

The required per-day record keys are:

```text
observer | daily_closed
completed_clock | minute_720_preclosure
completed_clock | daily_closed
capacity_pathway | replay_entry
demand_zero_locomotion | algebraic_entry
bci_feedback_operability | matched_start
endpoint_eligibility | minute_719
```

Each key must cover Days 1--120 exactly once. If BCI is classified
`nonoperative_here`, `bci_feedback_operability | adjusted_exit` must also cover
Days 1--120. The Runbook independently validates the complete projection
schemas, recursively reconstructs every changed object path from these raw
objects, compares that set exactly with the review CSV, and checks each path
against the phase-specific allowed prefixes declared above. Missing records,
omitted paths, one-sided hashes, empty value fallbacks, or an unlisted change
are hard failures.

## Classification Decision Tree

1. If observer instrumentation changes the production projection or exit RNG,
   classify diagnostic interference and stop.
2. If a valid-state queue, nutrient, mass, or energy ledger fails, classify a
   mechanically demonstrated implementation defect and stop semantic probes.
3. If code violates an explicit internal time, unit, or equation contract:
   - unique intended semantics: implementation/contract defect;
   - competing code/document conventions: unresolved contract requiring
     literature or Barry's decision.
4. If an isolated probe changes its response while all invariants hold:
   - behaviour matches accepted contract: intended model behaviour here;
   - biological magnitude is questioned: parameter-plausibility question;
   - production state or RNG topology diverges: total downstream interaction,
     not unique component attribution.
5. If a mechanism has no effect under its valid isolated probe, classify it as
   non-operative for this state/configuration, not universally irrelevant.
6. If the deficit persists after excluding mechanical defects, classify it as
   intended output conditional on current parameters. Do not infer that those
   parameters are biologically valid.

## Known Questions To Include

- The 720-minute loop advances a 24-hour queue 12 times before charging a
  daily maintenance requirement. Whether the model day is 12 active feeding
  hours within a 24-hour physiological day or only 720 total simulated minutes
  is a contract decision, not pre-decided by Goal 004.
- With `seq_len(720)` and `minute < 12 * 60`, only minutes 1--719 are behaviour
  eligible; minute 720 still ticks digestion. Goal 004 measures this endpoint
  effect but does not fix it. This is distinct from the production
  `<= EAT_RADIUS` distance gate, which is unchanged and is not the endpoint
  intervention.
- Repository documentation declares the locomotion coefficient in
  J/m/kg^B, while the implemented distance/conversion equation appears
  dimensionally inconsistent with that declaration. Goal 004 quantifies the
  implemented zero-locomotion bound and records the contradiction, but source
  interpretation and correction require primary literature or Barry.
- Maintenance, MRT, gut capacity, handling, digestibility, and caloric
  coefficients remain biological parameter-plausibility questions unless a
  mechanical contract violation is demonstrated.

## Deliverables And Review Surface

Planning deliverables are this `Goal.md`, `Plan.md`, `Runbook.md`, and
`Log.md`.

Intended execution paths are:

- `inst/extdata/scenarios/goal004_energy_decomposition_v1.yaml`
- `scripts/goal004_energy_ledger_helpers.R`
- `scripts/run_goal004_energy_decomposition.R`
- `tests/testthat/test_goal004_energy_decomposition.R`
- `docs/log/20260714_goal004_energy_budget_decomposition.md`

Canonical ignored evidence is generated under
`artefacts/goal004_energy_decomposition/run-a/` and `run-b/` with:

```text
run_manifest.json
baseline_projection.csv
baseline_daily_diagnostics.csv
baseline_plant_diagnostics.csv
baseline_diagnostic_summary.json
hourly_queue_ledger.csv
daily_energy_budget.csv
minute_intake_limits.csv
probe_comparison.csv
probe_invariants.csv
probe_state_snapshots.rds
classification_summary.json
energy_budget_diagnostics.png
```

Stable ignored execution/review evidence lives under:

```text
.superpowers/sdd/goal004-agents/executor/
.superpowers/sdd/goal004-agents/scientific-review/
.superpowers/sdd/goal004-agents/final-audit/
```

The scientific log is the ecologist-readable correction decision memo. It
must recommend at most one next production correction or one bounded
literature/parameter-validation goal. If two corrections remain comparably
supported, it must stop and present the choice to Barry rather than bundle
them.

`classification_summary.json` must give every mechanism one or more stable
evidence identifiers and set `dominant_cause_claim` to `false`. It may contain
either no `recommended_next_goal` or exactly one object whose `type` is
`production_correction` or `literature_parameter_validation`, with non-empty
evidence identifiers. If two or more alternatives remain comparably
supported, `recommended_next_goal` must be `null`,
`barry_decision_required` must be `true`, and `comparable_alternatives` must
name those alternatives and their evidence. Otherwise the alternatives array
must be empty. A correction and literature goal may never be recommended
simultaneously.

## Acceptance Gates

1. Goal 003's exact eight-path accepted footprint is committed locally as the
   source baseline, its tree/profile/runner/test/evidence hashes match this
   packet, no comparator path is modified, and Barry separately authorizes
   Goal 004 execution. Push/publication is neither required nor authorized.
2. Focused tests reach RED and GREEN for observer invariance, queue ledger,
   tick phase, pre-closure clock completion, fixed-opportunity capacity replay,
   intake-limit attribution, feedback projection, endpoint probe, manifests,
   and failure stops.
3. Both Goal 004 baseline branches reproduce the three accepted Goal 003
   machine-readable outputs exactly, and observer capture leaves the Goal 004
   bare-control production projection and RNG state exactly unchanged. No
   direct Goal 003 RNG-equivalence claim is made.
4. Queue mass, nutrient, energy, and day-boundary ledgers pass with zero
   unreported normalization/resizing adjustments.
5. Every probe changes one factor only and passes its stated plant, feeding,
   movement, drinking, requirement, RNG, and state invariants.
6. Run-a and run-b are byte-identical for all scientific evidence and have
   matching configuration, source, comparator, and output-set digests.
7. The classification summary distinguishes observation, identity,
   counterfactual, and literature-dependent judgement and makes no dominant-
   cause claim from non-additive contrasts.
8. Independent scientific and code review finds no open Critical or Important
   issue.
9. Exactly the authorized Goal 004 source surface is changed. No production
   semantics, parameter, public API, staging, commit, push, or publication
   occurs without separate authority.

## Authority And Correction Gates

Goal 004 is diagnostic. It does not authorize a production correction.

A later goal may change production code only if a valid-state ledger or
explicit internal contract is mechanically violated; intended semantics are
unique or Barry selects them; exactly one correction is predeclared; unrelated
feeding, plant, movement, RNG, and output projections are preserved; and no
parameter changes in the same goal.

A later goal may change a parameter only after accounting and time semantics
pass; primary literature supports the value, organismal scope, and units; the
parameter maps unambiguously to the implemented equation; the change is not
compensating for another defect; and Barry approves that separate bounded
goal.

Barry must decide the intended daily-clock semantics, unresolved locomotion
convention, any choice between comparably supported corrections, and any
public API or output-schema implication.

## Stop And Escalate

Stop on diagnostic interference; conservation failure; ambiguous accounting-
day attribution; non-zero unexplained queue normalization/resizing; feeding,
plant, movement, drinking, requirement, or RNG change in a supposedly isolated
probe; untracked RNG divergence; need for production or parameter changes;
more than one comparably supported correction; public API implications; or a
request to calibrate against BCI stability.

Do not add broad parameter sweeps, multiple seeds, taxa, forage qualities,
plant-only work, recoupling, empirical calibration, mortality, mass dynamics,
new physiological mechanisms, or publication framing. Those are later goals.
