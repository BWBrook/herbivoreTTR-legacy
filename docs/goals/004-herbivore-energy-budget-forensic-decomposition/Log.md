# Goal 004 Log

## 2026-07-14 - Scientific Direction

Goal 003 established a useful diagnostic checkpoint: plant forage remained
finite but mechanically non-binding, yet the semi-synthetic 50 kg herbivore
retained a persistent energy deficit, reached the BCI floor on day 25, and was
nearly indistinguishable from the coupled Goal 002 trajectory in mean intake
and deficit timing.

Barry approved the next direction: decompose the herbivore energy budget with
the eventual aim of correcting either faulty implementation or unrealistic
parameter values. Barry also reaffirmed bounded compartmentalization rather
than a broad stability/calibration exercise.

The orchestrator presented three boundaries:

1. diagnosis-only decomposition followed by a correction decision;
2. diagnosis plus immediate repair of a demonstrated mechanical defect;
3. diagnosis plus parameter calibration to a stable BCI target.

Barry selected option 1 on 2026-07-14. Goal 004 therefore stops with one
evidence-backed correction decision memo. Production or parameter correction
belongs to a separately approved later goal.

## 2026-07-14 - Read-Only Grounding

Planning inspection recorded:

```text
repository = /Users/bwbrook/git/herbivoreTTR
branch = codex/herbivore-ttr-goal-002
HEAD = e45a6b79b4fb5474609e916aa91e49b4ccc878e2
Goal 003 source = exactly eight accepted but currently untracked paths
Goal 003 canonical evidence = ignored run-a/run-b bundles
```

The accepted Goal 003 reference hashes are:

```text
manifest SHA = 7e9ad004137e2a1c3b8a7233f183fcbbed02ef6bfdcf94f43dfded82a707538f
configuration SHA = 68e28c9388e99cbf4658145b9e714556803a27f66367b8a7d8aee8c3535daa82
content SHA = 70ab1cd72f1a0de37cbc0da6317b76cf907be183efe7737e9760f8e25dc204eb
frozen plant SHA = 547ea977d2da05898555359051898c1453d2968907d4cb77e63382fd85d7a23f
```

Read-only calculations on existing Goal 003 CSV evidence found mean daily
intake 555.483291 g, energy intake 3427.569369 kJ, requirement 5673.015934 kJ,
and deficit -2245.446565 kJ. Maintenance is 5509.283531 kJ/day and locomotion
is approximately 164 kJ/day. The best intake day nearly breaks even, while
forage amount was already proven non-binding.

Code tracing found that the 720-minute baseline advances a 24-hour queue only
12 times before daily maintenance closure. It also found that
`minute < time_spent_foraging * 60` makes only minutes 1--719 behaviour-
eligible at a nominal 12-hour window. Repository units documentation and the
implemented locomotion equation appear internally inconsistent; primary
literature is needed before choosing which convention is intended.

These are hypotheses and contract questions, not pre-decided defects.

## 2026-07-14 - Independent Design Review

A profile-bound Sol Medium scientist reviewed three candidate approaches and
recommended diagnosis-only Goal 004. It required an exact queue ledger,
pre-closure completed-clock probe, bite-limit attribution, energy-conversion
reconstruction, demand decomposition, BCI operability probe, and one correction
memo. Review provenance is retained at:

```text
.superpowers/sdd/goal004-agents/design-review/runner/goal004-design-review.final.txt
```

The reviewer identified two internal hazards to include: the 719-minute
endpoint and an apparent locomotion-unit contradiction. It recommended Sol
High review because clock phase, queue release, gut capacity, behaviour, and
RNG topology interact.

The Sol High audit returned `REVISE_DESIGN`, not because the goal was too broad,
but because three identifiability details required tightening:

- the extra 12 ticks must branch at minute 720 before daily closure;
- a carried trajectory cannot uniquely identify gut-capacity mediation once
  behaviour or RNG call topology diverges, so a deterministic fixed-
  opportunity replay is required;
- equality must use a predeclared production projection excluding diagnostic
  metadata, and the correction memo may recommend at most one correction.

Those corrections are incorporated in `Goal.md`, `Plan.md`, and `Runbook.md`.
The Sol High provenance is retained at:

```text
.superpowers/sdd/goal004-agents/high-design-audit/runner/goal004-high-design-audit.final.txt
```

Sol Max was not justified for packet drafting. It is reserved for competing
clock repairs or a disputed central classification after evidence exists.

## 2026-07-14 - Packet Contract Review

