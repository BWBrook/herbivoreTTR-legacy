# Goal 003 Runbook

Run all commands from `/Users/bwbrook/git/herbivoreTTR` only after all three
publication and authority gates in `Goal.md` have been recorded as satisfied.
This runbook is an intended execution contract, not authorization. None of its
commands was run while drafting the packet.

## Stop Rules

- Stop unless the exact accepted Goal 002 footprint is authorized for
  publication, committed as baseline, and Goal 003 execution is separately
  authorized.
- Stop before editing Goal 002, production `R/`, an API, or any path outside
  the intended Goal 003 file map.
- Stop on any non-binding, eligibility, reset, RNG, seed, composition,
  accounting, finite-value, domain, or repeatability failure. Do not adjust
  biomass or composition.
- Do not add digestion-only ticks, plant-only runs, sensitivity analysis,
  calibration, extra seeds/scenarios, or mechanism changes.
- Do not stage, commit, push, clean, reset, stash, checkout, merge, tag, or
  publish without separate explicit authority.

## 1. Publication, State, And Runtime Preflight

First confirm that `Log.md` contains Barry's two distinct authorizations and
the intervening Goal 002 baseline commit. Then run:

```sh
pwd
git status --short --branch
git rev-parse HEAD
git log -1 --oneline
git branch --show-current
git ls-files --error-unmatch \
  docs/goals/002-minimal-coupled-baseline-diagnosis/Goal.md \
  docs/goals/002-minimal-coupled-baseline-diagnosis/Plan.md \
  docs/goals/002-minimal-coupled-baseline-diagnosis/Runbook.md \
  docs/goals/002-minimal-coupled-baseline-diagnosis/Log.md \
  docs/log/20260712_goal002_minimal_coupled_diagnosis.md \
  inst/extdata/scenarios/goal002_minimal_coupled_v1.yaml \
  scripts/run_goal002_minimal_diagnosis.R \
  tests/testthat/test_goal002_minimal_diagnosis.R
command -v R
command -v Rscript
/opt/homebrew/bin/R --version
/opt/homebrew/bin/R -q -e 'cat("renv ", as.character(packageVersion("renv")), "\n", sep = ""); status <- renv::status(); if (!isTRUE(status$synchronized)) quit(status = 1L)'
```

Expected: all eight Goal 002 paths are tracked by a recorded baseline commit;
only authorized Goal 003 planning/implementation paths are dirty; R is 4.6.x;
and `renv` is synchronized. A missing authorization, untracked Goal 002 path,
unexpected change, or runtime mismatch stops execution.

Verify the frozen comparator without regenerating it:

```sh
test -f artefacts/goal002_minimal_coupled/run-a/run_manifest.json
test "$(shasum -a 256 artefacts/goal002_minimal_coupled/run-a/run_manifest.json | cut -d " " -f 1)" = "4c61f2c866a5b3209608b4b7d29fc82209de749e3ecbefdd324d982ca2f4fb39"
jq -e '.configuration_sha256 == "46ce7fe6e467a3387ee6cc5ef027e87f315710d0b9610f805cc8864224317d89" and .content_sha256 == "98ad4f9da22a7b535a4bed94b12f4104293af1a0f89a02bb2b3d464b4793ac86"' artefacts/goal002_minimal_coupled/run-a/run_manifest.json
```

Expected: all three commands exit 0. If the canonical comparator is absent or
any hash differs, stop and ask Barry
how to restore accepted evidence. Do not rerun Goal 002 to update its Git SHA.

## 2. Focused RED/GREEN Contract

```sh
/opt/homebrew/bin/R -q -e 'testthat::test_file("tests/testthat/test_goal003_herbivore_reference.R", stop_on_failure = TRUE)'
```

Before implementation, expected RED is caused by the absent Goal 003 runner or
contract. After implementation, expected GREEN is zero failures and warnings.
The focused suite must test the exact plant-copy identity, unchanged sentinel
herbivore and `.Random.seed`, synthetic altered-closing reset, exact Goal 002
invariants and digestion queues, `apply_growth = FALSE`, seed sequence,
non-binding calculations, output schemas/hashes, invalid-profile failures, and
absent output-directory rule. Record both results in `Log.md`.

## 3. Clean Run-A And Run-B

```sh
test ! -e artefacts/goal003_herbivore_reference/run-a
test ! -e artefacts/goal003_herbivore_reference/run-b
/opt/homebrew/bin/Rscript scripts/run_goal003_herbivore_reference.R --profile inst/extdata/scenarios/goal003_herbivore_reference_v1.yaml --output-dir artefacts/goal003_herbivore_reference/run-a
/opt/homebrew/bin/Rscript scripts/run_goal003_herbivore_reference.R --profile inst/extdata/scenarios/goal003_herbivore_reference_v1.yaml --output-dir artefacts/goal003_herbivore_reference/run-b
```

Expected in each directory:

```text
run_manifest.json
daily_diagnostics.csv
plant_diagnostics.csv
diagnostic_summary.json
diagnostic_trajectories.png
```

