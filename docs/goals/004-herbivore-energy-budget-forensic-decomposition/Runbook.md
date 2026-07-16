# Goal 004 Runbook

Run all commands from `/Users/bwbrook/git/herbivoreTTR` only after the Goal
003 baseline and Goal 004 execution gates in `Goal.md` are satisfied. This
runbook is a planning contract, not authorization.

## Stop Rules

- Stop unless Goal 003's exact accepted eight-path footprint is committed and
  Barry separately authorizes Goal 004 execution.
- Stop before changing production `R/`, an exported API, package metadata,
  lockfiles, Goal 003, a parameter, a default, or an output contract.
- Stop on observer/RNG interference, conservation failure, ambiguous
  accounting-day assignment, unreported queue adjustment, or a failed probe
  invariant.
- Stop before broad parameter sweeps, extra seeds, biological calibration,
  recoupling, new taxa, new mechanisms, or stability-target tuning.
- Do not stage, commit, push, clean, reset, stash, checkout, merge, tag, or
  publish without separate explicit authority.

## 1. Authority, State, And Comparator Preflight

Confirm `Log.md` records the Goal 003 baseline commit and Barry's separate
Goal 004 execution authorization. Then run:

```sh
pwd
git status --short --branch
git rev-parse HEAD
git log -1 --oneline
git branch --show-current
git ls-files --error-unmatch \
  docs/goals/003-herbivore-only-daily-clamped-forage-reference/Goal.md \
  docs/goals/003-herbivore-only-daily-clamped-forage-reference/Plan.md \
  docs/goals/003-herbivore-only-daily-clamped-forage-reference/Runbook.md \
  docs/goals/003-herbivore-only-daily-clamped-forage-reference/Log.md \
  docs/log/20260714_goal003_herbivore_reference.md \
  inst/extdata/scenarios/goal003_herbivore_reference_v1.yaml \
  scripts/run_goal003_herbivore_reference.R \
  tests/testthat/test_goal003_herbivore_reference.R
/opt/homebrew/bin/R --version
/opt/homebrew/bin/R -q -e 'status <- renv::status(); if (!isTRUE(status$synchronized)) quit(status = 1L)'
```

Expected: Goal 003's eight paths are tracked by the recorded baseline commit;
only authorized Goal 004 paths are dirty; R is 4.6.x; `renv` is synchronized.

Bind the comparator commit and exact source tree. Every Goal 003 path must have
the same latest commit, the worktree must match it, and no production `R/` file
may differ from the accepted Goal 003 production base:

```sh
GOAL003_BASELINE_COMMIT="$(git log -1 --format=%H -- scripts/run_goal003_herbivore_reference.R)"
test -n "$GOAL003_BASELINE_COMMIT"
for f in \
  docs/goals/003-herbivore-only-daily-clamped-forage-reference/Goal.md \
  docs/goals/003-herbivore-only-daily-clamped-forage-reference/Plan.md \
  docs/goals/003-herbivore-only-daily-clamped-forage-reference/Runbook.md \
  docs/goals/003-herbivore-only-daily-clamped-forage-reference/Log.md \
  docs/log/20260714_goal003_herbivore_reference.md \
  inst/extdata/scenarios/goal003_herbivore_reference_v1.yaml \
  scripts/run_goal003_herbivore_reference.R \
  tests/testthat/test_goal003_herbivore_reference.R; do
  test "$(git log -1 --format=%H -- "$f")" = "$GOAL003_BASELINE_COMMIT"
done
git diff --quiet "$GOAL003_BASELINE_COMMIT" -- \
  docs/goals/003-herbivore-only-daily-clamped-forage-reference \
  docs/log/20260714_goal003_herbivore_reference.md \
  inst/extdata/scenarios/goal003_herbivore_reference_v1.yaml \
  scripts/run_goal003_herbivore_reference.R \
  tests/testthat/test_goal003_herbivore_reference.R
test -z "$(git diff --name-only e45a6b79b4fb5474609e916aa91e49b4ccc878e2 "$GOAL003_BASELINE_COMMIT" -- R)"
test "$(git show "$GOAL003_BASELINE_COMMIT:inst/extdata/scenarios/goal003_herbivore_reference_v1.yaml" | shasum -a 256 | cut -d " " -f 1)" = "07b99b21cdb48d34eac570a246c626d2b82931126bb4173aaf298c6327b85403"
test "$(git show "$GOAL003_BASELINE_COMMIT:scripts/run_goal003_herbivore_reference.R" | shasum -a 256 | cut -d " " -f 1)" = "b071096e431ee26c8e4b5946881dfcff35ec5bded0af379b267a04150722fb3b"
test "$(git show "$GOAL003_BASELINE_COMMIT:tests/testthat/test_goal003_herbivore_reference.R" | shasum -a 256 | cut -d " " -f 1)" = "1f5ea23dfea3ab379141596c9830c97715522f83b6b4be71ad9e7a140e221530"
TREE_DIGEST="$(
  for f in \
    docs/goals/003-herbivore-only-daily-clamped-forage-reference/Goal.md \
    docs/goals/003-herbivore-only-daily-clamped-forage-reference/Log.md \
    docs/goals/003-herbivore-only-daily-clamped-forage-reference/Plan.md \
    docs/goals/003-herbivore-only-daily-clamped-forage-reference/Runbook.md \
    docs/log/20260714_goal003_herbivore_reference.md \
    inst/extdata/scenarios/goal003_herbivore_reference_v1.yaml \
    scripts/run_goal003_herbivore_reference.R \
    tests/testthat/test_goal003_herbivore_reference.R; do
    printf '%s=' "$f"
    git show "$GOAL003_BASELINE_COMMIT:$f" | shasum -a 256 | cut -d " " -f 1
  done | shasum -a 256 | cut -d " " -f 1
)"
test "$TREE_DIGEST" = "03423aa5ec512ed4fda695a0ad55f828c3c308d1a7992ee20e09adc5af3a0d48"
```

Record `GOAL003_BASELINE_COMMIT` in `Log.md`. Push/publication is not a
precondition and remains unauthorized.

Verify accepted Goal 003 evidence without regenerating it:

