# Rebuild Goal 001: Legacy Freeze and Clean Repository Foundation

Status: planning complete; execution is not authorized.

Owner: one bounded Herbivore TTR executor, with root review. A subagent fleet is
not needed by default. Escalate only if an unexpected high-risk fork requires
independent scrutiny.

Repository at formulation: `/Users/bwbrook/git/herbivoreTTR`.

## Outcome

Preserve the current repository as the final private, read-only
`BWBrook/herbivoreTTR-legacy`, then establish a genuinely new private
`BWBrook/herbivoreTTR` containing only a minimal functional R package scaffold
and design documentation. Stop before implementing physiology.

This is a repository-foundation goal, not a model-development goal. Its
principal question is whether the legacy record can be frozen completely while
the active project restarts with clean history, narrow architecture, and an
explicit scientific contract.

## Why

The current code and documentation remain useful historical evidence, but they
must not define the rebuilt model's scientific truth or architecture. A clean
repository prevents accidental inheritance of coupled implementation choices,
release machinery, generated evidence, and undocumented assumptions while
retaining an accessible provenance trail.

## Approved Design Contract

- Keep R. Do not use Python, Julia, C++, or Rust for the rebuild.
- Treat legacy C++ and R behavior as historical evidence, not scientific
  authority.
- Rank ecological logic, dimensional consistency, empirical evidence, and
  transparent assumptions above legacy behavior.
- Use a small functional R package plus thin experiments. Use plain validated
  state records and pure functions, with strict separation of state, fixed
  parameters, prescribed inputs, process functions, and history. Do not adopt
  an object-oriented framework.
- Use explicit unit suffixes in names and documentation.
- Work in small goals: one principal question, one subsystem, compact
  predeclared outputs, proportionate tests, an explicit stop, and discussion
  before the next layer. Do not build bulk evidence machinery.

The future irreducible core is specified now but is out of scope for this goal:
a 50 kg semi-synthetic macropod-like herbivore; an explicit 24-hour clock with
hourly transitions; prescribed hourly intake; one homogeneous controlled food;
one well-mixed gut pool with first-order hourly passage; body-energy reserve in
kJ; fixed reference mass; maintenance-only expenditure; periodic steady-state
gut initialization; an exact neutral baseline; gut capacity as a fail-fast
input-validation boundary; one tidy hourly table and a derived daily summary;
and conservation plus neutral, deficit, and surplus tests.

Later goals may add activity, dynamic mass, protein, water, thermoregulation,
plants, spatial foraging, and coupling, one layer at a time.

## Review Surface

Review is limited to:

1. the final legacy commit, annotated tag, remote settings, and clean sibling
   checkout;
2. the replacement repository's single root commit, exact minimal tree,
   package metadata, design documents, and clean status;
3. the external `R CMD build` and `R CMD check --no-manual` result, synchronized
   `renv` status, and skeleton test result; and
4. proof that the two repositories do not share Git history and that no
   generated legacy material entered either commit.

## Current State

The following state was observed or supplied during formulation on 2026-07-16
and must be rechecked at execution:

```text
repository = /Users/bwbrook/git/herbivoreTTR
branch = codex/herbivore-ttr-goal-002
HEAD = abf68b691b4e30020625d1871dcabe56a5926bc1
branch relation = ahead of origin/codex/herbivore-ttr-goal-002 by one
origin = git@github.com:BWBrook/herbivoreTTR.git
origin/main = 872fb20fe5ff4ffd00cf2d29369e61fad764867a
origin/main relation = ancestor of HEAD
GitHub visibility = private
GitHub default branch = main
/Users/bwbrook/git/herbivoreTTR-legacy = absent
/Users/bwbrook/git/herbivoreTTR-rebuild-bootstrap = absent
GitHub BWBrook/herbivoreTTR-legacy = absent
available space under /Users/bwbrook/git = 254 GiB
```

The known untracked Goal 004 set is exactly:

```text
docs/goals/004-herbivore-energy-budget-forensic-decomposition/Goal.md
docs/goals/004-herbivore-energy-budget-forensic-decomposition/Log.md
docs/goals/004-herbivore-energy-budget-forensic-decomposition/Plan.md
docs/goals/004-herbivore-energy-budget-forensic-decomposition/Runbook.md
docs/log/20260714_goal004_energy_budget_decomposition.md
inst/extdata/scenarios/goal004_energy_decomposition_v1.yaml
scripts/goal004_energy_ledger_helpers.R
scripts/run_goal004_energy_decomposition.R
tests/testthat/test_goal004_energy_decomposition.R
```