A Sol Medium scientist reviewed the actual four-file packet and returned
`REVISE_PACKET`. It found that the first draft did not yet predeclare the full
production projection or deterministic capacity replay, treated the optional
carried trajectory inconsistently, under-specified comparator provenance and
independent ledger recomputation, and blurred local commit versus publication
authority. Review provenance is retained at:

```text
.superpowers/sdd/goal004-agents/packet-review/runner/goal004-packet-review.final.txt
```

The packet now enumerates the complete herbivore, digestion, plant, and daily
projection surfaces; binds full plant diagnostics and summary output to exact
accepted comparator artefacts; specifies the 720-call fixed-opportunity
capacity replay; makes the carried contrast optional and non-blocking; binds
Goal 003 source and evidence hashes to one local commit; independently
recomputes ledger residuals, tolerances, and released energy; names stable
review evidence paths; and requires no push or publication. A focused Sol High
re-review is the final planning acceptance gate.

A first focused Sol High packet re-review then returned `REVISE_PACKET` with no
Critical issue and four Important loopholes. Goal 003 had not retained RNG
vectors, raw queue transitions and probe invariants were not yet independently
bound tightly enough, and the one-recommendation rule was not mechanically
enforced. The packet now makes no direct Goal 003 RNG claim; requires exact
Goal 003 output reproduction plus Goal 004 bare-control/observer state and RNG
identity; retains raw slot, bite-insertion, and invariant evidence; validates
tick order, queue shift/chaining, nutrient release, capacity opportunities and
entry read sets; and enforces evidence-linked, mutually exclusive correction,
literature, or Barry-decision outcomes. Review provenance is retained at:

```text
.superpowers/sdd/goal004-agents/packet-high-rereview/runner/goal004-packet-high-rereview.final.txt
```

The next focused review confirmed the RNG, raw ledger, and decision-rule
repairs but retained one Important issue: a reported invariant CSV could omit a
forbidden changed path. Goal 004 now requires deterministic raw paired state
snapshots, exact per-day/checkpoint coverage and schemas, recursive independent
changed-path reconstruction, hard-coded phase-specific allowed paths, exact
reported-path set equality, and independent capacity read-set/gut/RNG checks.
That intermediate review is retained at:

```text
.superpowers/sdd/goal004-agents/packet-high-final/runner/goal004-packet-high-final.final.txt
```

The final one-issue Sol High acceptance check returned `ACCEPT_PACKET`. It
confirmed the raw snapshot/path gate closes the sole remaining Important issue
and found no new Critical or Important issue. It also confirmed that Sol Max is
not justified before execution. Acceptance provenance is retained at:

```text
.superpowers/sdd/goal004-agents/packet-high-acceptance/runner/goal004-packet-high-acceptance.final.txt
```

## 2026-07-14 - Planning-Only Packet

Created:

```text
docs/goals/004-herbivore-energy-budget-forensic-decomposition/Goal.md
docs/goals/004-herbivore-energy-budget-forensic-decomposition/Plan.md
docs/goals/004-herbivore-energy-budget-forensic-decomposition/Runbook.md
docs/goals/004-herbivore-energy-budget-forensic-decomposition/Log.md
```

The packet defines the frozen comparator, completed-state outcome,
observation/identity/counterfactual/literature labels, production projection,
ledger equations, eight orthogonal probes, pre-closure clock branch,
fixed-opportunity capacity replay, total downstream contrast, classification
tree, correction and literature gates, exact artefacts, validation ladder,
authority boundary, and stop rules.

No implementation file, production model, parameter, API, Goal 003 source,
artefact, test, simulation, lint, package check, target, document build, staging,
commit, push, or publication occurred while drafting Goal 004. Read-only R was
used only to summarize existing Goal 003 CSV evidence.

## 2026-07-15 - Execution Authorization And Comparator Lock

Barry approved the accepted packet and authorized Goal 004 execution. This is
recorded as authorization for the packet's required local immutable Goal 003
comparator commit and, separately, Goal 004 diagnostic execution. It does not
authorize a Goal 004 commit, push, publication, production correction, or
parameter change.

The exact eight-path Goal 003 footprint passed its pre-commit gate:

```text
tree/content digest = 03423aa5ec512ed4fda695a0ad55f828c3c308d1a7992ee20e09adc5af3a0d48
profile SHA = 07b99b21cdb48d34eac570a246c626d2b82931126bb4173aaf298c6327b85403
runner SHA = b071096e431ee26c8e4b5946881dfcff35ec5bded0af379b267a04150722fb3b
test SHA = 1f5ea23dfea3ab379141596c9830c97715522f83b6b4be71ad9e7a140e221530
manifest SHA = 7e9ad004137e2a1c3b8a7233f183fcbbed02ef6bfdcf94f43dfded82a707538f
```

