#!/usr/bin/env Rscript

goal003_source_helpers <- function() {
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
  for (path in r_files) sys.source(path, envir = .GlobalEnv)
  invisible(TRUE)
}

goal003_source_helpers()

goal003_abort <- function(message, class, ...) {
  if (requireNamespace("rlang", quietly = TRUE)) {
    rlang::abort(message, class = class, ...)
  }
  stop(message, call. = FALSE)
}

goal003_read_profile <- function(path) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path) || !file.exists(path)) {
    goal003_abort("Goal 003 profile path does not exist.", "herbivoreTTR_goal003_profile_missing")
  }
  if (!requireNamespace("yaml", quietly = TRUE)) {
    goal003_abort("Package `yaml` is required for the Goal 003 profile.", "herbivoreTTR_goal003_yaml_missing")
  }
  yaml::read_yaml(normalizePath(path, winslash = "/", mustWork = TRUE))
}

goal003_scalar <- function(x, name, integer = FALSE) {
  value <- if (integer) as.integer(x) else as.numeric(x)
  if (length(value) != 1L || !is.finite(value)) {
    goal003_abort(sprintf("Goal 003 profile field `%s` must be one finite scalar.", name),
                  "herbivoreTTR_goal003_profile_invalid")
  }
  value
}

goal003_validate_profile <- function(profile) {
  required <- c("goal_id", "profile_schema_version", "runtime", "population",
                "external_forcing", "forage", "initial_plant_state", "feedback",
                "stochasticity", "nonbinding", "outputs")
  if (!is.list(profile) || any(!required %in% names(profile))) {
    goal003_abort("Goal 003 profile is incomplete.", "herbivoreTTR_goal003_profile_invalid")
  }
  if (!identical(as.character(profile$goal_id), "003-herbivore-only-daily-clamped-forage-reference") ||
      !identical(as.character(profile$profile_schema_version), "1.0.0")) {
    goal003_abort("Goal 003 profile identity or schema version is invalid.",
                  "herbivoreTTR_goal003_profile_invalid")
  }

  runtime <- profile$runtime
  runtime_values <- list(
    seed = goal003_scalar(runtime$seed, "runtime$seed", integer = TRUE),
    days = goal003_scalar(runtime$days, "runtime$days", integer = TRUE),
    start_day = goal003_scalar(runtime$start_day, "runtime$start_day", integer = TRUE),
    minute_limit = goal003_scalar(runtime$minute_limit, "runtime$minute_limit", integer = TRUE),
    forage_access_scale = goal003_scalar(runtime$forage_access_scale, "runtime$forage_access_scale"),
    daily_seed_offset = goal003_scalar(profile$stochasticity$daily_seed_offset,
                                       "stochasticity$daily_seed_offset", integer = TRUE)
  )
  if (!identical(runtime_values$seed, 2002L) ||
      !identical(runtime_values$days, 120L) ||
      !identical(runtime_values$start_day, 6L) ||
      !identical(runtime_values$minute_limit, 720L) ||
      !identical(runtime_values$daily_seed_offset, 100000L) ||
      !identical(as.character(runtime$plant_backend), "internal_ttr") ||
      !identical(as.logical(runtime$apply_growth), FALSE) ||
      !identical(as.logical(runtime$daily_plant_reset), TRUE) ||
      !identical(as.integer(runtime$extra_digestion_ticks), 0L) ||
      !identical(runtime_values$forage_access_scale, 1) ||
      !identical(names(runtime), c("seed", "days", "start_day", "minute_limit",
                                  "forage_access_scale", "plant_backend", "apply_growth",
                                  "daily_plant_reset", "extra_digestion_ticks"))) {
    goal003_abort("Goal 003 runtime intervention or invariant is invalid.",
                  "herbivoreTTR_goal003_profile_invalid")
  }

  population <- profile$population
  herb_count <- goal003_scalar(population$herbivore_count, "population$herbivore_count", integer = TRUE)
  herb <- population$herbivore
  if (!identical(as.character(population$mode), "explicit_single") ||
      !identical(herb_count, 1L) || !is.list(herb)) {
    goal003_abort("Goal 003 must contain exactly one explicit herbivore.",
                  "herbivoreTTR_goal003_profile_invalid")
  }
  herb_required <- c("herbivore_id", "label", "empirical_parameterisation", "mass_g", "herb_type",
                     "MRT_hours", "foraging_mode", "xcor_m", "ycor_m", "behaviour",
                     "selected_plant_id", "movement_disruption_prob", "mixed_browser_weight")
  if (!identical(names(herb), herb_required) ||
      !identical(as.character(herb$herbivore_id), "goal002_grazer_1") ||
      !identical(as.character(herb$label), "simplified_grey_kangaroo_like_grazer") ||
      !identical(as.logical(herb$empirical_parameterisation), FALSE) ||
      !identical(goal003_scalar(herb$mass_g, "population$herbivore$mass_g", integer = TRUE), 50000L) ||
      !identical(goal003_scalar(herb$herb_type, "population$herbivore$herb_type", integer = TRUE), 0L) ||
      !identical(goal003_scalar(herb$MRT_hours, "population$herbivore$MRT_hours", integer = TRUE), 24L) ||
      !identical(as.character(herb$foraging_mode), "nutrient_targeting") ||
      !identical(as.numeric(herb$movement_disruption_prob), 0.1) ||
      !identical(as.numeric(herb$mixed_browser_weight), 0.5) ||
      !identical(as.character(herb$behaviour), "MOVING") ||
      !is.null(herb$selected_plant_id)) {
    goal003_abort("Goal 003 herbivore contract is invalid.",
                  "herbivoreTTR_goal003_profile_invalid")
  }
  for (field in c("xcor_m", "ycor_m")) {
    value <- goal003_scalar(herb[[field]], paste0("population$herbivore$", field))
    if (value < 0 || value > sqrt(CONSTANTS$PLOT_SIZE)) {
      goal003_abort("Goal 003 herbivore coordinates are outside the plot.",
                    "herbivoreTTR_goal003_profile_invalid")
    }
  }

  forcing <- profile$external_forcing
  forcing_names <- c("temperature_c", "soil_water", "soil_nitrogen")
  if (!is.list(forcing) || !identical(names(forcing), forcing_names) ||
      any(!vapply(forcing, function(x) length(x) == 1L && is.finite(as.numeric(x)), logical(1))) ||
      !identical(as.numeric(forcing$temperature_c), 25) ||
      !identical(as.numeric(forcing$soil_water), 0.5) ||
      !identical(as.numeric(forcing$soil_nitrogen), 0.5)) {
    goal003_abort("Goal 003 external forcing must match the fixed Goal 002 values.",
                  "herbivoreTTR_goal003_profile_invalid")
  }

  forage <- profile$forage
  forage_count <- goal003_scalar(forage$forage_type_count, "forage$forage_type_count", integer = TRUE)
  veg_types <- as.integer(unlist(forage$veg_types, use.names = FALSE))
  if (!identical(names(forage), c("forage_type_count", "veg_types", "forage_type_label",
                                  "empirical_parameterisation")) ||
      !identical(forage_count, 1L) || !identical(veg_types, 0L) ||
      !identical(as.character(forage$forage_type_label), "homogeneous_grass_like_diagnostic_resource") ||
      !identical(as.logical(forage$empirical_parameterisation), FALSE)) {
    goal003_abort("Goal 003 must contain one non-empirical homogeneous forage type.",
                  "herbivoreTTR_goal003_profile_invalid")
  }

  plant <- profile$initial_plant_state
  plant_required <- c(
    "plant_id", "xcor", "ycor", "veg_type", "ms", "mr", "cs", "cr", "ns", "nr",
    "cd", "nd", "bleaf", "bstem", "bdef", "md", "broot", "brepr", "height",
    "qroot", "qshoot", "gs", "gr", "gd", "uc", "un", "rsC", "rrC", "rdC",
    "rsN", "rrN", "rdN", "tauC", "tauN", "tauCd", "tauNd"
  )
  plant_expected <- c(
    plant_id = 1, xcor = 50, ycor = 50, veg_type = 0, ms = 50, mr = 50,
    cs = 22.5, cr = 22.5, ns = 1, nr = 1, cd = 0, nd = 0,
    bleaf = 49.995, bstem = 0, bdef = 0.005, md = 0.005, broot = 50,
    brepr = 0, height = 1, qroot = 400, qshoot = 400, gs = 0, gr = 0,
    gd = 0, uc = 0, un = 0, rsC = 0, rrC = 0, rdC = 0, rsN = 0,
    rrN = 0, rdN = 0, tauC = 0, tauN = 0, tauCd = 0, tauNd = 0
  )
  if (!is.list(plant) || !identical(names(plant), plant_required) ||
      !identical(goal003_scalar(plant$plant_id, "initial_plant_state$plant_id", integer = TRUE), 1L) ||
      !identical(goal003_scalar(plant$veg_type, "initial_plant_state$veg_type", integer = TRUE), 0L) ||
      any(!vapply(plant, function(x) length(x) == 1L && is.finite(as.numeric(x)), logical(1))) ||
      any(!vapply(names(plant_expected), function(field) {
        identical(as.numeric(plant[[field]]), unname(plant_expected[[field]]))
      }, logical(1)))) {
    goal003_abort("Goal 003 initial plant snapshot does not match Goal 002.",
                  "herbivoreTTR_goal003_profile_invalid")
  }

  feedback_required <- c("enabled", "initial_bci", "gain_coeff", "loss_coeff",
                         "effort_threshold", "stress_threshold", "max_foraging_boost")
  if (!is.list(profile$feedback) || !identical(names(profile$feedback), feedback_required) ||
      !identical(as.logical(profile$feedback$enabled), TRUE) ||
      !identical(as.numeric(profile$feedback$initial_bci), 0.8) ||
      !identical(as.numeric(profile$feedback$gain_coeff), 0.05) ||
      !identical(as.numeric(profile$feedback$loss_coeff), 0.08) ||
      !identical(as.numeric(profile$feedback$effort_threshold), 0.4) ||
      !identical(as.numeric(profile$feedback$stress_threshold), 0.2) ||
      !identical(as.numeric(profile$feedback$max_foraging_boost), 0.15)) {
    goal003_abort("Goal 003 feedback settings do not match Goal 002.",
                  "herbivoreTTR_goal003_profile_invalid")
  }

  if (!is.list(profile$stochasticity) ||
      !identical(names(profile$stochasticity), c("initial_coordinates", "daily_seed_offset", "fixed_seed_repeatability")) ||
      !identical(as.character(profile$stochasticity$initial_coordinates), "explicit_profile_values") ||
      !identical(as.logical(profile$stochasticity$fixed_seed_repeatability), TRUE)) {
    goal003_abort("Goal 003 stochasticity settings do not match Goal 002.",
                  "herbivoreTTR_goal003_profile_invalid")
  }

  nonbinding <- profile$nonbinding
  if (!is.list(nonbinding) || !identical(names(nonbinding), c("min_shoot_kg", "m_ref_kg", "tolerance")) ||
      !identical(as.numeric(nonbinding$min_shoot_kg), 0.001) ||
      !identical(as.numeric(nonbinding$m_ref_kg), 10) ||
      !identical(as.numeric(nonbinding$tolerance), 1e-10)) {
    goal003_abort("Goal 003 non-binding thresholds are invalid.",
                  "herbivoreTTR_goal003_profile_invalid")
  }

  artefacts <- as.character(unlist(profile$outputs$artefact_names, use.names = FALSE))
  expected_artefacts <- c("run_manifest.json", "daily_diagnostics.csv", "plant_diagnostics.csv",
                          "diagnostic_summary.json", "diagnostic_trajectories.png")
  if (!identical(artefacts, expected_artefacts)) {
    goal003_abort("Goal 003 artefact names do not match the runbook.",
                  "herbivoreTTR_goal003_profile_invalid")
  }

  list(
    goal_id = as.character(profile$goal_id),
    profile_schema_version = as.character(profile$profile_schema_version),
    description = as.character(profile$description),
    runtime = c(runtime_values[1:5], list(
      plant_backend = as.character(runtime$plant_backend),
      apply_growth = FALSE, daily_plant_reset = TRUE, extra_digestion_ticks = 0L,
      daily_seed_offset = runtime_values$daily_seed_offset
    )),
    population = list(mode = as.character(population$mode), herbivore_count = herb_count,
                      herbivore = herb),
    external_forcing = list(temperature_c = 25, soil_water = 0.5, soil_nitrogen = 0.5),
    forage = list(forage_type_count = forage_count, veg_types = veg_types,
                  forage_type_label = as.character(forage$forage_type_label),
                  empirical_parameterisation = FALSE),
    initial_plant_state = plant,
    feedback = profile$feedback,
    stochasticity = list(initial_coordinates = as.character(profile$stochasticity$initial_coordinates),
                         daily_seed_offset = runtime_values$daily_seed_offset,
                         fixed_seed_repeatability = TRUE),
    nonbinding = list(min_shoot_kg = 0.001, m_ref_kg = 10, tolerance = 1e-10),
    outputs = list(artefact_names = artefacts)
  )
}

