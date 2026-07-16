#!/usr/bin/env Rscript

goal004_runner_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  f <- grep("^--file=", args, value = TRUE)
  if (length(f)) {
    path <- sub("^--file=", "", f[[1L]])
    candidate <- normalizePath(dirname(path), winslash = "/", mustWork = TRUE)
    while (!dir.exists(file.path(candidate, "R")) && !identical(candidate, dirname(candidate))) candidate <- dirname(candidate)
    candidate
  } else {
    candidate <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
    while (!file.exists(file.path(candidate, "scripts", "goal004_energy_ledger_helpers.R")) &&
      !identical(candidate, dirname(candidate))) {
      candidate <- dirname(candidate)
    }
    candidate
  }
}

goal004_root <- goal004_runner_root()
sys.source(file.path(goal004_root, "scripts", "goal004_energy_ledger_helpers.R"), envir = .GlobalEnv)

# Goal 003 contains reusable read-only profile, state, output, and summary helpers.
# Evaluate its definitions without evaluating its command-line entry point.
goal003_script <- parse(file.path(goal004_root, "scripts", "run_goal003_herbivore_reference.R"))
eval(goal003_script[seq_len(length(goal003_script) - 1L)], envir = .GlobalEnv)

goal004_validate_comparator <- function(profile, repo_root) {
  cmp <- profile$comparator
  if (!identical(goal003_git_sha(repo_root), cmp$commit)) goal004_abort("Goal 003 comparator commit is not HEAD.", "herbivoreTTR_goal004_comparator_stop")
  goal3_paths <- c(
    "docs/goals/003-herbivore-only-daily-clamped-forage-reference/Goal.md",
    "docs/goals/003-herbivore-only-daily-clamped-forage-reference/Log.md",
    "docs/goals/003-herbivore-only-daily-clamped-forage-reference/Plan.md",
    "docs/goals/003-herbivore-only-daily-clamped-forage-reference/Runbook.md",
    "docs/log/20260714_goal003_herbivore_reference.md",
    "inst/extdata/scenarios/goal003_herbivore_reference_v1.yaml",
    "scripts/run_goal003_herbivore_reference.R",
    "tests/testthat/test_goal003_herbivore_reference.R"
  )
  tree_digest <- function(committed) {
    commands <- vapply(goal3_paths, function(path) {
      payload <- if (isTRUE(committed)) {
        sprintf("git -C %s show %s:%s", shQuote(repo_root), shQuote(cmp$commit), shQuote(path))
      } else {
        sprintf("cat %s", shQuote(file.path(repo_root, path)))
      }
      sprintf("printf '%%s=' %s; %s | shasum -a 256 | cut -d ' ' -f 1", shQuote(path), payload)
    }, character(1), USE.NAMES = FALSE)
    output <- system(sprintf(
      "(%s) | shasum -a 256 | cut -d ' ' -f 1",
      paste(commands, collapse = "; ")
    ), intern = TRUE)
    if (length(output) != 1L) {
      goal004_abort(
        "Could not compute the Goal 003 comparator tree.",
        "herbivoreTTR_goal004_comparator_stop"
      )
    }
    trimws(output[[1L]])
  }
  committed_tree <- tree_digest(TRUE)
  worktree_tree <- tree_digest(FALSE)
  # The tree digest is bound to committed content; compare each source hash and
  # the exact accepted digest before any diagnostic simulation is allowed.
  expected_sources <- c(cmp$profile_sha256, cmp$runner_sha256, cmp$test_sha256)
  actual_sources <- c(
    goal004_file_sha256(file.path(repo_root, "inst/extdata/scenarios/goal003_herbivore_reference_v1.yaml")),
    goal004_file_sha256(file.path(repo_root, "scripts/run_goal003_herbivore_reference.R")),
    goal004_file_sha256(file.path(repo_root, "tests/testthat/test_goal003_herbivore_reference.R"))
  )
  if (!identical(actual_sources, expected_sources)) goal004_abort("Goal 003 source hash differs from the accepted comparator.", "herbivoreTTR_goal004_comparator_stop")
  if (!identical(committed_tree, cmp$tree_sha256) || !identical(worktree_tree, cmp$tree_sha256)) {
    goal004_abort("Goal 003 path-qualified tree digest differs from the accepted comparator.", "herbivoreTTR_goal004_comparator_stop")
  }
  invisible(TRUE)
}

goal004_source_digest <- function(repo_root) {
  paths <- c(
    "inst/extdata/scenarios/goal004_energy_decomposition_v1.yaml",
    "scripts/goal004_energy_ledger_helpers.R", "scripts/run_goal004_energy_decomposition.R",
    "tests/testthat/test_goal004_energy_decomposition.R"
  )
  digest::digest(paste(vapply(paths, function(path) paste0(path, "=", goal004_file_sha256(file.path(repo_root, path))),
    character(1),
    USE.NAMES = FALSE
  ), collapse = "\n"), algo = "sha256", serialize = FALSE)
}

goal004_trajectory <- function(profile, goal3_profile, initial, conditions, observer) {
  h <- initial$herbivore_state
  frozen <- initial$plants_state
  daily_rows <- vector("list", profile$runtime$days)
  plant_rows <- vector("list", profile$runtime$days)
  phase_rows <- list()
  queue_rows <- list()
  limit_rows <- list()
  exits <- vector("list", profile$runtime$days)
  checkpoints <- vector("list", profile$runtime$days)
  event_count <- 0L
  prior_closing <- NULL
  for (i in seq_len(profile$runtime$days)) {
    model_day <- profile$runtime$start_day + i - 1L
    day_seed <- profile$runtime$seed + i * 100000L
    opening_h <- h
    reset <- goal003_reset_day(frozen, h, prior_closing)
    if (!isTRUE(reset$opening_from_frozen_snapshot) || !identical(reset$opening_state_sha256, reset$frozen_state_sha256)) {
      goal004_abort(sprintf("Day %d did not open from the frozen plant snapshot.", i), "herbivoreTTR_goal004_scientific_stop")
    }
    result <- goal004_run_day(
      reset$herbivore, reset$plants, conditions, model_day, day_seed,
      profile$runtime$minute_limit, profile$runtime$apply_growth,
      profile$runtime$plant_backend, profile$runtime$forage_access_scale, observer
    )
    h <- result$herbivore
    daily <- goal003_daily_row(i, model_day, day_seed, goal003_resolved_forcing(goal3_profile), opening_h, h)
    result$diagnostics$daily_record <- result$daily_record
    plant <- goal003_plant_row(i, model_day, reset$plants, result$plants, daily, result$diagnostics, reset, goal3_profile)
    if (!isTRUE(plant$closing_ms > plant$min_shoot_kg && plant$closing_ms > plant$m_ref_kg) ||
      !isTRUE(plant$closing_ms - plant$min_shoot_kg > daily$gut_capacity_g / 1000) ||
      !isTRUE(plant$closing_qshoot > 0 && plant$non_consumed_fields_identical)) {
      goal004_abort(sprintf("Goal 003 non-binding state failed on day %d.", i), "herbivoreTTR_goal004_scientific_stop")
    }
    daily_rows[[i]] <- daily
    plant_rows[[i]] <- plant
    exits[[i]] <- result$exit_rng
    closed_capture <- goal004_observer_checkpoint(
      i, profile$runtime$minute_limit, "daily_closed", result$herbivore,
      result$plants, daily,
      events = result$events,
      event = if (isTRUE(observer)) {
        list(
          day = i, minute = profile$runtime$minute_limit,
          type = "daily_closed"
        )
      } else {
        NULL
      },
      branch = if (isTRUE(observer)) "observer" else "bare_control",
      trajectory_id = if (isTRUE(observer)) "observer_replay" else "bare_control_replay",
      rng = result$exit_rng
    )
    result$events <- closed_capture$events
    event_count <- event_count + length(result$events)
    result$phase_rows[[length(result$phase_rows) + 1L]] <- closed_capture$rows
    phase_rows[[length(phase_rows) + 1L]] <- do.call(rbind, result$phase_rows)
    queue_rows[[length(queue_rows) + 1L]] <- do.call(rbind, result$queue_rows)
    limit_rows[[length(limit_rows) + 1L]] <- do.call(rbind, result$limit_rows)
    checkpoints[[i]] <- list(
      day = i, model_day = model_day, seed = day_seed,
      herbivore = result$checkpoint_herbivore, plants = result$checkpoint_plants,
      start_herbivore = result$diagnostics$herbivore_start,
      opening_herbivore = opening_h, opening_plants = reset$plants,
      closed_herbivore = h, closed_plants = result$plants,
      daily = daily, plant = plant, endpoint_719 = result$endpoint_719,
      daily_record = result$daily_record, exit_rng = result$exit_rng
    )
    prior_closing <- result$plants
  }
  daily <- do.call(rbind, daily_rows)
  plants_daily <- do.call(rbind, plant_rows)
  rownames(daily) <- NULL
  rownames(plants_daily) <- NULL
  daily$energy_cumulative_residual_kJ <- daily$cumulative_energy_balance_kJ - cumsum(daily$energy_delta_kJ)
  daily$water_cumulative_residual_g <- daily$cumulative_water_balance_g - cumsum(daily$daily_net_water_g)
  list(
    daily = daily, plants = plants_daily, phases = do.call(rbind, phase_rows),
    queues = do.call(rbind, queue_rows), limits = do.call(rbind, limit_rows),
    checkpoints = checkpoints, exits = exits, initial = initial,
    event_count = as.integer(event_count)
  )
}