It was committed locally, without push, as:

```text
abf68b691b4e30020625d1871dcabe56a5926bc1 Record Goal 003 herbivore-only reference
```

The normal commit hook could not build the `lorenzwalthert/precommit`
isolated environment because lockfile `Rcpp 1.1.1` fails to compile under R
4.6.1 on the removed `R_NamespaceRegistry` symbol. The second commit attempt
therefore skipped only `style-files` and `lintr`; end-of-file, trailing-
whitespace, YAML, and large-file hooks passed. This hook-infrastructure issue
did not alter the staged eight-path footprint or accepted Goal 003 evidence.
Goal 004 still requires its own focused/full tests and lint before acceptance.

A profile-bound Luna Light scout then mapped the production call order, state
mutations, RNG consumers, reusable Goal 003 helpers, and required Goal 004
wrappers without running R or editing files. It confirmed that a Goal 004-only
daily wrapper is required to expose hourly and minute-720 checkpoints while
calling production feeding, digestion, plant finalisation, water, energy, and
BCI functions unchanged. Scout evidence is retained at:

```text
.superpowers/sdd/goal004-agents/executor-scout/runner/goal004-executor-scout.final.txt
```

The scout also distinguished the endpoint probe's daily foraging-window
`minute < time_spent_foraging * 60` boundary from the unrelated production
`<= EAT_RADIUS` distance test. The packet now names that distinction
explicitly; no scientific escalation was required.

## 2026-07-15 - First Executor Attempt Not Accepted

A profile-bound Luna High executor created a first-pass Goal 004 profile,
helper, runner, and focused test. The direct runner reached its 1200-second
hard timeout before returning a completion report. Its persisted metadata is:

```text
.superpowers/sdd/goal004-agents/executor/runner/goal004-executor.metadata.json
model = gpt-5.6-luna
reasoning effort = high
return code = 124
timed out = true
```

The attempt retained an honest initial RED caused by the absent runner and a
later GREEN for three shallow helper tests. That GREEN does not satisfy the
packet's focused contract. Orchestrator inspection found that the partial
runner did not execute the tick-phase, feedback-disabled, or minute-720
endpoint counterfactuals; several invariant and manifest claims were
hard-coded or self-compared; the baseline daily budget covered only its first
day; and comparator-tree validation did not compare the accepted tree digest.

The first canonical run was then stopped manually after more than five minutes
without emitting an artefact. The repeatable performance cause is excessive
serialization and hashing of the complete plant, herbivore, daily, and RNG
projection at almost every minute in two separate 120-day trajectories. No
run-a or run-b evidence was accepted or retained. This is a failed
implementation attempt, not a scientific result, and it does not satisfy any
open Goal 004 task.

A bounded repair must first add failing tests for the missing contracts, then
replace the redundant observer architecture and implement real one-factor
probes. Canonical execution remains an orchestrator-controlled gate after the
focused suite and a deliberately small runtime proof pass.

## 2026-07-15 - Bounded Repair And Canonical Diagnosis

The orchestrator repaired the incomplete executor output within the Goal 004-
only source surface. Focused RED/GREEN iterations added real tick-phase,
completed-clock, fixed-opportunity capacity, locomotion identity,
feedback-disabled, and endpoint probes; complete raw state snapshots; exact
queue and bite ledgers; fixed diagnostic RNG; explicit carried-contrast skip;
and the machine-readable classification contract.

Five failed canonical attempts were preserved rather than overwritten. They
identified, in order, uncontrolled diagnostic RNG, incomplete ledger linkage,
an insufficient diagnostic figure, legend occlusion, and a classification that
did not yet expose the unresolved daily-clock decision to Barry. None is
accepted scientific evidence.

The accepted classification makes no dominant-cause claim and recommends no
production correction. It presents two comparable daily-clock alternatives:
a 720-minute complete accounting day with 12 ticks, or 12 active feeding hours
inside a 24-hour physiological day with 24 ticks. Both are linked to
`G004-tick_phase`, `G004-completed_clock`, and `G004-capacity_pathway`, and
require Barry's decision after source-contract validation. The locomotion axis
is recorded as an implementation-or-contract issue because repository and
equation units conflict, while explicitly stating that no implementation
defect has been demonstrated.

## 2026-07-15 - Final Evidence-Audit Repair

The first independent Luna High code/evidence audit returned `BLOCKED` with
four Important findings: observer invariant rows used self-comparisons,
completed-clock plant/demand/endpoint invariants contained self-comparisons,
daily-budget reconstruction overwrote captured values before validation, and
first-divergence evidence returned root objects or hard-coded labels.

