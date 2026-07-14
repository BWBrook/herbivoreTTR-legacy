# Goal 002: Minimal Coupled Baseline Diagnosis

Status: completed and independently accepted on 2026-07-12; uncommitted by
authority boundary.

Owner: Herbivore TTR orchestrator.

Execution model: orchestrator-controlled, profile-bound workers launched with
`/Users/bwbrook/.local/bin/codex-profile-exec`. Native task-name-only spawning
is not permitted until runtime profile binding has been independently proven.

Repository: `/Users/bwbrook/git/herbivoreTTR`.

Working branch: `codex/herbivore-ttr-goal-002`.

Starting commit: `7ea01321b3f6db398b6b6e549d2bfc478d93e420`
(`docs: close out Goal 001 publication record`).

## Completed-State Objective

Create and run one purpose-built, fixed-seed reproducible diagnostic profile
containing one simplified grey-kangaroo-like herbivore, one homogeneous
regenerating forage resource, and genuinely constant environmental forcing.
Use its compact daily evidence to characterize why the coupled system does or
does not maintain bounded physiological and vegetation trajectories over the
observed 120 days.

The accepted result is an evidence-backed mechanistic diagnosis of the
observed behaviour, or an explicit unresolved set of competing explanations.
It includes energy, water, intake, movement, vegetation, stress, and
state-carryover accounting, plus one tightly bounded recommendation for the
next goal. Goal 002 does not have to stabilize the system and must not tune it.

## Scientific Framing

This is a deliberately semi-synthetic laboratory system for understanding the
model. The herbivore is informed loosely by an eastern-grey-kangaroo-like
grazer but is not a parameterized representation of that species. The forage
and constant environment are diagnostic constructs, not a reconstruction of a
particular northern Australian savanna.

The wider programme may later introduce seasonality, multiple forage types,
real modern analogues, and extinct Sahul megafauna. Those extensions are not
part of Goal 002. The immediate question is whether the simplest coupled system
is understandable before realism is added.

## Why This Matters

Goal 001 established a trusted engineering baseline, but existing long-horizon
outputs can show persistent physiological stress even when numerical and
biomass guardrails pass. A general scenario cannot distinguish whether that
state arises from configuration, daily accounting, state carryover, parameter
scale, or a genuine interaction among model components.

The project should understand that failure mode before attempting calibration,
adding physiology, or interpreting habitat effects on extinct megafauna.

## Read First

1. `AGENTS.md`
2. This `Goal.md`
3. `Plan.md`
4. `Runbook.md`
5. `Log.md`
6. `docs/product_brief.md`
7. `docs/decisions.md`
8. `docs/contracts/scenario_contract_v2.md`
9. `docs/contracts/scenario_run_output_contract_v2.md`
10. `inst/extdata/scenarios/reference_grazer_v1.yaml`
11. `R/init_conditions.R`
12. `R/init_plants.R`
13. `R/init_herbivore.R`
14. `R/scenario_runner_v1.R`
15. `R/run_daily_herbivore_simulation.R`
16. `R/stability_suite_v1.R`
17. `tests/testthat/test_energy_water_balance.R`
18. `tests/testthat/test_domain_sanity_invariants.R`
19. `tests/testthat/test_determinism_contract.R`

## Starting-State Observations

- `reference_grazer_v1.yaml` uses one 500 kg grazer, three vegetation types,
  nutrient-targeting foraging, seven days, and a nominally flat climate.
- `init_conditions(mode = "flat")` holds soil water and nitrogen constant but
  still applies the configured sinusoidal temperature amplitude.
- `init_plants()` samples initial plant type and biomass; one allowed forage
  type alone does not produce an inspectably identical initial plant state.
- Herbivore state already includes daily energy and water balances, balance
  ratios, body-condition index, deficit streaks, physiological stress, intake,
  movement, gut state, and cumulative simulation state.
- Existing stability summaries report guardrail and stress outcomes, but were
  designed for broader scenario suites rather than this minimal diagnosis.

These are observations to test, not conclusions about model correctness.

## In Scope

- Define one named diagnostic profile that is independent of production
  defaults and contains exactly one herbivore and one forage type.
- Inventory the external forcing consumed by the diagnostic runner. The
  expected vector is temperature, soil water, and soil nitrogen; verify each
  by value across the run. If another external driver is consumed, record it
  and either add the same value-based constancy check or stop if it cannot be
  held constant without changing core behaviour.
- Make the initial plant state explicit and reproducible rather than merely
  reproducible through hidden random draws.
- Record the complete resolved initial herbivore state before stepping,
  including coordinates, gut and digestion state, body condition, behavioural
  state, feedback settings, and any seeded stochastic draw.
- Use one fixed seed and one bounded primary horizon of 120 model days.
- Add the smallest non-exported diagnostic harness needed to run the profile
  and extract compact daily evidence. Do not add a public API.
- Record the exact configuration and a content hash in the run manifest.
- Produce daily herbivore and plant diagnostics sufficient to reconcile
  energy intake, total requirement, daily delta, and cumulative balance; water
  inputs, requirement, daily net, and cumulative balance; and opening plant
  biomass, regeneration, herbivore removal, and closing biomass. If an
  accounting term is unavailable, quantify the resulting residual and retain
  the explanation as unresolved.
- Describe early, middle, and late trajectory behaviour without inventing a
  biological pass threshold.
- Trace how daily deficits and surpluses affect later state, including what is
  reset daily, accumulated, bounded, or not represented.