goal004_completed_trace <- function(checkpoint, extra_ticks = 12L) {
  h <- goal004_clone(checkpoint$herbivore)
  rows <- list()
  qn <- goal004_queue_names()
  opening <- goal004_clone(h)
  opening_plants <- goal004_clone(checkpoint$plants)
  opening_rng <- goal004_rng()
  for (j in seq_len(extra_ticks)) {
    before <- goal004_clone(h)
    rng_pre <- goal004_rng()
    h <- hourly_digestion_step(h)
    rng_post <- goal004_rng()
    for (nm in qn) {
      pre <- before$digestion[[nm]]
      post <- h$digestion[[nm]]
      release <- rep(0, length(pre))
      release[length(pre)] <- pre[length(pre)]
      rows[[length(rows) + 1L]] <- data.frame(
        branch = "completed_clock", Day = checkpoint$day, model_day = checkpoint$model_day,
        tick_index_day = 12L + j, elapsed_minute = (12L + j) * 60L, queue_name = nm,
        slot = seq_along(pre), opening_slot = pre, bite_insertion_slot = rep(0, length(pre)),
        pre_tick_slot = pre, normalization_adjustment_slot = rep(0, length(pre)),
        resizing_adjustment_slot = rep(0, length(pre)), terminal_release_raw = release,
        post_tick_slot = post, rng_pre_sha256 = goal004_sha256(rng_pre),
        rng_post_sha256 = goal004_sha256(rng_post), stringsAsFactors = FALSE, check.names = FALSE
      )
    }
  }
  closing_plants <- goal004_clone(checkpoint$plants)
  list(
    herbivore = h, plants = closing_plants, queues = do.call(rbind, rows),
    tick_count = as.integer(extra_ticks),
    invariants = list(
      plant = identical(opening_plants, closing_plants),
      intake = identical(opening$intake_total_day, h$intake_total_day),
      movement = identical(opening$distance_moved, h$distance_moved),
      drinking = identical(opening$intake_water_drinking, h$intake_water_drinking),
      requirement = identical(opening$total_energy_requirement_day, h$total_energy_requirement_day),
      rng = identical(opening_rng, goal004_rng())
    )
  )
}

goal004_tick_phase_probe <- function(herbivore) {
  qn <- goal004_queue_names()
  make_state <- function(slot) {
    h <- goal004_clone(herbivore)
    h$MRT <- resolve_mrt_hours(h$MRT)
    h$digestion <- stats::setNames(lapply(qn, function(nm) numeric(h$MRT)), qn)
    h$digestion$dc_leaf[slot] <- 1
    h$digestion$bleaf[slot] <- 1
    update_gut_content(h)
  }
  tick <- function(h) {
    before <- goal004_clone(h)
    after <- hourly_digestion_step(h)
    list(
      state = after,
      released_mass_g = before$digestion$dc_leaf[length(before$digestion$dc_leaf)],
      opening_queue_mass_g = sum(unlist(before$digestion[qn], use.names = FALSE)),
      queue_mass_g = sum(after$digestion$bleaf),
      queue_lengths = vapply(after$digestion[qn], length, integer(1))
    )
  }
  a <- tick(make_state(1L))
  b <- tick(make_state(herbivore$MRT))
  list(
    after_boundary = a, before_boundary = b,
    tick_count = c(after_boundary = 1L, before_boundary = 1L)
  )
}

goal004_daily_budget <- function(branch, checkpoint, h, q) {
  qd <- q[q$branch == branch & q$Day == checkpoint$day, , drop = FALSE]
  rel <- stats::setNames(tapply(qd$terminal_release_raw, qd$queue_name, sum), unique(qd$queue_name))
  for (nm in goal004_queue_names()) if (is.null(rel[[nm]])) rel[[nm]] <- 0
  biomass <- qd$queue_name %in% c("bleaf", "bstem", "bdef")
  opening <- sum(qd$opening_slot[biomass & qd$tick_index_day == min(qd$tick_index_day)])
  inserted <- sum(qd$bite_insertion_slot[biomass])
  released <- sum(qd$terminal_release_raw[biomass])
  closing <- sum(qd$post_tick_slot[biomass & qd$tick_index_day == max(qd$tick_index_day)])
  released_carb <- rel[["dc_leaf"]] + rel[["dc_stem"]]
  released_protein <- rel[["dp_leaf"]] + rel[["dp_stem"]] + rel[["dp_def"]]
  released_energy <- goal004_energy_from_terminal(rel)
  recorded_energy <- h$intake_PE_day + h$intake_NPE_day
  locomotion <- h$total_energy_requirement_day - h$maintenance_energy_requirement_day
  data.frame(
    branch = branch, Day = checkpoint$day, ticks = max(qd$tick_index_day),
    intake_total_g = checkpoint$daily$intake_total_g, released_carb_g = released_carb,
    released_protein_g = released_protein, intake_PE_kJ = h$intake_PE_day,
    intake_NPE_kJ = h$intake_NPE_day, maintenance_kJ = h$maintenance_energy_requirement_day,
    locomotion_kJ = locomotion, total_requirement_kJ = h$total_energy_requirement_day,
    energy_delta_kJ = h$daily_energy_delta, gut_opening_g = checkpoint$opening_herbivore$gut_content,
    gut_preclosure_g = checkpoint$herbivore$gut_content, gut_closing_g = h$gut_content,
    released_energy_recorded_kJ = recorded_energy, released_energy_reconstructed_kJ = released_energy,
    energy_release_residual_kJ = recorded_energy - released_energy,
    energy_release_tolerance_kJ = goal004_scale_tolerance(c(recorded_energy, released_energy)),
    queue_mass_opening_g = opening, queue_mass_inserted_g = inserted,
    queue_mass_released_g = released, queue_mass_closing_g = closing,
    queue_mass_residual_g = opening + inserted - released - closing,
    queue_mass_tolerance_g = goal004_scale_tolerance(c(opening, inserted, released, closing)),
    requested_foraging_h = checkpoint$opening_herbivore$time_spent_foraging,
    realised_foraging_h = h$time_spent_foraging, BodyConditionIndex = h$body_condition_index,
    exit_rng_sha256 = goal004_sha256(checkpoint$exit_rng), stringsAsFactors = FALSE, check.names = FALSE
  )
}

goal004_reconstruct_daily_budget <- function(q, daily_budget) {
  release <- aggregate(
    q$terminal_release_raw,
    by = list(branch = q$branch, Day = q$Day, queue_name = q$queue_name),
    FUN = sum
  )
  names(release)[[4L]] <- "release_g"
  wide <- reshape(release,
    idvar = c("branch", "Day"),
    timevar = "queue_name", direction = "wide"
  )
  for (nm in paste0("release_g.", goal004_queue_names())) {
    if (!nm %in% names(wide)) wide[[nm]] <- 0
  }
  idx <- match(
    paste(daily_budget$branch, daily_budget$Day),
    paste(wide$branch, wide$Day)
  )
  if (anyNA(idx)) {
    goal004_abort(
      "A daily budget row has no queue-ledger release evidence.",
      "herbivoreTTR_goal004_ledger_stop"
    )
  }
  carb <- (wide$release_g.dc_leaf + wide$release_g.dc_stem)[idx]
  protein <- (
    wide$release_g.dp_leaf + wide$release_g.dp_stem + wide$release_g.dp_def
  )[idx]
  energy <- 16.7 * carb + 23.0 * protein
  daily_budget$ledger_released_carb_g <- carb
  daily_budget$ledger_released_protein_g <- protein
  daily_budget$ledger_released_energy_kJ <- energy
  daily_budget$ledger_energy_release_residual_kJ <-
    daily_budget$released_energy_recorded_kJ - energy
  daily_budget$ledger_energy_release_tolerance_kJ <- 64 * .Machine$double.eps *
    pmax(1, abs(daily_budget$released_energy_recorded_kJ) + abs(energy))

  ledger_fields <- c(
    "ledger_intake_total_g", "ledger_queue_mass_opening_g",
    "ledger_queue_mass_inserted_g", "ledger_queue_mass_released_g",
    "ledger_queue_mass_closing_g", "ledger_queue_mass_residual_g",
    "ledger_queue_mass_tolerance_g"
  )
  for (nm in ledger_fields) daily_budget[[nm]] <- NA_real_

  biomass <- q$queue_name %in% c("bleaf", "bstem", "bdef")
  for (row in seq_len(nrow(daily_budget))) {
    x <- q[
      q$branch == daily_budget$branch[[row]] &
        q$Day == daily_budget$Day[[row]] & biomass, ,
      drop = FALSE
    ]
    if (!nrow(x)) {
      goal004_abort(
        "A daily budget row has no biomass queue evidence.",
        "herbivoreTTR_goal004_ledger_stop"
      )
    }
    first_tick <- min(x$tick_index_day)
    last_tick <- max(x$tick_index_day)
    opening <- sum(x$opening_slot[x$tick_index_day == first_tick])
    inserted <- sum(x$bite_insertion_slot)
    released <- sum(x$terminal_release_raw)
    closing <- sum(x$post_tick_slot[x$tick_index_day == last_tick])
    daily_budget$ledger_intake_total_g[[row]] <- inserted
    daily_budget$ledger_queue_mass_opening_g[[row]] <- opening
    daily_budget$ledger_queue_mass_inserted_g[[row]] <- inserted
    daily_budget$ledger_queue_mass_released_g[[row]] <- released
    daily_budget$ledger_queue_mass_closing_g[[row]] <- closing
    daily_budget$ledger_queue_mass_residual_g[[row]] <-
      opening + inserted - released - closing
    daily_budget$ledger_queue_mass_tolerance_g[[row]] <- 64 * .Machine$double.eps *
      max(1, abs(opening) + abs(inserted) + abs(released) + abs(closing))
  }
  daily_budget
}