```sh
test -f artefacts/goal003_herbivore_reference/run-a/run_manifest.json
test "$(shasum -a 256 artefacts/goal003_herbivore_reference/run-a/run_manifest.json | cut -d " " -f 1)" = "7e9ad004137e2a1c3b8a7233f183fcbbed02ef6bfdcf94f43dfded82a707538f"
jq -e '
  .status == "complete" and
  .configuration_sha256 == "68e28c9388e99cbf4658145b9e714556803a27f66367b8a7d8aee8c3535daa82" and
  .content_sha256 == "70ab1cd72f1a0de37cbc0da6317b76cf907be183efe7737e9760f8e25dc204eb" and
  .frozen_plant_state_sha256 == "547ea977d2da05898555359051898c1453d2968907d4cb77e63382fd85d7a23f"
' artefacts/goal003_herbivore_reference/run-a/run_manifest.json
```

Any missing path or changed hash stops execution. Do not rerun Goal 003 merely
to update embedded Git metadata.

## 2. Focused RED/GREEN Contract

```sh
/opt/homebrew/bin/R -q -e 'testthat::test_file("tests/testthat/test_goal004_energy_decomposition.R", stop_on_failure = TRUE)'
```

Before implementation, expected RED must arise only from absent Goal 004
helpers or runner. After implementation, expected GREEN is zero failures and
warnings. Retain exact outputs at:

```text
.superpowers/sdd/goal004-agents/executor/focused-red.txt
.superpowers/sdd/goal004-agents/executor/focused-green.txt
```

The focused suite must cover observer projection/RNG equality; all eight queue
ledgers; scale-aware residuals; zero canonical normalization/resizing;
before/after-boundary impulses; pre-closure +12 ticks; fixed-opportunity
capacity replay; bite-limit/tie/no-bite classifications; feedback projection;
minute-720 endpoint; first divergence; invalid profiles; absent output
directories; and stable artefact names.

## 3. Clean Run-A And Run-B

```sh
test ! -e artefacts/goal004_energy_decomposition/run-a
test ! -e artefacts/goal004_energy_decomposition/run-b
/opt/homebrew/bin/Rscript scripts/run_goal004_energy_decomposition.R \
  --profile inst/extdata/scenarios/goal004_energy_decomposition_v1.yaml \
  --output-dir artefacts/goal004_energy_decomposition/run-a
/opt/homebrew/bin/Rscript scripts/run_goal004_energy_decomposition.R \
  --profile inst/extdata/scenarios/goal004_energy_decomposition_v1.yaml \
  --output-dir artefacts/goal004_energy_decomposition/run-b
```

Expected in each directory:

```text
run_manifest.json
baseline_projection.csv
baseline_daily_diagnostics.csv
baseline_plant_diagnostics.csv
baseline_diagnostic_summary.json
hourly_queue_ledger.csv
daily_energy_budget.csv
minute_intake_limits.csv
probe_comparison.csv
probe_invariants.csv
probe_state_snapshots.rds
classification_summary.json
energy_budget_diagnostics.png
```

Preserve the first failed output and stop. Do not tune and rerun.

## 4. Manifest And Repeatability Gates

```sh
GOAL003_BASELINE_COMMIT="$(git log -1 --format=%H -- scripts/run_goal003_herbivore_reference.R)"
for f in run_manifest.json baseline_projection.csv baseline_daily_diagnostics.csv baseline_plant_diagnostics.csv baseline_diagnostic_summary.json hourly_queue_ledger.csv daily_energy_budget.csv minute_intake_limits.csv probe_comparison.csv probe_invariants.csv probe_state_snapshots.rds classification_summary.json energy_budget_diagnostics.png; do
  cmp "artefacts/goal004_energy_decomposition/run-a/$f" \
      "artefacts/goal004_energy_decomposition/run-b/$f"
done
jq -e --arg baseline_commit "$GOAL003_BASELINE_COMMIT" '
  .status == "complete" and
  .goal_id == "004-herbivore-energy-budget-forensic-decomposition" and
  .seed == 2002 and
  .days == 120 and
  .baseline_minute_limit == 720 and
  .baseline_ticks_per_day == 12 and
  .completed_clock_extra_ticks == 12 and
  .production_changes == false and
  .parameter_changes == false and
  .observer_projection_identical == true and
  .observer_exit_rng_identical == true and
  .goal003_rng_comparison == "not_available_not_claimed" and
  .all_ledger_checks_passed == true and
  .all_probe_invariants_passed == true and
  (.carried_policy_status == "complete" or
   .carried_policy_status == "not_run") and
  .goal003_reference.commit == $baseline_commit and
  .goal003_reference.tree_sha256 == "03423aa5ec512ed4fda695a0ad55f828c3c308d1a7992ee20e09adc5af3a0d48" and
  .goal003_reference.profile_sha256 == "07b99b21cdb48d34eac570a246c626d2b82931126bb4173aaf298c6327b85403" and
  .goal003_reference.runner_sha256 == "b071096e431ee26c8e4b5946881dfcff35ec5bded0af379b267a04150722fb3b" and
  .goal003_reference.test_sha256 == "1f5ea23dfea3ab379141596c9830c97715522f83b6b4be71ad9e7a140e221530" and
  .goal003_reference.manifest_sha256 == "7e9ad004137e2a1c3b8a7233f183fcbbed02ef6bfdcf94f43dfded82a707538f"
' artefacts/goal004_energy_decomposition/run-a/run_manifest.json
jq -e --slurpfile b artefacts/goal004_energy_decomposition/run-b/run_manifest.json '
  .configuration_sha256 == $b[0].configuration_sha256 and
  .source_sha256 == $b[0].source_sha256 and
  .content_sha256 == $b[0].content_sha256
' artefacts/goal004_energy_decomposition/run-a/run_manifest.json
```

Byte identity is fixed-seed computational repeatability only.

Require exact accepted Goal 003 output comparators:

```sh
cmp artefacts/goal004_energy_decomposition/run-a/baseline_daily_diagnostics.csv \
    artefacts/goal003_herbivore_reference/run-a/daily_diagnostics.csv
cmp artefacts/goal004_energy_decomposition/run-a/baseline_plant_diagnostics.csv \
    artefacts/goal003_herbivore_reference/run-a/plant_diagnostics.csv
cmp artefacts/goal004_energy_decomposition/run-a/baseline_diagnostic_summary.json \
    artefacts/goal003_herbivore_reference/run-a/diagnostic_summary.json
```

## 5. Structured Ledger And Probe Checks

