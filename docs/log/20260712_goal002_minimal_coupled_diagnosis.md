# Goal 002 Minimal Coupled Baseline Diagnosis

## Scope and interpretation boundary

Goal 002 is a fixed-seed computational diagnosis of one semi-synthetic
herbivore--forage configuration over 120 diagnostic days. It is not an
empirical eastern-grey-kangaroo model, a viability test, a causal experiment,
an equilibrium analysis, or an ecological-determinism claim. The herbivore is
loosely grey-kangaroo-like only as a diagnostic label; no taxon-specific
realism is inferred.

The canonical evidence is the final `run-a`/`run-b` pair under
`artefacts/goal002_minimal_coupled/`. Earlier bundles are retained as
development or superseded inspection evidence and are not used below.

## Canonical configuration and repeatability

The final profile is
`inst/extdata/scenarios/goal002_minimal_coupled_v1.yaml` with one explicit
50,000 g herbivore (`goal002_grazer_1`), one forage type, seed `2002`, 120
diagnostic days, model days 6--125, a 720-minute daily limit, active forage
access scale 1, and the `internal_ttr` plant backend. External forcing is
constant by value: temperature 25 C, soil water 0.5, and soil nitrogen 0.5.
The explicit initial plant has 50 kg shoot biomass and 50 kg root biomass at
(50, 50); all profile pools are recorded in the manifest.

The complete resolved initial herbivore state is recorded in each manifest at
`initial_herbivore_state.resolved_herbivore_state`, before the first step. All
58 fields in the initialized object are present, including the derived
foraging traits, clocks, feedback state, daily and cumulative balances,
deficit streaks, water requirements, and digestion queues. Key values are: mass
50,000 g; coordinates (50, 50) m; gut content 389.975733 g; gut capacity
1,114.216380 g; MRT 24 h; BCI 0.8; behaviour `MOVING`; no selected plant;
enabled body-condition feedback; and the complete eight-queue digestion state.
The seeded coordinate draws are retained for provenance, but the explicit
profile coordinates replace them in the resolved state.
The two typed missing target fields are encoded uniformly as JSON `null`, and
`resolved_herbivore_state_missing_schema` records `selected_plant_id` as R
`integer` and `selected_plant_dist` as R `double`, each missing at position 1.

Both manifests report `status = complete`, the same Git SHA
`7ea01321b3f6db398b6b6e549d2bfc478d93e420`, R 4.6.1, 120 rows in each CSV,
one herbivore, one forage type, and one value for each forcing variable.
Their final current hashes are:

| item | SHA-256 |
|---|---|
| `run_manifest.json` | `4c61f2c866a5b3209608b4b7d29fc82209de749e3ecbefdd324d982ca2f4fb39` |
| profile input | `59bf328c846eea934295fcbe6635b5398faaeb27f78945be53a35703604f2a71` |
| configuration | `46ce7fe6e467a3387ee6cc5ef027e87f315710d0b9610f805cc8864224317d89` |
| `daily_diagnostics.csv` | `b54e6f9a63ad2b8f946d58e2ac20d15e6843fbfd85bcf199a8e9272acf1c6e71` |
| `plant_diagnostics.csv` | `dc0910ed429c9fa742804b853893f9402a5c517ecc31d6a265cf9dbee8d26340` |
| `diagnostic_summary.json` | `49ce88b0e55620f669c586fb2bd0598d80f4e634acbf35102567de038139ecba` |
| `diagnostic_trajectories.png` | `baa0baeaff81b9f3f7b9c1bd4f151938bee8d3db8f42b942182eaceff4bd6ee6` |
| aggregate output-set digest | `98ad4f9da22a7b535a4bed94b12f4104293af1a0f89a02bb2b3d464b4793ac86` |

The listed output hashes and aggregate digest of the named output-hash map are
the values in the current manifests. The manifest field retaining that digest
is named `content_sha256`; it is not a digest of the manifest itself. `run-a`
and `run-b` are byte-identical in full, including both CSVs,
`diagnostic_summary.json`, and the PNG. This establishes fixed-seed
computational repeatability for this implementation and configuration; it
does not establish absence of stochastic processes or ecological
determinism. The figure is readable on a white background, uses `Diagnostic
day` labels, and does not imply a biological pass threshold.

