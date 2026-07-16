goal004_test_source <- local({
  loaded <- FALSE
  function() {
    if (!loaded) {
      source(file.path(repo_root_for_tests(), "scripts", "run_goal004_energy_decomposition.R"),
        local = .GlobalEnv
      )
      loaded <<- TRUE
    }
    invisible(TRUE)
  }
})

goal004_test_context <- function() {
  goal004_test_source()
  root <- repo_root_for_tests()
  profile <- goal003_validate_profile(goal003_read_profile(
    file.path(root, "inst", "extdata", "scenarios", "goal003_herbivore_reference_v1.yaml")
  ))
  forcing <- goal003_resolved_forcing(profile)
  conditions <- data.frame(
    day = 1L, temp_mean = forcing$temperature,
    sw = forcing$soil_water, N = forcing$soil_nitrogen
  )
  initial <- goal003_resolve_initial_state(profile)
  list(
    root = root, profile = profile, forcing = forcing, conditions = conditions,
    initial = initial
  )
}

testthat::test_that("Goal 004 rejects profile drift and preserves exact artefact names", {
  goal004_test_source()
  root <- repo_root_for_tests()
  path <- file.path(root, "inst", "extdata", "scenarios", "goal004_energy_decomposition_v1.yaml")
  profile <- goal004_validate_profile(goal004_read_profile(path))
  expected <- c(
    "run_manifest.json", "baseline_projection.csv", "baseline_daily_diagnostics.csv",
    "baseline_plant_diagnostics.csv", "baseline_diagnostic_summary.json",
    "hourly_queue_ledger.csv", "daily_energy_budget.csv", "minute_intake_limits.csv",
    "probe_comparison.csv", "probe_invariants.csv", "probe_state_snapshots.rds",
    "classification_summary.json", "energy_budget_diagnostics.png"
  )
  testthat::expect_identical(profile$outputs$artefact_names, expected)
  bad <- profile
  bad$outputs$artefact_names[[2L]] <- "renamed.csv"
  testthat::expect_error(goal004_validate_profile(bad), class = "herbivoreTTR_goal004_profile_invalid")
  bad <- profile
  bad$runtime$days <- 1L
  testthat::expect_error(goal004_validate_profile(bad), class = "herbivoreTTR_goal004_profile_invalid")
  existing_output <- tempfile("goal004-existing-output-")
  dir.create(existing_output)
  on.exit(unlink(existing_output, recursive = TRUE, force = TRUE), add = TRUE)
  testthat::expect_error(
    goal004_run("profile-not-read-when-output-exists.yaml", existing_output),
    class = "herbivoreTTR_goal004_output_exists"
  )
})

testthat::test_that("diagnostic figure contract exposes control, intervention, and effect scope", {
  goal004_test_source()
  daily <- data.frame(
    Day = 1:2,
    intake_total_g = c(500, 600),
    cumulative_energy_balance_kJ = c(-100, -300)
  )
  budget <- data.frame(
    branch = rep(c("baseline", "completed_clock"), each = 2L),
    Day = rep(1:2, 2L),
    energy_delta_kJ = c(-100, -200, 50, 75)
  )

  contract <- goal004_plot_contract(daily, budget, "not_run")

  testthat::expect_equal(contract$paired$direct_effect_kJ, c(150, 275))
  testthat::expect_match(contract$labels$control, "control")
  testthat::expect_match(contract$labels$intervention, "intervention")
  testthat::expect_match(contract$labels$effect_scope, "direct effect")
  testthat::expect_match(contract$labels$total_effect, "not run")
  testthat::expect_match(contract$labels$uncertainty, "no uncertainty interval")
})