```sh
/opt/homebrew/bin/Rscript - <<'RS'
options(warn = 2)
root <- "artefacts/goal004_energy_decomposition/run-a"
b <- read.csv(file.path(root, "baseline_projection.csv"), check.names = FALSE)
bd <- read.csv(file.path(root, "baseline_daily_diagnostics.csv"),
               check.names = FALSE)
q <- read.csv(file.path(root, "hourly_queue_ledger.csv"), check.names = FALSE)
d <- read.csv(file.path(root, "daily_energy_budget.csv"), check.names = FALSE)
i <- read.csv(file.path(root, "minute_intake_limits.csv"), check.names = FALSE)
p <- read.csv(file.path(root, "probe_comparison.csv"), check.names = FALSE)
v <- read.csv(file.path(root, "probe_invariants.csv"), check.names = FALSE,
              stringsAsFactors = FALSE, na.strings = character())
snapshots <- readRDS(file.path(root, "probe_state_snapshots.rds"))
s <- jsonlite::read_json(file.path(root, "classification_summary.json"), simplifyVector = TRUE)

queue_names <- c("bleaf", "bstem", "bdef", "dc_leaf", "dc_stem",
                 "dp_leaf", "dp_stem", "dp_def")
queue_fields <- c("branch", "Day", "model_day", "tick_index_day",
                  "elapsed_minute", "queue_name", "slot", "opening_slot",
                  "bite_insertion_slot", "pre_tick_slot",
                  "normalization_adjustment_slot",
                  "resizing_adjustment_slot", "terminal_release_raw",
                  "post_tick_slot")
daily_fields <- c("branch", "Day", "ticks", "intake_total_g",
                  "released_carb_g", "released_protein_g", "intake_PE_kJ",
                  "intake_NPE_kJ", "maintenance_kJ", "locomotion_kJ",
                  "total_requirement_kJ", "energy_delta_kJ", "gut_opening_g",
                  "gut_preclosure_g", "gut_closing_g",
                  "released_energy_recorded_kJ",
                  "released_energy_reconstructed_kJ",
                  "energy_release_residual_kJ", "energy_release_tolerance_kJ",
                  "queue_mass_opening_g", "queue_mass_inserted_g",
                  "queue_mass_released_g", "queue_mass_closing_g",
                  "queue_mass_residual_g", "queue_mass_tolerance_g",
                  "ledger_released_carb_g", "ledger_released_protein_g",
                  "ledger_released_energy_kJ",
                  "ledger_energy_release_residual_kJ",
                  "ledger_energy_release_tolerance_kJ",
                  "ledger_intake_total_g", "ledger_queue_mass_opening_g",
                  "ledger_queue_mass_inserted_g",
                  "ledger_queue_mass_released_g",
                  "ledger_queue_mass_closing_g",
                  "ledger_queue_mass_residual_g",
                  "ledger_queue_mass_tolerance_g",
                  "requested_foraging_h", "realised_foraging_h",
                  "BodyConditionIndex", "exit_rng_sha256")
limit_fields <- c("branch", "Day", "minute", "tick_index_day",
                  "opportunity_index", "eligible", "positive_intake",
                  "selected_plant_id", "gut_content_pre_g",
                  "gut_content_post_g", "intake_increment_g",
                  "handling_limit_kg", "capacity_limit_kg", "forage_limit_kg",
                  "mechanical_limit_kg", "winning_limit", "tie_mask",
                  "no_bite_reason", "rng_pre_sha256", "rng_post_sha256",
                  paste0("insert_", queue_names, "_g"))
probe_fields <- c("probe_id", "control", "intervention", "status",
                  "invariants_pass", "production_projection_identical",
                  "exit_rng_identical", "first_state_divergence",
                  "first_rng_divergence", "classification",
                  "allowed_inference")
invariant_fields <- c("probe_id", "branch", "Day", "checkpoint",
                      "invariant_name", "object_path",
                      "expected_value", "observed_value",
                      "expected_sha256", "observed_sha256",
                      "expected_relation")

stopifnot(all(queue_fields %in% names(q)))
stopifnot(all(daily_fields %in% names(d)))
stopifnot(all(limit_fields %in% names(i)))
stopifnot(all(probe_fields %in% names(p)))
stopifnot(all(invariant_fields %in% names(v)))
close <- function(expected, observed) {
  expected <- as.numeric(expected)
  observed <- as.numeric(observed)
  length(expected) == length(observed) &&
    all(abs(expected - observed) <=
          64 * .Machine$double.eps * pmax(1, abs(expected) + abs(observed)))
}
stopifnot(setequal(unique(q$queue_name), queue_names))
stopifnot(all(q$normalization_adjustment_slot == 0))
stopifnot(all(q$resizing_adjustment_slot == 0))
queue_key <- paste(q$branch, q$Day, q$tick_index_day, q$queue_name, q$slot,
                   sep = ":")
stopifnot(!anyDuplicated(queue_key))

transition_groups <- split(
  seq_len(nrow(q)),
  interaction(q$branch, q$Day, q$tick_index_day, q$queue_name,
              drop = TRUE, lex.order = TRUE)
)
transition_residual <- numeric(length(transition_groups))
transition_tolerance <- numeric(length(transition_groups))
for (g in seq_along(transition_groups)) {
  x <- q[transition_groups[[g]], , drop = FALSE]
  x <- x[order(x$slot), , drop = FALSE]
  stopifnot(identical(x$slot, seq_len(nrow(x))), nrow(x) == 24L)
  expected_pre <- x$opening_slot + x$bite_insertion_slot +
    x$normalization_adjustment_slot + x$resizing_adjustment_slot
  stopifnot(isTRUE(all.equal(x$pre_tick_slot, expected_pre, tolerance = 0)))
  expected_release <- ifelse(x$slot == 24L, expected_pre, 0)
  stopifnot(isTRUE(all.equal(x$terminal_release_raw, expected_release,
                             tolerance = 0)))
  expected_post <- c(0, expected_pre[seq_len(23L)])
  stopifnot(isTRUE(all.equal(x$post_tick_slot, expected_post, tolerance = 0)))
  transition_residual[[g]] <- sum(expected_pre) -
    sum(expected_release) - sum(expected_post)
  transition_tolerance[[g]] <- 64 * .Machine$double.eps *
    max(1, sum(abs(c(expected_pre, expected_release, expected_post))))
}
stopifnot(all(abs(transition_residual) <= transition_tolerance))

tick_keys <- unique(q[c("branch", "Day", "tick_index_day", "elapsed_minute")])
stopifnot(!anyDuplicated(paste(tick_keys$branch, tick_keys$Day,
                               tick_keys$tick_index_day, sep = ":")))
for (br in unique(tick_keys$branch)) {
  for (dy in sort(unique(tick_keys$Day[tick_keys$branch == br]))) {
    x <- tick_keys[tick_keys$branch == br & tick_keys$Day == dy, ]
    x <- x[order(x$tick_index_day), ]
    n_expected <- if (br %in% c("baseline", "carried_control")) 12L else 24L
    stopifnot(identical(x$tick_index_day, seq_len(n_expected)))
    stopifnot(identical(x$elapsed_minute, seq(60L, 60L * n_expected, by = 60L)))
  }
}

for (br in unique(q$branch)) for (dy in unique(q$Day[q$branch == br])) {
  for (nm in queue_names) {
    x <- q[q$branch == br & q$Day == dy & q$queue_name == nm, ]
    ticks <- sort(unique(x$tick_index_day))
    if (length(ticks) > 1L) for (tt in ticks[-1L]) {
      previous <- x$post_tick_slot[x$tick_index_day == tt - 1L]
      opening <- x$opening_slot[x$tick_index_day == tt]
      stopifnot(identical(previous, opening))
    }
  }
}
for (br in intersect(unique(q$branch),
                     c("baseline", "carried_control", "carried_completed_clock"))) {
  days <- sort(unique(q$Day[q$branch == br]))
  if (length(days) > 1L) for (dy in days[-1L]) for (nm in queue_names) {
    previous <- q$post_tick_slot[q$branch == br & q$Day == dy - 1L &
                                 q$queue_name == nm &
                                 q$tick_index_day == max(q$tick_index_day[
                                   q$branch == br & q$Day == dy - 1L])]
    opening <- q$opening_slot[q$branch == br & q$Day == dy &
                              q$queue_name == nm & q$tick_index_day == 1L]
    stopifnot(identical(previous, opening))
  }
}

insertion_columns <- stats::setNames(paste0("insert_", queue_names, "_g"),
                                     queue_names)
actual_insertions <- aggregate(
  q$bite_insertion_slot,
  by = list(branch = q$branch, Day = q$Day,
            tick_index_day = q$tick_index_day, queue_name = q$queue_name),
  FUN = sum
)
names(actual_insertions)[[5L]] <- "insertion_g"
source_limits <- i[i$branch %in% unique(q$branch), , drop = FALSE]
expected_sums <- do.call(rbind, lapply(queue_names, function(nm) {
  out <- aggregate(
    source_limits[[insertion_columns[[nm]]]],
    by = list(branch = source_limits$branch, Day = source_limits$Day,
              tick_index_day = source_limits$tick_index_day),
    FUN = sum
  )
  names(out)[[4L]] <- "insertion_g"
  out$queue_name <- nm
  out[c("branch", "Day", "tick_index_day", "queue_name", "insertion_g")]
}))
insertion_order <- function(x) order(
  x$branch, x$Day, x$tick_index_day, match(x$queue_name, queue_names)
)
actual_insertions <- actual_insertions[insertion_order(actual_insertions), ]
expected_sums <- expected_sums[insertion_order(expected_sums), ]
rownames(actual_insertions) <- NULL
rownames(expected_sums) <- NULL
insertion_keys <- c("branch", "Day", "tick_index_day", "queue_name")
key <- function(x) do.call(paste, c(x[insertion_keys], sep = ":"))
actual_key <- key(actual_insertions)
expected_key <- key(expected_sums)
expected_index <- match(actual_key, expected_key)
expected_insertions <- actual_insertions[insertion_keys]
expected_insertions$insertion_g <- 0
matched <- !is.na(expected_index)
expected_insertions$insertion_g[matched] <-
  expected_sums$insertion_g[expected_index[matched]]
stopifnot(!anyDuplicated(actual_key), !anyDuplicated(expected_key),
          all(expected_key %in% actual_key))
stopifnot(close(actual_insertions$insertion_g,
                expected_insertions$insertion_g))

energy_release <- aggregate(
  q$terminal_release_raw,
  by = list(branch = q$branch, Day = q$Day, queue_name = q$queue_name),
  FUN = sum
)
names(energy_release)[[4L]] <- "release_g"
wide <- reshape(energy_release, idvar = c("branch", "Day"),
                timevar = "queue_name", direction = "wide")
for (nm in paste0("release_g.", queue_names)) {
  if (!nm %in% names(wide)) wide[[nm]] <- 0
}
wide$independent_energy_kJ <- 16.7 *
  (wide$release_g.dc_leaf + wide$release_g.dc_stem) + 23.0 *
  (wide$release_g.dp_leaf + wide$release_g.dp_stem + wide$release_g.dp_def)
energy_idx <- match(paste(d$branch, d$Day), paste(wide$branch, wide$Day))
stopifnot(!anyNA(energy_idx))
independent_energy_kJ <- wide$independent_energy_kJ[energy_idx]
independent_carb_g <- (wide$release_g.dc_leaf +
                       wide$release_g.dc_stem)[energy_idx]
independent_protein_g <- (wide$release_g.dp_leaf + wide$release_g.dp_stem +
                          wide$release_g.dp_def)[energy_idx]
stopifnot(close(d$released_carb_g, independent_carb_g))
stopifnot(close(d$released_protein_g, independent_protein_g))
stopifnot(close(d$released_energy_reconstructed_kJ, independent_energy_kJ))
stopifnot(close(d$ledger_released_carb_g, independent_carb_g))
stopifnot(close(d$ledger_released_protein_g, independent_protein_g))
stopifnot(close(d$ledger_released_energy_kJ, independent_energy_kJ))
expected_energy_residual <- d$released_energy_recorded_kJ -
  independent_energy_kJ
expected_energy_tolerance <- 64 * .Machine$double.eps *
  pmax(1, abs(d$released_energy_recorded_kJ) + abs(independent_energy_kJ))
stopifnot(close(d$energy_release_residual_kJ, expected_energy_residual))
stopifnot(close(d$energy_release_tolerance_kJ, expected_energy_tolerance))
stopifnot(close(d$ledger_energy_release_residual_kJ,
                expected_energy_residual))
stopifnot(close(d$ledger_energy_release_tolerance_kJ,
                expected_energy_tolerance))
stopifnot(all(abs(expected_energy_residual) <= expected_energy_tolerance))

expected_mass_residual <- d$queue_mass_opening_g + d$queue_mass_inserted_g -
  d$queue_mass_released_g - d$queue_mass_closing_g
expected_mass_tolerance <- 64 * .Machine$double.eps *
  pmax(1, abs(d$queue_mass_opening_g) + abs(d$queue_mass_inserted_g) +
           abs(d$queue_mass_released_g) + abs(d$queue_mass_closing_g))
stopifnot(close(d$queue_mass_residual_g, expected_mass_residual))
stopifnot(close(d$queue_mass_tolerance_g, expected_mass_tolerance))
stopifnot(close(d$ledger_queue_mass_residual_g, expected_mass_residual))
stopifnot(close(d$ledger_queue_mass_tolerance_g, expected_mass_tolerance))
stopifnot(all(abs(expected_mass_residual) <= expected_mass_tolerance))

biomass <- q$queue_name %in% c("bleaf", "bstem", "bdef")
for (row in seq_len(nrow(d))) {
  x <- q[q$branch == d$branch[[row]] & q$Day == d$Day[[row]] & biomass, ]
  first_tick <- min(x$tick_index_day)
  last_tick <- max(x$tick_index_day)
  raw_opening <- sum(x$opening_slot[x$tick_index_day == first_tick])
  raw_inserted <- sum(x$bite_insertion_slot)
  raw_released <- sum(x$terminal_release_raw)
  raw_closing <- sum(x$post_tick_slot[x$tick_index_day == last_tick])
  stopifnot(close(d$queue_mass_opening_g[[row]], raw_opening))
  stopifnot(close(d$queue_mass_inserted_g[[row]], raw_inserted))
  stopifnot(close(d$queue_mass_released_g[[row]], raw_released))
  stopifnot(close(d$queue_mass_closing_g[[row]], raw_closing))
  stopifnot(close(d$intake_total_g[[row]], raw_inserted))
  stopifnot(close(d$ledger_queue_mass_opening_g[[row]], raw_opening))
  stopifnot(close(d$ledger_queue_mass_inserted_g[[row]], raw_inserted))
  stopifnot(close(d$ledger_queue_mass_released_g[[row]], raw_released))
  stopifnot(close(d$ledger_queue_mass_closing_g[[row]], raw_closing))
  stopifnot(close(d$ledger_intake_total_g[[row]], raw_inserted))
}

baseline_budget <- d[d$branch == "baseline", , drop = FALSE]
baseline_budget <- baseline_budget[order(baseline_budget$Day), , drop = FALSE]
bd <- bd[order(bd$Day), , drop = FALSE]
stopifnot(identical(as.integer(baseline_budget$Day), as.integer(bd$Day)))
stopifnot(close(baseline_budget$intake_total_g, bd$intake_total_g))
stopifnot(close(baseline_budget$ledger_intake_total_g, bd$intake_total_g))

stopifnot(all(d$ticks[d$branch == "baseline"] == 12L))
stopifnot(all(d$ticks[d$branch == "completed_clock"] == 24L))
required_invariants <- c(
  "observer_projection_equal", "observer_rng_equal",
  "tick_phase_opening_queue_equal", "tick_phase_tick_count_equal",
  "completed_clock_no_feeding", "completed_clock_no_movement",
  "completed_clock_plant_equal", "completed_clock_no_drinking",
  "completed_clock_rng_equal", "completed_clock_requirement_equal",
  "capacity_entry_non_gut_read_set_equal", "capacity_entry_plant_equal",
  "capacity_entry_gut_queue_identity", "capacity_rng_unchanged",
  "demand_state_unchanged", "bci_matched_start_rng",
  "endpoint_equal_through_minute_719"
)
stopifnot(all(required_invariants %in% v$invariant_name))
equal_rows <- v$expected_relation == "identical"
required_rows <- v$invariant_name %in% required_invariants
stopifnot(all(v$expected_relation[required_rows] == "identical"))
stopifnot(all(v$expected_relation %in% c("identical", "allowed_difference")))
hash_available <- nzchar(v$expected_sha256) & nzchar(v$observed_sha256)
value_available <- nzchar(v$expected_value) & nzchar(v$observed_value)
stopifnot(all(nzchar(v$expected_sha256) == nzchar(v$observed_sha256)))
stopifnot(all(nzchar(v$expected_value) == nzchar(v$observed_value)))
stopifnot(all(hash_available | value_available))
same <- rep(FALSE, nrow(v))
same[hash_available] <- v$expected_sha256[hash_available] ==
  v$observed_sha256[hash_available]
same[!hash_available & value_available] <-
  v$expected_value[!hash_available & value_available] ==
  v$observed_value[!hash_available & value_available]
stopifnot(all(same[equal_rows]))
stopifnot(all(same[required_rows]))
daily_invariants <- setdiff(required_invariants,
                            c("tick_phase_opening_queue_equal",
                              "tick_phase_tick_count_equal"))
for (nm in daily_invariants) {
  stopifnot(setequal(v$Day[v$invariant_name == nm], seq_len(120L)))
}

stopifnot(identical(names(snapshots), c("schema_version", "records")))
stopifnot(identical(snapshots$schema_version, "1.0.0"))
stopifnot(is.list(snapshots$records), length(snapshots$records) > 0L)

herbivore_fields <- c(
  "herbivore_id", "mass", "herb_type", "mixed_browser_weight",
  "movement_disruption_prob", "foraging_mode", "forage_access_scale",
  "xcor", "ycor", "current_hour", "last_hour", "MRT", "behaviour",
  "selected_plant_id", "selected_plant_dist", "gut_content",
  "distance_moved", "time_spent_foraging", "intake_total_day",
  "intake_digest_carbs_day", "intake_digest_protein_day", "intake_PE_day",
  "intake_NPE_day", "intake_defence_day", "intake_total",
  "metabolic_water_day", "intake_water_forage", "intake_water_drinking",
  "daily_net_water_balance", "daily_water_intake_total",
  "water_requirement_day", "water_balance_ratio",
  "maintenance_energy_requirement_day", "total_energy_requirement_day",
  "daily_energy_intake", "daily_energy_delta", "energy_balance_ratio",
  "energy_deficit_streak_days", "water_deficit_streak_days",
  "physiological_stress_flag", "body_condition_index",
  "baseline_time_spent_foraging", "body_condition_feedback_enabled",
  "body_condition_gain_coeff", "body_condition_loss_coeff",
  "body_condition_effort_threshold", "body_condition_stress_threshold",
  "body_condition_max_foraging_boost", "energy_balance", "water_balance",
  "digestion", "gut_capacity", "bite_size", "handling_time", "fv_max",
  "daily_water_requirement", "feedback_settings", "seeded_draws"
)
plant_fields <- c(
  "plant_id", "xcor", "ycor", "veg_type", "ms", "mr", "cs", "cr",
  "ns", "nr", "cd", "nd", "bleaf", "bstem", "bdef", "md", "broot",
  "brepr", "height", "qroot", "qshoot", "gs", "gr", "gd", "uc", "un",
  "rsC", "rrC", "rdC", "rsN", "rrN", "rdN", "tauC", "tauN", "tauCd",
  "tauNd"
)
daily_output_fields <- c(
  "Day", "model_day", "HerbivoreID", "day_seed", "temperature",
  "soil_water", "soil_nitrogen", "opening_xcor_m", "opening_ycor_m", "xcor",
  "ycor", "opening_gut_content_g", "gut_content_g", "gut_capacity_g",
  "intake_total_g", "intake_PE_kJ", "intake_NPE_kJ", "energy_intake_kJ",
  "total_energy_requirement_kJ", "energy_delta_kJ", "EnergyBalance",
  "cumulative_energy_balance_kJ", "metabolic_water_g", "forage_water_g",
  "drinking_water_g", "water_input_total_g", "water_requirement_g",
  "daily_net_water_g", "WaterBalance", "cumulative_water_balance_g",
  "distance_moved_m", "time_spent_foraging_h", "EnergyDeficitStreakDays",
  "WaterDeficitStreakDays", "BodyConditionIndex", "PhysiologicalStressFlag",
  "behaviour", "selected_plant_id", "energy_daily_residual_kJ",
  "energy_cumulative_residual_kJ", "water_daily_residual_g",
  "water_cumulative_residual_g"
)
constant_fields <- c("MIN_SHOOT", "MAX_BITE_FRACTION", "FRACTION_C",
                     "PROP_DIGEST_SC", "FRACTION_N", "N_TO_PROTEIN",
                     "PROP_DIGEST_TP")
feedback_fields <- c("enabled", "initial_bci", "gain_coeff", "loss_coeff",
                     "effort_threshold", "stress_threshold",
                     "max_foraging_boost")
seeded_fields <- c("initial_xcor_draw_m", "initial_ycor_draw_m", "seed",
                   "coordinate_resolution")

validate_projection <- function(x, closed) {
  stopifnot(is.list(x),
            identical(names(x), c("herbivore", "plants", "daily_output",
                                  "rng", "constants")),
            identical(names(x$herbivore), herbivore_fields),
            identical(names(x$herbivore$digestion), queue_names),
            all(lengths(x$herbivore$digestion) == 24L),
            identical(names(x$herbivore$feedback_settings), feedback_fields),
            identical(names(x$herbivore$seeded_draws), seeded_fields),
            is.data.frame(x$plants), nrow(x$plants) == 1L,
            identical(names(x$plants), plant_fields),
            identical(names(x$constants), constant_fields),
            all(lengths(x$constants) == 1L),
            is.null(x$rng) || is.integer(x$rng))
  if (closed) {
    stopifnot(is.data.frame(x$daily_output), nrow(x$daily_output) == 1L,
              identical(names(x$daily_output), daily_output_fields))
  } else {
    stopifnot(is.null(x$daily_output))
  }
  invisible(TRUE)
}

structure_attributes <- function(x) {
  out <- attributes(x)
  out$names <- NULL
  out
}
changed_paths <- function(a, b, path = "") {
  if (identical(a, b)) return(character())
  if (!identical(typeof(a), typeof(b)) || !identical(length(a), length(b)) ||
      !identical(names(a), names(b))) {
    return(paste0(path, ".__structure__"))
  }
  out <- character()
  if (!identical(structure_attributes(a), structure_attributes(b))) {
    out <- c(out, paste0(path, ".__attributes__"))
  }
  if (is.list(a)) {
    for (j in seq_along(a)) {
      label <- if (!is.null(names(a))) names(a)[[j]] else paste0("[[", j, "]]" )
      child <- if (nzchar(path)) paste(path, label, sep = ".") else label
      out <- c(out, changed_paths(a[[j]], b[[j]], child))
    }
    return(unique(out))
  }
  for (j in seq_along(a)) if (!identical(a[[j]], b[[j]])) {
    out <- c(out, if (length(a) == 1L) path else paste0(path, "[", j, "]"))
  }
  unique(out)
}

preclosure_allowed <- c(
  "herbivore.digestion", "herbivore.gut_content",
  "herbivore.intake_digest_carbs_day",
  "herbivore.intake_digest_protein_day", "herbivore.intake_NPE_day",
  "herbivore.intake_PE_day", "herbivore.metabolic_water_day"
)
postclosure_allowed <- c(
  preclosure_allowed, "herbivore.intake_water_drinking",
  "herbivore.distance_moved", "herbivore.daily_net_water_balance",
  "herbivore.daily_water_intake_total", "herbivore.water_requirement_day",
  "herbivore.water_balance_ratio", "herbivore.water_balance",
  "herbivore.maintenance_energy_requirement_day",
  "herbivore.total_energy_requirement_day", "herbivore.daily_energy_intake",
  "herbivore.daily_energy_delta", "herbivore.energy_balance_ratio",
  "herbivore.energy_balance", "herbivore.energy_deficit_streak_days",
  "herbivore.water_deficit_streak_days",
  "herbivore.physiological_stress_flag", "herbivore.body_condition_index",
  "daily_output.gut_content_g", "daily_output.intake_PE_kJ",
  "daily_output.intake_NPE_kJ", "daily_output.energy_intake_kJ",
  "daily_output.total_energy_requirement_kJ", "daily_output.energy_delta_kJ",
  "daily_output.EnergyBalance", "daily_output.cumulative_energy_balance_kJ",
  "daily_output.metabolic_water_g", "daily_output.drinking_water_g",
  "daily_output.water_input_total_g", "daily_output.daily_net_water_g",
  "daily_output.WaterBalance", "daily_output.cumulative_water_balance_g",
  "daily_output.distance_moved_m", "daily_output.EnergyDeficitStreakDays",
  "daily_output.WaterDeficitStreakDays", "daily_output.BodyConditionIndex",
  "daily_output.PhysiologicalStressFlag", "daily_output.energy_daily_residual_kJ",
  "daily_output.energy_cumulative_residual_kJ",
  "daily_output.water_daily_residual_g",
  "daily_output.water_cumulative_residual_g"
)
allowed_paths <- list(
  "observer|daily_closed" = character(),
  "completed_clock|minute_720_preclosure" = preclosure_allowed,
  "completed_clock|daily_closed" = postclosure_allowed,
  "capacity_pathway|replay_entry" = preclosure_allowed,
  "demand_zero_locomotion|algebraic_entry" = character(),
  "bci_feedback_operability|matched_start" =
    "herbivore.body_condition_feedback_enabled",
  "endpoint_eligibility|minute_719" = character(),
  "bci_feedback_operability|adjusted_exit" =
    "herbivore.body_condition_feedback_enabled"
)
path_is_allowed <- function(path, prefixes) {
  any(vapply(prefixes, function(prefix) {
    identical(path, prefix) || startsWith(path, paste0(prefix, ".")) ||
      startsWith(path, paste0(prefix, "["))
  }, logical(1)))
}

bci_class <- p$classification[p$probe_id == "bci_feedback_operability"]
stopifnot(length(bci_class) == 1L)
expected_record_keys <- c(
  "observer|daily_closed", "completed_clock|minute_720_preclosure",
  "completed_clock|daily_closed", "capacity_pathway|replay_entry",
  "demand_zero_locomotion|algebraic_entry",
  "bci_feedback_operability|matched_start",
  "endpoint_eligibility|minute_719"
)
if (identical(bci_class, "nonoperative_here")) {
  expected_record_keys <- c(expected_record_keys,
                            "bci_feedback_operability|adjusted_exit")
}
record_keys <- vapply(snapshots$records, function(record) {
  stopifnot(identical(names(record),
                      c("probe_id", "Day", "checkpoint", "control",
                        "intervention")),
            is.character(record$probe_id), length(record$probe_id) == 1L,
            is.integer(record$Day), length(record$Day) == 1L,
            is.character(record$checkpoint), length(record$checkpoint) == 1L)
  paste(record$probe_id, record$checkpoint, sep = "|")
}, character(1))
stopifnot(setequal(unique(record_keys), expected_record_keys))
for (key in expected_record_keys) {
  idx <- which(record_keys == key)
  days <- vapply(snapshots$records[idx], `[[`, integer(1), "Day")
  stopifnot(length(idx) == 120L, identical(sort(days), seq_len(120L)))
}

capacity_read_set <- function(x) {
  list(
    herbivore = x$herbivore[c(
      "selected_plant_id", "handling_time", "gut_capacity", "MRT",
      "intake_total_day", "intake_defence_day", "intake_water_forage"
    )],
    plant = x$plants[x$plants$plant_id == 1L,
                     c("plant_id", "bleaf", "bstem", "bdef", "qshoot"),
                     drop = FALSE],
    constants = x$constants
  )
}
gut_identity <- function(x) {
  identical(as.numeric(x$herbivore$gut_content),
            sum(unlist(x$herbivore$digestion[c("bleaf", "bstem", "bdef")],
                       use.names = FALSE)))
}

for (record_index in seq_along(snapshots$records)) {
  record <- snapshots$records[[record_index]]
  key <- record_keys[[record_index]]
  closed <- record$checkpoint %in% c("daily_closed", "adjusted_exit")
  validate_projection(record$control, closed)
  validate_projection(record$intervention, closed)
  paths <- sort(changed_paths(record$control, record$intervention))
  prefixes <- allowed_paths[[key]]
  stopifnot(length(paths) == 0L ||
            all(vapply(paths, path_is_allowed, logical(1), prefixes = prefixes)))
  reported <- v$object_path[
    v$probe_id == record$probe_id & v$Day == record$Day &
      v$checkpoint == record$checkpoint &
      v$invariant_name == "observed_changed_path"
  ]
  stopifnot(all(nzchar(reported)), setequal(paths, reported))
  if (identical(key, "capacity_pathway|replay_entry")) {
    stopifnot(identical(capacity_read_set(record$control),
                        capacity_read_set(record$intervention)),
              identical(record$control$plants, record$intervention$plants),
              identical(record$control$rng, record$intervention$rng),
              gut_identity(record$control), gut_identity(record$intervention))
  }
}

capacity <- i[i$branch %in% c("capacity_unticked",
                               "capacity_completed_clock"), ]
stopifnot(setequal(unique(capacity$branch),
                   c("capacity_unticked", "capacity_completed_clock")))
for (br in unique(capacity$branch)) for (dy in seq_len(120L)) {
  x <- capacity[capacity$branch == br & capacity$Day == dy, ]
  x <- x[order(x$opportunity_index), ]
  stopifnot(nrow(x) == 720L,
            identical(x$opportunity_index, seq_len(720L)),
            all(x$selected_plant_id == 1L),
            all(x$rng_pre_sha256 == x$rng_post_sha256),
            all(x$winning_limit != "forage"),
            !any(grepl("forage", x$tie_mask, fixed = TRUE)))
}
carried <- p[p$probe_id == "carried_completed_clock", , drop = FALSE]
stopifnot(nrow(carried) == 1L)
if (identical(carried$status[[1L]], "not_run")) {
  stopifnot("reason" %in% names(carried), nzchar(carried$reason[[1L]]))
}
bci <- p[p$probe_id == "bci_feedback_operability", , drop = FALSE]
stopifnot(nrow(bci) == 1L)
if (identical(bci$classification[[1L]], "nonoperative_here")) {
  stopifnot(all(c("bci_projection_equal", "bci_rng_equal") %in%
                v$invariant_name[same]))
}
stopifnot(all(is.finite(i$handling_limit_kg)))
stopifnot(all(is.finite(i$capacity_limit_kg)))
stopifnot(all(is.finite(i$forage_limit_kg)))
stopifnot(all(is.finite(i$mechanical_limit_kg)))
stopifnot(all(c("implementation_or_contract_defect", "parameter_plausibility",
                "intended_behaviour_here", "nonoperative_here",
                "unresolved_interaction") %in% s$allowed_classes))
stopifnot(isTRUE(s$stable_bci_is_not_target))
stopifnot(isFALSE(s$production_changed), isFALSE(s$parameter_changed))

numeric_tables <- list(b, q, d, i)
stopifnot(all(vapply(numeric_tables, function(x) {
  nums <- x[vapply(x, is.numeric, logical(1))]
  all(vapply(nums, function(y) all(is.finite(y)), logical(1)))
}, logical(1))))

cat("baseline rows:", nrow(b), "\n")
cat("queue ledger rows:", nrow(q), "\n")
cat("intake-limit rows:", nrow(i), "\n")
cat("maximum scaled queue residual:",
    max(abs(transition_residual / transition_tolerance)), "\n")
print(p[, probe_fields])
RS
test -s artefacts/goal004_energy_decomposition/run-a/energy_budget_diagnostics.png
```

All checks must pass without warnings. Visually inspect the figure for readable
units, control/intervention labels, direct versus total effects, uncertainty
text, and no biological pass threshold.

## 6. Baseline Equality And Scientific Stops

Goal 003 retained no caller/per-day exit RNG vectors. Verify exact state/RNG
equality only between Goal 004's bare-control and observer branches, while the
byte comparisons in Section 4 separately bind both branches' machine-readable
outputs to Goal 003. Do not report direct Goal 003 RNG equality:

```sh
/opt/homebrew/bin/Rscript - <<'RS'
z <- read.csv(
  "artefacts/goal004_energy_decomposition/run-a/baseline_projection.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
required <- c("branch", "Day", "minute", "phase",
              "herbivore_state_sha256", "plant_state_sha256",
              "daily_output_sha256", "rng_sha256")
stopifnot(all(required %in% names(z)))
stopifnot(setequal(unique(z$branch), c("bare_control", "observer")))
phase_rank <- c("daily_opening", "minute_post_step_pre_tick",
                "hourly_tick_pre", "hourly_tick_post",
                "minute_720_preclosure", "daily_closed")
stopifnot(!anyNA(match(z$phase, phase_rank)))
for (br in unique(z$branch)) {
  x <- z[z$branch == br, , drop = FALSE]
  expected_order <- order(x$Day, x$minute, match(x$phase, phase_rank))
  stopifnot(identical(expected_order, seq_len(nrow(x))))
}
key <- paste(z$Day, z$minute, z$phase, sep = ":")
control <- z[z$branch == "bare_control", required, drop = FALSE]
observer <- z[z$branch == "observer", required, drop = FALSE]
control_key <- paste(control$Day, control$minute, control$phase, sep = ":")
observer_key <- paste(observer$Day, observer$minute, observer$phase, sep = ":")
stopifnot(identical(control_key, observer_key))
for (nm in c("herbivore_state_sha256", "plant_state_sha256",
             "daily_output_sha256", "rng_sha256")) {
  stopifnot(identical(control[[nm]], observer[[nm]]))
}
stopifnot(!anyDuplicated(paste(z$branch, key, sep = ":")))
RS
jq -e '
  .observer_projection_identical == true and
  .observer_exit_rng_identical == true and
  .goal003_rng_comparison == "not_available_not_claimed" and
  .first_baseline_state_divergence == null and
  .first_baseline_rng_divergence == null
' artefacts/goal004_energy_decomposition/run-a/run_manifest.json
jq -e '
  all(.mechanisms[];
    (.evidence_type == "observation" or
     .evidence_type == "identity" or
     .evidence_type == "counterfactual" or
     .evidence_type == "literature_dependent") and
    (.classification == "implementation_or_contract_defect" or
     .classification == "parameter_plausibility" or
     .classification == "intended_behaviour_here" or
     .classification == "nonoperative_here" or
     .classification == "unresolved_interaction") and
    (.evidence_ids | type == "array") and
    (.evidence_ids | length > 0)) and
  .dominant_cause_claim == false and
  ((.comparable_alternatives | length) >= 2 and
    .barry_decision_required == true and
    .recommended_next_goal == null or
   (.comparable_alternatives | length) == 0 and
    .barry_decision_required == false and
    (.recommended_next_goal == null or
     ((.recommended_next_goal | type) == "object" and
      (.recommended_next_goal.type == "production_correction" or
       .recommended_next_goal.type == "literature_parameter_validation") and
      (.recommended_next_goal.evidence_ids | type) == "array" and
      (.recommended_next_goal.evidence_ids | length) > 0)))
' artefacts/goal004_energy_decomposition/run-a/classification_summary.json
```

If a supposedly isolated completed-clock, capacity, demand, feedback, or
endpoint probe changes a forbidden field, stop. Do not reinterpret it as an
isolated effect.

## 7. Full Repository Validation Ladder

```sh
/opt/homebrew/bin/R -q -e 'testthat::test_file("tests/testthat/test_goal004_energy_decomposition.R", stop_on_failure = TRUE)'
make test R=/opt/homebrew/bin/R RSCRIPT=/opt/homebrew/bin/Rscript
make lint R=/opt/homebrew/bin/R RSCRIPT=/opt/homebrew/bin/Rscript
/opt/homebrew/bin/R -q -e 'status <- renv::status(); if (!isTRUE(status$synchronized)) quit(status = 1L)'
git diff --check
git status --short --branch
git diff --name-status
git ls-files --others --exclude-standard
```

Expected: focused and full tests pass; lint is clean; `renv` is synchronized;
diff checks pass; and only the nine intended Goal 004 paths are added/changed.

Do not run `make smoke`, `make check`, reproducibility scripts, targets,
package checks, or document builds under the preferred design. A need for
those gates indicates production/package scope and requires Barry's approval.

## 8. Independent Review And Closeout

Provide reviewers with the exact source diff, Goal 003 hashes, Goal 004
manifests, projection/RNG equality, complete ledgers, probe invariant table,
first-divergence records, classification JSON, figure, scientific memo,
validation output, and final Git status.

Acceptance requires no open Critical or Important issue. Record reviewer
profile/runtime provenance and all finding resolutions in `Log.md`. Report
exact paths and stop. Goal acceptance does not authorize correction, staging,
commit, push, publication, or another simulation.

Retain the full validation transcript and final reviews at:

```text
.superpowers/sdd/goal004-agents/executor/validation.txt
.superpowers/sdd/goal004-agents/scientific-review/final.txt
.superpowers/sdd/goal004-agents/final-audit/final.txt
```