goal003_resolved_forcing <- function(profile) {
  list(temperature = profile$external_forcing$temperature_c,
       soil_water = profile$external_forcing$soil_water,
       soil_nitrogen = profile$external_forcing$soil_nitrogen)
}

goal003_initial_plants <- function(profile) {
  state <- profile$initial_plant_state
  row <- as.list(state)
  row$plant_id <- as.integer(row$plant_id)
  row$veg_type <- as.integer(row$veg_type)
  for (field in setdiff(names(state), c("plant_id", "veg_type"))) row[[field]] <- as.numeric(row[[field]])
  plants <- as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
  plants[, names(state), drop = FALSE]
}

goal003_missing_value_schema <- function(state) {
  has_missing <- vapply(state, function(value) is.atomic(value) && anyNA(value), logical(1))
  lapply(state[has_missing], function(value) list(
    r_type = typeof(value), length = length(value), missing_positions = as.integer(which(is.na(value)))
  ))
}

goal003_canonical_json <- function(value) {
  jsonlite::toJSON(value, auto_unbox = TRUE, pretty = FALSE, null = "null", na = "null", digits = 17)
}

goal003_value_sha256 <- function(value) {
  digest::digest(goal003_canonical_json(value), algo = "sha256", serialize = FALSE)
}

goal003_goal002_manifest_path <- function(profile_path) {
  repo_root <- normalizePath(file.path(dirname(profile_path), "..", "..", ".."),
                             winslash = "/", mustWork = TRUE)
  file.path(repo_root, "artefacts", "goal002_minimal_coupled", "run-a", "run_manifest.json")
}

