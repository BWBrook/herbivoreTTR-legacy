#!/usr/bin/env Rscript

goal004_source_helpers <- function() {
  if (exists("init_herbivore", mode = "function", inherits = TRUE) &&
    exists("run_daily_herbivore_simulation", mode = "function", inherits = TRUE)) {
    return(invisible(TRUE))
  }
  script_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", script_args, value = TRUE)
  script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1L]]) else NA_character_
  repo_root <- if (!is.na(script_path)) {
    normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
  } else {
    normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  }
  for (path in sort(list.files(file.path(repo_root, "R"), pattern = "\\.R$", full.names = TRUE))) {
    sys.source(path, envir = .GlobalEnv)
  }
  invisible(TRUE)
}

goal004_source_helpers()

goal004_queue_names <- function() {
  c("bleaf", "bstem", "bdef", "dc_leaf", "dc_stem", "dp_leaf", "dp_stem", "dp_def")
}

goal004_herbivore_fields <- function() {
  c(
    "herbivore_id", "mass", "herb_type", "mixed_browser_weight",
    "movement_disruption_prob", "foraging_mode", "forage_access_scale", "xcor", "ycor",
    "current_hour", "last_hour", "MRT", "behaviour", "selected_plant_id",
    "selected_plant_dist", "gut_content", "distance_moved", "time_spent_foraging",
    "intake_total_day", "intake_digest_carbs_day", "intake_digest_protein_day", "intake_PE_day",
    "intake_NPE_day", "intake_defence_day", "intake_total", "metabolic_water_day",
    "intake_water_forage", "intake_water_drinking", "daily_net_water_balance",
    "daily_water_intake_total", "water_requirement_day", "water_balance_ratio",
    "maintenance_energy_requirement_day", "total_energy_requirement_day", "daily_energy_intake",
    "daily_energy_delta", "energy_balance_ratio", "energy_deficit_streak_days",
    "water_deficit_streak_days", "physiological_stress_flag", "body_condition_index",
    "baseline_time_spent_foraging", "body_condition_feedback_enabled", "body_condition_gain_coeff",
    "body_condition_loss_coeff", "body_condition_effort_threshold", "body_condition_stress_threshold",
    "body_condition_max_foraging_boost", "energy_balance", "water_balance", "digestion",
    "gut_capacity", "bite_size", "handling_time", "fv_max", "daily_water_requirement",
    "feedback_settings", "seeded_draws"
  )
}

goal004_plant_fields <- function() {
  c(
    "plant_id", "xcor", "ycor", "veg_type", "ms", "mr", "cs", "cr", "ns", "nr",
    "cd", "nd", "bleaf", "bstem", "bdef", "md", "broot", "brepr", "height", "qroot",
    "qshoot", "gs", "gr", "gd", "uc", "un", "rsC", "rrC", "rdC", "rsN", "rrN",
    "rdN", "tauC", "tauN", "tauCd", "tauNd"
  )
}

goal004_daily_fields <- function() {
  c(
    "Day", "model_day", "HerbivoreID", "day_seed", "temperature", "soil_water", "soil_nitrogen",
    "opening_xcor_m", "opening_ycor_m", "xcor", "ycor", "opening_gut_content_g", "gut_content_g",
    "gut_capacity_g", "intake_total_g", "intake_PE_kJ", "intake_NPE_kJ", "energy_intake_kJ",
    "total_energy_requirement_kJ", "energy_delta_kJ", "EnergyBalance", "cumulative_energy_balance_kJ",
    "metabolic_water_g", "forage_water_g", "drinking_water_g", "water_input_total_g",
    "water_requirement_g", "daily_net_water_g", "WaterBalance", "cumulative_water_balance_g",
    "distance_moved_m", "time_spent_foraging_h", "EnergyDeficitStreakDays", "WaterDeficitStreakDays",
    "BodyConditionIndex", "PhysiologicalStressFlag", "behaviour", "selected_plant_id",
    "energy_daily_residual_kJ", "energy_cumulative_residual_kJ", "water_daily_residual_g",
    "water_cumulative_residual_g"
  )
}

goal004_abort <- function(message, class = "herbivoreTTR_goal004_contract_stop") {
  if (requireNamespace("rlang", quietly = TRUE)) rlang::abort(message, class = class)
  stop(message, call. = FALSE)
}

goal004_clone <- function(x) unserialize(serialize(x, NULL, version = 3L))
goal004_sha256 <- function(x) digest::digest(serialize(x, NULL, version = 3L), algo = "sha256")
goal004_file_sha256 <- function(path) digest::digest(file = path, algo = "sha256")
goal004_rng <- function() {
  if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    as.integer(get(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
  } else {
    NULL
  }
}

goal004_rng_guard <- function(seed) {
  seed <- as.integer(seed)
  if (length(seed) != 1L || is.na(seed)) {
    goal004_abort(
      "Goal 004 diagnostic RNG seed must be one finite integer.",
      "herbivoreTTR_goal004_profile_invalid"
    )
  }
  rng_env <- .GlobalEnv
  had_seed <- exists(".Random.seed", envir = rng_env, inherits = FALSE)
  old_seed <- if (had_seed) {
    get(".Random.seed", envir = rng_env, inherits = FALSE)
  } else {
    NULL
  }
  set.seed(seed)
  diagnostic_rng <- goal004_rng()
  restored <- FALSE
  restore <- function() {
    if (restored) {
      return(invisible(NULL))
    }
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = rng_env)
    } else if (exists(".Random.seed", envir = rng_env, inherits = FALSE)) {
      rm(".Random.seed", envir = rng_env)
    }
    restored <<- TRUE
    invisible(NULL)
  }
  list(
    seed = seed, rng = diagnostic_rng,
    sha256 = goal004_sha256(diagnostic_rng), restore = restore
  )
}

