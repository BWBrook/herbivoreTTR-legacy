#!/usr/bin/env Rscript

goal002_source_helpers <- function() {
  if (exists("init_herbivore", mode = "function", inherits = TRUE) &&
      exists("run_daily_herbivore_simulation", mode = "function", inherits = TRUE)) {
    return(invisible(TRUE))
  }

  script_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", script_args, value = TRUE)
  script_path <- if (length(file_arg) > 0L) sub("^--file=", "", file_arg[[1]]) else NA_character_
  repo_root <- if (!is.na(script_path)) {
    normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
  } else {
    normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  }

  r_files <- sort(list.files(file.path(repo_root, "R"), pattern = "\\.R$", full.names = TRUE))
  for (path in r_files) {
    sys.source(path, envir = .GlobalEnv)
  }
  invisible(TRUE)
}

goal002_source_helpers()

goal002_abort <- function(message, class, ...) {
  if (requireNamespace("rlang", quietly = TRUE)) {
    rlang::abort(message, class = class, ...)
  }
  stop(message, call. = FALSE)
}

read_goal002_profile <- function(path) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path) || !file.exists(path)) {
    goal002_abort("Goal 002 profile path does not exist.", "herbivoreTTR_goal002_profile_missing")
  }
  if (!requireNamespace("yaml", quietly = TRUE)) {
    goal002_abort("Package `yaml` is required for the Goal 002 profile.", "herbivoreTTR_goal002_yaml_missing")
  }
  yaml::read_yaml(normalizePath(path, winslash = "/", mustWork = TRUE))
}

goal002_scalar <- function(x, name, integer = FALSE) {
  value <- if (integer) as.integer(x) else as.numeric(x)
  if (length(value) != 1L || !is.finite(value)) {
    goal002_abort(sprintf("Goal 002 profile field `%s` must be one finite scalar.", name),
                 "herbivoreTTR_goal002_profile_invalid")
  }
  value
}