## Evidence convention

Each finding is labelled as **O** (observed output), **C** (direct code trace),
or **I** (inference from O and C). The output is one temporally autocorrelated
realisation, not 120 independent observations. The three 40-day windows below
are descriptive windows only.

## Verified trajectories

### Energy

**O.** All 120 daily energy deltas are negative. Mean intake is
3,427.450481 kJ/day against a constant requirement of 5,674.391837 kJ/day;
the cumulative balance ends at -269,632.962693 kJ. The daily delta ranges
from -4,517.094489 to -47.463305 kJ in days 1--40, then from approximately
-3,289.784 to -1,182.822 kJ in days 41--80 and approximately -3,289.711 to
-1,183.036 kJ in days 81--120. The energy plot is nearly linear in the later
period, with the alternating daily intake pattern visible in the daily CSV.

**C.** `calc_daily_energy_balance()` in
`R/calc_daily_energy_balance.R:11-31` computes intake as protein plus
non-protein energy, requirement as maintenance plus locomotion, daily delta as
intake minus requirement, and adds the delta to cumulative `energy_balance`.
The specialist’s code trace resolves the mean requirement into approximately
5,509.28 kJ maintenance and 165.11 kJ locomotion. The locomotion term is
generated by the 100 m daily water trip; spatial foraging movement is zero
because the animal and plant remain co-located.

**I.** A secure proximate explanation is that delivered energy never meets the
fixed model requirement while the configured compensatory response is capped
at the available 12-hour active-foraging window. The ultimate reason for the
energy shortfall is unresolved; digestion-clock timing, gut-capacity/MRT
dynamics, forage composition, behavioural persistence, and parameter scale
remain competing or interacting explanations.

### Water and movement

**O.** The recorded daily and cumulative water-balance fields are zero on all 120 days;
water-deficit streaks are zero. Mean daily movement is exactly 100 m and mean
realised foraging time is exactly 12 h. The daily CSV shows metabolic,
forage, and drinking water inputs summing to the 6,600 g requirement.

**C.** `check_daily_water_balance()` in
`R/check_daily_water_balance.R:13-49` adds drinking equal to any deficit and
adds `CONSTANTS$DIST_TO_WATER` to daily movement when drinking occurs. The
daily runner calls it after the 720-minute loop and before energy accounting
(`R/run_daily_herbivore_simulation.R:180-187`). `herbivore_move()` in
`R/herbivore_move.R:15-62` records spatial movement, which remains zero here.
`apply_body_condition_feedback()` in
`R/herbivore_diagnostics_v2.R:7-59` can request up to a 15% boost below the
effort threshold, but caps realised time at `minute_limit / 60`; with
`minute_limit = 720`, the realised value remains 12 h.

**I.** Water closure demonstrates algebraic closure under the model’s
unlimited drinking rule, not autonomous water sufficiency or ecological
viability. The 100 m water trip also contributes to the energy requirement.

### Gut, intake, and digestion

**O.** Gut content remains within capacity, alternating mainly between
194.987867 and 919.228514 g. The maximum closing content is 82.5% of the
1,114.216380 g capacity. Dry-matter removal alternates mainly between about
0.194988 and 0.919229 kg/day. This coincides with the alternating daily
energy-intake pattern.

**C.** `reset_daily_variables()` in
`R/reset_daily_variables.R:11-39` clears daily intake, water, energy, stress,
and movement counters, but reconstructs gut content from the digestion queues.
`herbivore_eat()` in `R/herbivore_eat.R:96-135` adds intake to the first queue
slot, schedules digestible carbohydrate and protein, removes shoot biomass,
and updates `intake_total_day`. `hourly_digestion_step()` in
`R/hourly_digestion_step.R:122-162` releases the terminal queue slot and
shifts all eight 24-slot queues. The daily loop calls it only at each
`minute %% 60 == 0` within the 720-minute loop
(`R/run_daily_herbivore_simulation.R:131-147`): 12 hourly shifts per model
day for a 24-hour MRT queue.

