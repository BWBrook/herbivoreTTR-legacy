# Rebuild Goal 001 Log

## 2026-07-16 - Barry's Decisions

Barry approved a clean rebuild rather than continued migration of the current
architecture:

- R remains the sole implementation language.
- Legacy C++ and R behavior is historical evidence, not scientific authority.
- Ecological logic, dimensional consistency, empirical evidence, and explicit
  assumptions govern the new model.
- The current repository will be frozen as private
  `BWBrook/herbivoreTTR-legacy`; the active private `BWBrook/herbivoreTTR` will
  be a genuinely new repository with unrelated history.
- Legacy remains accessible through a separate read-only sibling checkout, not
  an untracked directory inside the new repository.
- The new architecture is a small functional R package with thin experiments,
  plain validated state records, pure functions, and strict separation of
  state, fixed parameters, prescribed inputs, processes, and history. No
  object-oriented framework is approved.
- The future irreducible core and later layer order are exactly those recorded
  in `Goal.md`; neither is implemented by this goal.
- Future work uses one-question, one-subsystem goals with compact outputs,
  proportionate tests, explicit stops, and discussion before the next layer.

Barry approved the scientific architecture and the proposed boundary of
Rebuild Goal 001, then requested this planning packet. The detailed migration
sequence, commit and tag limits, generated-evidence cap, and split-state safety
rules are the orchestrator's proposal for Barry's review. They are not yet
approved, and execution remains unauthorized.

## 2026-07-16 - Formulation State

Read-only local inspection confirmed:

```text
repository = /Users/bwbrook/git/herbivoreTTR
branch = codex/herbivore-ttr-goal-002
HEAD = abf68b691b4e30020625d1871dcabe56a5926bc1
branch relation = ahead of origin/codex/herbivore-ttr-goal-002 by one
origin = git@github.com:BWBrook/herbivoreTTR.git
origin/main = 872fb20fe5ff4ffd00cf2d29369e61fad764867a
origin/main merge-base with HEAD = 872fb20fe5ff4ffd00cf2d29369e61fad764867a
```

Local status contained only the nine compact untracked Goal 004 paths listed in
`Goal.md` before this packet was created. No tracked modification was present.

Barry supplied these additional live, read-only observations for formulation:

```text
/Users/bwbrook/git/herbivoreTTR-legacy = absent
/Users/bwbrook/git/herbivoreTTR-rebuild-bootstrap = absent
GitHub BWBrook/herbivoreTTR = private, default branch main
GitHub BWBrook/herbivoreTTR-legacy = absent
available space under /Users/bwbrook/git = 254 GiB
```

These observations are not guarantees. `Runbook.md` requires live rechecks
before execution, including GitHub authentication and API state, fetch and
ancestor proof, exact dirty paths, sibling-path absence, tag absence, remote-
name availability, and at least 5 GiB free disk.

The 5.4 GB Goal 004 generated bundles and 201 MB scratch-agent traces were
deliberately deleted after Barry authorized cleanup. They were not inspected,
restored, or regenerated during formulation and are explicitly excluded from
both final repositories.

## 2026-07-16 - Planning-Only Packet

Created only:

```text
docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Goal.md
docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Plan.md
docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Runbook.md
docs/goals/rebuild-001-legacy-freeze-clean-repository-foundation/Log.md
```

No R command, test, package check, build, network operation, generated-output
command, staging, commit, push, tag, directory move, deletion, remote mutation,
GitHub mutation, migration operation, or physiological implementation occurred.
The packet itself remains untracked.

Execution status: not started and not authorized.

Before the final legacy snapshot, an authorized executor may append one concise
summary of preflight, scaffold validation, foundation SHA, and residual risks.
Raw transcripts and generated evidence remain excluded. Operations after the
final legacy commit belong in the executor's final response because no further
legacy commit is authorized.

## 2026-07-16 - Authorized Execution And Foundation Validation

Barry explicitly authorized the complete guarded Goal 001 sequence: the final
legacy snapshot commit and publication, annotated tag, GitHub rename, exact
local sibling moves, private replacement creation and push, and final legacy
archive. This authorization superseded the planning-only status above without
expanding the packet's scope or recovery authority.

Live preflight passed the exact dirty-set, path, disk, GitHub identity,
visibility, default-branch, name-collision, remote-main, ancestry, and tag
gates. The active legacy checkout remained at scientific baseline commit
`abf68b691b4e30020625d1871dcabe56a5926bc1`, with `origin/main` at
`872fb20fe5ff4ffd00cf2d29369e61fad764867a` before the final snapshot.

The unrelated bootstrap was constructed with the exact 24-file foundation
tree. Three mechanical issues were stopped, independently reviewed, and resumed
under Barry's explicit narrow authority:

- DCF scalar comparisons were changed to ignore matrix column names.
- The scaffold test retained its source-tree `DESCRIPTION` candidate and added
  the installed-package `DESCRIPTION` fallback required by `R CMD check`.
- Trailing horizontal whitespace emitted by `renv` in `renv/activate.R` was
  stripped without changing code content.

After those reviews, the focused scaffold test passed all 10 expectations,
`renv::status()` reported synchronization, the exact tree and staged-diff gates
passed, and external `R CMD build` plus `R CMD check --no-manual` completed with
`Status: OK`. All temporary validation directories were guarded and removed;
`outputs/` and persistent generated evidence remained absent.

The sole replacement foundation commit is
`ca2c9711f8e81831180a1c4875de44f84f964498`. At this pre-snapshot point the
GitHub rename, local moves, replacement push, and final legacy archive remained
pending and were the only material migration risks.

## 2026-07-16 - Mandatory Hook Repair And Retry Authorization

The first normal legacy commit attempt stopped when the mandatory pre-commit
hook's January R 4.5 dependency snapshot could not bootstrap under host R
4.6.1. The failure occurred while compiling pinned `Rcpp` 1.1.1 and produced no
commit.

Root rebuilt only the external pre-commit hook environment using the current
upstream R 4.6.1-compatible lock and `renv` bootstrap, then restored both
tracked cache source files byte-for-byte. Fresh activation reported R 4.6.1,
`renv` 1.2.3, `Rcpp` 1.1.2, `backports` 1.5.1, and pinned `precommit`
0.4.3.9021. No project hook configuration or previously staged project file
changed.

The Herbivore TTR orchestrator authorized the normal retry under Barry's
standing Goal 001 execution authority, with mandatory hooks enabled and no
bypass, skip, `--no-verify`, hook configuration edit, or extra legacy path. The
resume gate reconfirmed the exact 14-path index, zero unstaged project changes,
clean one-commit replacement foundation, unchanged remote-main pin, absent
final tag, GitHub authentication, and remote-name availability before retry.

Mandatory `style-files` changes were accepted only in the three authorized Goal
004 R/test paths. The two lines flagged by `lintr` were split without changing
expressions, arguments, strings, order, or behavior. The focused Goal 004 test
then passed 122/122 with zero failures, warnings, or skips; its exact empty,
ignored `.superpowers/sdd/goal004-agents` fixture residue was removed
deepest-first with `rmdir`. No scientific artefact was regenerated.