goal003_read_goal002_manifest <- function(profile_path) {
  path <- goal003_goal002_manifest_path(profile_path)
  expected_manifest_sha <- "4c61f2c866a5b3209608b4b7d29fc82209de749e3ecbefdd324d982ca2f4fb39"
  expected_configuration_sha <- "46ce7fe6e467a3387ee6cc5ef027e87f315710d0b9610f805cc8864224317d89"
  expected_content_sha <- "98ad4f9da22a7b535a4bed94b12f4104293af1a0f89a02bb2b3d464b4793ac86"
  goal003_check(file.exists(path), "Accepted Goal 002 manifest is missing.")
  goal003_check(identical(digest::digest(file = path, algo = "sha256"), expected_manifest_sha),
                "Accepted Goal 002 manifest hash does not match the frozen comparator.")
  manifest <- jsonlite::read_json(path, simplifyVector = FALSE)
  goal003_check(identical(manifest$configuration_sha256, expected_configuration_sha) &&
                  identical(manifest$content_sha256, expected_content_sha) &&
                  identical(manifest$status, "complete"),
                "Accepted Goal 002 manifest configuration or content digest is invalid.")
  list(path = path, manifest = manifest, manifest_sha256 = expected_manifest_sha,
       configuration_sha256 = expected_configuration_sha, content_sha256 = expected_content_sha)
}

goal003_validate_goal002_configuration <- function(profile, goal002_reference) {
  expected <- goal002_reference$manifest$configuration
  runtime_fields <- c("seed", "days", "start_day", "minute_limit", "forage_access_scale", "plant_backend")
  goal003_check(identical(goal003_canonical_json(profile$population),
                          goal003_canonical_json(expected$population)) &&
                  identical(goal003_canonical_json(profile$external_forcing),
                            goal003_canonical_json(expected$external_forcing)) &&
                  identical(goal003_canonical_json(profile$forage),
                            goal003_canonical_json(expected$forage)) &&
                  identical(goal003_canonical_json(profile$initial_plant_state),
                            goal003_canonical_json(expected$initial_plant_state)) &&
                  identical(goal003_canonical_json(profile$feedback),
                            goal003_canonical_json(expected$feedback)) &&
                  identical(goal003_canonical_json(profile$stochasticity),
                            goal003_canonical_json(expected$stochasticity)) &&
                  identical(goal003_canonical_json(profile$outputs),
                            goal003_canonical_json(expected$outputs)) &&
                  identical(goal003_canonical_json(profile$runtime[runtime_fields]),
                            goal003_canonical_json(expected$runtime[runtime_fields])),
                "Goal 003 configuration differs from the accepted Goal 002 configuration.")
  invisible(TRUE)
}

goal003_resolve_initial_state <- function(profile) {
  spec <- profile$population$herbivore
  herbivore <- with_optional_seed(profile$runtime$seed, {
    init_herbivore(mass = spec$mass_g, herb_type = spec$herb_type,
                   MRT = spec$MRT_hours, herbivore_id = spec$herbivore_id)
  })
  seeded_draws <- list(initial_xcor_draw_m = as.numeric(herbivore$xcor),
                       initial_ycor_draw_m = as.numeric(herbivore$ycor),
                       seed = profile$runtime$seed,
                       coordinate_resolution = "explicit_profile_values_replace_initial_draws")
  herbivore$xcor <- as.numeric(spec$xcor_m)
  herbivore$ycor <- as.numeric(spec$ycor_m)
  herbivore$behaviour <- as.character(spec$behaviour)
  herbivore$selected_plant_id <- NA_integer_
  herbivore$movement_disruption_prob <- as.numeric(spec$movement_disruption_prob)
  herbivore$mixed_browser_weight <- as.numeric(spec$mixed_browser_weight)
  herbivore$foraging_mode <- as.character(spec$foraging_mode)
  herbivore <- apply_scenario_feedback_config(herbivore, profile$feedback)
  herbivore$feedback_settings <- profile$feedback
  herbivore$seeded_draws <- seeded_draws
  plants <- goal003_initial_plants(profile)
  assert_domain_sanity_state(plants, herbivore, day_of_simulation = profile$runtime$start_day,
                             phase = "goal003_initial_state")
  list(
    herbivore_state = herbivore,
    plants_state = plants,
    herbivore = list(
      state_stage = "before_first_step", herbivore_id = herbivore$herbivore_id,
      mass_g = as.numeric(herbivore$mass), herb_type = as.integer(herbivore$herb_type),
      coordinates_m = list(xcor = as.numeric(herbivore$xcor), ycor = as.numeric(herbivore$ycor)),
      gut_content_g = as.numeric(herbivore$gut_content), gut_capacity_g = as.numeric(herbivore$gut_capacity),
      MRT_hours = as.integer(herbivore$MRT), digestion = herbivore$digestion,
      body_condition_index = as.numeric(herbivore$body_condition_index), behaviour = herbivore$behaviour,
      selected_plant_id = NULL, feedback_settings = herbivore$feedback_settings,
      foraging_mode = herbivore$foraging_mode, movement_disruption_prob = herbivore$movement_disruption_prob,
      seeded_draws = seeded_draws, resolved_herbivore_state = herbivore,
      resolved_herbivore_state_missing_schema = goal003_missing_value_schema(herbivore)
    ),
    plants = list(state_stage = "before_first_step", plant_row = as.list(plants[1, , drop = FALSE]),
                  total_shoot_biomass_kg = sum(plants$ms))
  )
}

