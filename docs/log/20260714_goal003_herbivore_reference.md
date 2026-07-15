# Goal 003 Herbivore-Only Daily-Clamped Forage Reference

Date: 2026-07-14

Status: accepted after full validation and independent scientific rereview.

## Question And Design

Goal 003 asks what trajectory the existing herbivore model produces when the
accepted Goal 002 plant snapshot is restored at the start of every day and
plant growth is disabled. The herbivore state and the existing within-day
selection, movement, eating, digestion, energetics, water, feedback, and RNG
semantics carry forward unchanged.

This is a finite but demonstrably non-binding daily forage reference. It is
not literally unlimited forage. The design jointly removes plant growth and
inter-day plant-state carryover, so it does not separately identify their
effects and is not a causal contrast.

## Reset And Carryover Map

At each of 120 diagnostic days (model days 6--125):

1. The exact complete Goal 002 pre-growth plant object is copied from a frozen
   snapshot.
2. The opening plant is proven byte-stably identical to that snapshot without
   consuming RNG or modifying the herbivore.
3. The existing daily simulator runs for 720 active minutes with
   `apply_growth = FALSE`, seed `2002 + day * 100000`, and normal within-day
   plant depletion.
4. The returned herbivore state is carried into the next day.
5. The altered closing plant state is recorded and discarded; it never
   supplies the next opening state.

The accepted Goal 002 manifest, configuration, and output-set hashes were
checked read-only. Canonical JSON/value comparison also confirms that the
resolved initial herbivore state, complete digestion queues, and initial plant
row match Goal 002.

## Observations

Two clean executions produced byte-identical CSV, JSON, PNG, and manifest
files. The final run-a manifest SHA-256 is
`7e9ad004137e2a1c3b8a7233f183fcbbed02ef6bfdcf94f43dfded82a707538f`;
configuration digest is
`68e28c9388e99cbf4658145b9e714556803a27f66367b8a7d8aee8c3535daa82`;
content digest is
`70ab1cd72f1a0de37cbc0da6317b76cf907be183efe7737e9760f8e25dc204eb`;
and frozen plant-state digest is
`547ea977d2da05898555359051898c1453d2968907d4cb77e63382fd85d7a23f`.

Forage remained mechanically non-binding in the captured trajectory:

- all 120 daily opening states were exact copies of the frozen snapshot;
- growth was disabled and all prior closing states were discarded;
- all 86,400 captured minute states retained detectability, reachability, and
  a positive plant-selection score;
- positive intake occurred on 17--76 minutes per day, always at 0 m from the
  plant and within the production eating radius;
- closing shoot was 49.080771--49.805012 kg dry matter;
- the minimum closing availability margin above `MIN_SHOOT` and the entire
  gut-capacity bound was 47.965555 kg;
- the minimum minute-level selection score was 12.644096;
- composition changes were at most `3.02e-14`, within the `1e-10` numerical
  tolerance;
- maximum absolute plant-accounting residuals were `1.24e-13` kg for dry
  matter and `8.54e-13` kg for forage water; opening and closing component
  residuals were zero.

The herbivore nevertheless declined throughout the reference:

- energy balance was negative on 120/120 days;
- physiological stress was flagged on 120/120 days;
- body condition fell from a maximum of 0.736316 to the floor on day 25 and
  remained there;
- final cumulative energy balance was -269453.587765 kJ;
- daily intake ranged from 194.988 to 919.229 g.

The frozen Goal 002 comparison is very similar. Mean daily intake is exactly
555.483291 g in both trajectories; both have 120 deficit days, 120 stress
days, and a day-25 BCI floor. Goal 003 final cumulative energy is only
179.374928 kJ less negative than Goal 002 over 120 days. The trajectories are
not byte-identical and their plant paths differ, as expected: Goal 002 closing
shoot spans 31.995930--65.535966 kg, whereas Goal 003 is reset daily and closes
within 49.080771--49.805012 kg.

Energy and water residual checks are wiring identities, not independent
biological conservation tests. The cumulative water trajectory reflects the
existing automatic closure semantics and is not evidence of realistic water
availability.

## Inference

Inter-day plant growth and plant-state carryover are not necessary conditions
for the persistent physiological decline under this one configuration, seed
schedule, implementation, and 120-day window.

This result does not show that vegetation has no effect, that the herbivore is
non-viable, that the system is at equilibrium, or that the physiological
mechanisms are empirically realistic. It does not identify the ultimate cause
of decline. The next diagnostic work should remain herbivore-focused, with
particular attention to energy intake/requirement construction, gut turnover,
and the known 12-of-24 digestion-queue timing before any recoupling claim.

## Assumptions And Uncertainty

- There is one semi-synthetic herbivore, one homogeneous plant, one fixed seed
  schedule, and no replicate-level uncertainty estimate.
- Days are autocorrelated observations of one trajectory, not independent
  replicates.
- Minute-level plant states are reconstructed from the exact opening state and
  cumulative dry-matter/forage-water intake. Production code independently
  enforces the eating-radius guard immediately before each bite.
- Fixed-seed repeatability is computational reproducibility, not biological
  robustness.
- The BCI floor masks the magnitude of continued deterioration after day 25.
- Goal 003 intentionally leaves the existing digestion timing and automatic
  water closure unchanged.

## Evidence Surface

Canonical ignored evidence:

```text
artefacts/goal003_herbivore_reference/run-a/
artefacts/goal003_herbivore_reference/run-b/
```

Superseded pre-review and pre-label-fix evidence is retained under
`.superpowers/sdd/goal003-agents/` and is not acceptance evidence. No staging,
commit, push, or publication was performed under Goal 003 execution authority.

Independent Sol High final audit verified the code, frozen comparator,
artefacts, bounds, hashes, reset chain, production code trace, and scope. It
identified one Important overstatement: an unsupported causal ranking of
vegetation carryover after the permitted necessity inference. That sentence
was deleted. A narrow independent Sol Medium recheck returned `ACCEPT` with no
remaining Critical or Important wording issue and no need for Barry or Sol Max
escalation.

Two Minor notes remain. The manifest does not hash the currently untracked
runner source, so provenance depends on preserving this workspace until a
later authorized commit binds source and evidence documentation. Focused tests
do not directly mutate every emitted sequence and residual field, although
the runner enforces those contracts and the root structured checks verified
them on canonical evidence. Neither note weakens the accepted result.
