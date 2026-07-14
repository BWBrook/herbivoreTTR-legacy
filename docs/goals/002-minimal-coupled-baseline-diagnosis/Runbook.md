# Goal 002 Runbook

Run all commands from `/Users/bwbrook/git/herbivoreTTR` on
`codex/herbivore-ttr-goal-002`.

This runbook is an execution contract, not authorization to begin. Goal 002
execution starts only after Barry approves the formulated packet.

## Stop Rules

- Diagnose the one baseline; do not tune it or make it pass a preferred
  physiological criterion.
- Stop before changing an existing default, core model behaviour, public API,
  output contract, scientific threshold, or taxon-specific parameter.
- Stop before a second scenario, seed, horizon, parameter setting, or
  counterfactual run.
- Do not add physiology, reserve dynamics, demography, seasonality, forage
  diversity, or nutritional-choice experiments.
- Do not edit outside the authorised File Map in `Plan.md`.
- Do not claim ecological determinism, causality, equilibrium, or asymptotic
  stability from one fixed-seed 120-day realization.
- Do not reset, clean, stash, force, commit, push, merge, tag, publish, or use
  remote compute.

## 1. State And Runtime Preflight

```sh
pwd
git status --short --branch
git rev-parse HEAD
git log -1 --oneline
command -v R
command -v Rscript
/opt/homebrew/bin/R --version
/opt/homebrew/bin/R -q -e 'cat("renv ", as.character(packageVersion("renv")), "\n", sep = ""); status <- renv::status(); if (!isTRUE(status$synchronized)) quit(status = 1L)'
```

Expected: Goal 002 branch based on `7ea0132`, only authorised Goal 002 packet
or implementation paths dirty, R 4.6.x, `renv` 1.2.3, synchronized project.

## 2. Focused Contract Cycle

```sh
/opt/homebrew/bin/R -q -e 'testthat::test_file("tests/testthat/test_goal002_minimal_diagnosis.R", stop_on_failure = TRUE)'
```

Before implementation, expected RED must be caused by the absent Goal 002
runner or evidence contract. After implementation, expected GREEN is zero
failures and zero warnings. Record both results in `Log.md`.

The focused tests must verify:

- exactly one herbivore and one forage type;
- seed and horizon equal the profile contract;
- temperature, soil water, and soil nitrogen are each constant by value;
- the initial plant state is explicit and reproducible;
- the complete resolved initial herbivore state is recorded before stepping;
- required diagnostic columns and manifest fields are complete;
- invalid or incomplete diagnostic profiles fail clearly;
- output directories must be absent before execution.

## 3. Clean Primary Executions

Preflight the authorised ignored output root:

```sh
test ! -e artefacts/goal002_minimal_coupled/run-a
test ! -e artefacts/goal002_minimal_coupled/run-b
```

Run the same profile twice:

```sh
/opt/homebrew/bin/Rscript scripts/run_goal002_minimal_diagnosis.R --profile inst/extdata/scenarios/goal002_minimal_coupled_v1.yaml --output-dir artefacts/goal002_minimal_coupled/run-a
/opt/homebrew/bin/Rscript scripts/run_goal002_minimal_diagnosis.R --profile inst/extdata/scenarios/goal002_minimal_coupled_v1.yaml --output-dir artefacts/goal002_minimal_coupled/run-b
```

Expected in each directory:

```text
run_manifest.json
daily_diagnostics.csv
plant_diagnostics.csv
diagnostic_summary.json
diagnostic_trajectories.png
```

No extra scenario, seed, horizon, or counterfactual is authorised.

## 4. Repeatability And Manifest Gates

```sh
cmp artefacts/goal002_minimal_coupled/run-a/daily_diagnostics.csv artefacts/goal002_minimal_coupled/run-b/daily_diagnostics.csv
cmp artefacts/goal002_minimal_coupled/run-a/plant_diagnostics.csv artefacts/goal002_minimal_coupled/run-b/plant_diagnostics.csv
cmp artefacts/goal002_minimal_coupled/run-a/diagnostic_summary.json artefacts/goal002_minimal_coupled/run-b/diagnostic_summary.json
jq -e '. as $m | .status == "complete" and .seed == 2002 and .days == 120 and .herbivore_count == 1 and .forage_type_count == 1 and (.configuration_sha256 | type == "string" and length == 64) and (.initial_herbivore_state.resolved_herbivore_state.selected_plant_id == null) and (.initial_herbivore_state.resolved_herbivore_state.selected_plant_dist == null) and (.initial_herbivore_state.resolved_herbivore_state_missing_schema.selected_plant_id == {"r_type":"integer","length":1,"missing_positions":1}) and (.initial_herbivore_state.resolved_herbivore_state_missing_schema.selected_plant_dist == {"r_type":"double","length":1,"missing_positions":1}) and (.output_hashes_sha256 | type == "object") and (["daily_diagnostics.csv", "plant_diagnostics.csv", "diagnostic_summary.json", "diagnostic_trajectories.png"] | all(. as $name | ($m.output_hashes_sha256 | has($name)) and ($m.output_hashes_sha256[$name] | type == "string" and length == 64)))' artefacts/goal002_minimal_coupled/run-a/run_manifest.json
jq -e --slurpfile b artefacts/goal002_minimal_coupled/run-b/run_manifest.json '.configuration_sha256 == $b[0].configuration_sha256 and .content_sha256 == $b[0].content_sha256' artefacts/goal002_minimal_coupled/run-a/run_manifest.json
```