validate_goal002_profile <- function(profile) {
  required <- c("goal_id", "profile_schema_version", "runtime", "population",
                "external_forcing", "forage", "initial_plant_state", "feedback",
                "stochasticity", "outputs")
  if (!is.list(profile) || any(!required %in% names(profile))) {
    goal002_abort("Goal 002 profile is incomplete.", "herbivoreTTR_goal002_profile_invalid")
  }
  if (!identical(as.character(profile$goal_id), "002-minimal-coupled-baseline-diagnosis") ||
      !identical(as.character(profile$profile_schema_version), "1.0.0")) {
    goal002_abort("Goal 002 profile identity or schema version is invalid.",
                 "herbivoreTTR_goal002_profile_invalid")
  }

  runtime <- profile$runtime
  seed <- goal002_scalar(runtime$seed, "runtime$seed", integer = TRUE)
  days <- goal002_scalar(runtime$days, "runtime$days", integer = TRUE)
  start_day <- goal002_scalar(runtime$start_day, "runtime$start_day", integer = TRUE)
  minute_limit <- goal002_scalar(runtime$minute_limit, "runtime$minute_limit", integer = TRUE)
  access_scale <- goal002_scalar(runtime$forage_access_scale, "runtime$forage_access_scale")
  if (!identical(seed, 2002L) || !identical(days, 120L) || !identical(start_day, 6L) ||
      !identical(minute_limit, 720L) || !identical(as.character(runtime$plant_backend), "internal_ttr") ||
      access_scale <= 0 || access_scale > 1) {
    goal002_abort("Goal 002 runtime contract is invalid.", "herbivoreTTR_goal002_profile_invalid")
  }

  population <- profile$population
  herb_count <- goal002_scalar(population$herbivore_count, "population$herbivore_count", integer = TRUE)
  herb <- population$herbivore
  if (!identical(as.character(population$mode), "explicit_single") ||
      !identical(herb_count, 1L) || !is.list(herb)) {
    goal002_abort("Goal 002 must contain exactly one explicit herbivore.",
                 "herbivoreTTR_goal002_profile_invalid")
  }
  if (!identical(as.character(herb$herbivore_id), "goal002_grazer_1") ||
      !identical(goal002_scalar(herb$mass_g, "population$herbivore$mass_g", integer = TRUE), 50000L) ||
      !identical(goal002_scalar(herb$herb_type, "population$herbivore$herb_type", integer = TRUE), 0L) ||
      !identical(goal002_scalar(herb$MRT_hours, "population$herbivore$MRT_hours", integer = TRUE), 24L) ||
      !is.logical(herb$empirical_parameterisation) || length(herb$empirical_parameterisation) != 1L ||
      is.na(herb$empirical_parameterisation) || !identical(herb$empirical_parameterisation, FALSE)) {
    goal002_abort("Goal 002 herbivore contract is invalid.", "herbivoreTTR_goal002_profile_invalid")
  }
  for (field in c("xcor_m", "ycor_m")) {
    value <- goal002_scalar(herb[[field]], paste0("population$herbivore$", field))
    if (value < 0 || value > sqrt(CONSTANTS$PLOT_SIZE)) {
      goal002_abort("Goal 002 herbivore coordinates are outside the plot.",
                   "herbivoreTTR_goal002_profile_invalid")
    }
  }

  forcing <- profile$external_forcing
  forcing_names <- c("temperature_c", "soil_water", "soil_nitrogen")
  if (!is.list(forcing) || !identical(names(forcing), forcing_names) ||
      any(!vapply(forcing, function(x) length(x) == 1L && is.finite(as.numeric(x)), logical(1)))) {
    goal002_abort("Goal 002 external forcing must be three finite scalar values.",
                 "herbivoreTTR_goal002_profile_invalid")
  }
  if (as.numeric(forcing$soil_water) < 0 || as.numeric(forcing$soil_nitrogen) < 0) {
    goal002_abort("Goal 002 soil forcing values must be non-negative.",
                 "herbivoreTTR_goal002_profile_invalid")
  }

  forage <- profile$forage
  forage_count <- goal002_scalar(forage$forage_type_count, "forage$forage_type_count", integer = TRUE)
  veg_types <- as.integer(unlist(forage$veg_types, use.names = FALSE))
  forage_empirical <- as.logical(forage$empirical_parameterisation)
  if (!identical(forage_count, 1L) || length(veg_types) != 1L || !identical(veg_types, 0L)) {
    goal002_abort("Goal 002 must contain exactly one homogeneous forage type.",
                 "herbivoreTTR_goal002_profile_invalid")
  }
  if (length(forage_empirical) != 1L || is.na(forage_empirical) || isTRUE(forage_empirical)) {
    goal002_abort("Goal 002 forage must remain explicitly non-empirical.",
                 "herbivoreTTR_goal002_profile_invalid")
  }

  plant <- profile$initial_plant_state
  plant_required <- c("plant_id", "xcor", "ycor", "veg_type", "ms", "mr", "cs", "cr", "ns", "nr",
                      "cd", "nd", "bleaf", "bstem", "bdef", "md", "broot", "brepr", "height",
                      "qroot", "qshoot", "gs", "gr", "gd", "uc", "un", "rsC", "rrC", "rdC",
                      "rsN", "rrN", "rdN", "tauC", "tauN", "tauCd", "tauNd")
  if (!is.list(plant) || any(!plant_required %in% names(plant)) ||
      !identical(goal002_scalar(plant$plant_id, "initial_plant_state$plant_id", integer = TRUE), 1L) ||
      !identical(goal002_scalar(plant$veg_type, "initial_plant_state$veg_type", integer = TRUE), 0L) ||
      any(!vapply(plant[plant_required], function(x) length(x) == 1L && is.finite(as.numeric(x)), logical(1)))) {
    goal002_abort("Goal 002 initial plant state is incomplete or invalid.",
                 "herbivoreTTR_goal002_profile_invalid")
  }
  if (goal002_scalar(plant$ms, "initial_plant_state$ms") < 0 ||
      goal002_scalar(plant$mr, "initial_plant_state$mr") < 0) {
    goal002_abort("Goal 002 initial plant biomass must be non-negative.",
                 "herbivoreTTR_goal002_profile_invalid")
  }

  feedback_required <- c("enabled", "initial_bci", "gain_coeff", "loss_coeff",
                         "effort_threshold", "stress_threshold", "max_foraging_boost")
  if (!is.list(profile$feedback) || any(!feedback_required %in% names(profile$feedback))) {
    goal002_abort("Goal 002 feedback settings are incomplete.", "herbivoreTTR_goal002_profile_invalid")
  }
  if (!is.logical(profile$feedback$enabled) || length(profile$feedback$enabled) != 1L ||
      is.na(profile$feedback$enabled) ||
      goal002_scalar(profile$feedback$initial_bci, "feedback$initial_bci") < 0 ||
      goal002_scalar(profile$feedback$initial_bci, "feedback$initial_bci") > 1) {
    goal002_abort("Goal 002 feedback settings are invalid.", "herbivoreTTR_goal002_profile_invalid")
  }

  artefacts <- as.character(unlist(profile$outputs$artefact_names, use.names = FALSE))
  expected_artefacts <- c("run_manifest.json", "daily_diagnostics.csv", "plant_diagnostics.csv",
                          "diagnostic_summary.json", "diagnostic_trajectories.png")
  if (!identical(artefacts, expected_artefacts)) {
    goal002_abort("Goal 002 artefact names do not match the runbook.",
                 "herbivoreTTR_goal002_profile_invalid")
  }

  list(
    goal_id = as.character(profile$goal_id),
    profile_schema_version = as.character(profile$profile_schema_version),
    description = as.character(profile$description),
    runtime = list(seed = seed, days = days, start_day = start_day,
                   minute_limit = minute_limit, forage_access_scale = access_scale,
                   plant_backend = as.character(runtime$plant_backend)),
    population = list(mode = as.character(population$mode), herbivore_count = herb_count,
                      herbivore = herb),
    external_forcing = list(temperature_c = as.numeric(forcing$temperature_c),
                            soil_water = as.numeric(forcing$soil_water),
                            soil_nitrogen = as.numeric(forcing$soil_nitrogen)),
    forage = list(forage_type_count = forage_count, veg_types = veg_types,
                  forage_type_label = as.character(forage$forage_type_label),
                  empirical_parameterisation = forage_empirical),
    initial_plant_state = plant,
    feedback = profile$feedback,
    stochasticity = profile$stochasticity,
    outputs = list(artefact_names = artefacts)
  )
}