goal003_state_sha256 <- function(object) {
  digest::digest(serialize(object, NULL, version = 3), algo = "sha256")
}

goal003_reset_day <- function(frozen_plants, herbivore, prior_closing = NULL) {
  reset_plants <- unserialize(serialize(frozen_plants, NULL, version = 3))
  opening_hash <- goal003_state_sha256(reset_plants)
  frozen_hash <- goal003_state_sha256(frozen_plants)
  prior_hash <- if (is.null(prior_closing)) NA_character_ else goal003_state_sha256(prior_closing)
  list(
    plants = reset_plants,
    herbivore = herbivore,
    opening_source = "frozen_snapshot",
    opening_state_sha256 = opening_hash,
    frozen_state_sha256 = frozen_hash,
    prior_closing_state_sha256 = prior_hash,
    opening_from_frozen_snapshot = identical(reset_plants, frozen_plants),
    opening_identical_to_prior_closing = !is.null(prior_closing) && identical(reset_plants, prior_closing)
  )
}

goal003_daily_row <- function(day, model_day, day_seed, forcing, opening, herbivore) {
  data.frame(
    Day = as.integer(day), model_day = as.integer(model_day), HerbivoreID = as.character(herbivore$herbivore_id),
    day_seed = as.integer(day_seed), temperature = forcing$temperature,
    soil_water = forcing$soil_water, soil_nitrogen = forcing$soil_nitrogen,
    opening_xcor_m = opening$xcor, opening_ycor_m = opening$ycor,
    xcor = herbivore$xcor, ycor = herbivore$ycor,
    opening_gut_content_g = opening$gut_content, gut_content_g = herbivore$gut_content,
    gut_capacity_g = herbivore$gut_capacity, intake_total_g = herbivore$intake_total_day,
    intake_PE_kJ = herbivore$intake_PE_day, intake_NPE_kJ = herbivore$intake_NPE_day,
    energy_intake_kJ = herbivore$daily_energy_intake,
    total_energy_requirement_kJ = herbivore$total_energy_requirement_day,
    energy_delta_kJ = herbivore$daily_energy_delta, EnergyBalance = herbivore$energy_balance,
    cumulative_energy_balance_kJ = herbivore$energy_balance,
    metabolic_water_g = herbivore$metabolic_water_day, forage_water_g = herbivore$intake_water_forage,
    drinking_water_g = herbivore$intake_water_drinking, water_input_total_g = herbivore$daily_water_intake_total,
    water_requirement_g = herbivore$water_requirement_day, daily_net_water_g = herbivore$daily_net_water_balance,
    WaterBalance = herbivore$water_balance, cumulative_water_balance_g = herbivore$water_balance,
    distance_moved_m = herbivore$distance_moved, time_spent_foraging_h = herbivore$time_spent_foraging,
    EnergyDeficitStreakDays = herbivore$energy_deficit_streak_days,
    WaterDeficitStreakDays = herbivore$water_deficit_streak_days,
    BodyConditionIndex = herbivore$body_condition_index,
    PhysiologicalStressFlag = herbivore$physiological_stress_flag,
    behaviour = herbivore$behaviour,
    selected_plant_id = as.integer(if (is.na(herbivore$selected_plant_id)) -1L else herbivore$selected_plant_id),
    energy_daily_residual_kJ = herbivore$daily_energy_intake - herbivore$total_energy_requirement_day - herbivore$daily_energy_delta,
    energy_cumulative_residual_kJ = 0,
    water_daily_residual_g = herbivore$metabolic_water_day + herbivore$intake_water_forage +
      herbivore$intake_water_drinking - herbivore$water_requirement_day - herbivore$daily_net_water_balance,
    water_cumulative_residual_g = 0,
    stringsAsFactors = FALSE
  )
}

goal003_ratio <- function(numerator, denominator) {
  value <- as.numeric(numerator) / as.numeric(denominator)
  if (length(value) != 1L || !is.finite(value)) NA_real_ else value
}

goal003_selection_ratio <- function(plant) {
  goal003_ratio(as.numeric(plant$ns) / CONSTANTS$N_TO_PROTEIN,
                as.numeric(plant$cs) * CONSTANTS$PROP_DIGEST_SC)
}