testthat::test_that("projection is complete, version-3 stable, and reports the first divergence", {
  ctx <- goal004_test_context()
  h <- ctx$initial$herbivore_state
  p <- ctx$initial$plants_state
  projection <- goal004_projection(h, p, NULL, c(1L, 2L, 3L))
  testthat::expect_identical(names(projection), c("herbivore", "plants", "daily_output", "rng", "constants"))
  testthat::expect_identical(names(projection$herbivore), goal004_herbivore_fields())
  testthat::expect_identical(names(projection$plants), goal004_plant_fields())
  testthat::expect_identical(names(projection$herbivore$digestion), goal004_queue_names())
  testthat::expect_identical(
    goal004_projection_hashes(projection),
    goal004_projection_hashes(goal004_clone(projection))
  )
  a <- list(x = 1, y = list(z = 2))
  b <- list(x = 1, y = list(z = 3))
  testthat::expect_identical(goal004_changed_paths(a, b), "y.z")
  changed <- goal004_clone(projection)
  changed$herbivore$mass <- if (is.integer(changed$herbivore$mass)) {
    as.integer(changed$herbivore$mass + 1L)
  } else {
    changed$herbivore$mass + 1
  }
  divergence <- goal004_first_divergence(
    projection, changed, "unit_test"
  )
  testthat::expect_identical(divergence$path, "herbivore.mass")
  testthat::expect_identical(divergence$expected, projection$herbivore$mass)
  testthat::expect_identical(divergence$observed, changed$herbivore$mass)
  testthat::expect_identical(
    divergence$expected_hash, goal004_sha256(projection$herbivore$mass)
  )
  testthat::expect_false(identical(
    divergence$expected_hash, goal004_sha256(projection$herbivore)
  ))
  row <- goal004_invariant("x", "paired", 1L, "checkpoint", "must_be_true", "x", TRUE, FALSE)
  testthat::expect_false(goal004_invariant_pass(row))
  testthat::expect_error(goal004_assert_invariants(row), class = "herbivoreTTR_goal004_probe_stop")
})

testthat::test_that("all eight queue transitions reconcile with zero canonical adjustments", {
  goal004_test_source()
  qn <- goal004_queue_names()
  transitions <- lapply(seq_along(qn), function(i) {
    goal004_queue_transition(seq_len(24L) * i, rep(i / 10, 24L), 24L)
  })
  testthat::expect_identical(length(transitions), 8L)
  testthat::expect_true(all(vapply(transitions, function(x) all(x$normalization == 0), logical(1))))
  testthat::expect_true(all(vapply(transitions, function(x) all(x$resizing == 0), logical(1))))
  testthat::expect_true(all(vapply(transitions, function(x) abs(x$residual) <= x$tolerance, logical(1))))
  testthat::expect_equal(transitions[[1L]]$post_tick, c(0, transitions[[1L]]$pre_tick[-24L]))
  terminal <- stats::setNames(vapply(transitions, function(x) x$terminal_release[24L], numeric(1)), qn)
  testthat::expect_equal(
    goal004_energy_from_terminal(terminal),
    16.7 * sum(terminal[c("dc_leaf", "dc_stem")]) +
      23 * sum(terminal[c("dp_leaf", "dp_stem", "dp_def")])
  )
})

testthat::test_that("tick phase uses real production digestion on matched states", {
  ctx <- goal004_test_context()
  h <- ctx$initial$herbivore_state
  result <- goal004_tick_phase_probe(h)
  testthat::expect_identical(result$tick_count, c(after_boundary = 1L, before_boundary = 1L))
  testthat::expect_equal(result$after_boundary$released_mass_g, 0)
  testthat::expect_gt(result$before_boundary$released_mass_g, 0)
  testthat::expect_identical(result$after_boundary$queue_lengths, result$before_boundary$queue_lengths)
  testthat::expect_equal(
    result$after_boundary$opening_queue_mass_g,
    result$before_boundary$opening_queue_mass_g
  )
})

testthat::test_that("completed clock applies exactly twelve production digestion-only ticks", {
  ctx <- goal004_test_context()
  reset <- goal003_reset_day(ctx$initial$plants_state, ctx$initial$herbivore_state)
  day <- goal004_run_day(reset$herbivore, reset$plants, ctx$conditions, 6L, 102002L, 720L,
    FALSE, "internal_ttr", 1,
    observer = TRUE
  )
  result <- goal004_completed_trace(list(
    herbivore = day$checkpoint_herbivore,
    plants = day$checkpoint_plants,
    day = 1L, model_day = 6L
  ), 12L)
  testthat::expect_identical(result$tick_count, 12L)
  testthat::expect_identical(result$invariants$plant, TRUE)
  testthat::expect_identical(result$invariants$intake, TRUE)
  testthat::expect_identical(result$invariants$movement, TRUE)
  testthat::expect_identical(result$invariants$drinking, TRUE)
  testthat::expect_identical(result$invariants$requirement, TRUE)
  testthat::expect_identical(result$invariants$rng, TRUE)
  testthat::expect_true(all(result$queues$normalization_adjustment_slot == 0))
  testthat::expect_true(all(result$queues$resizing_adjustment_slot == 0))
})