This four-file Rebuild Goal 001 packet is also untracked after formulation.
The previously generated 5.4 GB Goal 004 bundles and 201 MB scratch-agent
traces were deliberately deleted with Barry's authorization. They must not be
regenerated, restored, committed, or archived.

## Authority

This packet is executable guidance, not execution authority. Barry must give a
separate explicit authorization before any commit, push, tag, directory move,
remote mutation, GitHub rename, GitHub creation, GitHub archive action, or
deletion. Authorization must cover the full guarded sequence.

Once authorized, this goal permits exactly one final legacy snapshot commit and
exactly one replacement foundation commit. It permits no other commit. A failed
commit attempt that produces no commit may be diagnosed, but bypassing hooks,
amending, or creating an extra commit requires escalation.

No force push, reset, clean, stash, history rewrite, rollback improvisation,
duplicate remote, or destructive recovery is allowed.

## In Scope

- Build and validate the replacement first at
  `/Users/bwbrook/git/herbivoreTTR-rebuild-bootstrap`.
- Add one concise `ARCHIVED.md` notice to the legacy repository.
- Include existing history, committed Goal 003, the exact compact Goal 004 set,
  and this packet in the final legacy snapshot.
- Fast-forward remote `main`, create annotated tag
  `legacy-final-2026-07-16` at that exact snapshot, rename the old remote, move
  the local checkouts, create and push the replacement, then archive legacy.
- Leave legacy accessible only as the clean sibling checkout
  `/Users/bwbrook/git/herbivoreTTR-legacy`.

## Out Of Scope

- Any physiological function, plant model, calibration, simulation, model
  output, or scientific parameter choice.
- Legacy compatibility code, copied legacy source or documentation, a subtree,
  fork, shared-history branch, targets pipeline, release machinery, dashboard,
  or migration of generated artifacts.
- Any change outside the exact legacy and bootstrap paths declared in
  `Plan.md`.

## Replacement Foundation

The new repository has package identity `herbivoreTTR`, version `0.0.0.9000`,
Barry Brook only as author and creator, MIT licensing, no `Imports`, and only
the minimum `Suggests` needed for the skeleton test. Its source tree contains:

- package metadata, license, ignores, `renv.lock`, and standard `renv`
  activation support;
- package-level R documentation and its generated `Rd` scaffold, with no
  physiological function;
- a `testthat` loader and one skeleton metadata test;
- `experiments/README.md` and `references/README.md`; and
- the charter, model specification, variable dictionary, roadmap, and clean-
  rebuild decision listed in `Plan.md`.

The documents must record every approved decision in this goal. They must point
to private legacy repository `BWBrook/herbivoreTTR-legacy`, tag
`legacy-final-2026-07-16`, and scientific baseline commit
`abf68b691b4e30020625d1871dcabe56a5926bc1`. The final migration report must
also give the exact commit resolved by the legacy tag.

`outputs/` and all build/check products are ignored and absent. Persistent
generated evidence is capped at zero. Validation occurs in a temporary external
directory that is removed after inspection; only a concise transcript summary
may be added to this `Log.md` before the final legacy commit and repeated in the
executor's final response.

## Acceptance

Acceptance requires all of the following:

- the old remote `main` advanced by ordinary fast-forward to one final snapshot
  containing only the declared legacy additions;
- annotated tag `legacy-final-2026-07-16` resolves exactly to that commit;
- `BWBrook/herbivoreTTR-legacy` is private and archived only after the
  replacement push is verified;
- `/Users/bwbrook/git/herbivoreTTR-legacy` is clean, on `main`, and has origin
  `git@github.com:BWBrook/herbivoreTTR-legacy.git`;
- the replacement is a new private repository with default branch `main`, one
  root foundation commit, the exact declared tree, and no common history with
  legacy;
- `/Users/bwbrook/git/herbivoreTTR` is the clean replacement checkout with
  origin `git@github.com:BWBrook/herbivoreTTR.git`;
- `renv::status()` reports synchronization, the skeleton test passes, and both
  required R package commands pass from temporary external validation space;
  and
- the final report presents both clean states, remote URLs and settings, exact
  SHAs and tag, replacement tree, validation summary, and residual risks.

## Stop And Escalate

Stop before mutation if any preflight observation differs, any unknown dirty
path exists, a sibling path or remote name collides, the old remote is not the
expected private repository, `origin/main` changed, the ancestor proof fails,
the tag exists, free disk is below the runbook threshold, or authorization is
not explicit.

After mutation begins, stop immediately on any failed commit, push, tag, GitHub
API call, directory move, remote update, validation, or verification. Report
the exact split state and take no rollback or destructive recovery action.
Completion stops after the final evidence report. Do not implement physiology.