Expected: `cmp` exits 0; both manifests report complete runs and identical
configuration/content hashes. This proves fixed-seed computational
repeatability, not absence of stochastic processes. Git SHA and runtime
provenance may differ only if the repository changed, in which case the run
pair is invalid and must be regenerated after review.

## 5. Structured Diagnostic Inspection

```sh
/opt/homebrew/bin/R -q -e '
options(warn = 2)
d <- read.csv("artefacts/goal002_minimal_coupled/run-a/daily_diagnostics.csv")
p <- read.csv("artefacts/goal002_minimal_coupled/run-a/plant_diagnostics.csv")
stopifnot(nrow(d) == 120L, identical(d$Day, seq_len(120L)))
stopifnot(nrow(p) == 120L, identical(p$Day, seq_len(120L)))
stopifnot(length(unique(d$temperature)) == 1L)
stopifnot(length(unique(d$soil_water)) == 1L)
stopifnot(length(unique(d$soil_nitrogen)) == 1L)
stopifnot(all(vapply(d[vapply(d, is.numeric, logical(1))], function(x) all(is.finite(x)), logical(1))))
stopifnot(all(vapply(p[vapply(p, is.numeric, logical(1))], function(x) all(is.finite(x)), logical(1))))
stopifnot(all(p$closing_total_shoot_biomass_kg >= 0))
stopifnot(all(d$BodyConditionIndex >= 0 & d$BodyConditionIndex <= 1))
cat("daily rows:", nrow(d), "plant rows:", nrow(p), "\n")
cat("stress days:", sum(d$PhysiologicalStressFlag != 0), "\n")
cat("body condition range:", range(d$BodyConditionIndex), "\n")
cat("energy balance range:", range(d$EnergyBalance), "\n")
cat("water balance range:", range(d$WaterBalance), "\n")
cat("shoot biomass range:", range(p$closing_total_shoot_biomass_kg), "\n")
'
test -s artefacts/goal002_minimal_coupled/run-a/diagnostic_trajectories.png
```

The runner may use canonical field names internally, but the diagnostic CSVs
must provide the fields used by these commands exactly. Additional fields are
allowed only when they directly support the Goal objective and are documented.

The manifest must enumerate every external forcing value consumed by the
runner. The scientific review must confirm that no unlisted time-varying driver
enters the model.

Inspect the trajectory figure visually as a secondary review surface. Confirm
that axes, units, legends, and the 120-day extent are readable and that no
panel implies a biological pass threshold not authorized by the goal.

## 6. State-Accounting Review

The scientific log must identify, with exact source paths and symbols:

- daily energy intake, requirement, delta, ratio, cumulative balance, and
  their reset/carryover rules;
- forage, drinking, and metabolic water inputs; requirement, daily net water,
  cumulative balance, and their reset/carryover rules;
- dry-matter and nutrient intake, gut content/capacity, and digestion state;
- movement and foraging-time costs;
- body-condition update, bounds, feedback, deficit streaks, and stress flag;
- opening plant biomass, daily TTR growth/regeneration, herbivore removal,
  closing biomass, and any unreconciled accounting residual;
- any quantity needed for physiological decline that is not represented.

The report must name the existing constants or rules that generate
`PhysiologicalStressFlag`. Counts of flagged days describe model-defined
threshold crossings and are not empirical evidence of grey-kangaroo stress or
non-viability.

For each conclusion, label the source as observed output, direct code trace, or
inference. Quantify unresolved accounting residuals rather than explaining
them away. Describe trajectory direction, magnitude, persistence, and observed
reversals. First-half and second-half summaries are descriptive windows only;
do not claim equilibrium or asymptotic stability.

## 7. Required Engineering Gates

```sh
/opt/homebrew/bin/R -q -e 'testthat::test_file("tests/testthat/test_goal002_minimal_diagnosis.R", stop_on_failure = TRUE)'
make test R=/opt/homebrew/bin/R RSCRIPT=/opt/homebrew/bin/Rscript
make lint R=/opt/homebrew/bin/R RSCRIPT=/opt/homebrew/bin/Rscript
/opt/homebrew/bin/R -q -e 'status <- renv::status(); if (!isTRUE(status$synchronized)) quit(status = 1L)'
git diff --check
git status --short --branch
git diff --name-status
```

Expected: focused and full tests pass with no unexpected warnings; lint,
environment, and diff checks pass; only authorised Goal 002 paths are changed.

Run `make smoke` only if Goal 002 changes a production model file, targets
surface, or existing scenario execution path. Such a change also requires an
explicit scope review before proceeding. Run `make check` only if package code,
metadata, exports, or installed-package behaviour changes. The preferred Goal
002 implementation needs neither.

## 8. Independent Review And Closeout

The independent scientific reviewer receives:

- the complete diff;
- both run manifests and fixed-seed repeatability evidence;
- the diagnostic figure and summary;
- the state-accounting map;
- the finding classifications and one proposed next goal;
- all validation results and final Git status.

Acceptance requires no open Critical or Important issue. Record the final
verdict and every retained profile-runner provenance path in `Log.md`.

Do not stage, commit, or push. Report the exact changed paths and stop for
Barry's scientific review.