testthat::test_that("capacity replay makes 720 direct plant-1 calls in both branches", {
  ctx <- goal004_test_context()
  h <- ctx$initial$herbivore_state
  h <- calc_foraging_traits(h)
  h$selected_plant_id <- 1L
  h$behaviour <- "EATING"
  p1 <- goal004_clone(ctx$initial$plants_state)
  p2 <- goal004_clone(ctx$initial$plants_state)
  before <- goal004_rng()
  a <- goal004_capacity_replay(h, p1, 720L, "capacity_unticked", 1L)
  b <- goal004_capacity_replay(h, p2, 720L, "capacity_completed_clock", 1L)
  testthat::expect_identical(nrow(a$rows), 720L)
  testthat::expect_identical(nrow(b$rows), 720L)
  testthat::expect_identical(a$rows$opportunity_index, seq_len(720L))
  testthat::expect_identical(b$rows$opportunity_index, seq_len(720L))
  testthat::expect_true(all(a$rows$selected_plant_id == 1L & b$rows$selected_plant_id == 1L))
  testthat::expect_identical(before, goal004_rng())
  testthat::expect_true(all(a$rows$plant_available_nonbinding & b$rows$plant_available_nonbinding))
})

testthat::test_that("bite attribution exposes winner, ties, positive identity, and no-bite reasons", {
  goal004_test_source()
  h <- list(handling_time = 2, gut_capacity = 1000, gut_content = 0)
  plant <- data.frame(bleaf = 1, bstem = 0, bdef = 0, ms = 1, qshoot = 1)
  limits <- goal004_bite_limits(h, plant)
  testthat::expect_true(limits$winner %in% c("handling", "capacity", "forage", "mechanical"))
  testthat::expect_true(nzchar(limits$tie_mask))
  testthat::expect_identical(goal004_classify_no_bite(positive_intake = TRUE, eligible = TRUE), "positive_bite")
  testthat::expect_identical(goal004_classify_no_bite(positive_intake = FALSE, eligible = FALSE), "foraging_window")
  testthat::expect_identical(goal004_classify_no_bite(positive_intake = FALSE, eligible = TRUE), "nonpositive_limit")
  testthat::expect_identical(
    goal004_classify_no_bite(
      positive_intake = FALSE, eligible = TRUE, limits = limits,
      behaviour_pre = "MOVING", behaviour_post = "MOVING",
      selected_pre = 1L, selected_post = 1L
    ),
    "movement_or_targeting"
  )
})

testthat::test_that("BCI and endpoint probes execute matched production branches", {
  ctx <- goal004_test_context()
  reset <- goal003_reset_day(ctx$initial$plants_state, ctx$initial$herbivore_state)
  bci <- goal004_bci_probe(reset$herbivore, reset$plants, ctx$conditions, 6L, 102002L, 720L)
  testthat::expect_identical(bci$excluded_path, "herbivore.body_condition_feedback_enabled")
  testthat::expect_s3_class(bci$enabled$daily, "data.frame")
  testthat::expect_s3_class(bci$disabled$daily, "data.frame")
  testthat::expect_identical(names(bci$enabled$daily), goal004_daily_fields())
  testthat::expect_identical(names(bci$disabled$daily), goal004_daily_fields())
  testthat::expect_true(is.logical(bci$adjusted_projection_identical) && length(bci$adjusted_projection_identical) == 1L)
  testthat::expect_true(is.logical(bci$exit_rng_identical) && length(bci$exit_rng_identical) == 1L)
  day <- goal004_run_day(reset$herbivore, reset$plants, ctx$conditions, 6L, 102002L, 720L,
    FALSE, "internal_ttr", 1,
    observer = TRUE
  )
  testthat::expect_identical(
    goal004_projection(day$herbivore, day$plants, NULL, day$exit_rng),
    goal004_projection(
      bci$enabled$herbivore, bci$enabled$plants, NULL,
      bci$enabled$exit_rng
    )
  )
  endpoint <- goal004_endpoint_probe(day$endpoint_719, ctx$conditions, 6L, 102002L)
  testthat::expect_identical(endpoint$control$after_tick_count, 1L)
  testthat::expect_identical(endpoint$intervention$after_tick_count, 1L)
  testthat::expect_true(is.logical(endpoint$equal_through_719) && endpoint$equal_through_719)
  testthat::expect_identical(
    endpoint$control$entry,
    endpoint$intervention$entry
  )
  testthat::expect_true(is.null(endpoint$first_divergence) ||
    is.list(endpoint$first_divergence))
  testthat::expect_true(is.character(endpoint$consequence) && nzchar(endpoint$consequence))
})

