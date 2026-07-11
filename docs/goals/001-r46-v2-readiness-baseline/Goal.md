# Goal 001: R 4.6 / v2.0 Readiness Baseline

Status: completed on 2026-07-11 after independent final acceptance review.

Owner: Herbivore TTR orchestrator.

Execution model: orchestrator-controlled specialist subagents using
`gpt-5.6-sol`; no persistent action-agent thread is available or required.

Repository: `/Users/bwbrook/git/herbivoreTTR`.

Working branch: `codex/herbivore-ttr-goal-001`.

Starting commit: `872fb20` (`docs: record scientist walkthrough plan`).

## Completed-State Objective

Convert the inherited Mac R 4.6 / v2.0 readiness patch into a coherent,
evidence-backed local baseline. The accepted state must have a synchronized
`renv` environment, internally consistent runtime and restore documentation,
fresh validation evidence, inspected v2 artefacts, no unexplained scientific
or public-interface change, and one reviewed local commit. Do not push.

## Why This Matters

The formal roadmap queues are already substantially complete, while the
current checkout contains a broad uncommitted readiness bundle. Starting new
science on top of that state would make provenance and regressions harder to
separate. Goal 001 establishes a trusted engineering baseline first.

## Read First

1. `AGENTS.md`
2. This `Goal.md`
3. `Plan.md`
4. `Runbook.md`
5. `Log.md`
6. `README.md`
7. `DESCRIPTION`
8. `Makefile`
9. `docs/product_brief.md`
10. `docs/workflow.md`
11. `docs/release_checklist.md`
12. `docs/decisions.md`
13. `docs/log/20260529_r46_mac_readiness.md`

## Starting State To Preserve And Classify

The checkout began on `main...origin/main` at `872fb20` with these inherited
changes, which were moved unchanged onto the Goal 001 branch:

```text
M DESCRIPTION
M Makefile
M renv.lock
M renv/activate.R
M scripts/run_external_repro_check.R
M scripts/run_external_repro_check_v2.R
M tests/testthat/test_memory_usage.R
?? docs/log/20260529_r46_mac_readiness.md
?? scripts/dev_dependencies.R
```

Observed at goal start:

- host runtime is currently R 4.6.1;
- `renv.lock` records R 4.6.0 and `renv` 1.2.3;
- `DESCRIPTION` and the lock use `lobstr` rather than `pryr`;
- canonical restore policy disables `pak`;
- `docs/product_brief.md` still names R 4.5.3 and `pak` as preferred;
- the May readiness log contains historical validation claims that must not be
  presented as current evidence without a fresh run.

## In Scope

- Classify every inherited changed file as required, incorrect, generated but
  valid, or out of scope.
- Reconcile the R 4.6.x runtime, lockfile, `renv` activation, dependency
  discovery, Makefile runtime overrides, external restore checks, and memory
  instrumentation.
- Make narrow current-documentation corrections where the live restore policy
  or supported R 4.6 baseline is misstated.
- Preserve historical changelog statements as history unless they falsely
  claim to be current policy.
- Run the complete validation ladder in `Runbook.md`.
- Regenerate ignored v2 report, release, smoke, and reproducibility artefacts
  required by the validation ladder.
- Inspect manifests, checklists, reports, and representative model outputs.
- Record evidence and decisions in `Log.md` and the readiness log.
- Create one exact-path local commit after independent final review.

## Out Of Scope

- New ecological assumptions, calibration, interpretation, model features, or
  roadmap work.
- Public API, scenario-contract, output-schema, or default-behaviour changes.
- A package version bump, release tag, GitHub release, PR, or remote push.
- New dependencies beyond reconciling the inherited `pryr` to `lobstr` change.
- Broad refactoring, style cleanup, generated-output churn outside the named
  validation commands, or deletion of existing user files.
- `git reset`, `git clean`, `git stash`, force operations, or destructive
  checkout commands.

## Deliverables And Review Surface

- The final full working-tree diff from `872fb20`.
- This four-file goal packet with a current `Log.md`.
- A corrected readiness log containing fresh 2026-07-11 evidence.
- Validation output for every required command in `Runbook.md`.
- Structured inspection of both reproducibility manifests and summaries.
- Structured inspection of the v2 release manifest and checklist.
- Inspection of the rendered v2 report and representative canonical outputs.
- An independent whole-change review with no open Critical or Important issue.
- Final branch, commit SHA, exact committed path list, and clean tracked status.

## Acceptance Gates

1. Every inherited change has a coherent readiness purpose and no unrelated
   change is swept into the commit.
2. `renv::status()` reports the project synchronized on the current host.
3. Current docs agree that R 4.6.x is the supported Mac baseline and that the
   canonical restore path disables `pak` under the existing decision record.
4. The complete required validation ladder exits successfully. Expected
   `R CMD check` notes may remain only if their exact text is recorded and an
   independent reviewer agrees they are non-actionable for this repository.
5. Reproducibility manifests report `all_pass: true`, all summary rows pass,
   and release checklist rows all pass.
6. Generated model outputs remain finite and physically bounded under the
   repository's existing checks. No result is reinterpreted scientifically.
7. Independent final review reports no open Critical or Important finding.
8. A local commit contains only accepted Goal 001 paths. Nothing is pushed.

## Authority

Subagents may inspect the full action repository and may edit only files named
by this goal or narrow tests/docs required to correct a demonstrated defect.
They may run the commands in `Runbook.md` and regenerate ignored artefacts.

The orchestrator may create the Goal 001 branch, stage exact accepted paths,
and create one local commit after all gates pass. The orchestrator may not
push, tag, publish externally, merge to `main`, or broaden scientific scope.

## Stop And Escalate

Pause and bring Barry a recommendation with evidence before:

- changing a scientific assumption, ecological interpretation, or model
  default;
- changing a public API or output contract;
- changing the package version or release framing;
- adding a dependency other than the inherited `lobstr` substitution;
- accepting a validation failure that requires work outside this goal;
- making a material trade-off between reproducibility and supported platform
  behaviour.