Each manifest must remain incomplete or the command must fail if a stop rule
is reached. Preserve the first failed output for diagnosis; do not tune and
rerun.

## 4. Hash, Manifest, And Repeatability Gates

```sh
for f in daily_diagnostics.csv plant_diagnostics.csv diagnostic_summary.json diagnostic_trajectories.png run_manifest.json; do
  cmp "artefacts/goal003_herbivore_reference/run-a/$f" "artefacts/goal003_herbivore_reference/run-b/$f"
done
jq -e '.status == "complete" and .seed == 2002 and .days == 120 and .start_day == 6 and .minute_limit == 720 and .daily_seed_offset == 100000 and .apply_growth == false and .daily_plant_reset == true and .herbivore_count == 1 and .forage_type_count == 1 and .nonbinding_tolerance == 1e-10 and .all_nonbinding_checks_passed == true and (.configuration_sha256 | type == "string" and length == 64) and (.content_sha256 | type == "string" and length == 64)' artefacts/goal003_herbivore_reference/run-a/run_manifest.json
jq -e --slurpfile b artefacts/goal003_herbivore_reference/run-b/run_manifest.json '.configuration_sha256 == $b[0].configuration_sha256 and .content_sha256 == $b[0].content_sha256 and .frozen_plant_state_sha256 == $b[0].frozen_plant_state_sha256' artefacts/goal003_herbivore_reference/run-a/run_manifest.json
```

Expected: every `cmp` exits 0 and both manifests identify the same complete
configuration, frozen plant state, and output set. This is fixed-seed
computational repeatability only.

## 5. Structured R Evidence Checks

The implementation must emit the columns referenced below exactly. Complete
opening/closing state columns use `opening_` and `closing_` prefixes for every
field in the profile's `initial_plant_state`.

```sh
/opt/homebrew/bin/R -q -e '
options(warn = 2)
d <- read.csv("artefacts/goal003_herbivore_reference/run-a/daily_diagnostics.csv", check.names = FALSE)
p <- read.csv("artefacts/goal003_herbivore_reference/run-a/plant_diagnostics.csv", check.names = FALSE)
cfg <- yaml::read_yaml("inst/extdata/scenarios/goal003_herbivore_reference_v1.yaml")
fields <- names(cfg$initial_plant_state)
op <- paste0("opening_", fields)
cl <- paste0("closing_", fields)
stopifnot(nrow(d) == 120L, identical(d$Day, seq_len(120L)))
stopifnot(nrow(p) == 120L, identical(p$Day, seq_len(120L)))
stopifnot(identical(d$model_day, 6:125))
stopifnot(identical(d$day_seed, as.integer(2002 + seq_len(120L) * 100000)))
stopifnot(all(c(op, cl) %in% names(p)))
for (nm in fields) stopifnot(all(p[[paste0("opening_", nm)]] == unlist(cfg$initial_plant_state[[nm]], use.names = FALSE)))
stopifnot(length(unique(p$opening_state_sha256)) == 1L)
stopifnot(all(p$opening_state_sha256 == p$frozen_state_sha256))
stopifnot(all(p$opening_source == "frozen_snapshot"))
stopifnot(all(p$opening_from_frozen_snapshot))
stopifnot(all(!p$opening_identical_to_prior_closing))
stopifnot(all(p$apply_growth == FALSE))
stopifnot(all(p$daily_plant_reset))
stopifnot(all(p$shoot_drawdown_kg >= 0))
stopifnot(all(p$closing_is_daily_minimum))
stopifnot(all(p$closing_ms > p$m_ref_kg, p$closing_ms > p$min_shoot_kg))
stopifnot(all(p$closing_ms - p$min_shoot_kg > d$gut_capacity_g / 1000))
stopifnot(all(p$closing_qshoot > 0))
ratio_cols <- c("qshoot_shoot_ratio_change", "leaf_fraction_change", "stem_fraction_change", "defence_fraction_change", "selection_nutrient_ratio_change")
stopifnot(all(vapply(p[ratio_cols], function(x) all(abs(x) <= 1e-10), logical(1))))
stopifnot(all(p$single_plant_eligible, p$positive_selection_score, p$co_located_for_eating))
stopifnot(all(p$detectable_throughout_active_loop, p$reachable_throughout_active_loop))
stopifnot(all(p$minimum_all_minute_selection_score > 0))
stopifnot(all(p$positive_selection_minutes == 720L))
stopifnot(all(p$positive_intake_minutes > 0, p$positive_intake_within_eat_radius))
stopifnot(all(p$non_consumed_fields_identical))
stopifnot(max(abs(p$opening_shoot_component_residual_kg)) <= 1e-12)
stopifnot(max(abs(p$closing_shoot_component_residual_kg)) <= 1e-12)
stopifnot(max(abs(p$intake_drawdown_residual_kg)) <= 1e-10)
stopifnot(max(abs(p$qshoot_water_residual_kg)) <= 1e-10)
stopifnot(all(vapply(d[vapply(d, is.numeric, logical(1))], function(x) all(is.finite(x)), logical(1))))
stopifnot(all(vapply(p[vapply(p, is.numeric, logical(1))], function(x) all(is.finite(x)), logical(1))))
stopifnot(all(d$gut_content_g <= d$gut_capacity_g + 1e-8))
stopifnot(all(d$BodyConditionIndex >= 0 & d$BodyConditionIndex <= 1))
stopifnot(max(abs(d$energy_daily_residual_kJ)) <= 1e-8)
stopifnot(max(abs(d$energy_cumulative_residual_kJ)) <= 1e-8)
stopifnot(max(abs(d$water_daily_residual_g)) <= 1e-8)
stopifnot(max(abs(d$water_cumulative_residual_g)) <= 1e-8)
cat("rows:", nrow(d), nrow(p), "\n")
cat("closing shoot range kg:", range(p$closing_ms), "\n")
cat("minimum availability margin kg:", min(p$closing_ms - p$min_shoot_kg - d$gut_capacity_g / 1000), "\n")
cat("BCI range:", range(d$BodyConditionIndex), "\n")
cat("energy delta range kJ:", range(d$energy_delta_kJ), "\n")
'
test -s artefacts/goal003_herbivore_reference/run-a/diagnostic_trajectories.png
```