testthat::test_that("comparator, output, manifest, and classification checks fail closed", {
  goal004_test_source()
  ctx <- goal004_test_context()
  profile <- goal004_validate_profile(goal004_read_profile(
    file.path(ctx$root, "inst", "extdata", "scenarios", "goal004_energy_decomposition_v1.yaml")
  ))
  bad <- profile
  bad$comparator$tree_sha256 <- strrep("0", 64)
  testthat::expect_error(goal004_validate_comparator(bad, ctx$root), class = "herbivoreTTR_goal004_comparator_stop")
  existing <- file.path(ctx$root, ".superpowers", "sdd", "goal004-agents", "executor-repair", "existing")
  dir.create(existing, recursive = TRUE, showWarnings = FALSE)
  testthat::expect_error(
    goal004_run(file.path(
      ctx$root, "inst", "extdata", "scenarios",
      "goal004_energy_decomposition_v1.yaml"
    ), existing),
    class = "herbivoreTTR_goal004_output_exists"
  )
  rows <- data.frame(
    probe_id = "x", classification = "nonoperative_here",
    invariants_pass = TRUE, production_projection_identical = TRUE,
    exit_rng_identical = TRUE, status = "complete",
    stringsAsFactors = FALSE
  )
  decision <- goal004_clock_decision()
  classification <- goal004_classification_summary(
    rows,
    evidence_ids = list("x" = c("G004-x")), decision = decision
  )
  testthat::expect_true(is.list(classification$mechanisms[[1L]]$evidence_ids))
  testthat::expect_length(classification$mechanisms[[1L]]$evidence_ids, 1L)
  testthat::expect_true(classification$barry_decision_required)
  testthat::expect_null(classification$recommended_next_goal)
  testthat::expect_length(classification$comparable_alternatives, 2L)
  testthat::expect_true(all(vapply(
    classification$comparable_alternatives,
    function(alternative) {
      identical(
        alternative$evidence_ids,
        list("G004-tick_phase", "G004-completed_clock", "G004-capacity_pathway")
      )
    },
    logical(1)
  )))
  testthat::expect_true(goal004_manifest_pass(list(
    all_probe_invariants_passed = TRUE,
    observer_projection_identical = TRUE,
    observer_exit_rng_identical = TRUE,
    stable_filenames = TRUE
  )))
  testthat::expect_false(goal004_manifest_pass(list(
    all_probe_invariants_passed = FALSE,
    observer_projection_identical = TRUE,
    observer_exit_rng_identical = TRUE,
    stable_filenames = TRUE
  )))
})