**I.** The 12-of-24 queue advancement is consistent with the strong two-day
alternation and is a model interaction or missing daily-clock completion
mechanism, but this single baseline cannot quantify how much of the energy
deficit it causes. No gut-capacity violation was observed.

### Body condition and stress

**O.** BCI falls below 0.4 on diagnostic day 13, below 0.2 on day 19, reaches
the lower bound 0 on day 25, and remains censored there. `PhysiologicalStressFlag`
equals 1 on all 120 days. The first 40-day window has BCI range 0--0.736316;
the middle and final windows are at 0 throughout. Stress is therefore
persistent in the model output, while the BCI trajectory is bounded by its
implementation floor.

**C.** `update_herbivore_daily_diagnostics()` in
`R/herbivore_diagnostics_v2.R:61-100` increments the energy-deficit streak for
negative daily delta, increments the water-deficit streak for negative daily
net water, updates BCI using the energy-balance ratio and gain/loss
coefficients, clamps BCI to [0, 1], and sets stress through the OR condition:
BCI below the configured stress threshold **or** a positive energy-deficit
streak **or** a positive water-deficit streak. Since the energy-deficit streak
is positive from day 1, the stress flag is not independent corroboration of
the later BCI decline.

**I.** Stress days are model-defined threshold crossings, not an empirical
viability threshold and not evidence of grey-kangaroo stress, suffering, or
non-viability. The model has no reserve depletion, mass loss, mortality, or
maintenance-requirement response after BCI reaches zero. Continued energetic
decline is represented by cumulative energy balance and the deficit streak,
not by an unmodelled biological state.

### Plants

**O.** Closing shoot biomass begins at 51.321513 kg after day 1, peaks at
65.535966 kg on day 14, and ends at 32.044539 kg on day 120; the minimum
closing value is 31.995930 kg. Across the 120 days, net TTR regeneration is
48.702534 kg and herbivore removal is 66.657995 kg. The trajectory therefore
shows an early increase followed by a persistent sawtooth decline, with no
evidence for equilibrium or asymptotic stability.

**C.** The daily runner applies the internal TTR plant step before herbivory
(`R/run_daily_herbivore_simulation.R:43-61`), then `herbivore_eat()` directly
removes shoot pools (`R/herbivore_eat.R:117-129`). The diagnostic plant row in
`scripts/run_goal002_minimal_diagnosis.R:319-336` records opening biomass,
net regeneration, removal, closing biomass, and the arithmetic identity.

**I.** Net regeneration is insufficient to offset removal over this run. Gross
TTR growth and gross litter loss are not separately exposed by the existing
daily interface, so their individual contributions cannot be identified from
these outputs; they remain a stated limitation rather than an inferred cause.

## State map: daily reset versus carryover

| state/process | reset each diagnostic day | carried, accumulated, or bounded |
|---|---|---|
| energy | protein/non-protein intake, requirement, daily delta and ratio | cumulative `energy_balance` and energy-deficit streak; BCI also carries and is bounded |
| water | metabolic, forage and drinking inputs, requirement, daily net and ratio | cumulative `water_balance` and water-deficit streak; drinking closes deficits before diagnostics |
| gut/digestion | gut content is recomputed from queues at reset | eight 24-slot biomass/nutrient queues carry; only 12 hourly shifts occur per model day |
| intake | daily dry matter and nutrient fields reset | declared `intake_total` is not updated |
| foraging | behaviour resets to `MOVING`; daily foraging time is recalculated | baseline 12 h and BCI carry; target and coordinates carry |
| stress | flag resets to zero before end-of-day update | streaks and BCI provide memory; flag is recomputed from the OR rule |
| movement | daily distance resets | coordinates and selected target carry; the water-trip increment is added daily |
| plants | no daily reset | all TTR pools carry; growth occurs before herbivory and consumption removes shoot and `qshoot` |

The initial-state construction is traced to `R/init_herbivore.R:14-82` and
the manifest’s `before_first_step` record. The map is a code description, not
a claim that every carried quantity represents a biologically adequate reserve
or memory mechanism.

## Finding classifications and defects