goal003_daily_record_table <- function(daily_record) {
  rows <- lapply(daily_record, function(entry) {
    if (is.null(entry)) return(NULL)
    as.data.frame(entry, stringsAsFactors = FALSE)
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (!length(rows)) return(data.frame())
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

goal003_reconstruct_minute_plants <- function(opening, records) {
  required <- c("minute", "xcor", "ycor", "intake_total_day", "intake_water_forage")
  goal003_check(nrow(records) == 720L && all(required %in% names(records)),
                "Goal 003 minute diagnostics do not contain all 720 captured records.")
  opening_ms <- sum(as.numeric(opening$ms))
  intake_kg <- as.numeric(records$intake_total_day) / 1000
  forage_water_kg <- as.numeric(records$intake_water_forage) / 1000
  out <- opening[rep(1L, nrow(records)), , drop = FALSE]
  out$ms <- opening_ms - intake_kg
  out$bleaf <- as.numeric(opening$bleaf) * out$ms / opening_ms
  out$bstem <- as.numeric(opening$bstem) * out$ms / opening_ms
  out$bdef <- as.numeric(opening$bdef) * out$ms / opening_ms
  out$qshoot <- as.numeric(opening$qshoot) - forage_water_kg
  out$distance <- calc_toroidal_distance(
    records$xcor, records$ycor, opening$xcor, opening$ycor,
    sqrt(CONSTANTS$PLOT_SIZE), sqrt(CONSTANTS$PLOT_SIZE)
  )
  out
}

goal003_all_minute_evidence <- function(opening, diagnostics, herbivore_start, profile) {
  records <- goal003_daily_record_table(diagnostics$daily_record)
  minute_plants <- goal003_reconstruct_minute_plants(opening, records)
  distances <- as.numeric(minute_plants$distance)
  herb_type <- normalize_herb_type(herbivore_start$herb_type)
  reachable <- rep(TRUE, nrow(minute_plants))
  if (herb_type %in% c(1L, 2L)) {
    reachable <- CONSTANTS$LEAF_HEIGHT * as.numeric(minute_plants$height) <= CONSTANTS$BROWSE_HEIGHT
  }
  detectable <- distances <= CONSTANTS$DETECTION_DISTANCE
  selection_scores <- calc_plant_tastiness(minute_plants, herbivore_start, CONSTANTS$DP_TO_DC_TARGET)
  intake_increment <- c(as.numeric(records$intake_total_day[[1L]]),
                         diff(as.numeric(records$intake_total_day)))
  positive_intake <- intake_increment > 0
  positive_distances <- distances[positive_intake]
  list(
    minute_records = records,
    minute_plants = minute_plants,
    max_all_minute_plant_distance_m = max(distances),
    detectable_throughout_active_loop = all(detectable),
    reachable_throughout_active_loop = all(reachable),
    minimum_all_minute_selection_score = min(selection_scores),
    positive_selection_minutes = sum(selection_scores > 0),
    positive_intake_minutes = sum(positive_intake),
    positive_intake_within_eat_radius = length(positive_distances) > 0L &&
      all(positive_distances <= CONSTANTS$EAT_RADIUS),
    maximum_positive_intake_distance_m = if (length(positive_distances)) max(positive_distances) else NA_real_,
    code_trace_distance_guard = paste(
      "Production herbivore_step() independently checks toroidal distance <=",
      "CONSTANTS$EAT_RADIUS immediately before every call to herbivore_eat()."
    )
  )
}

goal003_plant_row <- function(day, model_day, opening, closing, daily, diagnostics, reset, profile) {
  state_fields <- names(opening)
  row <- list(Day = as.integer(day), model_day = as.integer(model_day))
  for (field in state_fields) {
    row[[paste0("opening_", field)]] <- as.numeric(opening[[field]])
    row[[paste0("closing_", field)]] <- as.numeric(closing[[field]])
  }
  opening_ms <- sum(as.numeric(opening$ms))
  closing_ms <- sum(as.numeric(closing$ms))
  opening_qshoot <- sum(as.numeric(opening$qshoot))
  closing_qshoot <- sum(as.numeric(closing$qshoot))
  opening_components <- sum(as.numeric(opening$bleaf), as.numeric(opening$bstem), as.numeric(opening$bdef))
  closing_components <- sum(as.numeric(closing$bleaf), as.numeric(closing$bstem), as.numeric(closing$bdef))
  opening_nutrient <- goal003_selection_ratio(opening)
  closing_nutrient <- goal003_selection_ratio(closing)
  records <- goal003_daily_record_table(diagnostics$daily_record)
  all_minute <- goal003_all_minute_evidence(opening, diagnostics, diagnostics$herbivore_start, profile)
  eating <- c(as.numeric(records$intake_total_day[[1L]]), diff(as.numeric(records$intake_total_day))) > 0
  eating_distances <- all_minute$minute_plants$distance[eating]
  start_h <- diagnostics$herbivore_start
  start_near <- get_plants_within_range(start_h, opening)
  close_near <- get_plants_within_range(start_h, closing)
  start_score <- calc_plant_tastiness(start_near, start_h, CONSTANTS$DP_TO_DC_TARGET)
  close_score <- calc_plant_tastiness(close_near, start_h, CONSTANTS$DP_TO_DC_TARGET)
  non_consumed <- setdiff(state_fields, c("ms", "bleaf", "bstem", "bdef", "qshoot"))
  non_consumed_identical <- all(vapply(non_consumed, function(field) identical(opening[[field]], closing[[field]]), logical(1)))
  as.data.frame(c(row, list(
    opening_state_sha256 = reset$opening_state_sha256,
    closing_state_sha256 = goal003_state_sha256(closing),
    frozen_state_sha256 = reset$frozen_state_sha256,
    prior_closing_state_sha256 = reset$prior_closing_state_sha256,
    opening_source = reset$opening_source,
    opening_from_frozen_snapshot = reset$opening_from_frozen_snapshot,
    opening_identical_to_prior_closing = reset$opening_identical_to_prior_closing,
    apply_growth = isTRUE(profile$runtime$apply_growth), daily_plant_reset = isTRUE(profile$runtime$daily_plant_reset),
    closing_is_daily_minimum = isTRUE(closing_ms <= opening_ms) &&
      all(unlist(closing[c("bleaf", "bstem", "bdef")], use.names = FALSE) <=
            unlist(opening[c("bleaf", "bstem", "bdef")], use.names = FALSE) + 1e-12),
    shoot_drawdown_kg = opening_ms - closing_ms, qshoot_drawdown_kg = opening_qshoot - closing_qshoot,
    opening_shoot_component_residual_kg = opening_ms - opening_components,
    closing_shoot_component_residual_kg = closing_ms - closing_components,
    intake_drawdown_residual_kg = opening_ms - closing_ms - daily$intake_total_g / 1000,
    qshoot_water_residual_kg = opening_qshoot - closing_qshoot - daily$forage_water_g / 1000,
    qshoot_shoot_ratio_change = goal003_ratio(closing_qshoot, closing_ms) - goal003_ratio(opening_qshoot, opening_ms),
    leaf_fraction_change = goal003_ratio(closing$bleaf, closing_ms) - goal003_ratio(opening$bleaf, opening_ms),
    stem_fraction_change = goal003_ratio(closing$bstem, closing_ms) - goal003_ratio(opening$bstem, opening_ms),
    defence_fraction_change = goal003_ratio(closing$bdef, closing_ms) - goal003_ratio(opening$bdef, opening_ms),
    opening_selection_nutrient_ratio = opening_nutrient, closing_selection_nutrient_ratio = closing_nutrient,
    selection_nutrient_ratio_change = closing_nutrient - opening_nutrient,
    min_shoot_kg = profile$nonbinding$min_shoot_kg, m_ref_kg = profile$nonbinding$m_ref_kg,
    gut_capacity_g = daily$gut_capacity_g,
    single_plant_eligible = nrow(start_near) == 1L && nrow(close_near) == 1L &&
      identical(as.integer(start_near$plant_id), 1L) && identical(as.integer(close_near$plant_id), 1L),
    positive_selection_score = all_minute$minimum_all_minute_selection_score > 0,
    opening_selection_score = if (length(start_score) == 1L) start_score else NA_real_,
    closing_selection_score = if (length(close_score) == 1L) close_score else NA_real_,
    eating_attempts = sum(eating),
    co_located_for_eating = length(eating_distances) > 0L && all(eating_distances <= CONSTANTS$EAT_RADIUS),
    minimum_eating_distance_m = if (length(eating_distances)) min(eating_distances) else NA_real_,
    maximum_eating_distance_m = if (length(eating_distances)) max(eating_distances) else NA_real_,
    non_consumed_fields_identical = non_consumed_identical,
    max_all_minute_plant_distance_m = all_minute$max_all_minute_plant_distance_m,
    detectable_throughout_active_loop = all_minute$detectable_throughout_active_loop,
    reachable_throughout_active_loop = all_minute$reachable_throughout_active_loop,
    minimum_all_minute_selection_score = all_minute$minimum_all_minute_selection_score,
    positive_selection_minutes = all_minute$positive_selection_minutes,
    positive_intake_minutes = all_minute$positive_intake_minutes,
    positive_intake_within_eat_radius = all_minute$positive_intake_within_eat_radius,
    maximum_positive_intake_distance_m = all_minute$maximum_positive_intake_distance_m,
    code_trace_distance_guard = all_minute$code_trace_distance_guard,
    closing_ms = closing_ms, closing_qshoot = closing_qshoot
  )), stringsAsFactors = FALSE, check.names = FALSE)
}

goal003_write_json <- function(object, path) {
  json <- jsonlite::toJSON(object, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null", digits = 17)
  writeLines(json, path, useBytes = TRUE)
}

goal003_hash_file <- function(path) digest::digest(file = path, algo = "sha256")

goal003_git_sha <- function(repo_root) {
  result <- tryCatch(system2("git", c("-C", repo_root, "rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE),
                     error = function(e) character())
  if (length(result)) trimws(result[[1]]) else "unavailable"
}

goal003_check <- function(condition, message) {
  if (!isTRUE(condition)) goal003_abort(message, "herbivoreTTR_goal003_scientific_stop")
}

goal003_summary <- function(daily, plants, profile, configuration_sha256, frozen_sha256) {
  list(
    goal_id = profile$goal_id,
    interpretation_scope = "finite but demonstrably non-binding daily forage reference; fixed-seed descriptive computation; no causal, viability, equilibrium, or empirical realism claim",
    configuration_sha256 = configuration_sha256, frozen_plant_state_sha256 = frozen_sha256,
    days = nrow(daily), daily_coverage = list(first_day = min(daily$Day), last_day = max(daily$Day), rows = nrow(daily)),
    trajectory = list(
      energy_delta_range_kJ = range(daily$energy_delta_kJ),
      final_cumulative_energy_balance_kJ = tail(daily$cumulative_energy_balance_kJ, 1),
      body_condition_range = range(daily$BodyConditionIndex),
      first_bci_floor_day = if (any(daily$BodyConditionIndex == 0)) min(daily$Day[daily$BodyConditionIndex == 0]) else NULL,
      intake_range_g = range(daily$intake_total_g), gut_content_range_g = range(daily$gut_content_g),
      energy_deficit_days = sum(daily$energy_delta_kJ < 0), stress_days = sum(daily$PhysiologicalStressFlag != 0),
      distance_range_m = range(daily$distance_moved_m), foraging_hours_range = range(daily$time_spent_foraging_h)
    ),
    nonbinding_extrema = list(
      closing_shoot_range_kg = range(plants$closing_ms),
      minimum_availability_margin_kg = min(plants$closing_ms - plants$min_shoot_kg - plants$gut_capacity_g / 1000),
      closing_qshoot_range = range(plants$closing_qshoot),
      maximum_abs_composition_change = max(abs(unlist(plants[c("qshoot_shoot_ratio_change", "leaf_fraction_change", "stem_fraction_change", "defence_fraction_change", "selection_nutrient_ratio_change")]))),
      minimum_eating_distance_m = min(plants$minimum_eating_distance_m),
      maximum_eating_distance_m = max(plants$maximum_eating_distance_m),
      maximum_all_minute_plant_distance_m = max(plants$max_all_minute_plant_distance_m),
      minimum_all_minute_selection_score = min(plants$minimum_all_minute_selection_score),
      minimum_positive_intake_minutes = min(plants$positive_intake_minutes),
      maximum_positive_intake_distance_m = max(plants$maximum_positive_intake_distance_m),
      detectable_throughout_active_loop = all(plants$detectable_throughout_active_loop),
      reachable_throughout_active_loop = all(plants$reachable_throughout_active_loop),
      positive_intake_within_eat_radius = all(plants$positive_intake_within_eat_radius)
    ),
    accounting_residual = list(
      opening_shoot_component_max_abs_kg = max(abs(plants$opening_shoot_component_residual_kg)),
      closing_shoot_component_max_abs_kg = max(abs(plants$closing_shoot_component_residual_kg)),
      intake_drawdown_max_abs_kg = max(abs(plants$intake_drawdown_residual_kg)),
      qshoot_water_max_abs_kg = max(abs(plants$qshoot_water_residual_kg)),
      energy_daily_max_abs_kJ = max(abs(daily$energy_daily_residual_kJ)),
      energy_cumulative_max_abs_kJ = max(abs(daily$energy_cumulative_residual_kJ)),
      water_daily_max_abs_g = max(abs(daily$water_daily_residual_g)),
      water_cumulative_max_abs_g = max(abs(daily$water_cumulative_residual_g)),
      definitions = list(
        opening_shoot_components = "opening ms minus (opening bleaf + opening bstem + opening bdef)",
        closing_shoot_components = "closing ms minus (closing bleaf + closing bstem + closing bdef)",
        intake_drawdown = "opening shoot minus closing shoot minus cumulative herbivore dry-matter intake",
        qshoot_water = "opening qshoot minus closing qshoot minus cumulative forage-water intake",
        energy = "wiring identity: daily intake minus requirement equals daily energy delta; cumulative balance equals cumulative daily deltas",
        water = "wiring identity: metabolic plus forage plus drinking water minus requirement equals daily net water"
      )
    )
  )
}

run_goal003_herbivore_reference <- function(profile_path, output_dir) {
  if (file.exists(output_dir)) {
    goal003_abort("Goal 003 output directory must be absent before execution.", "herbivoreTTR_goal003_output_exists")
  }
  if (!requireNamespace("digest", quietly = TRUE) || !requireNamespace("jsonlite", quietly = TRUE)) {
    goal003_abort("Goal 003 requires existing `digest` and `jsonlite` dependencies.", "herbivoreTTR_goal003_dependency_missing")
  }
  profile <- goal003_validate_profile(goal003_read_profile(profile_path))
  goal002_reference <- goal003_read_goal002_manifest(profile_path)
  goal003_validate_goal002_configuration(profile, goal002_reference)
  configuration_json <- jsonlite::toJSON(profile, auto_unbox = TRUE, pretty = FALSE, null = "null", digits = 17)
  configuration_sha256 <- digest::digest(configuration_json, algo = "sha256", serialize = FALSE)
  forcing <- goal003_resolved_forcing(profile)
  conditions <- data.frame(day = 1L, temp_mean = forcing$temperature,
                           sw = forcing$soil_water, N = forcing$soil_nitrogen)
  initial <- goal003_resolve_initial_state(profile)
  goal003_check(identical(
    goal003_canonical_json(initial$herbivore$resolved_herbivore_state),
    goal003_canonical_json(goal002_reference$manifest$initial_herbivore_state$resolved_herbivore_state)
  ), "Resolved Goal 003 herbivore state differs from accepted Goal 002 state.")
  goal003_check(identical(
    goal003_canonical_json(initial$plants$plant_row),
    goal003_canonical_json(goal002_reference$manifest$initial_plant_state$plant_row)
  ), "Resolved Goal 003 plant state differs from accepted Goal 002 state.")
  herbivore <- initial$herbivore_state
  frozen_plants <- initial$plants_state
  frozen_sha256 <- goal003_state_sha256(frozen_plants)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  daily_rows <- vector("list", profile$runtime$days)
  plant_rows <- vector("list", profile$runtime$days)
  prior_closing <- NULL
  for (i in seq_len(profile$runtime$days)) {
    model_day <- profile$runtime$start_day + i - 1L
    day_seed <- profile$runtime$seed + i * profile$runtime$daily_seed_offset
    opening_herbivore <- herbivore
    reset <- goal003_reset_day(frozen_plants, herbivore, prior_closing)
    goal003_check(identical(reset$opening_source, "frozen_snapshot") &&
                    reset$opening_from_frozen_snapshot &&
                    identical(reset$opening_state_sha256, reset$frozen_state_sha256),
                  "Daily plant opening is not exactly the frozen snapshot.")
    goal003_check(identical(reset$herbivore, opening_herbivore), "Daily reset changed herbivore state.")
    result <- run_daily_herbivore_simulation(
      herbivore = reset$herbivore, plants = reset$plants, conditions = conditions,
      day_of_simulation = model_day, minute_limit = profile$runtime$minute_limit,
      capture_diagnostics = TRUE, seed = day_seed, apply_growth = FALSE,
      plant_backend = profile$runtime$plant_backend, forage_access_scale = profile$runtime$forage_access_scale
    )
    herbivore <- result$herbivore
    closing <- result$plants
    daily <- goal003_daily_row(i, model_day, day_seed, forcing, opening_herbivore, herbivore)
    result$diagnostics$daily_record <- result$daily_record
    plant <- goal003_plant_row(i, model_day, reset$plants, closing, daily, result$diagnostics, reset, profile)
    goal003_check(identical(plant$opening_state_sha256, reset$opening_state_sha256) &&
                    identical(plant$frozen_state_sha256, reset$frozen_state_sha256),
                  "Opening plant state hash differs from reset-derived state.")
    goal003_check(plant$closing_ms > plant$min_shoot_kg && plant$closing_ms > plant$m_ref_kg,
                  "Closing shoot is at or below a non-binding threshold.")
    goal003_check(plant$closing_ms - plant$min_shoot_kg > daily$gut_capacity_g / 1000,
                  "Plant availability could bind before total gut capacity.")
    goal003_check(plant$closing_qshoot > 0 && plant$non_consumed_fields_identical,
                  "Closing qshoot or non-consumed plant state is invalid.")
    goal003_check(plant$single_plant_eligible && plant$positive_selection_score &&
                    plant$co_located_for_eating && plant$detectable_throughout_active_loop &&
                    plant$reachable_throughout_active_loop && plant$positive_intake_within_eat_radius,
                  "Plant eligibility, positive selection score, or eating distance failed.")
    composition_changes <- abs(unlist(plant[c("qshoot_shoot_ratio_change", "leaf_fraction_change", "stem_fraction_change", "defence_fraction_change", "selection_nutrient_ratio_change")]))
    if (!all(composition_changes <= profile$nonbinding$tolerance)) {
      goal003_abort(sprintf("Plant composition or selection nutrient ratio changed beyond tolerance on day %d (maximum %.17g).",
                            i, max(composition_changes)), "herbivoreTTR_goal003_scientific_stop")
    }
    goal003_check(abs(plant$opening_shoot_component_residual_kg) <= 1e-12 &&
                    abs(plant$closing_shoot_component_residual_kg) <= 1e-12 &&
                    abs(plant$intake_drawdown_residual_kg) <= 1e-10 &&
                    abs(plant$qshoot_water_residual_kg) <= 1e-10,
                  "Plant or intake accounting residual exceeded the prescribed tolerance.")
    goal003_check(all(vapply(herbivore[c("gut_content", "gut_capacity", "body_condition_index", "energy_balance", "water_balance")], is.finite, logical(1))) &&
                    herbivore$gut_content <= herbivore$gut_capacity + 1e-8 &&
                    herbivore$body_condition_index >= 0 && herbivore$body_condition_index <= 1,
                  "Herbivore domain bounds failed.")
    daily_rows[[i]] <- daily
    plant_rows[[i]] <- plant
    prior_closing <- closing
  }

  daily <- do.call(rbind, daily_rows)
  plants_daily <- do.call(rbind, plant_rows)
  rownames(daily) <- NULL
  rownames(plants_daily) <- NULL
  daily$energy_cumulative_residual_kJ <- daily$cumulative_energy_balance_kJ - cumsum(daily$energy_delta_kJ)
  daily$water_cumulative_residual_g <- daily$cumulative_water_balance_g - cumsum(daily$daily_net_water_g)
  goal003_check(identical(daily$Day, seq_len(profile$runtime$days)) && identical(plants_daily$Day, seq_len(profile$runtime$days)),
                "Daily coverage or ordering is incomplete.")
  goal003_check(max(abs(daily$energy_daily_residual_kJ)) <= 1e-8 &&
                  max(abs(daily$energy_cumulative_residual_kJ)) <= 1e-8 &&
                  max(abs(daily$water_daily_residual_g)) <= 1e-8 &&
                  max(abs(daily$water_cumulative_residual_g)) <= 1e-8,
                "Energy or water accounting residual exceeded the prescribed tolerance.")
  goal003_check(all(vapply(daily[vapply(daily, is.numeric, logical(1))], function(x) all(is.finite(x)), logical(1))) &&
                  all(vapply(plants_daily[vapply(plants_daily, is.numeric, logical(1))], function(x) all(is.finite(x)), logical(1))),
                "Non-finite daily or plant diagnostic value observed.")

  daily_path <- file.path(output_dir, "daily_diagnostics.csv")
  plant_path <- file.path(output_dir, "plant_diagnostics.csv")
  summary_path <- file.path(output_dir, "diagnostic_summary.json")
  figure_path <- file.path(output_dir, "diagnostic_trajectories.png")
  utils::write.csv(daily, daily_path, row.names = FALSE, na = "")
  utils::write.csv(plants_daily, plant_path, row.names = FALSE, na = "")
  summary <- goal003_summary(daily, plants_daily, profile, configuration_sha256, frozen_sha256)
  goal003_write_json(summary, summary_path)

  grDevices::png(filename = figure_path, width = 1200, height = 900, res = 120, bg = "white")
  old_par <- graphics::par(no.readonly = TRUE)
  on.exit({ graphics::par(old_par); grDevices::dev.off() }, add = TRUE)
  graphics::par(mfrow = c(2, 2), mar = c(4, 4, 2, 1), oma = c(3, 0, 0, 0))
  graphics::plot(daily$Day, daily$BodyConditionIndex, type = "l", xlab = "Diagnostic day (1--120)",
                 ylab = "Body condition index (0--1)", main = "Body condition")
  graphics::plot(daily$Day, daily$cumulative_energy_balance_kJ, type = "l", xlab = "Diagnostic day (1--120)",
                 ylab = "Cumulative energy balance (kJ)", main = "Energy balance")
  graphics::plot(daily$Day, daily$cumulative_water_balance_g, type = "l", xlab = "Diagnostic day (1--120)",
                 ylab = "Cumulative water balance (g)", main = "Cumulative water balance")
  graphics::plot(plants_daily$Day, plants_daily$closing_ms, type = "l", xlab = "Diagnostic day (1--120)",
                 ylab = "Closing shoot biomass (kg DM)", main = "Daily-clamped shoot")
  graphics::mtext("Single fixed-seed trajectory; finite but demonstrably non-binding daily forage reference; no biological pass threshold",
                  side = 1, outer = TRUE, line = 1, cex = 0.8)
  grDevices::dev.off()
  on.exit(NULL, add = FALSE)

  output_paths <- c(daily_path, plant_path, summary_path, figure_path)
  output_hashes <- stats::setNames(vapply(output_paths, goal003_hash_file, character(1)), basename(output_paths))
  content_sha256 <- digest::digest(paste(names(output_hashes), output_hashes, sep = "=", collapse = "\n"),
                                   algo = "sha256", serialize = FALSE)
  manifest <- list(
    status = "complete", goal_id = profile$goal_id, profile_path = normalizePath(profile_path, winslash = "/", mustWork = TRUE),
    seed = profile$runtime$seed, days = profile$runtime$days, start_day = profile$runtime$start_day,
    minute_limit = profile$runtime$minute_limit, daily_seed_offset = profile$runtime$daily_seed_offset,
    herbivore_count = profile$population$herbivore_count, forage_type_count = profile$forage$forage_type_count,
    forage_access_scale = profile$runtime$forage_access_scale, plant_backend = profile$runtime$plant_backend,
    apply_growth = FALSE, daily_plant_reset = TRUE, extra_digestion_ticks = 0L,
    nonbinding_tolerance = profile$nonbinding$tolerance, all_nonbinding_checks_passed = TRUE,
    git_sha = goal003_git_sha(dirname(dirname(normalizePath(profile_path, winslash = "/", mustWork = TRUE)))),
    R_version = R.version$version.string,
    input_sha256 = list(profile_yaml = goal003_hash_file(profile_path),
                        goal002_manifest = goal002_reference$manifest_sha256),
    configuration = profile, configuration_sha256 = configuration_sha256,
    goal002_reference = list(
      manifest_path = "artefacts/goal002_minimal_coupled/run-a/run_manifest.json",
      manifest_sha256 = goal002_reference$manifest_sha256,
      configuration_sha256 = goal002_reference$configuration_sha256,
      content_sha256 = goal002_reference$content_sha256,
      comparison = "read-only canonical JSON/value comparison of accepted Goal 002 configuration and resolved initial states"
    ),
    initial_state_digests = list(
      resolved_herbivore_state_sha256 = goal003_value_sha256(initial$herbivore$resolved_herbivore_state),
      initial_plant_row_sha256 = goal003_value_sha256(initial$plants$plant_row),
      frozen_plant_state_sha256 = frozen_sha256
    ),
    frozen_plant_state_sha256 = frozen_sha256, initial_herbivore_state = initial$herbivore,
    initial_plant_state = initial$plants, output_hashes_sha256 = as.list(output_hashes),
    content_sha256 = content_sha256,
    row_counts = list(daily_diagnostics = nrow(daily), plant_diagnostics = nrow(plants_daily)),
    artefacts = profile$outputs$artefact_names
  )
  manifest_path <- file.path(output_dir, "run_manifest.json")
  goal003_write_json(manifest, manifest_path)
  list(output_dir = normalizePath(output_dir, winslash = "/", mustWork = TRUE),
       artefacts = file.path(output_dir, profile$outputs$artefact_names), manifest = manifest,
       daily = daily, plants = plants_daily)
}

goal003_cli <- function(args = commandArgs(trailingOnly = TRUE)) {
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
    stop("Usage: Rscript scripts/run_goal003_herbivore_reference.R --profile PROFILE --output-dir OUTPUT_DIR", call. = FALSE)
  }
  run_goal003_herbivore_reference(profile, output_dir)
  invisible(NULL)
}

if (any(grepl("^--profile(?:=|$)", commandArgs(trailingOnly = TRUE)))) goal003_cli()