testthat::test_that("bounded integration emits a complete evidence bundle from observed checkpoints", {
  goal004_test_source()
  root <- repo_root_for_tests()
  output <- tempfile("goal004-bounded-integration-")
  set.seed(1902L)
  caller_rng <- .Random.seed
  manifest <- goal004_run(
    file.path(root, "inst", "extdata", "scenarios", "goal004_energy_decomposition_v1.yaml"),
    output,
    days = 1L
  )
  testthat::expect_identical(manifest$status, "complete")
  testthat::expect_identical(manifest$days, 1L)
  testthat::expect_identical(manifest$baseline_replays, 2L)
  testthat::expect_identical(manifest$diagnostic_rng_seed, 2002L)
  testthat::expect_match(manifest$diagnostic_rng_sha256, "^[0-9a-f]{64}$")
  testthat::expect_identical(.Random.seed, caller_rng)
  testthat::expect_identical(manifest$bare_control_event_records, 0L)
  testthat::expect_gt(manifest$observer_event_records, 0L)
  testthat::expect_true(isTRUE(manifest$observer_projection_identical))
  testthat::expect_true(isTRUE(manifest$observer_exit_rng_identical))
  testthat::expect_null(manifest$first_baseline_state_divergence)
  testthat::expect_null(manifest$first_baseline_rng_divergence)
  expected <- goal004_validate_profile(goal004_read_profile(
    file.path(root, "inst", "extdata", "scenarios", "goal004_energy_decomposition_v1.yaml")
  ))$outputs$artefact_names
  testthat::expect_setequal(list.files(output), expected)
  classification <- jsonlite::read_json(
    file.path(output, "classification_summary.json"),
    simplifyVector = FALSE
  )
  testthat::expect_true(classification$barry_decision_required)
  testthat::expect_null(classification$recommended_next_goal)
  testthat::expect_length(classification$comparable_alternatives, 2L)
  demand <- classification$mechanisms[vapply(
    classification$mechanisms,
    function(mechanism) identical(mechanism$mechanism, "demand_zero_locomotion"),
    logical(1)
  )]
  testthat::expect_length(demand, 1L)
  testthat::expect_identical(
    demand[[1L]]$classification, "implementation_or_contract_defect"
  )
  testthat::expect_match(demand[[1L]]$note, "no implementation defect demonstrated")
  projection <- utils::read.csv(file.path(output, "baseline_projection.csv"),
    stringsAsFactors = FALSE, check.names = FALSE
  )
  testthat::expect_setequal(unique(projection$branch), c("bare_control", "observer"))
  testthat::expect_identical(
    unique(projection$trajectory_id[projection$branch == "bare_control"]),
    "bare_control_replay"
  )
  testthat::expect_identical(
    unique(projection$trajectory_id[projection$branch == "observer"]),
    "observer_replay"
  )
  testthat::expect_true(all(c(
    "observer_projection_identical",
    "observer_rng_identical"
  ) %in% names(projection)))
  testthat::expect_true(all(projection$observer_projection_identical))
  testthat::expect_true(all(projection$observer_rng_identical))
  snapshots <- readRDS(file.path(output, "probe_state_snapshots.rds"))
  demand_snapshots <- snapshots$records[vapply(
    snapshots$records,
    function(record) {
      identical(record$probe_id, "demand_zero_locomotion") &&
        identical(record$checkpoint, "algebraic_entry")
    },
    logical(1)
  )]
  testthat::expect_length(demand_snapshots, 1L)
  testthat::expect_true(all(vapply(demand_snapshots, function(record) {
    is.null(record$control$daily_output) &&
      is.null(record$intervention$daily_output)
  }, logical(1))))
  bci_exit_snapshots <- snapshots$records[vapply(
    snapshots$records,
    function(record) {
      identical(record$probe_id, "bci_feedback_operability") &&
        identical(record$checkpoint, "adjusted_exit")
    },
    logical(1)
  )]
  testthat::expect_true(length(bci_exit_snapshots) %in% c(0L, 1L))
  if (length(bci_exit_snapshots)) {
    testthat::expect_true(all(vapply(bci_exit_snapshots, function(record) {
      is.data.frame(record$control$daily_output) &&
        nrow(record$control$daily_output) == 1L &&
        is.data.frame(record$intervention$daily_output) &&
        nrow(record$intervention$daily_output) == 1L
    }, logical(1))))
  }
  limits <- utils::read.csv(file.path(output, "minute_intake_limits.csv"),
    stringsAsFactors = FALSE, check.names = FALSE
  )
  testthat::expect_true(all(c(
    "baseline", "completed_clock", "capacity_unticked",
    "capacity_completed_clock"
  ) %in% unique(limits$branch)))
  queue <- utils::read.csv(file.path(output, "hourly_queue_ledger.csv"),
    check.names = FALSE
  )
  budget <- utils::read.csv(file.path(output, "daily_energy_budget.csv"),
    check.names = FALSE
  )
  baseline_daily <- utils::read.csv(
    file.path(output, "baseline_daily_diagnostics.csv"),
    check.names = FALSE
  )
  testthat::expect_true(
    goal004_ledger_checks(queue, limits, budget, baseline_daily)$passed
  )
  if ("completed_clock" %in% limits$branch) {
    bad_completed_limits <- limits
    completed_row <- which(bad_completed_limits$branch == "completed_clock")[[1L]]
    bad_completed_limits$insert_bleaf_g[[completed_row]] <-
      bad_completed_limits$insert_bleaf_g[[completed_row]] + 1
    testthat::expect_false(
      goal004_ledger_checks(
        queue, bad_completed_limits, budget, baseline_daily
      )$passed
    )
  }
  eligible_no_bite <- limits$branch == "baseline" & limits$eligible &
    !limits$positive_intake
  positive_raw_limit <- pmin(
    limits$handling_limit_kg, limits$capacity_limit_kg,
    limits$forage_limit_kg, limits$mechanical_limit_kg
  ) > 0
  testthat::expect_false(any(
    eligible_no_bite & positive_raw_limit &
      limits$no_bite_reason == "nonpositive_limit"
  ))

  release <- aggregate(
    queue$terminal_release_raw,
    by = list(
      branch = queue$branch, Day = queue$Day,
      queue_name = queue$queue_name
    ),
    FUN = sum
  )
  names(release)[[4L]] <- "release_g"
  wide <- reshape(release,
    idvar = c("branch", "Day"),
    timevar = "queue_name", direction = "wide"
  )
  idx <- match(
    paste(budget$branch, budget$Day),
    paste(wide$branch, wide$Day)
  )
  independent_protein <- (
    wide$release_g.dp_leaf + wide$release_g.dp_stem + wide$release_g.dp_def
  )[idx]
  testthat::expect_true(
    goal004_values_close(budget$released_protein_g, independent_protein)
  )

  biomass <- queue$queue_name %in% c("bleaf", "bstem", "bdef")
  inserted <- vapply(seq_len(nrow(budget)), function(row) {
    sum(queue$bite_insertion_slot[
      queue$branch == budget$branch[[row]] &
        queue$Day == budget$Day[[row]] & biomass
    ])
  }, numeric(1))
  testthat::expect_true(goal004_values_close(budget$intake_total_g, inserted))
  testthat::expect_true(
    goal004_values_close(budget$ledger_intake_total_g, inserted)
  )
  bad_budget <- budget
  bad_budget$intake_total_g[[1L]] <- bad_budget$intake_total_g[[1L]] + 1
  testthat::expect_false(
    goal004_ledger_checks(queue, limits, bad_budget, baseline_daily)$passed
  )
  bad_daily <- baseline_daily
  bad_daily$intake_total_g[[1L]] <- bad_daily$intake_total_g[[1L]] + 1
  testthat::expect_false(
    goal004_ledger_checks(queue, limits, budget, bad_daily)$passed
  )

  repeat_output <- tempfile("goal004-bounded-repeat-")
  set.seed(991L)
  repeat_caller_rng <- .Random.seed
  repeat_manifest <- goal004_run(
    file.path(
      root, "inst", "extdata", "scenarios",
      "goal004_energy_decomposition_v1.yaml"
    ),
    repeat_output,
    days = 1L
  )
  testthat::expect_identical(.Random.seed, repeat_caller_rng)
  testthat::expect_identical(
    manifest$diagnostic_rng_sha256,
    repeat_manifest$diagnostic_rng_sha256
  )
  repeatability_files <- c(
    "hourly_queue_ledger.csv", "minute_intake_limits.csv",
    "probe_invariants.csv", "probe_state_snapshots.rds"
  )
  testthat::expect_true(all(vapply(repeatability_files, function(name) {
    identical(
      readBin(file.path(output, name), "raw", n = file.info(file.path(output, name))$size),
      readBin(file.path(repeat_output, name), "raw",
        n = file.info(file.path(repeat_output, name))$size
      )
    )
  }, logical(1))))

  queue$pre_tick_slot[[1L]] <- queue$pre_tick_slot[[1L]] + 1
  testthat::expect_false(
    goal004_ledger_checks(queue, limits, budget, baseline_daily)$passed
  )
})