goal004_ledger_checks <- function(q, limits, daily_budget, baseline_daily) {
  queue_names <- goal004_queue_names()
  transition_groups <- split(
    seq_len(nrow(q)),
    interaction(q$branch, q$Day, q$tick_index_day, q$queue_name,
      drop = TRUE, lex.order = TRUE
    )
  )
  transition_ok <- all(vapply(transition_groups, function(idx) {
    x <- q[idx, , drop = FALSE]
    x <- x[order(x$slot), , drop = FALSE]
    expected_pre <- x$opening_slot + x$bite_insertion_slot +
      x$normalization_adjustment_slot + x$resizing_adjustment_slot
    expected_release <- ifelse(x$slot == length(x$slot), expected_pre, 0)
    expected_post <- c(0, expected_pre[seq_len(length(expected_pre) - 1L)])
    identical(x$slot, seq_len(nrow(x))) && nrow(x) == 24L &&
      isTRUE(all.equal(x$pre_tick_slot, expected_pre, tolerance = 0)) &&
      isTRUE(all.equal(x$terminal_release_raw, expected_release, tolerance = 0)) &&
      isTRUE(all.equal(x$post_tick_slot, expected_post, tolerance = 0))
  }, logical(1)))
  insertion_columns <- stats::setNames(paste0("insert_", queue_names, "_g"), queue_names)
  actual_insertions <- aggregate(
    q$bite_insertion_slot,
    by = list(
      branch = q$branch, Day = q$Day,
      tick_index_day = q$tick_index_day, queue_name = q$queue_name
    ),
    FUN = sum
  )
  names(actual_insertions)[[5L]] <- "insertion_g"
  source_limits <- limits[limits$branch %in% unique(q$branch), , drop = FALSE]
  expected_sums <- do.call(rbind, lapply(queue_names, function(nm) {
    out <- aggregate(
      source_limits[[insertion_columns[[nm]]]],
      by = list(
        branch = source_limits$branch, Day = source_limits$Day,
        tick_index_day = source_limits$tick_index_day
      ),
      FUN = sum
    )
    names(out)[[4L]] <- "insertion_g"
    out$queue_name <- nm
    out[c("branch", "Day", "tick_index_day", "queue_name", "insertion_g")]
  }))
  insertion_order <- function(x) {
    order(
      x$branch, x$Day, x$tick_index_day, match(x$queue_name, queue_names)
    )
  }
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
  insertion_ok <- !anyDuplicated(actual_key) && !anyDuplicated(expected_key) &&
    all(expected_key %in% actual_key) &&
    goal004_values_close(
      actual_insertions$insertion_g,
      expected_insertions$insertion_g
    )
  reconstructed <- goal004_reconstruct_daily_budget(q, daily_budget)
  field_pairs <- list(
    c("intake_total_g", "ledger_intake_total_g"),
    c("released_carb_g", "ledger_released_carb_g"),
    c("released_protein_g", "ledger_released_protein_g"),
    c("released_energy_reconstructed_kJ", "ledger_released_energy_kJ"),
    c("energy_release_residual_kJ", "ledger_energy_release_residual_kJ"),
    c("energy_release_tolerance_kJ", "ledger_energy_release_tolerance_kJ"),
    c("queue_mass_opening_g", "ledger_queue_mass_opening_g"),
    c("queue_mass_inserted_g", "ledger_queue_mass_inserted_g"),
    c("queue_mass_released_g", "ledger_queue_mass_released_g"),
    c("queue_mass_closing_g", "ledger_queue_mass_closing_g"),
    c("queue_mass_residual_g", "ledger_queue_mass_residual_g"),
    c("queue_mass_tolerance_g", "ledger_queue_mass_tolerance_g")
  )
  summary_ok <- all(vapply(field_pairs, function(pair) {
    goal004_values_close(
      reconstructed[[pair[[1L]]]],
      reconstructed[[pair[[2L]]]]
    )
  }, logical(1))) &&
    all(daily_budget$ticks[daily_budget$branch == "baseline"] == 12L) &&
    all(daily_budget$ticks[daily_budget$branch == "completed_clock"] == 24L)
  residual_ok <- all(abs(reconstructed$ledger_energy_release_residual_kJ) <=
    reconstructed$ledger_energy_release_tolerance_kJ) &&
    all(abs(reconstructed$ledger_queue_mass_residual_g) <=
      reconstructed$ledger_queue_mass_tolerance_g)
  baseline_budget <- reconstructed[
    reconstructed$branch == "baseline", ,
    drop = FALSE
  ]
  baseline_budget <- baseline_budget[order(baseline_budget$Day), , drop = FALSE]
  baseline_daily <- baseline_daily[order(baseline_daily$Day), , drop = FALSE]
  baseline_link_ok <- identical(
    as.integer(baseline_budget$Day),
    as.integer(baseline_daily$Day)
  ) &&
    goal004_values_close(
      baseline_budget$intake_total_g,
      baseline_daily$intake_total_g
    ) &&
    goal004_values_close(
      baseline_budget$ledger_intake_total_g,
      baseline_daily$intake_total_g
    )
  finite_ok <- all(is.finite(unlist(q[c(
    "opening_slot", "bite_insertion_slot", "pre_tick_slot",
    "terminal_release_raw", "post_tick_slot"
  )], use.names = FALSE)))
  list(
    passed = transition_ok && insertion_ok && residual_ok && summary_ok &&
      baseline_link_ok && finite_ok,
    transition_ok = transition_ok, insertion_ok = insertion_ok,
    residual_ok = residual_ok, summary_ok = summary_ok,
    baseline_link_ok = baseline_link_ok, finite_ok = finite_ok
  )
}

goal004_snapshot <- function(probe_id, day, checkpoint, control, intervention) {
  list(
    probe_id = as.character(probe_id), Day = as.integer(day), checkpoint = as.character(checkpoint),
    control = control, intervention = intervention
  )
}