goal004_json <- function(x, pretty = FALSE) {
  jsonlite::toJSON(x, auto_unbox = TRUE, pretty = pretty, null = "null", na = "null", digits = 17)
}

goal004_read_profile <- function(path) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    goal004_abort("Goal 004 profile path does not exist.", "herbivoreTTR_goal004_profile_missing")
  }
  if (!requireNamespace("yaml", quietly = TRUE)) goal004_abort("Goal 004 requires yaml.", "herbivoreTTR_goal004_dependency_missing")
  yaml::read_yaml(normalizePath(path, winslash = "/", mustWork = TRUE))
}

goal004_validate_profile <- function(profile) {
  required <- c(
    "goal_id", "profile_schema_version", "description", "goal003_profile_path",
    "runtime", "comparator", "probes", "allowed_paths", "outputs", "classification"
  )
  if (!is.list(profile) || !identical(names(profile), required)) goal004_abort("Goal 004 profile is incomplete.", "herbivoreTTR_goal004_profile_invalid")
  if (!identical(as.character(profile$goal_id), "004-herbivore-energy-budget-forensic-decomposition") ||
    !identical(as.character(profile$profile_schema_version), "1.0.0")) {
    goal004_abort("Goal 004 profile identity or schema is invalid.", "herbivoreTTR_goal004_profile_invalid")
  }
  runtime <- profile$runtime
  runtime_names <- c(
    "seed", "days", "start_day", "minute_limit", "forage_access_scale", "plant_backend",
    "apply_growth", "daily_plant_reset", "completed_clock_extra_ticks", "serialization_version"
  )
  if (!identical(names(runtime), runtime_names) || !identical(as.integer(runtime$seed), 2002L) ||
    !identical(as.integer(runtime$days), 120L) || !identical(as.integer(runtime$start_day), 6L) ||
    !identical(as.integer(runtime$minute_limit), 720L) || !identical(as.numeric(runtime$forage_access_scale), 1) ||
    !identical(as.character(runtime$plant_backend), "internal_ttr") || !identical(as.logical(runtime$apply_growth), FALSE) ||
    !identical(as.logical(runtime$daily_plant_reset), TRUE) || !identical(as.integer(runtime$completed_clock_extra_ticks), 12L) ||
    !identical(as.integer(runtime$serialization_version), 3L)) {
    goal004_abort("Goal 004 runtime is not the accepted fixed diagnostic contract.", "herbivoreTTR_goal004_profile_invalid")
  }
  cmp <- profile$comparator
  cmp_names <- c("commit", "production_base", "tree_sha256", "profile_sha256", "runner_sha256", "test_sha256", "manifest_sha256")
  if (!identical(names(cmp), cmp_names) || !identical(cmp$commit, "abf68b691b4e30020625d1871dcabe56a5926bc1") ||
    !identical(cmp$production_base, "e45a6b79b4fb5474609e916aa91e49b4ccc878e2") ||
    !identical(cmp$tree_sha256, "03423aa5ec512ed4fda695a0ad55f828c3c308d1a7992ee20e09adc5af3a0d48") ||
    !identical(cmp$manifest_sha256, "7e9ad004137e2a1c3b8a7233f183fcbbed02ef6bfdcf94f43dfded82a707538f")) {
    goal004_abort("Goal 003 comparator provenance is not locked.", "herbivoreTTR_goal004_comparator_stop")
  }
  if (!identical(as.character(profile$classification$carried_policy_status), "not_run") ||
    !nzchar(as.character(profile$classification$carried_policy_reason)) ||
    !identical(as.logical(profile$classification$dominant_cause_claim), FALSE)) {
    goal004_abort("The optional carried contrast or classification contract is invalid.", "herbivoreTTR_goal004_profile_invalid")
  }
  artefacts <- as.character(unlist(profile$outputs$artefact_names, use.names = FALSE))
  expected <- c(
    "run_manifest.json", "baseline_projection.csv", "baseline_daily_diagnostics.csv",
    "baseline_plant_diagnostics.csv", "baseline_diagnostic_summary.json", "hourly_queue_ledger.csv",
    "daily_energy_budget.csv", "minute_intake_limits.csv", "probe_comparison.csv", "probe_invariants.csv",
    "probe_state_snapshots.rds", "classification_summary.json", "energy_budget_diagnostics.png"
  )
  if (!identical(artefacts, expected)) goal004_abort("Goal 004 artefact names are not stable.", "herbivoreTTR_goal004_profile_invalid")
  profile$runtime <- list(
    seed = 2002L, days = 120L, start_day = 6L, minute_limit = 720L,
    forage_access_scale = 1, plant_backend = "internal_ttr", apply_growth = FALSE,
    daily_plant_reset = TRUE, completed_clock_extra_ticks = 12L, serialization_version = 3L
  )
  profile$outputs$artefact_names <- artefacts
  profile
}