| finding | classification | evidence-bound statement |
|---|---|---|
| persistent negative energy balance and BCI floor | observed configuration behaviour; model interaction | directly observed, with feedback capped by the 720-minute horizon |
| 12 hourly digestion shifts for a 24-hour MRT queue | model interaction / missing state mechanism | direct code trace and output pattern; contribution to the deficit is unresolved |
| net plant regeneration below removal | observed configuration behaviour | direct plant CSV accounting; gross growth and litter are unavailable |
| possible maintenance, digestion, forage-composition, or attainable-intake scale mismatch | qualified suspected parameter-scale issue | hypothesis only; no internal dimensional contradiction was proven |
| `intake_total` | existing code defect, non-causal here | `R/init_herbivore.R:50` documents and initialises it, but no update occurs; Goal 002 uses `intake_total_day`, so this defect does not explain the trajectory |
| figure x-axis label | corrected output-label defect | the figure now labels diagnostic days 1--120; actual model days are 6--125 |

No core dynamics defect has been demonstrated as the sole cause. The one
secure proximate explanation is the energy shortfall under the fixed
requirement plus the capped compensatory response. The ultimate cause remains
unresolved.

## Arithmetic checks and limitations

The in-memory summary reports zero maximum absolute residual for the daily and
cumulative energy identities, daily and cumulative water identities, and plant
identity. Independent reconstruction after CSV decimal serialization gives
maximum absolute residuals of `1.02e-11` kJ for daily energy, `5.82e-10` kJ for
cumulative energy, `9.09e-12` g for daily water, and zero for cumulative water
and plant biomass. These values are numerical zero within floating-point and
serialization tolerance, not exact symbolic identities and not biological
thresholds:

- energy: `energy_intake_kJ - total_energy_requirement_kJ = energy_delta_kJ`;
- cumulative energy: model cumulative balance equals the cumulative daily
  deltas;
- water: metabolic + forage + drinking water - requirement = daily net water;
- plant: opening biomass + net TTR regeneration - removal - closing biomass.

The canonical tables have complete 120-day coverage, finite numeric values,
non-negative shoot biomass, bounded BCI, and no gut-capacity violation. Material
uncertainties and assumptions are: daily aggregation; BCI floor censoring;
automatic water-deficit closure; no separate gross-growth/litter terms; no
overnight or additional digestion-only diagnostics; a single fixed-seed
realisation; and no modelled reserve, mass, mortality, demographic, or
equilibrium mechanism. No causal effect, long-run stability, parameter
contribution, empirical viability, or kangaroo realism is claimed.

## Exactly one bounded next goal

The specialist recommendation is one Goal 003 only: **paired completion of the
missing 12 daily digestion-only hourly ticks while holding active forage access
and all other settings fixed.** The paired comparison should add exactly 12
post-foraging hourly digestion-only ticks per model day to complete the 24-hour
queue clock, without adding feeding, movement, plant growth, drinking, or a
second parameter change. Seed, horizon, 720-minute active-foraging window,
plant configuration, energetics, feedback, and forcing must remain identical.

Required evidence is hourly queue mass and scheduled digestible energy on early
recovery days; queue mass/energy conservation residuals; daily gut content,
plant removal, digested energy, energy delta, deficit streak, BCI, and realised
active-foraging minutes; and paired repeatability hashes. The discriminating
result is whether digestion-only completion removes the two-day alternation and
materially changes energy deficits without increasing forage opportunity.

Stop after this paired comparison. If the 12 ticks cannot be isolated without
changing feeding, RNG draws, plant stepping, or energy equations, or if queue
conservation fails, report the mechanism as unresolved or defective and do not
broaden into tuning or sensitivity analysis. This is a recommendation, not
authorisation to run Goal 003.

## Provenance

The retained scientific interpretation is
`.superpowers/sdd/goal002-agents/specialist/goal002-specialist.final.txt`.
Final independent acceptance is retained at
`.superpowers/sdd/goal002-agents/final-acceptance/goal002-final-acceptance.final.txt`.
Implementation and contract provenance remains in the Goal 002 `Log.md`,
including the pre-canonical 50,000 g and 720-minute corrections, the focused
contract cycle, the independent-review correction, and the retained
non-canonical development bundles.