goal004_invariant <- function(probe_id, branch, day, checkpoint, name, path, expected, observed, relation = "identical") {
  expected_text <- if (is.character(expected) && length(expected) == 1L) expected else goal004_json(expected)
  observed_text <- if (is.character(observed) && length(observed) == 1L) observed else goal004_json(observed)
  data.frame(
    probe_id = probe_id, branch = branch, Day = as.integer(day), checkpoint = checkpoint,
    invariant_name = name, object_path = path, expected_value = expected_text,
    observed_value = observed_text, expected_sha256 = goal004_sha256(expected),
    observed_sha256 = goal004_sha256(observed), expected_relation = relation,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

goal004_compare_projection <- function(expected, observed, exclusions = character(), phase = NA_character_) {
  changed <- goal004_changed_paths(expected, observed)
  allowed <- if (length(exclusions)) {
    vapply(changed, goal004_path_allowed, logical(1), prefixes = exclusions)
  } else {
    logical(length(changed))
  }
  forbidden <- changed[!allowed]
  list(
    equal = !length(forbidden), changed_paths = changed, forbidden_paths = forbidden,
    first_divergence = if (length(forbidden)) goal004_first_divergence(expected, observed, phase) else NULL
  )
}

goal004_bci_probe <- function(herbivore, plants, conditions, day_of_simulation, day_seed,
                              minute_limit = 720L, backend = "internal_ttr") {
  condition_index <- ((day_of_simulation - 1L) %% nrow(conditions)) + 1L
  forcing <- list(
    temperature = conditions$temp_mean[[condition_index]],
    soil_water = conditions$sw[[condition_index]],
    soil_nitrogen = conditions$N[[condition_index]]
  )
  diagnostic_day <- day_of_simulation - 5L
  run_branch <- function(enabled) {
    h <- goal004_clone(herbivore)
    h$body_condition_feedback_enabled <- isTRUE(enabled)
    with_optional_seed(day_seed, {
      result <- run_daily_herbivore_simulation(
        herbivore = h, plants = goal004_clone(plants), conditions = conditions,
        day_of_simulation = day_of_simulation, minute_limit = minute_limit,
        capture_diagnostics = FALSE, seed = NULL, apply_growth = FALSE,
        plant_backend = backend, forage_access_scale = 1
      )
      result$exit_rng <- goal004_rng()
      result$daily <- goal003_daily_row(
        diagnostic_day, day_of_simulation, day_seed, forcing,
        herbivore, result$herbivore
      )
      result
    })
  }
  enabled_start <- goal004_clone(herbivore)
  enabled_start$body_condition_feedback_enabled <- TRUE
  disabled_start <- goal004_clone(herbivore)
  disabled_start$body_condition_feedback_enabled <- FALSE
  start_rng <- with_optional_seed(day_seed, goal004_rng())
  enabled <- run_branch(TRUE)
  disabled <- run_branch(FALSE)
  a <- goal004_projection(
    enabled$herbivore, enabled$plants, enabled$daily,
    enabled$exit_rng
  )
  b <- goal004_projection(
    disabled$herbivore, disabled$plants, disabled$daily,
    disabled$exit_rng
  )
  comparison <- goal004_compare_projection(
    a, b,
    "herbivore.body_condition_feedback_enabled",
    "bci_adjusted_exit"
  )
  list(
    enabled = enabled, disabled = disabled,
    enabled_start = goal004_projection(enabled_start, goal004_clone(plants), NULL, start_rng),
    disabled_start = goal004_projection(disabled_start, goal004_clone(plants), NULL, start_rng),
    adjusted_projection_identical = comparison$equal,
    exit_rng_identical = identical(enabled$exit_rng, disabled$exit_rng),
    excluded_path = "herbivore.body_condition_feedback_enabled",
    first_divergence = comparison$first_divergence,
    adjusted_exit_projection = comparison
  )
}

goal004_with_rng_state <- function(state, code) {
  had_rng <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_rng <- if (had_rng) get(".Random.seed", envir = .GlobalEnv, inherits = FALSE) else NULL
  on.exit(
    {
      if (had_rng) {
        assign(".Random.seed", old_rng, envir = .GlobalEnv)
      } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    },
    add = TRUE
  )
  if (is.null(state)) {
    if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  } else {
    assign(".Random.seed", as.integer(state), envir = .GlobalEnv)
  }
  code()
}

goal004_endpoint_probe <- function(endpoint, conditions, day_of_simulation, day_seed,
                                   backend = "internal_ttr") {
  if (is.null(endpoint$herbivore) || is.null(endpoint$plants) || !"rng" %in% names(endpoint)) {
    goal004_abort("Minute-719 endpoint clone is incomplete.", "herbivoreTTR_goal004_probe_stop")
  }
  run_branch <- function(intervene) {
    goal004_with_rng_state(endpoint$rng, function() {
      h <- goal004_clone(endpoint$herbivore)
      p <- goal004_clone(endpoint$plants)
      entry <- list(herbivore = goal004_clone(h), plants = goal004_clone(p), rng = goal004_rng())
      if (isTRUE(intervene)) {
        step <- herbivore_step(h, p)
        h <- step$herbivore
        p <- step$plants
      }
      before_tick <- goal004_clone(h)
      h <- hourly_digestion_step(h)
      list(
        entry = entry, herbivore = h, plants = p,
        released_mass_g = before_tick$digestion$bleaf[length(before_tick$digestion$bleaf)],
        exit_rng = goal004_rng(), after_tick_count = 1L
      )
    })
  }
  control <- run_branch(FALSE)
  intervention <- run_branch(TRUE)
  equal_through_719 <- identical(control$entry$herbivore, intervention$entry$herbivore) &&
    identical(control$entry$plants, intervention$entry$plants) &&
    identical(control$entry$rng, intervention$entry$rng)
  control_projection <- goal004_projection(control$herbivore, control$plants, NULL, control$exit_rng)
  intervention_projection <- goal004_projection(intervention$herbivore, intervention$plants, NULL, intervention$exit_rng)
  first_divergence <- if (identical(control_projection, intervention_projection)) {
    NULL
  } else {
    goal004_first_divergence(control_projection, intervention_projection, "minute_720")
  }
  consequence <- sprintf(
    "minute-720 herbivore_step intake_delta_g=%.17g movement_delta_m=%.17g rng_equal=%s",
    intervention$herbivore$intake_total_day - control$herbivore$intake_total_day,
    intervention$herbivore$distance_moved - control$herbivore$distance_moved,
    identical(control$exit_rng, intervention$exit_rng)
  )
  list(
    control = control, intervention = intervention, equal_through_719 = equal_through_719,
    first_divergence = first_divergence, consequence = consequence,
    exit_rng_identical = identical(control$exit_rng, intervention$exit_rng)
  )
}

goal004_clock_decision <- function() {
  evidence_ids <- list(
    "G004-tick_phase", "G004-completed_clock", "G004-capacity_pathway"
  )
  list(
    comparable_alternatives = list(
      list(
        alternative_id = "twelve_tick_active_day",
        description = paste(
          "A 720-minute model day represents the full accounting day, with",
          "12 digestion ticks and the daily maintenance charge."
        ),
        evidence_ids = evidence_ids
      ),
      list(
        alternative_id = "twenty_four_tick_physiological_day",
        description = paste(
          "The 720-minute loop represents 12 active feeding hours within a",
          "24-hour physiological day, with 24 digestion ticks before the daily maintenance charge."
        ),
        evidence_ids = evidence_ids
      )
    ),
    barry_decision_required = TRUE,
    recommended_next_goal = NULL
  )
}

goal004_classification_summary <- function(probe_rows, evidence_ids = list(),
                                           decision = NULL) {
  if (!is.data.frame(probe_rows) || !nrow(probe_rows)) {
    goal004_abort("Classification requires validated probe evidence.", "herbivoreTTR_goal004_probe_stop")
  }
  mechanisms <- lapply(seq_len(nrow(probe_rows)), function(i) {
    id <- as.character(probe_rows$probe_id[[i]])
    evidence <- evidence_ids[[id]]
    if (is.null(evidence)) evidence <- list(paste0("G004-", id))
    if (is.character(evidence) && length(evidence) == 1L) evidence <- as.list(evidence)
    evidence_type <- if (id %in% c("observer_ledger", "intake_attribution")) {
      "observation"
    } else if (identical(id, "demand_zero_locomotion")) {
      "identity"
    } else {
      "counterfactual"
    }
    note <- if ("allowed_inference" %in% names(probe_rows)) {
      as.character(probe_rows$allowed_inference[[i]])
    } else {
      "Derived from validated invariant and projection evidence."
    }
    list(
      mechanism = id, evidence_type = evidence_type,
      classification = as.character(probe_rows$classification[[i]]),
      evidence_ids = evidence, note = note
    )
  })
  if (is.null(decision)) {
    decision <- list(
      comparable_alternatives = list(),
      barry_decision_required = FALSE,
      recommended_next_goal = NULL
    )
  }
  if (!is.list(decision$comparable_alternatives) ||
    !is.logical(decision$barry_decision_required) ||
    length(decision$barry_decision_required) != 1L ||
    (isTRUE(decision$barry_decision_required) &&
      length(decision$comparable_alternatives) < 2L) ||
    (!isTRUE(decision$barry_decision_required) &&
      length(decision$comparable_alternatives) > 0L)) {
    goal004_abort(
      "Classification decision state is inconsistent.",
      "herbivoreTTR_goal004_probe_stop"
    )
  }
  list(
    schema_version = "1.0.0", stable_bci_is_not_target = TRUE,
    production_changed = FALSE, parameter_changed = FALSE,
    dominant_cause_claim = FALSE,
    comparable_alternatives = decision$comparable_alternatives,
    barry_decision_required = decision$barry_decision_required,
    recommended_next_goal = decision$recommended_next_goal,
    mechanisms = mechanisms
  )
}

goal004_manifest_pass <- function(manifest) {
  required <- c(
    "all_probe_invariants_passed", "observer_projection_identical",
    "observer_exit_rng_identical", "stable_filenames"
  )
  all(required %in% names(manifest)) && all(vapply(required, function(nm) isTRUE(manifest[[nm]]), logical(1)))
}

goal004_write_numeric_csv <- function(x, path) {
  encoded <- x
  for (nm in names(encoded)) {
    if (is.double(encoded[[nm]])) {
      encoded[[nm]] <- ifelse(
        is.na(encoded[[nm]]), NA_character_, sprintf("%a", encoded[[nm]])
      )
    }
  }
  utils::write.csv(encoded, path, row.names = FALSE, na = "")
}

goal004_path_allowed <- function(path, prefixes) {
  any(vapply(prefixes, function(prefix) {
    identical(path, prefix) || startsWith(path, paste0(prefix, ".")) ||
      startsWith(path, paste0(prefix, "["))
  }, logical(1)))
}

goal004_capacity_read_set <- function(x) {
  constants <- x$constants
  if (is.null(constants)) {
    constants <- stats::setNames(
      as.list(as.numeric(c(
        CONSTANTS$MIN_SHOOT,
        CONSTANTS$MAX_BITE_FRACTION, CONSTANTS$FRACTION_C, CONSTANTS$PROP_DIGEST_SC,
        CONSTANTS$FRACTION_N, CONSTANTS$N_TO_PROTEIN, CONSTANTS$PROP_DIGEST_TP
      ))),
      c(
        "MIN_SHOOT", "MAX_BITE_FRACTION", "FRACTION_C", "PROP_DIGEST_SC",
        "FRACTION_N", "N_TO_PROTEIN", "PROP_DIGEST_TP"
      )
    )
  }
  list(
    herbivore = x$herbivore[c(
      "selected_plant_id", "handling_time", "gut_capacity", "MRT",
      "intake_total_day", "intake_defence_day", "intake_water_forage"
    )],
    plant = x$plants[x$plants$plant_id == 1L, c("plant_id", "bleaf", "bstem", "bdef", "qshoot"), drop = FALSE],
    constants = constants
  )
}

goal004_gut_identity <- function(x) {
  identical(
    as.numeric(x$herbivore$gut_content),
    sum(unlist(x$herbivore$digestion[c("bleaf", "bstem", "bdef")], use.names = FALSE))
  )
}

goal004_plot_contract <- function(daily, daily_budget, carried_status) {
  daily_fields <- c("Day", "intake_total_g", "cumulative_energy_balance_kJ")
  budget_fields <- c("branch", "Day", "energy_delta_kJ")
  if (!all(daily_fields %in% names(daily)) ||
    !all(budget_fields %in% names(daily_budget))) {
    goal004_abort(
      "Goal 004 diagnostic plot inputs are incomplete.",
      "herbivoreTTR_goal004_plot_stop"
    )
  }
  control <- daily_budget[daily_budget$branch == "baseline",
    c("Day", "energy_delta_kJ"),
    drop = FALSE
  ]
  intervention <- daily_budget[daily_budget$branch == "completed_clock",
    c("Day", "energy_delta_kJ"),
    drop = FALSE
  ]
  names(control)[[2L]] <- "control_energy_delta_kJ"
  names(intervention)[[2L]] <- "intervention_energy_delta_kJ"
  paired <- merge(control, intervention, by = "Day", sort = TRUE)
  if (anyDuplicated(control$Day) || anyDuplicated(intervention$Day) ||
    !identical(paired$Day, daily$Day)) {
    goal004_abort(
      "Goal 004 diagnostic plot branches are not one-to-one by day.",
      "herbivoreTTR_goal004_plot_stop"
    )
  }
  paired$direct_effect_kJ <- paired$intervention_energy_delta_kJ -
    paired$control_energy_delta_kJ
  list(
    paired = paired,
    labels = list(
      control = "Baseline control (12 ticks/day)",
      intervention = "Completed-clock intervention (+12 ticks/day)",
      effect_scope = "Isolated daily direct effect: intervention - control",
      total_effect = sprintf(
        "Carried 120-day total effect: %s (non-identifiable)",
        gsub("_", " ", carried_status, fixed = TRUE)
      ),
      uncertainty = paste(
        "Single fixed-seed deterministic trajectory; no uncertainty interval;",
        "no biological pass threshold"
      )
    )
  )
}

goal004_run <- function(profile_path, output_dir, days = NULL) {
  if (file.exists(output_dir)) goal004_abort("Goal 004 output directory must be absent before execution.", "herbivoreTTR_goal004_output_exists")
  if (!requireNamespace("digest", quietly = TRUE) || !requireNamespace("jsonlite", quietly = TRUE) ||
    !requireNamespace("yaml", quietly = TRUE)) {
    goal004_abort("Goal 004 requires existing digest, jsonlite, and yaml dependencies.", "herbivoreTTR_goal004_dependency_missing")
  }
  profile <- goal004_validate_profile(goal004_read_profile(profile_path))
  diagnostic_rng <- goal004_rng_guard(profile$runtime$seed)
  on.exit(diagnostic_rng$restore(), add = TRUE)
  requested_days <- if (is.null(days)) profile$runtime$days else as.integer(days)
  if (length(requested_days) != 1L || !is.finite(requested_days) || requested_days < 1L ||
    requested_days > profile$runtime$days) {
    goal004_abort(
      "Bounded Goal 004 execution must request between 1 and the canonical 120 days.",
      "herbivoreTTR_goal004_profile_invalid"
    )
  }
  profile$runtime$days <- requested_days
  repo_root <- normalizePath(goal004_root, winslash = "/", mustWork = TRUE)
  goal004_validate_comparator(profile, repo_root)
  goal3_path <- normalizePath(file.path(repo_root, profile$goal003_profile_path), winslash = "/", mustWork = TRUE)
  goal3_profile <- goal003_validate_profile(goal003_read_profile(goal3_path))
  goal002_reference <- goal003_read_goal002_manifest(goal3_path)
  goal003_validate_goal002_configuration(goal3_profile, goal002_reference)
  accepted_manifest <- file.path(repo_root, "artefacts/goal003_herbivore_reference/run-a/run_manifest.json")
  if (!file.exists(accepted_manifest) || !identical(goal004_file_sha256(accepted_manifest), profile$comparator$manifest_sha256)) {
    goal004_abort("Accepted Goal 003 evidence is missing or has an unexpected manifest hash.", "herbivoreTTR_goal004_comparator_stop")
  }
  configuration_sha256 <- digest::digest(goal004_json(profile), algo = "sha256", serialize = FALSE)
  forcing <- goal003_resolved_forcing(goal3_profile)
  conditions <- data.frame(day = 1L, temp_mean = forcing$temperature, sw = forcing$soil_water, N = forcing$soil_nitrogen)
  initial <- goal003_resolve_initial_state(goal3_profile)
  frozen_sha <- goal003_state_sha256(initial$plants_state)
  # Execute distinct bare-control and observer replays from the same frozen
  # state. The bare replay records no observer events.
  bare <- goal004_trajectory(profile, goal3_profile, initial, conditions, observer = FALSE)
  observer <- goal004_trajectory(profile, goal3_profile, initial, conditions, observer = TRUE)
  phase_cols <- c(
    "Day", "minute", "phase", "herbivore_state_sha256",
    "plant_state_sha256", "daily_output_sha256", "rng_sha256"
  )
  bare_phase <- bare$phases[, phase_cols, drop = FALSE]
  observer_phase <- observer$phases[observer$phases$branch == "observer", phase_cols, drop = FALSE]
  rownames(bare_phase) <- NULL
  rownames(observer_phase) <- NULL
  phase_key <- function(x) paste(x$Day, x$minute, x$phase, sep = ":")
  if (!identical(phase_key(bare_phase), phase_key(observer_phase))) {
    goal004_abort(
      "Bare-control and observer checkpoints are not matched.",
      "herbivoreTTR_goal004_observer_stop"
    )
  }
  projection_hash_fields <- c(
    "herbivore_state_sha256", "plant_state_sha256", "daily_output_sha256"
  )
  phase_projection_equal <- vapply(seq_len(nrow(bare_phase)), function(i) {
    identical(
      bare_phase[i, projection_hash_fields, drop = FALSE],
      observer_phase[i, projection_hash_fields, drop = FALSE]
    )
  }, logical(1))
  phase_rng_equal <- bare_phase$rng_sha256 == observer_phase$rng_sha256
  bare$phases$observer_projection_identical <- phase_projection_equal
  observer$phases$observer_projection_identical <- phase_projection_equal
  bare$phases$observer_rng_identical <- phase_rng_equal
  observer$phases$observer_rng_identical <- phase_rng_equal
  replay_surface <- function(x) {
    x[c("daily", "plants", "checkpoints", "exits", "initial")]
  }
  full_replay_projection_equal <- identical(replay_surface(bare), replay_surface(observer))
  checkpoint_projection_equal <- all(phase_projection_equal)
  checkpoint_rng_equal <- identical(bare$exits, observer$exits) &&
    all(phase_rng_equal)
  if (!identical(bare_phase, observer_phase) || !full_replay_projection_equal ||
    !checkpoint_projection_equal || !checkpoint_rng_equal ||
    bare$event_count != 0L || observer$event_count < 1L) {
    goal004_abort("Observer instrumentation changed the Goal 004 production projection or RNG.", "herbivoreTTR_goal004_observer_stop")
  }
  if (!identical(bare_phase$Day, bare_phase$Day[order(
    bare_phase$Day, bare_phase$minute,
    match(bare_phase$phase, c(
      "daily_opening", "minute_post_step_pre_tick",
      "hourly_tick_pre", "hourly_tick_post", "minute_720_preclosure", "daily_closed"
    ))
  )])) {
    # The recorded order is already the production traversal order; this guard
    # catches accidental reordering before canonical evidence is written.
    goal004_abort("Baseline projection ordering is not deterministic.", "herbivoreTTR_goal004_scientific_stop")
  }
  phase_out <- rbind(bare$phases, observer$phases)
  daily <- observer$daily
  plants_daily <- observer$plants
  goal003_summary_json <- goal003_summary(
    daily, plants_daily, goal3_profile,
    "68e28c9388e99cbf4658145b9e714556803a27f66367b8a7d8aee8c3535daa82", frozen_sha
  )
  bare_summary_json <- goal003_summary(
    bare$daily, bare$plants, goal3_profile,
    "68e28c9388e99cbf4658145b9e714556803a27f66367b8a7d8aee8c3535daa82", frozen_sha
  )
  if (!identical(bare$daily, daily) || !identical(bare$plants, plants_daily) ||
    !identical(bare_summary_json, goal003_summary_json)) {
    goal004_abort(
      "Bare-control and observer outputs are not exactly identical.",
      "herbivoreTTR_goal004_observer_stop"
    )
  }

  completed_checkpoints <- vector("list", profile$runtime$days)
  completed_rows <- vector("list", profile$runtime$days)
  completed_q <- vector("list", profile$runtime$days)
  daily_budget_rows <- lapply(seq_len(profile$runtime$days), function(i) {
    goal004_daily_budget(
      "baseline", observer$checkpoints[[i]],
      observer$checkpoints[[i]]$closed_herbivore, observer$queues
    )
  })
  snapshots <- list()
  invariant_rows <- list()
  bci_results <- vector("list", profile$runtime$days)
  endpoint_results <- vector("list", profile$runtime$days)
  demand_values <- vector("list", profile$runtime$days)
  completed_divergences <- vector("list", profile$runtime$days)
  capacity_divergences <- vector("list", profile$runtime$days)
  endpoint_divergences <- vector("list", profile$runtime$days)
  add_snapshot <- function(probe_id, day, checkpoint, control, intervention, prefixes, enforce = TRUE) {
    rec <- goal004_snapshot(probe_id, day, checkpoint, control, intervention)
    snapshots[[length(snapshots) + 1L]] <<- rec
    paths <- sort(goal004_changed_paths(control, intervention))
    if (isTRUE(enforce) && length(paths) && !all(vapply(paths, goal004_path_allowed, logical(1), prefixes = prefixes))) {
      goal004_abort(sprintf("Forbidden changed path in %s day %d: %s", probe_id, day, paste(paths, collapse = ", ")), "herbivoreTTR_goal004_probe_stop")
    }
    if (isTRUE(enforce) && length(paths)) {
      for (path in paths) {
        invariant_rows[[length(invariant_rows) + 1L]] <<- goal004_invariant(
          probe_id, "paired", day, checkpoint, "observed_changed_path", path,
          goal004_sha256(control), goal004_sha256(intervention), "allowed_difference"
        )
      }
    }
  }
  add_equal <- function(probe_id, branch, day, checkpoint, name, expected, observed = expected,
                        path = "", relation = "identical") {
    invariant_rows[[length(invariant_rows) + 1L]] <<- goal004_invariant(
      probe_id, branch, day, checkpoint, name, path, expected, observed, relation
    )
  }

  for (i in seq_len(profile$runtime$days)) {
    cb <- bare$checkpoints[[i]]
    co <- observer$checkpoints[[i]]
    add_snapshot(
      "observer", i, "daily_closed",
      goal004_projection(cb$closed_herbivore, cb$closed_plants, cb$daily, cb$exit_rng),
      goal004_projection(co$closed_herbivore, co$closed_plants, co$daily, co$exit_rng), character()
    )
    bare_closed <- goal004_projection(cb$closed_herbivore, cb$closed_plants, cb$daily, cb$exit_rng)
    observer_closed <- goal004_projection(co$closed_herbivore, co$closed_plants, co$daily, co$exit_rng)
    add_equal(
      "observer", "observer", i, "daily_closed", "observer_projection_equal",
      bare_closed[c("herbivore", "plants", "daily_output", "constants")],
      observer_closed[c("herbivore", "plants", "daily_output", "constants")],
      "bare_control_vs_observer.production_projection"
    )
    add_equal(
      "observer", "observer", i, "daily_closed", "observer_rng_equal",
      cb$exit_rng, co$exit_rng, "bare_control_vs_observer.rng"
    )

    extra <- goal004_completed_trace(cb, profile$runtime$completed_clock_extra_ticks)
    complete <- goal004_close_day(extra$herbivore, cb$plants, conditions, cb$model_day, resolve_plant_backend(profile$runtime$plant_backend))
    complete_daily <- goal003_daily_row(i, cb$model_day, cb$seed, forcing, cb$opening_herbivore, complete$herbivore)
    completed_checkpoints[[i]] <- list(
      day = i, model_day = cb$model_day, herbivore = extra$herbivore,
      plants = cb$plants, closed_herbivore = complete$herbivore, closed_plants = complete$plants,
      daily = complete_daily, exit_rng = cb$exit_rng
    )
    completed_q[[i]] <- rbind(observer$queues[observer$queues$Day == i, , drop = FALSE] |>
      transform(branch = "completed_clock"), extra$queues)
    completed_checkpoint <- cb
    completed_checkpoint$daily <- complete_daily
    completed_checkpoint$herbivore <- extra$herbivore
    completed_rows[[i]] <- goal004_daily_budget(
      "completed_clock", completed_checkpoint, complete$herbivore, completed_q[[i]]
    )
    daily_budget_rows[[length(daily_budget_rows) + 1L]] <- completed_rows[[i]]
    p_control <- goal004_projection(cb$herbivore, cb$plants, NULL, cb$exit_rng)
    p_complete <- goal004_projection(extra$herbivore, cb$plants, NULL, cb$exit_rng)
    completed_divergences[[i]] <- goal004_first_divergence(
      p_control, p_complete, "minute_720_preclosure"
    )
    add_snapshot("completed_clock", i, "minute_720_preclosure", p_control, p_complete, profile$allowed_paths$completed_clock_preclosure)
    add_snapshot(
      "completed_clock", i, "daily_closed",
      goal004_projection(cb$closed_herbivore, cb$closed_plants, cb$daily, cb$exit_rng),
      goal004_projection(complete$herbivore, complete$plants, complete_daily, cb$exit_rng), profile$allowed_paths$completed_clock_closed
    )
    add_equal("completed_clock", "paired", i, "minute_720_preclosure", "completed_clock_no_feeding", cb$herbivore$intake_total_day, extra$herbivore$intake_total_day, "herbivore.intake_total_day")
    add_equal("completed_clock", "paired", i, "minute_720_preclosure", "completed_clock_no_movement", cb$herbivore$distance_moved, extra$herbivore$distance_moved, "herbivore.distance_moved")
    add_equal("completed_clock", "paired", i, "minute_720_preclosure", "completed_clock_plant_equal", cb$plants, extra$plants, "plants")
    add_equal(
      "completed_clock",
      "paired",
      i,
      "minute_720_preclosure",
      "completed_clock_no_drinking",
      cb$herbivore$intake_water_drinking,
      extra$herbivore$intake_water_drinking,
      "herbivore.intake_water_drinking"
    )
    add_equal("completed_clock", "paired", i, "minute_720_preclosure", "completed_clock_rng_equal", TRUE, extra$invariants$rng, "rng")
    add_equal(
      "completed_clock",
      "paired",
      i,
      "minute_720_preclosure",
      "completed_clock_requirement_equal",
      cb$herbivore$total_energy_requirement_day,
      extra$herbivore$total_energy_requirement_day,
      "herbivore.total_energy_requirement_day"
    )

    cap_unticked <- goal004_capacity_replay(cb$herbivore, cb$opening_plants, 720L, "capacity_unticked", i)
    cap_complete <- goal004_capacity_replay(extra$herbivore, cb$opening_plants, 720L, "capacity_completed_clock", i)
    baseline_cap_projection <- goal004_projection(cb$herbivore, cb$opening_plants, NULL, goal004_rng())
    completed_cap_projection <- goal004_projection(extra$herbivore, cb$opening_plants, NULL, goal004_rng())
    capacity_divergences[[i]] <- goal004_first_divergence(
      baseline_cap_projection, completed_cap_projection, "replay_entry"
    )
    add_snapshot(
      "capacity_pathway", i, "replay_entry", baseline_cap_projection, completed_cap_projection,
      profile$allowed_paths$completed_clock_preclosure
    )
    read_equal <- identical(goal004_capacity_read_set(baseline_cap_projection), goal004_capacity_read_set(completed_cap_projection))
    plant_equal <- identical(baseline_cap_projection$plants, completed_cap_projection$plants)
    queue_equal <- goal004_gut_identity(baseline_cap_projection) && goal004_gut_identity(completed_cap_projection) &&
      identical(names(baseline_cap_projection$herbivore$digestion), names(completed_cap_projection$herbivore$digestion))
    add_equal("capacity_pathway", "paired", i, "replay_entry", "capacity_entry_non_gut_read_set_equal", TRUE, read_equal, "read_set")
    add_equal("capacity_pathway", "paired", i, "replay_entry", "capacity_entry_plant_equal", TRUE, plant_equal, "plants")
    add_equal("capacity_pathway", "paired", i, "replay_entry", "capacity_entry_gut_queue_identity", TRUE, queue_equal, "herbivore.gut_content")
    add_equal(
      "capacity_pathway", "paired", i, "replay_entry", "capacity_rng_unchanged",
      TRUE, cap_unticked$rng_unchanged && cap_complete$rng_unchanged, "rng"
    )
    # Keep both fixed-opportunity branches; the canonical output is the only
    # source used for the capacity contrast.
    completed_q[[i]] <- completed_q[[i]]
    if (i == 1L) capacity_rows <- list(cap_unticked$rows, cap_complete$rows) else capacity_rows <- c(capacity_rows, list(cap_unticked$rows, cap_complete$rows))

    demand_before <- goal004_projection(cb$herbivore, cb$plants, NULL, cb$exit_rng)
    maintenance <- cb$closed_herbivore$maintenance_energy_requirement_day
    loc <- cb$closed_herbivore$total_energy_requirement_day - maintenance
    demand_zero_delta <- cb$closed_herbivore$daily_energy_intake - maintenance
    demand_after <- goal004_projection(cb$herbivore, cb$plants, NULL, cb$exit_rng)
    add_snapshot(
      "demand_zero_locomotion", i, "algebraic_entry",
      demand_before, demand_after, character()
    )
    add_equal(
      "demand_zero_locomotion", "paired", i, "algebraic_entry",
      "demand_state_unchanged", demand_before, demand_after,
      "projection"
    )
    demand_values[[i]] <- c(locomotion_kJ = loc, zero_locomotion_energy_delta_kJ = demand_zero_delta)

    bci <- goal004_bci_probe(
      cb$opening_herbivore, cb$opening_plants, conditions,
      cb$model_day, cb$seed, profile$runtime$minute_limit,
      profile$runtime$plant_backend
    )
    bci_results[[i]] <- bci
    add_snapshot(
      "bci_feedback_operability", i, "matched_start",
      bci$enabled_start, bci$disabled_start,
      "herbivore.body_condition_feedback_enabled"
    )
    add_equal(
      "bci_feedback_operability", "paired", i, "matched_start",
      "bci_matched_start_rng", bci$enabled_start$rng,
      bci$disabled_start$rng, "rng"
    )

    endpoint <- cb$endpoint_719
    if (is.null(endpoint)) goal004_abort("Minute-719 endpoint checkpoint was not captured.", "herbivoreTTR_goal004_probe_stop")
    endpoint_result <- goal004_endpoint_probe(
      endpoint, conditions, cb$model_day, cb$seed,
      profile$runtime$plant_backend
    )
    endpoint_results[[i]] <- endpoint_result
    endpoint_divergences[[i]] <- endpoint_result$first_divergence
    ep_control <- goal004_projection(
      endpoint_result$control$entry$herbivore,
      endpoint_result$control$entry$plants, NULL,
      endpoint_result$control$entry$rng
    )
    ep_intervention <- goal004_projection(
      endpoint_result$intervention$entry$herbivore,
      endpoint_result$intervention$entry$plants, NULL,
      endpoint_result$intervention$entry$rng
    )
    add_snapshot("endpoint_eligibility", i, "minute_719", ep_control, ep_intervention, character())
    add_equal(
      "endpoint_eligibility", "paired", i, "minute_719", "endpoint_equal_through_minute_719",
      TRUE, endpoint_result$equal_through_719, "projection"
    )
  }
  bci_equal <- all(vapply(bci_results, function(x) isTRUE(x$adjusted_projection_identical), logical(1)))
  bci_rng_equal <- all(vapply(bci_results, function(x) isTRUE(x$exit_rng_identical), logical(1)))
  bci_class <- if (bci_equal && bci_rng_equal) "nonoperative_here" else "intended_behaviour_here"
  if (identical(bci_class, "nonoperative_here")) {
    for (i in seq_along(bci_results)) {
      bci <- bci_results[[i]]
      bci_control <- goal004_projection(
        bci$enabled$herbivore, bci$enabled$plants, bci$enabled$daily,
        bci$enabled$exit_rng
      )
      bci_intervention <- goal004_projection(
        bci$disabled$herbivore, bci$disabled$plants, bci$disabled$daily,
        bci$disabled$exit_rng
      )
      add_snapshot(
        "bci_feedback_operability", i, "adjusted_exit",
        bci_control, bci_intervention,
        "herbivore.body_condition_feedback_enabled"
      )
      add_equal(
        "bci_feedback_operability", "paired", i, "adjusted_exit",
        "bci_projection_equal", TRUE,
        bci$adjusted_projection_identical, "projection"
      )
      add_equal(
        "bci_feedback_operability", "paired", i, "adjusted_exit",
        "bci_rng_equal", TRUE, bci$exit_rng_identical, "rng"
      )
    }
  }
  tick_phase <- goal004_tick_phase_probe(initial$herbivore_state)
  add_equal(
    "tick_phase", "paired", 1L, "hourly_boundary", "tick_phase_release_after_boundary",
    0, tick_phase$after_boundary$released_mass_g, "dc_leaf_terminal"
  )
  add_equal(
    "tick_phase", "paired", 1L, "hourly_boundary", "tick_phase_release_before_boundary",
    1, tick_phase$before_boundary$released_mass_g, "dc_leaf_terminal"
  )
  add_equal(
    "tick_phase", "paired", 1L, "hourly_boundary", "tick_phase_opening_queue_mass_equal",
    tick_phase$after_boundary$opening_queue_mass_g,
    tick_phase$before_boundary$opening_queue_mass_g, "queue"
  )
  add_equal(
    "tick_phase", "paired", 1L, "hourly_boundary", "tick_phase_queue_lengths_equal",
    tick_phase$after_boundary$queue_lengths,
    tick_phase$before_boundary$queue_lengths, "queue"
  )
  add_equal(
    "tick_phase", "paired", 1L, "hourly_boundary", "tick_phase_opening_queue_equal",
    tick_phase$after_boundary$opening_queue_mass_g,
    tick_phase$before_boundary$opening_queue_mass_g, "queue"
  )
  add_equal(
    "tick_phase", "paired", 1L, "hourly_boundary", "tick_phase_tick_count_equal",
    tick_phase$tick_count[["after_boundary"]],
    tick_phase$tick_count[["before_boundary"]], "tick_count"
  )
  capacity_table <- do.call(rbind, capacity_rows)
  q_baseline <- observer$queues
  q_completed <- do.call(rbind, completed_q)
  q <- rbind(q_baseline, q_completed)
  daily_budget <- do.call(rbind, daily_budget_rows)
  daily_budget <- goal004_reconstruct_daily_budget(q, daily_budget)
  completed_limits <- observer$limits
  completed_limits$branch <- "completed_clock"
  limits <- rbind(observer$limits, completed_limits, capacity_table)
  demand_values <- as.data.frame(do.call(rbind, demand_values))
  inv <- do.call(rbind, invariant_rows)
  invariant_pass <- function(probe) {
    x <- inv[inv$probe_id == probe, , drop = FALSE]
    nrow(x) > 0L && all(vapply(seq_len(nrow(x)), function(j) goal004_invariant_pass(x[j, , drop = FALSE]), logical(1)))
  }
  required_names <- c(
    "observer_projection_equal", "observer_rng_equal", "tick_phase_opening_queue_equal",
    "tick_phase_tick_count_equal",
    "tick_phase_release_after_boundary", "tick_phase_release_before_boundary",
    "completed_clock_no_feeding", "completed_clock_no_movement",
    "completed_clock_plant_equal", "completed_clock_no_drinking", "completed_clock_rng_equal",
    "completed_clock_requirement_equal", "capacity_entry_non_gut_read_set_equal", "capacity_entry_plant_equal",
    "capacity_entry_gut_queue_identity", "capacity_rng_unchanged", "demand_state_unchanged",
    "bci_matched_start_rng", "endpoint_equal_through_minute_719"
  )
  if (!all(required_names %in% inv$invariant_name)) {
    goal004_abort("A required Goal 004 invariant is missing.", "herbivoreTTR_goal004_probe_stop")
  }
  capacity_ok <- invariant_pass("capacity_pathway")
  first_path <- function(x) {
    hit <- Filter(Negate(is.null), x)
    if (length(hit)) hit[[1L]]$path else NA_character_
  }
  tick_divergence <- goal004_first_changed_value(
    tick_phase$after_boundary$state,
    tick_phase$before_boundary$state,
    "herbivore"
  )
  bci_divergence <- first_path(lapply(bci_results, `[[`, "first_divergence"))
  endpoint_note <- paste(vapply(endpoint_results, `[[`, character(1), "consequence"), collapse = "; ")
  probe_rows <- data.frame(
    probe_id = c(
      "observer_ledger", "tick_phase", "completed_clock", "capacity_pathway", "intake_attribution",
      "demand_zero_locomotion", "bci_feedback_operability", "endpoint_eligibility", "carried_completed_clock"
    ),
    control = c(
      "bare_control", "impulse_after_boundary", "baseline", "capacity_unticked", "baseline",
      "implemented_requirement", "feedback_enabled", "minute_719", "not_run"
    ),
    intervention = c(
      "observer_capture", "impulse_before_boundary", "+12_digestion_ticks", "capacity_completed_clock",
      "observer_gate_log", "zero_locomotion_algebra", "feedback_disabled", "inclusive_minute_720", "not_run"
    ),
    status = c(rep("complete", 8L), "not_run"),
    invariants_pass = c(
      invariant_pass("observer"), invariant_pass("tick_phase"), invariant_pass("completed_clock"),
      capacity_ok, invariant_pass("observer"), invariant_pass("demand_zero_locomotion"),
      invariant_pass("bci_feedback_operability"), invariant_pass("endpoint_eligibility"), TRUE
    ),
    production_projection_identical = c(invariant_pass("observer"), NA, NA, NA, TRUE, TRUE, bci_equal, NA, NA),
    exit_rng_identical = c(
      invariant_pass("observer"), NA, invariant_pass("completed_clock"), capacity_ok,
      invariant_pass("observer"), TRUE, bci_rng_equal, NA, NA
    ),
    first_state_divergence = c(
      NA, if (is.null(tick_divergence)) NA_character_ else tick_divergence$path,
      first_path(completed_divergences), first_path(capacity_divergences),
      NA, NA, bci_divergence, first_path(endpoint_divergences), NA
    ),
    first_rng_divergence = rep(NA_character_, 9L),
    classification = c(
      "intended_behaviour_here", "intended_behaviour_here", "intended_behaviour_here",
      if (capacity_ok) "intended_behaviour_here" else "unresolved_interaction",
      "intended_behaviour_here", "implementation_or_contract_defect", bci_class,
      "intended_behaviour_here", "unresolved_interaction"
    ),
    allowed_inference = c(
      "Accounting or instrumentation fidelity only",
      "Measured discrete phase sensitivity using production hourly_digestion_step()",
      "Conditional effect of completing 24 ticks",
      "Capacity-mediated intake under fixed replay only",
      "Constraints binding along this trajectory",
      paste(
        "Maximum implemented locomotion contribution; repository and equation units",
        "conflict requires literature/source contract validation;",
        "no implementation defect demonstrated"
      ),
      if (bci_class == "nonoperative_here") {
        "Adjusted projections and RNG are equal here"
      } else {
        "Measured feedback-disabled adjusted projection and RNG consequence; no biological realism claim"
      },
      paste("Foraging-window endpoint consequence:", endpoint_note),
      "Not run: isolated probes are sufficient and carried contrast is non-identifiable"
    ),
    reason = c(rep("", 8L), profile$classification$carried_policy_reason), stringsAsFactors = FALSE, check.names = FALSE
  )
  probe_rows$invariants_pass <- as.logical(probe_rows$invariants_pass)
  if (!all(probe_rows$invariants_pass[probe_rows$status == "complete"])) {
    goal004_abort("A required Goal 004 invariant failed.", "herbivoreTTR_goal004_probe_stop")
  }
  classification <- goal004_classification_summary(
    probe_rows[probe_rows$status == "complete", , drop = FALSE],
    decision = goal004_clock_decision()
  )
  classification$allowed_classes <- c(
    "implementation_or_contract_defect", "parameter_plausibility",
    "intended_behaviour_here", "nonoperative_here", "unresolved_interaction"
  )
  classification$carried_policy_status <- "not_run"
  classification$carried_policy_reason <- profile$classification$carried_policy_reason
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(phase_out, file.path(output_dir, "baseline_projection.csv"), row.names = FALSE, na = "")
  utils::write.csv(daily, file.path(output_dir, "baseline_daily_diagnostics.csv"), row.names = FALSE, na = "")
  utils::write.csv(plants_daily, file.path(output_dir, "baseline_plant_diagnostics.csv"), row.names = FALSE, na = "")
  goal003_write_json(goal003_summary_json, file.path(output_dir, "baseline_diagnostic_summary.json"))
  goal004_write_numeric_csv(q, file.path(output_dir, "hourly_queue_ledger.csv"))
  goal004_write_numeric_csv(daily_budget, file.path(output_dir, "daily_energy_budget.csv"))
  goal004_write_numeric_csv(limits, file.path(output_dir, "minute_intake_limits.csv"))
  utils::write.csv(probe_rows, file.path(output_dir, "probe_comparison.csv"), row.names = FALSE, na = "")
  utils::write.csv(inv, file.path(output_dir, "probe_invariants.csv"), row.names = FALSE, na = "", quote = TRUE)
  saveRDS(list(schema_version = "1.0.0", records = snapshots), file.path(output_dir, "probe_state_snapshots.rds"), version = 3)
  goal004_json_write <- function(x, path) writeLines(goal004_json(x, pretty = TRUE), path, useBytes = TRUE)
  goal004_json_write(classification, file.path(output_dir, "classification_summary.json"))
  write_diagnostic_plot <- function() {
    plot_contract <- goal004_plot_contract(
      daily, daily_budget, classification$carried_policy_status
    )
    paired <- plot_contract$paired
    labels <- plot_contract$labels
    control_colour <- "#0072B2"
    intervention_colour <- "#D55E00"
    grDevices::png(file.path(output_dir, "energy_budget_diagnostics.png"),
      width = 1200, height = 900, res = 120, bg = "white"
    )
    old <- graphics::par(no.readonly = TRUE)
    on.exit(
      {
        graphics::par(old)
        grDevices::dev.off()
      },
      add = TRUE
    )
    graphics::par(mfrow = c(2, 2), mar = c(4, 4, 2, 1), oma = c(5, 0, 0, 0))
    graphics::plot(
      daily$Day, daily$intake_total_g,
      type = "l", col = control_colour,
      xlab = "Diagnostic day (1--120)", ylab = "Dry-matter intake (g/day)",
      main = "Baseline control intake"
    )
    energy_range <- range(c(
      paired$control_energy_delta_kJ,
      paired$intervention_energy_delta_kJ
    ))
    graphics::plot(
      paired$Day, paired$control_energy_delta_kJ,
      type = "l",
      col = control_colour, lty = 1, ylim = energy_range,
      xlab = "Diagnostic day (1--120)", ylab = "Daily energy delta (kJ/day)",
      main = "Control and intervention"
    )
    graphics::lines(paired$Day, paired$intervention_energy_delta_kJ,
      col = intervention_colour, lty = 2
    )
    graphics::legend(
      "topright",
      legend = c(labels$control, labels$intervention),
      col = c(control_colour, intervention_colour), lty = c(1, 2),
      bty = "o", bg = "white", box.col = "white", cex = 0.72
    )
    graphics::plot(
      paired$Day, paired$direct_effect_kJ,
      type = "l",
      col = intervention_colour,
      xlab = "Diagnostic day (1--120)", ylab = "Energy-delta difference (kJ/day)",
      main = "Isolated completed-clock direct effect"
    )
    graphics::abline(h = 0, col = "grey60", lty = 3)
    graphics::plot(
      daily$Day, daily$cumulative_energy_balance_kJ,
      type = "l",
      col = control_colour,
      xlab = "Diagnostic day (1--120)", ylab = "Cumulative energy balance (kJ)",
      main = "Baseline control cumulative energy"
    )
    graphics::mtext(paste(labels$effect_scope, labels$total_effect, sep = "; "),
      side = 1, outer = TRUE, line = 2.6, cex = 0.72
    )
    graphics::mtext(labels$uncertainty,
      side = 1, outer = TRUE, line = 1.1,
      cex = 0.72
    )
  }
  write_diagnostic_plot()
  artefacts <- c(
    "baseline_projection.csv", "baseline_daily_diagnostics.csv", "baseline_plant_diagnostics.csv",
    "baseline_diagnostic_summary.json", "hourly_queue_ledger.csv", "daily_energy_budget.csv",
    "minute_intake_limits.csv", "probe_comparison.csv", "probe_invariants.csv", "probe_state_snapshots.rds",
    "classification_summary.json", "energy_budget_diagnostics.png"
  )
  output_hashes <- stats::setNames(vapply(artefacts, function(x) goal004_file_sha256(file.path(output_dir, x)), character(1)), artefacts)
  content_sha <- digest::digest(paste(names(output_hashes), output_hashes, sep = "=", collapse = "\n"), algo = "sha256", serialize = FALSE)
  observer_projection_identical <- full_replay_projection_equal &&
    checkpoint_projection_equal && identical(bare_phase, observer_phase)
  observer_exit_rng_identical <- checkpoint_rng_equal
  written_q <- utils::read.csv(file.path(output_dir, "hourly_queue_ledger.csv"), check.names = FALSE)
  written_limits <- utils::read.csv(file.path(output_dir, "minute_intake_limits.csv"), check.names = FALSE)
  written_daily_budget <- utils::read.csv(file.path(output_dir, "daily_energy_budget.csv"), check.names = FALSE)
  written_baseline_daily <- utils::read.csv(
    file.path(output_dir, "baseline_daily_diagnostics.csv"),
    check.names = FALSE
  )
  ledger_checks <- goal004_ledger_checks(
    written_q, written_limits, written_daily_budget, written_baseline_daily
  )
  all_ledger_checks_passed <- ledger_checks$passed
  all_probe_invariants_passed <- all(probe_rows$invariants_pass[probe_rows$status == "complete"])
  stable_filenames <- identical(c("run_manifest.json", artefacts), profile$outputs$artefact_names)
  manifest <- list(
    status = if (all_ledger_checks_passed && all_probe_invariants_passed &&
      observer_projection_identical && observer_exit_rng_identical &&
      stable_filenames) {
      "complete"
    } else {
      "failed"
    },
    goal_id = profile$goal_id, seed = profile$runtime$seed, days = profile$runtime$days, start_day = profile$runtime$start_day,
    baseline_replays = 2L, diagnostic_rng_seed = diagnostic_rng$seed,
    diagnostic_rng_sha256 = diagnostic_rng$sha256,
    bare_control_event_records = bare$event_count,
    observer_event_records = observer$event_count,
    baseline_minute_limit = 720L, baseline_ticks_per_day = 12L, completed_clock_extra_ticks = 12L,
    production_changes = FALSE, parameter_changes = FALSE, observer_projection_identical = observer_projection_identical,
    observer_exit_rng_identical = observer_exit_rng_identical,
    first_baseline_state_divergence = NULL, first_baseline_rng_divergence = NULL,
    goal003_rng_comparison = "not_available_not_claimed",
    all_ledger_checks_passed = all_ledger_checks_passed, all_probe_invariants_passed = all_probe_invariants_passed, carried_policy_status = "not_run",
    goal003_reference = list(
      commit = profile$comparator$commit, tree_sha256 = profile$comparator$tree_sha256,
      profile_sha256 = profile$comparator$profile_sha256, runner_sha256 = profile$comparator$runner_sha256,
      test_sha256 = profile$comparator$test_sha256, manifest_sha256 = profile$comparator$manifest_sha256
    ),
    configuration_sha256 = configuration_sha256, source_sha256 = goal004_source_digest(repo_root), content_sha256 = content_sha,
    output_set_sha256 = digest::digest(paste(artefacts, collapse = "\n"), algo = "sha256", serialize = FALSE),
    all_artefacts = c("run_manifest.json", artefacts), stable_filenames = stable_filenames, dominant_cause_claim = FALSE
  )
  goal004_json_write(manifest, file.path(output_dir, "run_manifest.json"))
  invisible(manifest)
}

goal004_cli <- function(args = commandArgs(trailingOnly = TRUE)) {
  value_for <- function(flag) {
    i <- match(flag, args)
    if (!is.na(i) && i < length(args)) {
      return(args[[i + 1L]])
    }
    hit <- args[startsWith(args, paste0(flag, "="))]
    if (length(hit) == 1L) {
      return(sub(paste0("^", flag, "="), "", hit))
    }
    NA_character_
  }
  profile <- value_for("--profile")
  output <- value_for("--output-dir")
  if (is.na(profile) || is.na(output)) stop("Usage: Rscript scripts/run_goal004_energy_decomposition.R --profile PROFILE --output-dir OUTPUT_DIR", call. = FALSE)
  goal004_run(profile, output)
  invisible(NULL)
}

if (any(grepl("^--profile(?:=|$)", commandArgs(trailingOnly = TRUE)))) goal004_cli()