resolved_goal002_forcing <- function(profile) {
  forcing <- profile$external_forcing
  list(
    temperature = as.numeric(forcing$temperature_c),
    soil_water = as.numeric(forcing$soil_water),
    soil_nitrogen = as.numeric(forcing$soil_nitrogen)
  )
}

goal002_initial_plants <- function(profile) {
  state <- profile$initial_plant_state
  numeric_fields <- setdiff(names(state), c("plant_id", "veg_type"))
  row <- as.list(state)
  row$plant_id <- as.integer(row$plant_id)
  row$veg_type <- as.integer(row$veg_type)
  for (field in numeric_fields) row[[field]] <- as.numeric(row[[field]])
  plants <- as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
  plants <- plants[, names(state), drop = FALSE]
  plants
}

goal002_missing_value_schema <- function(state) {
  has_missing <- vapply(
    state,
    function(value) is.atomic(value) && anyNA(value),
    logical(1)
  )
  lapply(state[has_missing], function(value) {
    list(
      r_type = typeof(value),
      length = length(value),
      missing_positions = as.integer(which(is.na(value)))
    )
  })
}

goal002_initial_state_json <- function(profile, herbivore, plants) {
  list(
    state_stage = "before_first_step",
    herbivore_id = herbivore$herbivore_id,
    mass_g = as.numeric(herbivore$mass),
    herb_type = as.integer(herbivore$herb_type),
    coordinates_m = list(xcor = as.numeric(herbivore$xcor), ycor = as.numeric(herbivore$ycor)),
    gut_content_g = as.numeric(herbivore$gut_content),
    gut_capacity_g = as.numeric(herbivore$gut_capacity),
    MRT_hours = as.integer(herbivore$MRT),
    digestion = herbivore$digestion,
    body_condition_index = as.numeric(herbivore$body_condition_index),
    behaviour = as.character(herbivore$behaviour),
    selected_plant_id = if (is.na(herbivore$selected_plant_id)) NULL else as.integer(herbivore$selected_plant_id),
    feedback_settings = herbivore$feedback_settings,
    foraging_mode = as.character(herbivore$foraging_mode),
    movement_disruption_prob = as.numeric(herbivore$movement_disruption_prob),
    seeded_draws = herbivore$seeded_draws,
    resolved_herbivore_state = herbivore,
    resolved_herbivore_state_missing_schema = goal002_missing_value_schema(herbivore),
    plant_state_stage = "before_first_step",
    plant_row = as.list(plants[1, , drop = FALSE]),
    total_shoot_biomass_kg = sum(plants$ms)
  )
}