- Classify each important finding as observed configuration behaviour, code
  defect, suspected parameter-scale issue, model interaction, missing state
  mechanism, or unresolved. A parameter-scale issue remains a qualified
  hypothesis unless an internal dimensional or accounting inconsistency proves
  it within this goal.
- Recommend exactly one bounded next-goal intervention, supported by the
  diagnosis.

## Out Of Scope

- Tuning parameters to produce a preferred equilibrium or non-stressed state.
- Optimization, calibration, fitting, broad sensitivity analysis, seed
  ensembles, or factorial experiments.
- Literature review or empirical parameterization of eastern grey kangaroos,
  other modern herbivores, Diprotodon, or other extinct taxa.
- Seasonal or stochastic forcing, multiple forage types, nutritional-choice
  experiments, competition, multiple animals, or population dynamics.
- Adding reserve, mass-loss, mortality, demographic, or other physiological
  mechanisms.
- Changing a scientific threshold, public API, output contract, package
  version, production default, or existing reference scenario semantics.
- Paper framing, manuscript drafting, publication claims, or release work.
- Remote or HPC execution, expensive compute, or dependency additions.
- Merge, tag, release, PR, or remote push.

## Deliverables And Review Surface

- This four-file Goal 002 packet with a current `Log.md`.
- `inst/extdata/scenarios/goal002_minimal_coupled_v1.yaml`, containing the
  complete diagnostic configuration or a manifest pointer to any explicit
  state table required by the harness.
- `scripts/run_goal002_minimal_diagnosis.R`, a non-exported reproducible
  runner with the command-line contract specified in `Runbook.md`.
- Focused tests under
  `tests/testthat/test_goal002_minimal_diagnosis.R`.
- Ignored evidence under `artefacts/goal002_minimal_coupled/`, including:
  `run_manifest.json`, `daily_diagnostics.csv`, `plant_diagnostics.csv`,
  `diagnostic_summary.json`, and `diagnostic_trajectories.png`.
- `docs/log/20260712_goal002_minimal_coupled_diagnosis.md`, containing the
  configuration, accounting map, observed trajectories, evidence-backed
  classification, limitations, and one next-goal recommendation.
- Retained profile-worker provenance: `.metadata.json`, `.events.jsonl`,
  `.final.txt`, and `.stderr.txt` for each independent worker or reviewer.
- Final diff, exact changed-path list, validation output, artefact inspection,
  and independent scientific review.

The named implementation paths are the authorised maximum write surface. A
worker may propose a narrower layout, but must pause before adding another
tracked path.

## Acceptance Gates

1. The profile demonstrably contains one herbivore, one forage type, an
   explicit initial plant state, one fixed seed, and 120 model days.
2. The complete external forcing vector consumed by the runner is enumerated.
   Temperature, soil water, and soil nitrogen each have exactly one value
   across the run; any additional consumed driver is also constant by value.
   A label such as `flat` is not evidence.
3. Two clean executions into separate empty directories produce identical
   configuration hashes and byte-identical diagnostic CSV and JSON content.
4. Diagnostic outputs have complete daily coverage, finite numeric values,
   non-negative biomass, bounded body condition, and no existing gut-capacity
   or domain-invariant violation.
5. The complete initial herbivore state is recorded before stepping. Every
   energy, water, intake, movement, stress, biomass, and condition field used
   in the diagnosis is traced to its generating or updating code and its
   carryover/reset rule. Any unreconciled residual is quantified and labelled.
6. The report distinguishes observation from inference and does not describe
   the synthetic herbivore as an empirical eastern grey kangaroo model. It
   names the existing thresholds behind `PhysiologicalStressFlag` and treats
   that field only as a model-defined indicator.
7. No parameter search, tuning, new mechanism, public-interface change, or
   scientific threshold is introduced.
8. The conclusion reports direction, magnitude, persistence, and observed
   reversals in the 120-day trajectories. It may say that no material trend was
   detected over the observed window only when the reported evidence supports
   that wording; it must not claim equilibrium or asymptotic stability.
9. An independent profile-bound scientific reviewer reports no open Critical
   or Important issue in the diagnosis, scope compliance, or recommendation.

## Authority

During execution, profile-bound workers may inspect the full repository and
may edit only the named Goal 002 write surface. They may run the commands in
`Runbook.md` and regenerate the ignored Goal 002 evidence directories.

The orchestrator may integrate narrow corrections after review. No worker or
orchestrator is authorised by this packet to commit, push, merge, tag, publish,
or open a PR. Those actions require later explicit authority from Barry.

## Stop And Escalate

Stop and return evidence before:

- changing core model behaviour merely to make the baseline look stable;
- changing an existing production default, reference scenario, public API, or
  output schema;
- choosing a biological viability threshold or taxon-specific parameter;
- adding reserve dynamics, mass loss, mortality, demography, or another state
  mechanism;
- expanding beyond one animal, one forage type, constant forcing, one seed, or
  the 120-day primary run;
- running extra counterfactuals, parameter sweeps, seasonal scenarios, or
  empirical calibration;
- interpreting fixed-seed repeatability as absence of stochasticity, or
  synthetic results as evidence about Sahul megafaunal decline;
- adding a dependency or requiring remote compute;
- editing outside the authorised write surface.

If the single baseline cannot distinguish competing causes, record those
explanations explicitly and recommend the smallest discriminating Goal 003.
Do not broaden Goal 002 to resolve them.
