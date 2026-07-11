# Goal 001 R 4.6 / v2.0 Readiness Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` for implementation and
> `superpowers:test-driven-development` for any new behaviour or bug fix.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a reviewed, validated, locally committed R 4.6 / v2.0
readiness baseline from the inherited dirty patch without changing science or
publishing remotely.

**Architecture:** Treat the inherited patch as one provenance bundle with
four coupled surfaces: runtime/dependency metadata, command orchestration,
external reproducibility, and readiness documentation. Independent auditors
assess those surfaces before one bounded worker reconciles them. The
orchestrator owns the validation ladder, artefact inspection, final acceptance,
and exact-path commit.

**Tech Stack:** R 4.6.x, `renv` 1.2.3, GNU Make, `testthat`, `lintr`,
`targets`, Quarto, `actionlint`, Git.

## Global Constraints

- Work only in `/Users/bwbrook/git/herbivoreTTR` on
  `codex/herbivore-ttr-goal-001`.
- Preserve all inherited work until it has been classified from evidence.
- Do not change scientific assumptions, public APIs, output schemas, scenario
  semantics, model defaults, or package version.
- Canonical restore policy remains `RENV_CONFIG_PAK_ENABLED=FALSE` unless Barry
  authorizes a policy change.
- R 4.6.1 host validation and the R 4.6.0 lock entry must be either shown
  compatible or reconciled with an explicit provenance rationale.
- No reset, clean, stash, destructive checkout, force operation, merge, tag,
  push, PR, or external publication.
- Generated files under ignored artefact, package-build, check, target, and
  cache paths are validation evidence and are not staged.
- Stage exact accepted paths only after final review.

---

## File Map

Inherited implementation surface:

- `DESCRIPTION`: development dependency declaration.
- `Makefile`: overridable R/Rscript command surface and quality gates.
- `renv.lock`: R and package lock state.
- `renv/activate.R`: generated `renv` 1.2.3 activation script.
- `scripts/dev_dependencies.R`: dependency discovery for Makefile-only tools.
- `scripts/run_external_repro_check.R`: isolated v1 restore and replay.
- `scripts/run_external_repro_check_v2.R`: isolated v2 restore and replay.
- `tests/testthat/test_memory_usage.R`: bounded memory instrumentation.

Documentation and control surface:

- `docs/product_brief.md`: current supported-stack statement.
- `docs/log/20260529_r46_mac_readiness.md`: historical sweep plus fresh Goal
  001 validation evidence.
- `docs/goals/001-r46-v2-readiness-baseline/Goal.md`: outcome contract.
- `docs/goals/001-r46-v2-readiness-baseline/Plan.md`: execution structure.
- `docs/goals/001-r46-v2-readiness-baseline/Runbook.md`: validation contract.
- `docs/goals/001-r46-v2-readiness-baseline/Log.md`: durable progress and
  evidence ledger.

Current-policy docs that may be edited only if an auditor demonstrates a live
contradiction:

- `README.md`
- `docs/workflow.md`
- `docs/release_checklist.md`
- `docs/decisions.md`
- `CHANGELOG.md`

## Task 1: Independent Read-Only Audit

**Files:** all files in the File Map; no writes.

- [x] Record the exact start branch, commit, status, diff statistics, host R
  version, lock R version, `renv` version, and restore policy.
- [x] Run three parallel `gpt-5.6-sol` audits: implementation/diff,
  documentation/provenance, and validation/artefact design.
- [x] Require each auditor to identify blockers, recommended changes, and
  evidence, while making no edits and running no full validation suite.
- [x] Integrate the findings into `Log.md`; resolve ordinary engineering
  questions within the orchestrator and escalate only a material scientific or
  strategic fork.

## Task 2: Bounded Reconciliation

**Files:** inherited implementation surface plus documentation files approved
from Task 1.

- [x] Dispatch one `gpt-5.6-sol` worker with exclusive ownership of the
  accepted write set and the audit findings.
- [x] Preserve the `lobstr` dependency migration only if `DESCRIPTION`,
  `renv.lock`, dependency discovery, and memory test agree.
- [x] Preserve generated `renv/activate.R` only if it is consistent with the
  locked `renv` 1.2.3 activation resource and contains no hand edits.
- [x] Preserve Makefile overrides only if every R and Rscript recipe follows
  the same override contract and `make check` propagates the selected R binary.
- [x] Preserve external restore hardening only if isolated-library status is
  checked correctly and failure status cannot be silently ignored.
- [x] Replace the current product-brief stack statement with the audited R
  4.6.x and non-`pak` restore policy; do not rewrite historical changelog
  entries merely because policy later changed.
- [x] For any newly discovered behavioural defect, require a failing regression
  test before the fix and capture the red/green commands in `Log.md`.
- [x] Require worker self-review, exact changed-path report, and focused tests.
- [x] Obtain independent task review for both specification compliance and
  code quality; resolve every Critical or Important finding before validation.

## Task 3: Validation And Artefact Review

**Files:** no additional tracked files except evidence updates to `Log.md` and
`docs/log/20260529_r46_mac_readiness.md`.

- [x] Run every required command in `Runbook.md` from a fresh shell context and
  record exit status plus decisive counts or messages.
- [x] If a command fails, use systematic root-cause debugging and rerun the
  smallest proving command before resuming the ladder.
- [x] Inspect the v1 and v2 reproducibility manifest JSON and summary CSV files.
- [x] Inspect the v2 release manifest and every checklist row.
- [x] Inspect the rendered v2 report for non-empty output and required content.
- [x] Inspect representative canonical plant/herbivore and v2 experiment
  outputs for finite values, non-negative bounded state, and expected row
  presence using existing contracts rather than new ecological judgments.
- [x] Update the readiness log with fresh 2026-07-11 results, clearly
  separating them from the historical 2026-05-29 run.

## Task 4: Final Review And Local Commit

**Files:** the complete Goal 001 diff from `872fb20`.

- [x] Generate a whole-change review package containing commit list, diff
  statistics, full diff, validation evidence, artefact evidence, and final
  status.
- [x] Dispatch an independent `gpt-5.6-sol` final reviewer at `max` reasoning
  to check scope, provenance, code, tests, docs, artefacts, and stop rules.
- [x] Resolve all Critical and Important findings through one bounded fix
  worker, rerun affected gates, and re-review.
- [x] Re-run `git diff --check`, the final `renv::status()` command, and
  `git status --short --branch` immediately before staging.
- [x] Stage exact accepted paths only and inspect the staged diff and path list.
- [x] Create one local commit with message
  `chore: consolidate R 4.6 readiness baseline`.
- [x] Confirm final branch, commit SHA, clean tracked status, and no push.