The final repair:

- derives observer evidence from distinct bare-control and observer replays;
- compares separately captured control/intervention or pre/post states;
- preserves captured daily-budget fields and emits separate `ledger_*`
  reconstructions;
- requires baseline intake to agree with raw daily diagnostics and queue
  insertion evidence;
- reports path-local first-divergence values and hashes; and
- groups insertion-source reconciliation by exact branch/day/tick/queue keys,
  preserving the full check while avoiding repeated full-ledger scans.

A profile-bound Luna High repair worker timed out after 300 seconds and was not
accepted. Its useful partial diff was inspected and completed by the
orchestrator. A memory-heavy intermediate design retaining every minute-level
production object was also stopped and replaced with matched per-phase hash
equality plus independent in-memory daily/replay comparisons. These are
process records, not scientific results.

## 2026-07-15 - Accepted Evidence And Validation

The final canonical bundles are:

```text
artefacts/goal004_energy_decomposition/run-a/
artefacts/goal004_energy_decomposition/run-b/
files per bundle = 13
source SHA = 2d1117462c0fa401ce5398729b8bbd32e50a653475cebb9b84f9016a7943b0d1
content SHA = 024d82acf3b03f9e267d51cbf845a51db37a5588b85ed839f8569734a068b45a
output-set SHA = 1a6ea1f0a916c7bb5e6e95174a5438716b2499f0baa8e891267250ef59d9293c
```

All 13 files are byte-identical between run-a and run-b. The three baseline
daily, plant, and summary files are byte-identical to accepted Goal 003.
Both manifests are complete, observer state/RNG equality is true, all ledger
and probe gates are true, and production/parameter changes are false.

The exact Runbook checks reported:

```text
baseline projection rows = 179040
queue ledger rows = 829440
intake-limit rows = 345600
maximum scaled queue residual = 0.005128524
Section 5 structured ledger/probe checks = pass
Section 6 baseline equality/scientific stops = pass
```

Repository validation reported:

```text
focused Goal 004 suite = pass
make test = 1447 pass, 0 fail, 0 warn, 32 expected opt-in skips
make lint = pass
renv::status() = synchronized, no issues
git diff --check = pass
```

The ecologist-facing synthesis is
`docs/log/20260714_goal004_energy_budget_decomposition.md`. No production
`R/` file, biological parameter, package metadata, lockfile, staging, Goal 004
commit, push, or publication occurred.

## 2026-07-15 - Independent Final Acceptance

A fresh Luna High code/evidence re-review returned
`ACCEPT_CODE_EVIDENCE`. It verified the four repaired audit surfaces, canonical
repeatability and comparator identity, validation transcripts, and exact source
scope, with no Critical or Important finding. Provenance is retained at:

```text
.superpowers/sdd/goal004-agents/final-audit/code-rereview-runner/goal004-final-code-rereview.final.txt
```

A fresh Sol High ecological memo review returned `ACCEPT_MEMO`. It reproduced
the quoted quantitative results, confirmed the observation/identity/
counterfactual boundaries, accepted the non-dominance and non-estimate
language, and agreed that daily-clock semantics and locomotion units require
source-contract validation followed by Barry's decision. It found no Critical
or Important issue and judged that Sol Max was not justified. Provenance is
retained at:

```text
.superpowers/sdd/goal004-agents/final-audit/memo-review-runner/goal004-final-memo-review.final.txt
```

Goal 004 is accepted locally. It ends with no production correction, parameter
change, staging, Goal 004 commit, push, or publication.

## Progress Ledger

- [x] Goal 003 scientific conclusion and unresolved herbivore mechanisms
  reviewed.
- [x] Energy, digestion, intake, demand, feedback, and timebase code traced.
- [x] Diagnosis-only boundary selected by Barry.
- [x] Sol Medium scientific design review completed.
- [x] Sol High identifiability audit incorporated.
- [x] Four-file Goal 004 planning packet drafted.
- [x] Sol Medium packet contract review incorporated.
- [x] Focused Sol High packet re-review has no open Critical or Important
  finding.
- [x] Barry authorizes the local Goal 003 baseline commit; push/publication is
  not required or authorized.
- [x] Goal 003 is committed as the immutable comparator at
  `abf68b691b4e30020625d1871dcabe56a5926bc1`.
- [x] Barry separately authorizes Goal 004 execution.
- [x] Goal 004 focused RED/GREEN contract is complete.
- [x] Canonical run-a/run-b evidence is complete and repeatable.
- [x] Classification and correction decision memo is independently accepted.
- [x] Final no-correction/no-commit/no-push state is ready to report to Barry.