resolve_goal002_initial_state <- function(profile) {
  herb_spec <- profile$population$herbivore
  herbivore <- with_optional_seed(profile$runtime$seed, {
    init_herbivore(
      mass = as.numeric(herb_spec$mass_g),
      herb_type = as.integer(herb_spec$herb_type),
      MRT = as.integer(herb_spec$MRT_hours),
      herbivore_id = as.character(herb_spec$herbivore_id)
    )
  })
  seeded_draws <- list(
    initial_xcor_draw_m = as.numeric(herbivore$xcor),
    initial_ycor_draw_m = as.numeric(herbivore$ycor),
    seed = as.integer(profile$runtime$seed),
    coordinate_resolution = "explicit_profile_values_replace_initial_draws"
  )
  herbivore$xcor <- as.numeric(herb_spec$xcor_m)
  herbivore$ycor <- as.numeric(herb_spec$ycor_m)
  herbivore$behaviour <- as.character(herb_spec$behaviour)
  herbivore$selected_plant_id <- NA_integer_
  herbivore$movement_disruption_prob <- as.numeric(herb_spec$movement_disruption_prob)
  herbivore$mixed_browser_weight <- as.numeric(herb_spec$mixed_browser_weight)
  herbivore$foraging_mode <- as.character(herb_spec$foraging_mode)
  herbivore <- apply_scenario_feedback_config(herbivore, profile$feedback)
  herbivore$feedback_settings <- profile$feedback
  herbivore$seeded_draws <- seeded_draws
  plants <- goal002_initial_plants(profile)
  assert_domain_sanity_state(plants, herbivore, day_of_simulation = profile$runtime$start_day,
                             phase = "goal002_initial_state")
  list(
    herbivore = goal002_initial_state_json(profile, herbivore, plants),
    plants = list(
      state_stage = "before_first_step",
      plant_row = as.list(plants[1, , drop = FALSE]),
      total_shoot_biomass_kg = sum(plants$ms)
    ),
    herbivore_state = herbivore,
    plants_state = plants
  )
}

goal002_total_shoot <- function(plants) sum(as.numeric(plants$ms))

goal002_daily_row <- function(day, model_day, day_seed, forcing, opening_herbivore, herbivore, daily_summary) {
  data.frame(
    Day = as.integer(day),
    model_day = as.integer(model_day),
    HerbivoreID = as.character(herbivore$herbivore_id),
    day_seed = as.integer(day_seed),
    temperature = as.numeric(forcing$temperature),
    soil_water = as.numeric(forcing$soil_water),
    soil_nitrogen = as.numeric(forcing$soil_nitrogen),
    opening_xcor_m = as.numeric(opening_herbivore$xcor),
    opening_ycor_m = as.numeric(opening_herbivore$ycor),
    xcor = as.numeric(herbivore$xcor),
    ycor = as.numeric(herbivore$ycor),
    opening_gut_content_g = as.numeric(opening_herbivore$gut_content),
    gut_content_g = as.numeric(herbivore$gut_content),
    gut_capacity_g = as.numeric(herbivore$gut_capacity),
    intake_total_g = as.numeric(herbivore$intake_total_day),
    intake_PE_kJ = as.numeric(herbivore$intake_PE_day),
    intake_NPE_kJ = as.numeric(herbivore$intake_NPE_day),
    energy_intake_kJ = as.numeric(herbivore$daily_energy_intake),
    total_energy_requirement_kJ = as.numeric(herbivore$total_energy_requirement_day),
    energy_delta_kJ = as.numeric(herbivore$daily_energy_delta),
    EnergyBalance = as.numeric(herbivore$energy_balance),
    cumulative_energy_balance_kJ = as.numeric(herbivore$energy_balance),
    metabolic_water_g = as.numeric(herbivore$metabolic_water_day),
    forage_water_g = as.numeric(herbivore$intake_water_forage),
    drinking_water_g = as.numeric(herbivore$intake_water_drinking),
    water_input_total_g = as.numeric(herbivore$daily_water_intake_total),
    water_requirement_g = as.numeric(herbivore$water_requirement_day),
    daily_net_water_g = as.numeric(herbivore$daily_net_water_balance),
    WaterBalance = as.numeric(herbivore$water_balance),
    cumulative_water_balance_g = as.numeric(herbivore$water_balance),
    distance_moved_m = as.numeric(herbivore$distance_moved),
    time_spent_foraging_h = as.numeric(herbivore$time_spent_foraging),
    EnergyDeficitStreakDays = as.integer(herbivore$energy_deficit_streak_days),
    WaterDeficitStreakDays = as.integer(herbivore$water_deficit_streak_days),
    BodyConditionIndex = as.numeric(herbivore$body_condition_index),
    PhysiologicalStressFlag = as.integer(herbivore$physiological_stress_flag),
    behaviour = as.character(herbivore$behaviour),
    selected_plant_id = as.integer(if (is.na(herbivore$selected_plant_id)) -1L else herbivore$selected_plant_id),
    stringsAsFactors = FALSE
  )
}

