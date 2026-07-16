# Goal 004 Herbivore Energy-Budget Decomposition

## Purpose And Scope

Goal 004 asks where the persistent energy deficit in the accepted Goal 003
herbivore-only reference arises. It is a forensic diagnostic, not a calibration
exercise. The 50 kg semi-synthetic herbivore, frozen non-binding forage state,
forcing, seed schedule, 120-day horizon, production functions, and biological
parameters were unchanged.

The evidence separates direct observations, algebraic identities, isolated
counterfactuals, and literature-dependent judgements. It does not establish
which daily-clock convention is biologically intended.

## Bottom Line

The baseline deficit is real within the implemented accounting system and is
not explained by forage amount, the minute-720 endpoint, body-condition
feedback, or locomotion demand alone. The largest isolated response came from
completing 24 digestion ticks before daily closure, but that result is
conditional: it shows that the present energy balance is highly sensitive to
the relationship between the 720-minute activity loop, the 24-hour digestion
queue, and the daily maintenance charge. It does not prove that 24 ticks are
the intended model semantics or that clock treatment is the unique ecological
cause.

Two daily-clock interpretations remain comparably defensible from repository
evidence. Barry's scientific decision is therefore required before any model
correction is designed.

## Baseline Observations

Across the 120 diagnostic days, mean dry-matter intake was 555.483 g/day
(range 194.988--919.229), mean released energy was 3427.569 kJ/day, and mean
total requirement was 5673.016 kJ/day. Every day was energy-negative, with a
mean deficit of -2245.447 kJ/day and a final cumulative balance of
-269453.588 kJ. Stress was reported from day 1 and body condition first reached
zero on day 25.

The queue ledger reconciled all eight queues at bite, tick, and day scales.
Baseline daily intake agrees independently with both the raw daily diagnostic
and the queue-derived insertion total. The bare-control and observer replays
are state- and RNG-identical, reproduce the accepted Goal 003 daily, plant, and
summary artefacts exactly, and produce byte-identical run-a/run-b evidence.

Forage availability did not bind positive bites. Of 86,280 eligible baseline
minutes, 78,154 (90.58%) had non-positive remaining gut capacity. There were
5,506 positive bites: 5,386 were handling-limited and 120 capacity-limited;
forage was never the winning limit. Eligible no-bite minutes were attributed
to non-positive capacity (78,154) or behaviour not eating (2,620), with 120
minutes outside the strict foraging window.

## Diagnostic Identities And Counterfactuals

### Daily clock and digestion

The baseline advances the 24-hour digestion queue 12 times during its
720-minute loop. Adding exactly 12 digestion-only ticks at minute 720, while
holding feeding, movement, plants, drinking, requirement, and RNG invariant,
increased mean released energy from 3427.569 to 6865.366 kJ/day. Mean daily
energy balance changed from -2245.447 to +1192.350 kJ/day; the isolated direct
difference averaged +3437.796 kJ/day (range +1203.363 to +5626.932), and all
120 intervention closures were positive. Mean closing gut content fell from
558.703 to 1.595 g.

This is an isolated same-day closure contrast, not a stable 120-day alternative
trajectory. A carried trajectory was deliberately not run because behaviour
and RNG topology can diverge after the intervention, making a unique
gut-capacity or clock attribution non-identifiable.

### Intake capacity

Under 720 fixed direct feeding opportunities with matched plant state and no
behaviour, movement, closure, or RNG path, the unticked entry state admitted
555.513 g mean incremental intake and the completed-clock entry state admitted
1112.621 g. The +557.108 g/day difference demonstrates a capacity-mediated
pathway under this artificial replay. It is not an estimate of realised intake
under a recoupled trajectory.

### Energy demand

Mean implemented maintenance was 5509.284 kJ/day and locomotion was
163.732 kJ/day, only 2.89% of total requirement. Algebraically removing all
locomotion still leaves a mean deficit of -2081.714 kJ/day. Locomotion therefore
cannot explain most of the baseline deficit.

Repository unit documentation and the implemented locomotion equation are not
internally aligned. This is classified as an implementation-or-contract issue
requiring source validation, but Goal 004 demonstrates no locomotion
implementation defect and does not choose a corrected unit convention.

### Endpoint and body condition

Executing the nominal minute-720 feeding step from independently cloned
minute-719 states changed neither intake nor movement and preserved RNG on all
120 days. The strict 719/720 boundary is therefore not consequential on this
trajectory.

Feedback-enabled and feedback-disabled matched probes had identical adjusted
production projections and RNG after excluding only the deliberately changed
enable flag. Body-condition feedback is non-operative here; the declining BCI
is a reporter of the deficit, not a demonstrated driver of it.

## Mechanism Classification

| Mechanism | Evidence type | Classification | Interpretation |
|---|---|---|---|
| Observer ledger | Observation | Intended behaviour here | Instrumentation reproduces the frozen reference without interference. |
| Tick phase | Counterfactual | Intended behaviour here | Queue release is discretely sensitive to impulse position around a tick. |
| Completed clock | Counterfactual | Intended behaviour here | Completing 24 ticks has a large conditional closure effect. |
| Capacity pathway | Counterfactual | Intended behaviour here | Gut vacancy changes attainable intake in a fixed-opportunity replay. |
| Intake attribution | Observation | Intended behaviour here | Capacity and handling bind; forage amount does not. |
| Zero locomotion | Identity | Implementation or contract issue | Units require source review; locomotion is too small to remove the deficit. |
| BCI feedback | Counterfactual | Non-operative here | Feedback does not alter this reference trajectory. |
| Minute-720 endpoint | Counterfactual | Intended behaviour here | The excluded endpoint has no direct consequence here. |

No dominant-cause claim is made. Clock throughput, queue inventory, gut
capacity, and realised behaviour are coupled, and only the isolated direct
effects above are identified.

## Decision Required

The repository currently supports two competing interpretations:

1. **Twelve-tick accounting day:** the 720-minute loop is the complete model
   day, so 12 digestion ticks and one daily maintenance charge are intended.
2. **Twenty-four-tick physiological day:** the 720-minute loop represents 12
   active feeding hours within a 24-hour physiological day, so 24 digestion
   ticks should precede the daily maintenance charge.

Internal model behaviour cannot decide between them. A bounded next goal
should trace original design sources and relevant physiological literature,
resolve the intended units and timebase for digestion, maintenance, activity,
and locomotion, and present the evidence to Barry for a decision. It should not
change code, tune parameters, or target stable BCI.

## Explicit Non-Estimates

Goal 004 did not estimate a stable BCI, physiological viability, an empirical
or causal ecological effect, parameter realism, population variability,
generality across taxa or environments, or paper readiness. The completed-
clock intervention is not an approved production correction.

## Evidence And Validation

Canonical evidence is retained in
`artefacts/goal004_energy_decomposition/run-a/` and `run-b/`. Each bundle has
13 files; all files are byte-identical between runs. Manifest source SHA is
`2d1117462c0fa401ce5398729b8bbd32e50a653475cebb9b84f9016a7943b0d1`
and content SHA is
`024d82acf3b03f9e267d51cbf845a51db37a5588b85ed839f8569734a068b45a`.

The exact Runbook ledger and scientific gates passed. The repository-wide
test suite reported 1447 passes, 0 failures, 0 warnings, and 32 expected opt-in
skips. Lint passed, `renv::status()` reported a synchronized project, and
`git diff --check` was clean. No production `R/` file, biological parameter,
package metadata, lockfile, commit, push, or publication changed.