All checks must pass without warnings. The tolerances are numerical only and
must be reported. Visually inspect the figure for readable axes, units,
120-day extent, uncertainty/limitation captions, and absence of biological
pass thresholds.

## 6. Frozen Goal 002 Descriptive Comparison

```sh
/opt/homebrew/bin/R -q -e '
g2 <- read.csv("artefacts/goal002_minimal_coupled/run-a/daily_diagnostics.csv")
g2p <- read.csv("artefacts/goal002_minimal_coupled/run-a/plant_diagnostics.csv")
g3 <- read.csv("artefacts/goal003_herbivore_reference/run-a/daily_diagnostics.csv")
g3p <- read.csv("artefacts/goal003_herbivore_reference/run-a/plant_diagnostics.csv")
stopifnot(nrow(g2) == 120L, nrow(g2p) == 120L, nrow(g3) == 120L, nrow(g3p) == 120L)
summ <- function(d) c(mean_energy_delta_kJ = mean(d$energy_delta_kJ), final_energy_balance_kJ = tail(d$cumulative_energy_balance_kJ, 1), first_bci_floor_day = if (any(d$BodyConditionIndex == 0)) min(d$Day[d$BodyConditionIndex == 0]) else NA_real_, mean_intake_g = mean(d$intake_total_g), stress_days = sum(d$PhysiologicalStressFlag != 0))
print(rbind(goal002 = summ(g2), goal003 = summ(g3)))
cat("Goal 002 closing shoot range kg:", range(g2p$closing_total_shoot_biomass_kg), "\n")
cat("Goal 003 closing shoot range kg:", range(g3p$closing_ms), "\n")
'
```

Expected evidence is a descriptive table, not a hypothesis test. Report
direction, magnitude, persistence, and timing. Do not treat days as
independent replicates or the contrast as clean causal isolation.

## 7. Full Repository Validation Ladder

```sh
/opt/homebrew/bin/R -q -e 'testthat::test_file("tests/testthat/test_goal003_herbivore_reference.R", stop_on_failure = TRUE)'
make test R=/opt/homebrew/bin/R RSCRIPT=/opt/homebrew/bin/Rscript
make lint R=/opt/homebrew/bin/R RSCRIPT=/opt/homebrew/bin/Rscript
/opt/homebrew/bin/R -q -e 'status <- renv::status(); if (!isTRUE(status$synchronized)) quit(status = 1L)'
git diff --check
git status --short --branch
git diff --name-status
git ls-files --others --exclude-standard
```

Expected: focused and full tests pass with no unexpected failures or warnings;
lint is clean; `renv` is synchronized; diff checks pass; only the intended
Goal 003 tracked paths appear; run artefacts remain ignored.

Do not run the following under the preferred design. If any production model
file, targets surface, package metadata, export, or installed-package behavior
has been touched, stop for scope review first. Only after Barry authorizes that
expanded surface are the conditional gates:

```sh
make smoke R=/opt/homebrew/bin/R RSCRIPT=/opt/homebrew/bin/Rscript
make check R=/opt/homebrew/bin/R RSCRIPT=/opt/homebrew/bin/Rscript
```

A documentation build is not required for the four Markdown planning files or
the non-exported diagnostic script. If later implementation changes rendered
documentation, stop for scope review and run the relevant documented render
gate only after that surface is authorized.

## 8. Independent Review And Closeout

Provide the independent scientific reviewer with the exact diff, both Goal
003 manifests, repeatability hashes, structured-check output, figure, complete
plant reset/non-binding/accounting evidence, frozen Goal 002 hashes and
descriptive comparison, interpretation draft, validation output, and final Git
status. Acceptance requires no open Critical or Important issue.

Record the verdict and retained profile-runner provenance in `Log.md`. Report
the exact changed paths and stop. Packet or result approval does not authorize
staging, commit, push, publication, or another simulation.