goal002_plant_row <- function(day, model_day, opening, after_growth, closing) {
  opening_ms <- goal002_total_shoot(opening)
  growth_ms <- goal002_total_shoot(after_growth)
  closing_ms <- goal002_total_shoot(closing)
  regeneration <- growth_ms - opening_ms
  removal <- growth_ms - closing_ms
  data.frame(
    Day = as.integer(day),
    model_day = as.integer(model_day),
    forage_type_count = 1L,
    opening_total_shoot_biomass_kg = opening_ms,
    ttr_net_regeneration_kg = regeneration,
    herbivore_removal_kg = removal,
    closing_total_shoot_biomass_kg = closing_ms,
    plant_accounting_residual_kg = opening_ms + regeneration - removal - closing_ms,
    opening_total_root_biomass_kg = sum(as.numeric(opening$mr)),
    closing_total_root_biomass_kg = sum(as.numeric(closing$mr)),
    stringsAsFactors = FALSE
  )
}

goal002_summary <- function(daily, plants, profile, configuration_sha256) {
  window_summary <- function(label, rows) {
    list(
      label = label,
      day_start = min(rows$Day),
      day_end = max(rows$Day),
      energy_delta_range_kJ = range(rows$energy_delta_kJ),
      water_net_range_g = range(rows$daily_net_water_g),
      body_condition_range = range(rows$BodyConditionIndex),
      plant_biomass_range_kg = range(plants$closing_total_shoot_biomass_kg[rows$Day]),
      stress_days = sum(rows$PhysiologicalStressFlag != 0L)
    )
  }
  n <- nrow(daily)
  energy_daily_residual <- daily$energy_intake_kJ - daily$total_energy_requirement_kJ -
    daily$energy_delta_kJ
  energy_cumulative_residual <- daily$cumulative_energy_balance_kJ -
    cumsum(daily$energy_delta_kJ)
  water_daily_residual <- daily$metabolic_water_g + daily$forage_water_g +
    daily$drinking_water_g - daily$water_requirement_g - daily$daily_net_water_g
  water_cumulative_residual <- daily$cumulative_water_balance_g -
    cumsum(daily$daily_net_water_g)
  windows <- list(
    first_window = window_summary("first descriptive window", daily[seq_len(floor(n / 3)), , drop = FALSE]),
    middle_window = window_summary("middle descriptive window", daily[(floor(n / 3) + 1L):(floor(2 * n / 3)), , drop = FALSE]),
    final_window = window_summary("final descriptive window", daily[(floor(2 * n / 3) + 1L):n, , drop = FALSE])
  )
  list(
    goal_id = profile$goal_id,
    interpretation_scope = "fixed-seed computational diagnostic; not ecological determinism, causality, equilibrium, or empirical kangaroo realism",
    configuration_sha256 = configuration_sha256,
    days = n,
    daily_coverage = list(first_day = min(daily$Day), last_day = max(daily$Day), rows = n),
    forcing_constancy = list(
      temperature_values = unique(daily$temperature),
      soil_water_values = unique(daily$soil_water),
      soil_nitrogen_values = unique(daily$soil_nitrogen)
    ),
    trajectory_windows = windows,
    stress_flag_days = sum(daily$PhysiologicalStressFlag != 0L),
    accounting_residual = list(
      energy_daily_identity_max_abs_kJ = max(abs(energy_daily_residual)),
      energy_cumulative_identity_max_abs_kJ = max(abs(energy_cumulative_residual)),
      water_daily_identity_max_abs_g = max(abs(water_daily_residual)),
      water_cumulative_identity_max_abs_g = max(abs(water_cumulative_residual)),
      plant_max_abs_kg = max(abs(plants$plant_accounting_residual_kg)),
      energy_definition = "daily_energy_intake_kJ - total_energy_requirement_kJ equals energy_delta_kJ; cumulative balance is model state",
      water_definition = "metabolic_water_g + forage_water_g + drinking_water_g - water_requirement_g equals daily_net_water_g",
      plant_definition = "opening biomass + net TTR regeneration - herbivore removal - closing biomass",
      unavailable_term = "gross TTR growth and gross litter loss are not separately exposed by the existing daily interface"
    )
  )
}