goal004_projection <- function(herbivore, plants, daily_output = NULL, rng = goal004_rng()) {
  hf <- goal004_herbivore_fields()
  pf <- goal004_plant_fields()
  if (any(!hf %in% names(herbivore))) goal004_abort("Herbivore projection field is absent.")
  if (any(!pf %in% names(plants))) goal004_abort("Plant projection field is absent.")
  h <- herbivore[hf]
  h$digestion <- stats::setNames(lapply(goal004_queue_names(), function(nm) {
    normalize_digestion_queue(h$digestion[[nm]], h$MRT)
  }), goal004_queue_names())
  h$feedback_settings <- h$feedback_settings[c(
    "enabled", "initial_bci", "gain_coeff", "loss_coeff",
    "effort_threshold", "stress_threshold", "max_foraging_boost"
  )]
  h$seeded_draws <- h$seeded_draws[c("initial_xcor_draw_m", "initial_ycor_draw_m", "seed", "coordinate_resolution")]
  p <- plants[, pf, drop = FALSE]
  d <- if (is.null(daily_output)) NULL else daily_output[, goal004_daily_fields(), drop = FALSE]
  list(
    herbivore = h, plants = p, daily_output = d,
    rng = if (is.null(rng)) NULL else as.integer(rng),
    constants = stats::setNames(
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
  )
}

goal004_projection_hashes <- function(x) {
  c(
    herbivore_state_sha256 = goal004_sha256(x$herbivore), plant_state_sha256 = goal004_sha256(x$plants),
    daily_output_sha256 = goal004_sha256(x$daily_output), rng_sha256 = goal004_sha256(x$rng)
  )
}

goal004_structure_attributes <- function(x) {
  a <- attributes(x)
  a$names <- NULL
  a
}

goal004_changed_paths <- function(a, b, path = "") {
  if (identical(a, b)) {
    return(character())
  }
  if (!identical(typeof(a), typeof(b)) || !identical(length(a), length(b)) || !identical(names(a), names(b))) {
    return(paste0(path, ".__structure__"))
  }
  out <- if (!identical(goal004_structure_attributes(a), goal004_structure_attributes(b))) paste0(path, ".__attributes__") else character()
  if (is.list(a)) {
    for (j in seq_along(a)) {
      label <- if (!is.null(names(a))) names(a)[[j]] else paste0("[[", j, "]]")
      child <- if (nzchar(path)) paste(path, label, sep = ".") else label
      out <- c(out, goal004_changed_paths(a[[j]], b[[j]], child))
    }
    return(unique(out))
  }
  for (j in seq_along(a)) if (!identical(a[[j]], b[[j]])) out <- c(out, if (length(a) == 1L) path else paste0(path, "[", j, "]"))
  unique(out)
}

goal004_first_changed_value <- function(expected, observed, path) {
  if (identical(expected, observed)) {
    return(NULL)
  }
  if (!identical(typeof(expected), typeof(observed)) ||
    !identical(length(expected), length(observed)) ||
    !identical(names(expected), names(observed))) {
    return(list(
      path = paste0(path, ".__structure__"),
      expected = expected, observed = observed
    ))
  }
  if (!identical(
    goal004_structure_attributes(expected),
    goal004_structure_attributes(observed)
  )) {
    return(list(
      path = paste0(path, ".__attributes__"),
      expected = goal004_structure_attributes(expected),
      observed = goal004_structure_attributes(observed)
    ))
  }
  if (is.list(expected)) {
    for (j in seq_along(expected)) {
      label <- if (!is.null(names(expected))) names(expected)[[j]] else paste0("[[", j, "]]")
      child <- if (nzchar(path)) paste(path, label, sep = ".") else label
      found <- goal004_first_changed_value(expected[[j]], observed[[j]], child)
      if (!is.null(found)) {
        return(found)
      }
    }
    return(NULL)
  }
  for (j in seq_along(expected)) {
    if (!identical(expected[[j]], observed[[j]])) {
      return(list(
        path = if (length(expected) == 1L) path else paste0(path, "[", j, "]"),
        expected = expected[[j]], observed = observed[[j]]
      ))
    }
  }
  NULL
}

goal004_first_divergence <- function(expected, observed, phase = NA_character_) {
  roots <- c("herbivore", "plants", "daily_output", "rng", "constants")
  if (!identical(names(expected), roots) || !identical(names(observed), roots)) {
    goal004_abort("Projection roots are not in the accepted order.", "herbivoreTTR_goal004_probe_stop")
  }
  for (root in roots) {
    found <- goal004_first_changed_value(expected[[root]], observed[[root]], root)
    if (!is.null(found)) {
      return(list(
        phase = phase, root = root, path = found$path,
        expected = found$expected, observed = found$observed,
        expected_hash = goal004_sha256(found$expected),
        observed_hash = goal004_sha256(found$observed),
        expected_state_hash = goal004_sha256(expected[[root]]),
        observed_state_hash = goal004_sha256(observed[[root]]),
        expected_rng_hash = goal004_sha256(expected$rng),
        observed_rng_hash = goal004_sha256(observed$rng)
      ))
    }
  }
  NULL
}

goal004_invariant_pass <- function(row) {
  if (!is.data.frame(row) || nrow(row) != 1L) {
    return(FALSE)
  }
  relation <- as.character(row$expected_relation[[1L]])
  if (identical(relation, "identical")) {
    identical(as.character(row$expected_sha256[[1L]]), as.character(row$observed_sha256[[1L]]))
  } else if (identical(relation, "equal")) {
    isTRUE(all.equal(row$expected_value[[1L]], row$observed_value[[1L]]))
  } else if (identical(relation, "allowed_difference")) {
    nzchar(as.character(row$expected_value[[1L]])) && nzchar(as.character(row$observed_value[[1L]]))
  } else {
    FALSE
  }
}

goal004_assert_invariants <- function(rows) {
  if (!is.data.frame(rows) || !nrow(rows) || any(!vapply(seq_len(nrow(rows)), function(i) {
    goal004_invariant_pass(rows[i, , drop = FALSE])
  }, logical(1)))) {
    goal004_abort("A required Goal 004 invariant failed.", "herbivoreTTR_goal004_probe_stop")
  }
  invisible(TRUE)
}

goal004_scale_tolerance <- function(values) 64 * .Machine$double.eps * max(1, sum(abs(as.numeric(values))))

goal004_values_close <- function(expected, observed) {
  expected <- as.numeric(expected)
  observed <- as.numeric(observed)
  length(expected) == length(observed) &&
    all(is.finite(expected)) && all(is.finite(observed)) &&
    all(abs(expected - observed) <=
      64 * .Machine$double.eps * pmax(1, abs(expected) + abs(observed)))
}

goal004_queue_transition <- function(opening, insertion, mrt, normalization = 0, resizing = 0) {
  k <- as.integer(mrt)
  opening <- as.numeric(opening)
  insertion <- as.numeric(insertion)
  if (length(opening) != k || length(insertion) != k || k < 1L) {
    goal004_abort("Queue transition length does not match MRT.", "herbivoreTTR_goal004_ledger_stop")
  }
  adjustment <- function(x) {
    x <- as.numeric(x)
    if (length(x) == 1L) {
      rep(x, k)
    } else if (length(x) == k) {
      x
    } else {
      goal004_abort("Queue adjustment length does not match MRT.", "herbivoreTTR_goal004_ledger_stop")
    }
  }
  normalization <- adjustment(normalization)
  resizing <- adjustment(resizing)
  pre <- opening + insertion + normalization + resizing
  release <- rep(0, length(pre))
  release[length(pre)] <- pre[length(pre)]
  post <- c(0, pre[seq_len(length(pre) - 1L)])
  list(
    opening = opening, insertion = insertion, pre_tick = pre, normalization = normalization,
    resizing = resizing, terminal_release = release, post_tick = post,
    residual = sum(pre) - sum(release) - sum(post), tolerance = goal004_scale_tolerance(c(pre, release, post))
  )
}

goal004_energy_from_terminal <- function(terminal) {
  terminal_names <- names(terminal)
  terminal <- as.numeric(terminal)
  names(terminal) <- terminal_names
  if (is.null(names(terminal))) {
    16.7 * sum(terminal[seq_len(min(2L, length(terminal)))]) +
      23.0 * sum(terminal[seq.int(3L, min(5L, length(terminal)))])
  } else {
    16.7 * sum(terminal[c("dc_leaf", "dc_stem")]) + 23.0 * sum(terminal[c("dp_leaf", "dp_stem", "dp_def")])
  }
}

goal004_bite_limits <- function(herbivore, plant) {
  bleaf <- ifelse(is.finite(plant$bleaf), plant$bleaf, 0)
  bstem <- ifelse(is.finite(plant$bstem), plant$bstem, 0)
  bdef <- ifelse(is.finite(plant$bdef), plant$bdef, 0)
  total <- bleaf + bstem + bdef
  prop_def <- if (total > 0) max(min(bdef / total, 1), 0) else 0
  handling <- if (is.finite(herbivore$handling_time) && herbivore$handling_time > 0) {
    (1 / herbivore$handling_time / 1000) * (1 - prop_def)
  } else {
    0
  }
  capacity <- max((herbivore$gut_capacity - herbivore$gut_content) / 1000, 0)
  forage <- max(total - max(CONSTANTS$MIN_SHOOT, 0), 0)
  mechanical <- max(CONSTANTS$MAX_BITE_FRACTION, 0) * herbivore$gut_capacity / 1000
  limits <- c(handling = handling, capacity = capacity, forage = forage, mechanical = mechanical)
  winner <- names(limits)[which.min(limits)]
  tie <- names(limits)[abs(limits - min(limits)) <= 64 * .Machine$double.eps * max(1, sum(abs(limits)))]
  list(
    handling = handling, capacity = capacity, forage = forage, mechanical = mechanical,
    winner = winner, tie_mask = paste(tie, collapse = "|"), winning = min(limits)
  )
}

goal004_classify_no_bite <- function(positive_intake, eligible, limits = NULL,
                                     behaviour_pre = NA_character_,
                                     behaviour_post = NA_character_,
                                     selected_pre = NA_integer_,
                                     selected_post = NA_integer_) {
  if (!isTRUE(eligible)) {
    return("foraging_window")
  }
  if (isTRUE(positive_intake)) {
    return("positive_bite")
  }
  if (is.null(limits)) {
    return("nonpositive_limit")
  }

  raw_limits <- as.numeric(unlist(limits[
    c("handling", "capacity", "forage", "mechanical")
  ], use.names = FALSE))
  if (length(raw_limits) != 4L || any(!is.finite(raw_limits))) {
    return("invalid_limit_evidence")
  }
  if (min(raw_limits) <= 0) {
    return("nonpositive_limit")
  }
  if (is.na(selected_pre) || is.na(selected_post) ||
    identical(behaviour_pre, "MOVING") || identical(behaviour_post, "MOVING")) {
    return("movement_or_targeting")
  }
  if (!identical(behaviour_pre, "EATING")) {
    return("behaviour_not_eating")
  }
  "other_production_gate"
}

goal004_direct_capacity_check <- function(herbivore, plants) {
  goal004_abort("Capacity replay requires valid herbivore and plant clones.")
}

goal004_daily_record <- function(h, minute = NA_integer_) {
  list(
    minute = as.integer(minute), xcor = h$xcor, ycor = h$ycor, gut_content = h$gut_content,
    selected_plant_id = h$selected_plant_id, behaviour = h$behaviour,
    energy_balance = h$energy_balance, water_balance = h$water_balance,
    distance_moved = h$distance_moved, intake_total_day = h$intake_total_day,
    intake_pe_day = h$intake_PE_day, intake_npe_day = h$intake_NPE_day,
    intake_water_forage = h$intake_water_forage, intake_water_drink = h$intake_water_drinking
  )
}

goal004_projection_record <- function(branch, day, minute, phase, h, p, daily_output = NULL, rng = goal004_rng()) {
  hashes <- goal004_projection_hashes(goal004_projection(h, p, daily_output, rng))
  cbind(
    data.frame(
      branch = as.character(branch), Day = as.integer(day), minute = as.integer(minute),
      phase = as.character(phase), stringsAsFactors = FALSE, check.names = FALSE
    ),
    as.data.frame(as.list(hashes), stringsAsFactors = FALSE, check.names = FALSE)
  )
}

goal004_observer_checkpoint <- function(day, minute, phase, h, p, daily_output = NULL,
                                        events = list(), event = NULL,
                                        branch = "observer",
                                        trajectory_id = "observer_replay",
                                        rng = NULL) {
  current_rng <- if (is.null(rng)) goal004_rng() else rng
  current <- goal004_projection(h, p, daily_output, current_rng)
  hashes <- goal004_projection_hashes(current)
  if (!is.null(event)) events[[length(events) + 1L]] <- event
  row <- data.frame(
    Day = as.integer(day), minute = as.integer(minute), phase = as.character(phase),
    herbivore_state_sha256 = unname(hashes[["herbivore_state_sha256"]]),
    plant_state_sha256 = unname(hashes[["plant_state_sha256"]]),
    daily_output_sha256 = unname(hashes[["daily_output_sha256"]]),
    rng_sha256 = unname(hashes[["rng_sha256"]]),
    observer_projection_identical = NA,
    observer_rng_identical = NA,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  row <- cbind(
    branch = as.character(branch),
    trajectory_id = as.character(trajectory_id), row
  )
  list(rows = row, events = events, projection = current, rng = current_rng)
}

goal004_close_day <- function(h, p, conditions, day_of_simulation, backend) {
  p <- backend$apply_herbivory(p)
  today_temp <- conditions$temp_mean[((day_of_simulation - 1L) %% nrow(conditions)) + 1L]
  h$daily_water_requirement <- calc_water_requirement(h$mass) *
    (1 + CONSTANTS$TEMP_WATER_SCALING * (today_temp - 20))
  h <- check_daily_water_balance(h)
  h <- calc_daily_energy_balance(h)
  h <- update_herbivore_daily_diagnostics(h)
  list(herbivore = h, plants = p)
}

goal004_run_day <- function(herbivore, plants, conditions, day_of_simulation, day_seed,
                            minute_limit, apply_growth, plant_backend, forage_access_scale,
                            observer = FALSE) {
  with_optional_seed(day_seed, {
    backend <- resolve_plant_backend(plant_backend)
    day_index <- ((day_of_simulation - 1L) %% nrow(conditions)) + 1L
    today_temp <- conditions$temp_mean[day_index]
    diagnostics <- list(
      plants_start = plants, day_of_simulation = day_of_simulation,
      plant_backend = backend$name
    )
    if (isTRUE(apply_growth)) {
      plants <- backend$step_day(plants, conditions, day_index)
      diagnostics$plants_after_growth <- plants
    }
    assert_domain_sanity_state(plants, herbivore,
      day_of_simulation = day_of_simulation,
      minute_of_day = 0L, phase = if (apply_growth) "post_growth" else "pre_foraging",
      check_plants = TRUE, check_herbivore = FALSE
    )
    h <- reset_daily_variables(herbivore)
    h <- calc_foraging_traits(h)
    h <- apply_body_condition_feedback(h, minute_limit)
    access_scale <- as.numeric(forage_access_scale)
    if (!is.finite(access_scale) || access_scale <= 0 || access_scale > 1) access_scale <- 1
    h$forage_access_scale <- access_scale
    h$time_spent_foraging <- h$time_spent_foraging * access_scale
    diagnostics$herbivore_start <- h
    assert_domain_sanity_state(plants, h,
      day_of_simulation = day_of_simulation,
      minute_of_day = 0L, phase = "start_of_day"
    )
    h$MRT <- resolve_mrt_hours(h$MRT)
    qn <- goal004_queue_names()
    qlen <- if (is.list(h$digestion)) vapply(qn, function(nm) length(h$digestion[[nm]]), integer(1)) else integer()
    if (length(qlen) != length(qn) || any(qlen != h$MRT)) h <- set_herbivore_MRT(h, h$MRT, preserve_content = TRUE)
    h$daily_water_requirement <- calc_water_requirement(h$mass)
    daily_record <- vector("list", minute_limit)
    phase_rows <- list()
    queue_rows <- list()
    limit_rows <- list()
    events <- list()
    tick_index <- 0L
    interval_opening <- stats::setNames(lapply(qn, function(nm) as.numeric(h$digestion[[nm]])), qn)
    pending_insertions <- stats::setNames(lapply(qn, function(nm) numeric(h$MRT)), qn)
    endpoint_719 <- NULL
    trajectory_branch <- if (isTRUE(observer)) "observer" else "bare_control"
    trajectory_id <- if (isTRUE(observer)) "observer_replay" else "bare_control_replay"
    add_phase <- function(minute, phase, hh, pp, daily_output = NULL, event = NULL) {
      capture <- goal004_observer_checkpoint(
        day_of_simulation - 5L, minute, phase, hh, pp, daily_output,
        events = events,
        event = if (isTRUE(observer)) event else NULL,
        branch = trajectory_branch,
        trajectory_id = trajectory_id
      )
      events <<- capture$events
      phase_rows[[length(phase_rows) + 1L]] <<- capture$rows
    }
    add_phase(0L, "daily_opening", h, plants)
    spin_up_days <- CONSTANTS$SPIN_UP_LENGTH * nrow(conditions)
    herbivory_active <- isTRUE(CONSTANTS$HERBIVORY != 0) && day_of_simulation > spin_up_days
    eligible_index <- 0L
    if (herbivory_active) {
      for (minute in seq_len(minute_limit)) {
        h <- update_gut_content(h)
        before_h <- goal004_clone(h)
        eligible <- minute < h$time_spent_foraging * 60
        if (eligible) {
          eligible_index <- eligible_index + 1L
          selected <- h$selected_plant_id
          target <- if (!is.na(selected)) plants[plants$plant_id == selected, , drop = FALSE] else plants[1L, , drop = FALSE]
          if (!nrow(target)) target <- plants[1L, , drop = FALSE]
          limits <- goal004_bite_limits(h, target)
          rng_pre <- goal004_rng()
          step_result <- herbivore_step(h, plants)
          rng_post <- goal004_rng()
          h <- step_result$herbivore
          plants <- step_result$plants
          insertion <- stats::setNames(lapply(qn, function(nm) {
            as.numeric(h$digestion[[nm]]) - as.numeric(before_h$digestion[[nm]])
          }), qn)
          for (nm in qn) pending_insertions[[nm]] <- pending_insertions[[nm]] + insertion[[nm]]
          actual <- h$intake_total_day - before_h$intake_total_day
          reason <- goal004_classify_no_bite(
            positive_intake = actual > 0, eligible = TRUE, limits = limits,
            behaviour_pre = before_h$behaviour, behaviour_post = h$behaviour,
            selected_pre = before_h$selected_plant_id,
            selected_post = h$selected_plant_id
          )
          limit_rows[[length(limit_rows) + 1L]] <- data.frame(
            branch = if (observer) "baseline" else "baseline", Day = as.integer(day_of_simulation - 5L),
            minute = as.integer(minute), tick_index_day = as.integer(ceiling(minute / 60)),
            opportunity_index = as.integer(eligible_index), eligible = TRUE, positive_intake = actual > 0,
            selected_plant_id = as.integer(if (is.na(h$selected_plant_id)) -1L else h$selected_plant_id),
            gut_content_pre_g = before_h$gut_content, gut_content_post_g = h$gut_content,
            intake_increment_g = actual, handling_limit_kg = limits$handling, capacity_limit_kg = limits$capacity,
            forage_limit_kg = limits$forage, mechanical_limit_kg = limits$mechanical,
            winning_limit = limits$winner, tie_mask = limits$tie_mask, no_bite_reason = reason,
            plant_available_nonbinding = isTRUE(limits$forage > 0) &&
              isTRUE(limits$forage > min(unlist(limits[c("handling", "capacity", "mechanical")]))),
            rng_pre_sha256 = goal004_sha256(rng_pre), rng_post_sha256 = goal004_sha256(rng_post),
            stringsAsFactors = FALSE, check.names = FALSE
          )
          limit_rows[[length(limit_rows)]] <- cbind(
            limit_rows[[length(limit_rows)]],
            as.data.frame(as.list(stats::setNames(
              vapply(qn, function(nm) sum(insertion[[nm]]), numeric(1)),
              paste0("insert_", qn, "_g")
            )), check.names = FALSE)
          )
        } else {
          limit_rows[[length(limit_rows) + 1L]] <- data.frame(
            branch = "baseline", Day = as.integer(day_of_simulation - 5L), minute = as.integer(minute),
            tick_index_day = as.integer(ceiling(minute / 60)), opportunity_index = as.integer(eligible_index),
            eligible = FALSE, positive_intake = FALSE, selected_plant_id = -1L,
            gut_content_pre_g = h$gut_content, gut_content_post_g = h$gut_content, intake_increment_g = 0,
            handling_limit_kg = 0, capacity_limit_kg = max((h$gut_capacity - h$gut_content) / 1000, 0),
            forage_limit_kg = 0, mechanical_limit_kg = max(CONSTANTS$MAX_BITE_FRACTION, 0) * h$gut_capacity / 1000,
            winning_limit = "foraging_window", tie_mask = "", no_bite_reason = "foraging_window",
            plant_available_nonbinding = FALSE,
            rng_pre_sha256 = goal004_sha256(goal004_rng()), rng_post_sha256 = goal004_sha256(goal004_rng()),
            stringsAsFactors = FALSE, check.names = FALSE
          )
          limit_rows[[length(limit_rows)]] <- cbind(
            limit_rows[[length(limit_rows)]],
            as.data.frame(as.list(stats::setNames(rep(0, length(qn)), paste0("insert_", qn, "_g"))),
              check.names = FALSE
            )
          )
        }
        if (eligible) {
          add_phase(
            minute, "minute_post_step_pre_tick", h, plants,
            event = list(
              day = day_of_simulation - 5L, minute = minute,
              type = "behaviour_step"
            )
          )
        }
        if (minute == 719L) {
          endpoint_719 <- list(
            herbivore = goal004_clone(h), plants = goal004_clone(plants), rng = goal004_rng()
          )
        }
        if (minute %% 60L == 0L) {
          tick_index <- tick_index + 1L
          pre_tick <- goal004_clone(h)
          rng_pre_tick <- goal004_rng()
          h <- hourly_digestion_step(h)
          rng_post_tick <- goal004_rng()
          post_tick <- goal004_clone(h)
          for (nm in qn) {
            tr <- goal004_queue_transition(interval_opening[[nm]], pending_insertions[[nm]], h$MRT)
            actual_pre <- as.numeric(pre_tick$digestion[[nm]])
            tr$insertion <- actual_pre - tr$opening
            tr$pre_tick <- actual_pre
            tr$terminal_release <- rep(0, length(actual_pre))
            tr$terminal_release[length(actual_pre)] <- actual_pre[length(actual_pre)]
            tr$post_tick <- as.numeric(post_tick$digestion[[nm]])
            tr$residual <- sum(tr$pre_tick) - sum(tr$terminal_release) - sum(tr$post_tick)
            interval_rows <- which(vapply(limit_rows, function(x) {
              identical(x$tick_index_day[[1L]], as.integer(tick_index))
            }, logical(1)))
            eligible_rows <- interval_rows[vapply(limit_rows[interval_rows], function(x) {
              isTRUE(x$eligible[[1L]])
            }, logical(1))]
            insertion_column <- paste0("insert_", nm, "_g")
            recorded_insertion <- sum(vapply(limit_rows[interval_rows], function(x) {
              as.numeric(x[[insertion_column]][[1L]])
            }, numeric(1)))
            insertion_remainder <- sum(tr$insertion) - recorded_insertion
            if (length(eligible_rows) && insertion_remainder != 0) {
              last_eligible <- tail(eligible_rows, 1L)
              limit_rows[[last_eligible]][[insertion_column]] <-
                limit_rows[[last_eligible]][[insertion_column]] + insertion_remainder
            } else if (!length(eligible_rows) && insertion_remainder != 0) {
              goal004_abort(
                "Queue insertion cannot be attributed to an eligible bite.",
                "herbivoreTTR_goal004_ledger_stop"
              )
            }
            queue_rows[[length(queue_rows) + 1L]] <- data.frame(
              branch = if (observer) "baseline" else "baseline", Day = as.integer(day_of_simulation - 5L),
              model_day = as.integer(day_of_simulation), tick_index_day = as.integer(tick_index),
              elapsed_minute = as.integer(tick_index * 60L), queue_name = nm, slot = seq_len(h$MRT),
              opening_slot = tr$opening, bite_insertion_slot = tr$insertion,
              pre_tick_slot = tr$pre_tick, normalization_adjustment_slot = tr$normalization,
              resizing_adjustment_slot = tr$resizing, terminal_release_raw = tr$terminal_release,
              post_tick_slot = tr$post_tick, rng_pre_sha256 = goal004_sha256(rng_pre_tick),
              rng_post_sha256 = goal004_sha256(rng_post_tick), stringsAsFactors = FALSE, check.names = FALSE
            )
          }
          interval_opening <- stats::setNames(lapply(qn, function(nm) as.numeric(post_tick$digestion[[nm]])), qn)
          pending_insertions <- stats::setNames(lapply(qn, function(nm) numeric(h$MRT)), qn)
          add_phase(minute, "hourly_tick_pre", pre_tick, plants)
          add_phase(minute, "hourly_tick_post", post_tick, plants,
            event = list(
              day = day_of_simulation - 5L, minute = minute,
              type = "digestion_tick"
            )
          )
        }
        assert_domain_sanity_state(plants, h,
          day_of_simulation = day_of_simulation,
          minute_of_day = as.integer(minute), phase = "minute_loop"
        )
        daily_record[[minute]] <- goal004_daily_record(h, minute)
      }
    }
    checkpoint_h <- goal004_clone(h)
    checkpoint_p <- goal004_clone(plants)
    add_phase(minute_limit, "minute_720_preclosure", checkpoint_h, checkpoint_p)
    closed <- goal004_close_day(h, plants, conditions, day_of_simulation, backend)
    h <- closed$herbivore
    plants <- closed$plants
    diagnostics$herbivore_end <- h
    diagnostics$plants_end <- plants
    list(
      herbivore = h, plants = plants, checkpoint_herbivore = checkpoint_h,
      checkpoint_plants = checkpoint_p, daily_record = daily_record, diagnostics = diagnostics,
      daily_summary = list(day_of_simulation = day_of_simulation, today_temp = today_temp),
      phase_rows = phase_rows, queue_rows = queue_rows,
      limit_rows = limit_rows, events = events,
      endpoint_719 = endpoint_719, exit_rng = goal004_rng()
    )
  })
}

goal004_apply_completed_clock <- function(h, n = 12L) {
  out <- goal004_clone(h)
  for (i in seq_len(n)) out <- hourly_digestion_step(out)
  out
}

goal004_capacity_replay <- function(herbivore, plants, opportunities = 720L, branch = "capacity_unticked", day = 1L) {
  if (!is.list(herbivore) || !is.data.frame(plants)) goal004_abort("Capacity replay requires valid herbivore and plant clones.")
  h <- goal004_clone(herbivore)
  p <- goal004_clone(plants)
  h$selected_plant_id <- 1L
  h$behaviour <- "EATING"
  rows <- vector("list", opportunities)
  start_total <- h$intake_total_day
  start_gut <- h$gut_content
  start_rng <- goal004_rng()
  for (opportunity in seq_len(opportunities)) {
    before_h <- goal004_clone(h)
    before_p <- goal004_clone(p)
    plant <- p[p$plant_id == 1L, , drop = FALSE]
    if (nrow(plant) != 1L) goal004_abort("Capacity replay target plant 1 is absent.", "herbivoreTTR_goal004_probe_stop")
    limits <- goal004_bite_limits(h, plant)
    rng_pre <- goal004_rng()
    result <- herbivore_eat(h, p)
    h <- result$herbivore
    p <- result$plants
    rng_post <- goal004_rng()
    inc <- h$intake_total_day - before_h$intake_total_day
    ins <- stats::setNames(lapply(goal004_queue_names(), function(nm) {
      sum(h$digestion[[nm]] - before_h$digestion[[nm]])
    }), goal004_queue_names())
    rows[[opportunity]] <- data.frame(
      branch = branch, Day = as.integer(day), minute = as.integer(opportunity), tick_index_day = 0L,
      opportunity_index = as.integer(opportunity), eligible = TRUE, positive_intake = inc > 0,
      selected_plant_id = 1L, gut_content_pre_g = before_h$gut_content, gut_content_post_g = h$gut_content,
      intake_increment_g = inc, handling_limit_kg = limits$handling, capacity_limit_kg = limits$capacity,
      forage_limit_kg = limits$forage, mechanical_limit_kg = limits$mechanical,
      winning_limit = limits$winner, tie_mask = limits$tie_mask,
      no_bite_reason = goal004_classify_no_bite(
        inc > 0, TRUE,
        limits = limits,
        behaviour_pre = before_h$behaviour, behaviour_post = h$behaviour,
        selected_pre = before_h$selected_plant_id,
        selected_post = h$selected_plant_id
      ),
      plant_available_nonbinding = isTRUE(limits$forage > 0) &&
        isTRUE(limits$forage > min(unlist(limits[c("handling", "capacity", "mechanical")]))),
      rng_pre_sha256 = goal004_sha256(rng_pre), rng_post_sha256 = goal004_sha256(rng_post),
      stringsAsFactors = FALSE, check.names = FALSE
    )
    rows[[opportunity]] <- cbind(rows[[opportunity]], as.data.frame(as.list(stats::setNames(
      vapply(goal004_queue_names(), function(nm) sum(h$digestion[[nm]] - before_h$digestion[[nm]]), numeric(1)),
      paste0("insert_", goal004_queue_names(), "_g")
    )), check.names = FALSE))
    if (!identical(before_p$plant_id, p$plant_id) || !identical(before_p$qshoot > 0, p$qshoot > 0)) {
      goal004_abort("Capacity replay changed plant identity or validity.", "herbivoreTTR_goal004_probe_stop")
    }
  }
  end_rng <- goal004_rng()
  if (!identical(start_rng, end_rng)) goal004_abort("Capacity replay consumed RNG.", "herbivoreTTR_goal004_probe_stop")
  list(
    herbivore = h, plants = p, rows = do.call(rbind, rows), opening_gut = start_gut,
    opening_total = start_total, final_vacancy = h$gut_capacity - h$gut_content,
    plant_drawdown = plants$ms[plants$plant_id == 1L] - p$ms[p$plant_id == 1L],
    rng_unchanged = identical(start_rng, end_rng), opening_rng = start_rng, exit_rng = end_rng
  )
}