goal002_write_json <- function(object, path) {
  json <- jsonlite::toJSON(
    object,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null",
    digits = 17
  )
  writeLines(json, path, useBytes = TRUE)
}

goal002_hash_file <- function(path) digest::digest(file = path, algo = "sha256")

goal002_git_sha <- function(repo_root) {
  result <- tryCatch(
    system2("git", c("-C", repo_root, "rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE),
    error = function(e) character()
  )
  if (length(result) == 0L) "unavailable" else trimws(result[[1]])
}

run_goal002_minimal_diagnosis <- function(profile_path, output_dir) {
  if (file.exists(output_dir)) {
    goal002_abort("Goal 002 output directory must be absent before execution.",
                 "herbivoreTTR_goal002_output_exists")
  }
  if (!requireNamespace("digest", quietly = TRUE) || !requireNamespace("jsonlite", quietly = TRUE)) {
    goal002_abort("Goal 002 requires existing `digest` and `jsonlite` dependencies.",
                 "herbivoreTTR_goal002_dependency_missing")
  }

  profile <- validate_goal002_profile(read_goal002_profile(profile_path))
  configuration_json <- jsonlite::toJSON(profile, auto_unbox = TRUE, pretty = FALSE,
                                         null = "null", digits = 17)
  configuration_sha256 <- digest::digest(configuration_json, algo = "sha256", serialize = FALSE)
  forcing <- resolved_goal002_forcing(profile)
  conditions <- data.frame(
    day = 1L,
    temp_mean = forcing$temperature,
    sw = forcing$soil_water,
    N = forcing$soil_nitrogen
  )
  initial <- resolve_goal002_initial_state(profile)
  herbivore <- initial$herbivore_state
  plants <- initial$plants_state
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  daily_rows <- vector("list", profile$runtime$days)
  plant_rows <- vector("list", profile$runtime$days)
  for (i in seq_len(profile$runtime$days)) {
    day <- profile$runtime$start_day + i - 1L
    day_seed <- profile$runtime$seed + i * as.integer(profile$stochasticity$daily_seed_offset)
    opening_herbivore <- herbivore
    opening_plants <- plants
    result <- run_daily_herbivore_simulation(
      herbivore = herbivore,
      plants = plants,
      conditions = conditions,
      day_of_simulation = day,
      minute_limit = profile$runtime$minute_limit,
      capture_diagnostics = TRUE,
      seed = day_seed,
      apply_growth = TRUE,
      plant_backend = profile$runtime$plant_backend,
      forage_access_scale = profile$runtime$forage_access_scale
    )
    herbivore <- result$herbivore
    plants <- result$plants
    daily_rows[[i]] <- goal002_daily_row(i, day, day_seed, forcing, opening_herbivore,
                                         herbivore, result$daily_summary)
    plant_rows[[i]] <- goal002_plant_row(
      day = i,
      model_day = day,
      opening = result$diagnostics$plants_start,
      after_growth = result$diagnostics$plants_after_growth,
      closing = result$diagnostics$plants_end
    )
  }

  daily <- do.call(rbind, daily_rows)
  plants_daily <- do.call(rbind, plant_rows)
  rownames(daily) <- NULL
  rownames(plants_daily) <- NULL

  daily_path <- file.path(output_dir, "daily_diagnostics.csv")
  plant_path <- file.path(output_dir, "plant_diagnostics.csv")
  summary_path <- file.path(output_dir, "diagnostic_summary.json")
  figure_path <- file.path(output_dir, "diagnostic_trajectories.png")
  utils::write.csv(daily, daily_path, row.names = FALSE, na = "")
  utils::write.csv(plants_daily, plant_path, row.names = FALSE, na = "")
  summary <- goal002_summary(daily, plants_daily, profile, configuration_sha256)
  goal002_write_json(summary, summary_path)

  grDevices::png(filename = figure_path, width = 1200, height = 900, res = 120,
                 bg = "white")
  old_par <- graphics::par(no.readonly = TRUE)
  on.exit({
    graphics::par(old_par)
    grDevices::dev.off()
  }, add = TRUE)
  graphics::par(mfrow = c(2, 2), mar = c(4, 4, 2, 1))
  graphics::plot(daily$Day, daily$BodyConditionIndex, type = "l", xlab = "Diagnostic day",
                 ylab = "Body condition index", main = "Body condition")
  graphics::plot(daily$Day, daily$cumulative_energy_balance_kJ, type = "l", xlab = "Diagnostic day",
                 ylab = "Cumulative energy balance (kJ)", main = "Energy balance")
  graphics::plot(daily$Day, daily$cumulative_water_balance_g, type = "l", xlab = "Diagnostic day",
                 ylab = "Cumulative water balance (g)", main = "Water balance")
  graphics::plot(plants_daily$Day, plants_daily$closing_total_shoot_biomass_kg, type = "l",
                 xlab = "Diagnostic day", ylab = "Closing shoot biomass (kg DM)", main = "Plant biomass")
  grDevices::dev.off()
  on.exit(NULL, add = FALSE)

  output_paths <- c(daily_path, plant_path, summary_path, figure_path)
  output_hashes <- stats::setNames(vapply(output_paths, goal002_hash_file, character(1)), basename(output_paths))
  content_sha256 <- digest::digest(paste(names(output_hashes), output_hashes, sep = "=", collapse = "\n"),
                                   algo = "sha256", serialize = FALSE)
  manifest <- list(
    status = "complete",
    goal_id = profile$goal_id,
    profile_path = normalizePath(profile_path, winslash = "/", mustWork = TRUE),
    seed = profile$runtime$seed,
    days = profile$runtime$days,
    start_day = profile$runtime$start_day,
    minute_limit = profile$runtime$minute_limit,
    herbivore_count = profile$population$herbivore_count,
    forage_type_count = profile$forage$forage_type_count,
    git_sha = goal002_git_sha(dirname(dirname(normalizePath(profile_path, winslash = "/", mustWork = TRUE)))),
    R_version = R.version$version.string,
    input_sha256 = list(profile_yaml = goal002_hash_file(profile_path)),
    configuration = profile,
    configuration_sha256 = configuration_sha256,
    external_forcing = list(
      temperature = list(value = forcing$temperature, unique_values = 1L),
      soil_water = list(value = forcing$soil_water, unique_values = 1L),
      soil_nitrogen = list(value = forcing$soil_nitrogen, unique_values = 1L)
    ),
    initial_herbivore_state = initial$herbivore,
    initial_plant_state = initial$plants,
    output_hashes_sha256 = as.list(output_hashes),
    content_sha256 = content_sha256,
    row_counts = list(daily_diagnostics = nrow(daily), plant_diagnostics = nrow(plants_daily)),
    artefacts = profile$outputs$artefact_names
  )
  manifest_path <- file.path(output_dir, "run_manifest.json")
  goal002_write_json(manifest, manifest_path)

  list(
    output_dir = normalizePath(output_dir, winslash = "/", mustWork = TRUE),
    artefacts = file.path(output_dir, profile$outputs$artefact_names),
    manifest = manifest,
    daily = daily,
    plants = plants_daily
  )
}

goal002_cli <- function(args = commandArgs(trailingOnly = TRUE)) {
  value_for <- function(flag) {
    idx <- match(flag, args)
    if (!is.na(idx) && idx < length(args)) return(args[[idx + 1L]])
    prefix <- paste0(flag, "=")
    match_value <- args[startsWith(args, prefix)]
    if (length(match_value) == 1L) return(sub(prefix, "", match_value))
    NA_character_
  }
  profile <- value_for("--profile")
  output_dir <- value_for("--output-dir")
  if (is.na(profile) || is.na(output_dir)) {
    stop("Usage: Rscript scripts/run_goal002_minimal_diagnosis.R --profile PROFILE --output-dir OUTPUT_DIR",
         call. = FALSE)
  }
  run_goal002_minimal_diagnosis(profile, output_dir)
  invisible(NULL)
}

if (any(grepl("^--profile(?:=|$)", commandArgs(trailingOnly = TRUE)))) {
  goal002_cli()
}
