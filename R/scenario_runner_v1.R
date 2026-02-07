# Scenario execution helpers (explicit cohorts + implicit representative mode).

build_conditions_from_scenario <- function(scenario) {
  validated <- validate_scenario_v1(scenario)

  # Seed any stochastic climate mode deterministically from scenario runtime seed.
  with_optional_seed(validated$runtime$seed, {
    conditions <- init_conditions(
      mode = validated$climate$mode,
      mean_temp = validated$climate$mean_temp,
      amplitude = validated$climate$amplitude
    )

    conditions$sw <- pmax(conditions$sw * validated$climate$sw_scale, 0)
    conditions$N <- pmax(conditions$N * validated$climate$n_scale, 0)
    conditions
  })
}

scenario_plot_area_km2 <- function(scenario) {
  validated <- validate_scenario_v1(scenario)
  validated$plot$plot_size_m2 / 1e6
}

init_herbivore_from_spec <- function(spec, feedback = NULL) {
  herb <- init_herbivore(
    mass = spec$mass_g,
    herb_type = spec$herb_type,
    MRT = spec$MRT_hours,
    herbivore_id = spec$herbivore_id
  )
  herb$foraging_mode <- spec$foraging_mode
  herb <- apply_scenario_feedback_config(herb, feedback)
  herb
}

init_cohort_from_scenario <- function(scenario) {
  validated <- validate_scenario_v1(scenario)
  if (!validated$population$mode %in% c("explicit_single", "explicit_cohort")) {
    rlang::abort(
      "Scenario population mode is not explicit cohort mode.",
      class = "herbivoreTTR_cohort_mode_not_explicit",
      mode = validated$population$mode
    )
  }

  cohort <- lapply(validated$population$cohort, init_herbivore_from_spec, feedback = validated$feedback)
  ids <- vapply(cohort, `[[`, character(1), "herbivore_id")
  names(cohort) <- ids
  cohort
}

sort_herbivore_cohort <- function(herbivores) {
  if (!is.list(herbivores) || length(herbivores) < 1L) {
    rlang::abort(
      "Argument `herbivores` must be a non-empty list.",
      class = "herbivoreTTR_cohort_empty"
    )
  }

  ids <- vapply(herbivores, function(h) {
    if (!is.list(h) || !is.character(h$herbivore_id) || length(h$herbivore_id) != 1L || !nzchar(h$herbivore_id)) {
      rlang::abort(
        "Each herbivore must contain non-empty `herbivore_id`.",
        class = "herbivoreTTR_cohort_id_missing"
      )
    }
    h$herbivore_id
  }, character(1L))

  if (anyDuplicated(ids)) {
    rlang::abort(
      "Herbivore cohort IDs must be unique.",
      class = "herbivoreTTR_cohort_id_duplicate",
      herbivore_ids = ids
    )
  }

  ord <- order(ids)
  sorted <- herbivores[ord]
  names(sorted) <- ids[ord]
  sorted
}

make_herbivore_daily_row <- function(herbivore, daily_summary, day_of_simulation) {
  data.frame(
    HerbivoreID = as.character(herbivore$herbivore_id),
    Day = as.integer(day_of_simulation),
    HerbType = as.integer(herbivore$herb_type),
    DailyDistMoved = as.numeric(daily_summary$total_distance_moved),
    DailyPEI = as.numeric(herbivore$intake_PE_day),
    DailyNPEI = as.numeric(herbivore$intake_NPE_day),
    DailyDMI = as.numeric(daily_summary$total_biomass_eaten),
    DailyForageWater = as.numeric(daily_summary$daily_water_forage),
    DailyWaterDrinking = as.numeric(daily_summary$daily_water_drinking),
    MaintenanceEnergyReq = as.numeric(herbivore$maintenance_energy_requirement_day),
    EnergyBalanceRatio = as.numeric(herbivore$energy_balance_ratio),
    WaterRequirement = as.numeric(herbivore$water_requirement_day),
    WaterBalanceRatio = as.numeric(herbivore$water_balance_ratio),
    EnergyDeficitStreakDays = as.integer(herbivore$energy_deficit_streak_days),
    WaterDeficitStreakDays = as.integer(herbivore$water_deficit_streak_days),
    BodyConditionIndex = as.numeric(herbivore$body_condition_index),
    PhysiologicalStressFlag = as.integer(herbivore$physiological_stress_flag),
    WaterBalance = as.numeric(daily_summary$water_balance),
    EnergyBalance = as.numeric(daily_summary$energy_balance),
    stringsAsFactors = FALSE
  )
}

run_daily_herbivore_cohort <- function(herbivores,
                                       plants,
                                       conditions,
                                       day_of_simulation,
                                       minute_limit,
                                       forage_access_scale = 1,
                                       seed = NULL) {
  ordered <- sort_herbivore_cohort(herbivores)

  day_index <- ((day_of_simulation - 1L) %% nrow(conditions)) + 1L
  plants_state <- transport_resistance(plants, conditions, day_index)

  updated <- vector("list", length(ordered))
  names(updated) <- names(ordered)
  rows <- vector("list", length(ordered))

  for (i in seq_along(ordered)) {
    herb <- ordered[[i]]
    local_seed <- if (is.null(seed)) NULL else as.integer(seed + i * 1000L)

    res <- run_daily_herbivore_simulation(
      herbivore = herb,
      plants = plants_state,
      conditions = conditions,
      day_of_simulation = day_of_simulation,
      minute_limit = minute_limit,
      forage_access_scale = forage_access_scale,
      seed = local_seed,
      apply_growth = FALSE
    )

    plants_state <- res$plants
    updated[[i]] <- res$herbivore
    rows[[i]] <- make_herbivore_daily_row(
      herbivore = res$herbivore,
      daily_summary = res$daily_summary,
      day_of_simulation = day_of_simulation
    )
  }

  daily_df <- do.call(rbind, rows)
  rownames(daily_df) <- NULL

  list(
    herbivores = updated,
    plants = plants_state,
    daily_summary = daily_df
  )
}

run_herbivore_cohort_days <- function(herbivores,
                                      plants,
                                      conditions,
                                      start_day,
                                      days,
                                      minute_limit,
                                      forage_access_scale = 1,
                                      seed = NULL) {
  state_herbivores <- sort_herbivore_cohort(herbivores)
  state_plants <- plants

  all_rows <- vector("list", as.integer(days))
  metric_rows <- vector("list", as.integer(days))
  first_day_plants <- NULL

  for (i in seq_len(as.integer(days))) {
    current_day <- as.integer(start_day + i - 1L)
    day_seed <- if (is.null(seed)) NULL else as.integer(seed + i * 100000L)

    day_res <- run_daily_herbivore_cohort(
      herbivores = state_herbivores,
      plants = state_plants,
      conditions = conditions,
      day_of_simulation = current_day,
      minute_limit = minute_limit,
      forage_access_scale = forage_access_scale,
      seed = day_seed
    )

    state_herbivores <- day_res$herbivores
    state_plants <- day_res$plants
    all_rows[[i]] <- day_res$daily_summary

    if (i == 1L) {
      first_day_plants <- state_plants
    }

    metric_rows[[i]] <- state_plants
  }

  list(
    herbivores = state_herbivores,
    plants = state_plants,
    first_day_plants = first_day_plants,
    daily_summary = do.call(rbind, all_rows),
    plants_by_day = metric_rows
  )
}

derive_implicit_visitation <- function(scenario) {
  validated <- validate_scenario_v1(scenario)
  if (!identical(validated$population$mode, "implicit_representative")) {
    rlang::abort(
      "Scenario population mode is not implicit representative mode.",
      class = "herbivoreTTR_implicit_mode_invalid",
      mode = validated$population$mode
    )
  }

  expected_visits <- validated$population$stocking_density_per_km2 *
    scenario_plot_area_km2(validated) *
    validated$population$visitation_rate_per_day

  expected_visits <- max(expected_visits, 0)

  list(
    plot_area_km2 = scenario_plot_area_km2(validated),
    stocking_density_per_km2 = validated$population$stocking_density_per_km2,
    visitation_rate_per_day = validated$population$visitation_rate_per_day,
    effective_visits_per_day = expected_visits,
    full_visits = floor(expected_visits),
    fractional_visit = expected_visits - floor(expected_visits)
  )
}

run_daily_implicit_representative <- function(representative_spec,
                                              visitation,
                                              plants,
                                              conditions,
                                              day_of_simulation,
                                              minute_limit,
                                              forage_access_scale = 1,
                                              feedback = NULL,
                                              seed = NULL) {
  day_index <- ((day_of_simulation - 1L) %% nrow(conditions)) + 1L
  plants_state <- transport_resistance(plants, conditions, day_index)

  visit_rows <- list()
  visit_counter <- 0L

  run_visit <- function(weight, minutes, tag, visit_seed_offset) {
    herb <- init_herbivore_from_spec(representative_spec, feedback = feedback)
    herb$herbivore_id <- sprintf("%s_%s", representative_spec$herbivore_id, tag)

    res <- run_daily_herbivore_simulation(
      herbivore = herb,
      plants = plants_state,
      conditions = conditions,
      day_of_simulation = day_of_simulation,
      minute_limit = minutes,
      forage_access_scale = forage_access_scale,
      seed = if (is.null(seed)) NULL else as.integer(seed + visit_seed_offset),
      apply_growth = FALSE
    )

    plants_state <<- res$plants
    row <- make_herbivore_daily_row(
      herbivore = res$herbivore,
      daily_summary = res$daily_summary,
      day_of_simulation = day_of_simulation
    )
    row$VisitWeight <- as.numeric(weight)
    row$VisitMinutes <- as.integer(minutes)
    row
  }

  if (visitation$full_visits > 0L) {
    for (i in seq_len(visitation$full_visits)) {
      visit_counter <- visit_counter + 1L
      visit_rows[[visit_counter]] <- run_visit(
        weight = 1,
        minutes = as.integer(minute_limit),
        tag = sprintf("full_%03d", i),
        visit_seed_offset = i * 1000L
      )
    }
  }

  if (visitation$fractional_visit > CONSTANTS$TOLERANCE) {
    visit_counter <- visit_counter + 1L
    frac_minutes <- max(1L, as.integer(ceiling(minute_limit * visitation$fractional_visit)))
    visit_rows[[visit_counter]] <- run_visit(
      weight = visitation$fractional_visit,
      minutes = frac_minutes,
      tag = "fractional",
      visit_seed_offset = 99999L
    )
  }

  if (length(visit_rows) == 0L) {
    empty <- data.frame(
      HerbivoreID = character(),
      Day = integer(),
      HerbType = integer(),
      DailyDistMoved = numeric(),
      DailyPEI = numeric(),
      DailyNPEI = numeric(),
      DailyDMI = numeric(),
      DailyForageWater = numeric(),
      DailyWaterDrinking = numeric(),
      MaintenanceEnergyReq = numeric(),
      EnergyBalanceRatio = numeric(),
      WaterRequirement = numeric(),
      WaterBalanceRatio = numeric(),
      EnergyDeficitStreakDays = integer(),
      WaterDeficitStreakDays = integer(),
      BodyConditionIndex = numeric(),
      PhysiologicalStressFlag = integer(),
      WaterBalance = numeric(),
      EnergyBalance = numeric(),
      VisitWeight = numeric(),
      VisitMinutes = integer(),
      stringsAsFactors = FALSE
    )

    aggregated <- data.frame(
      HerbivoreID = representative_spec$herbivore_id,
      Day = as.integer(day_of_simulation),
      HerbType = as.integer(representative_spec$herb_type),
      DailyDistMoved = 0,
      DailyPEI = 0,
      DailyNPEI = 0,
      DailyDMI = 0,
      DailyForageWater = 0,
      DailyWaterDrinking = 0,
      MaintenanceEnergyReq = 0,
      EnergyBalanceRatio = 0,
      WaterRequirement = 0,
      WaterBalanceRatio = 0,
      EnergyDeficitStreakDays = 0L,
      WaterDeficitStreakDays = 0L,
      BodyConditionIndex = as.numeric(if (is.null(feedback$initial_bci)) CONSTANTS$BODY_CONDITION_INITIAL else feedback$initial_bci),
      PhysiologicalStressFlag = 0L,
      WaterBalance = 0,
      EnergyBalance = 0,
      EffectiveVisitsPerDay = visitation$effective_visits_per_day,
      stringsAsFactors = FALSE
    )

    return(list(
      plants = plants_state,
      visit_summary = empty,
      aggregated_summary = aggregated
    ))
  }

  visit_df <- do.call(rbind, visit_rows)
  total_weight <- sum(visit_df$VisitWeight)
  if (total_weight <= 0) {
    total_weight <- 1
  }

  weighted_mean <- function(x) sum(x * visit_df$VisitWeight) / total_weight

  aggregated <- data.frame(
    HerbivoreID = representative_spec$herbivore_id,
    Day = as.integer(day_of_simulation),
    HerbType = as.integer(representative_spec$herb_type),
    DailyDistMoved = weighted_mean(visit_df$DailyDistMoved),
    DailyPEI = weighted_mean(visit_df$DailyPEI),
    DailyNPEI = weighted_mean(visit_df$DailyNPEI),
    DailyDMI = weighted_mean(visit_df$DailyDMI),
    DailyForageWater = weighted_mean(visit_df$DailyForageWater),
    DailyWaterDrinking = weighted_mean(visit_df$DailyWaterDrinking),
    MaintenanceEnergyReq = weighted_mean(visit_df$MaintenanceEnergyReq),
    EnergyBalanceRatio = weighted_mean(visit_df$EnergyBalanceRatio),
    WaterRequirement = weighted_mean(visit_df$WaterRequirement),
    WaterBalanceRatio = weighted_mean(visit_df$WaterBalanceRatio),
    EnergyDeficitStreakDays = as.integer(round(weighted_mean(visit_df$EnergyDeficitStreakDays))),
    WaterDeficitStreakDays = as.integer(round(weighted_mean(visit_df$WaterDeficitStreakDays))),
    BodyConditionIndex = weighted_mean(visit_df$BodyConditionIndex),
    PhysiologicalStressFlag = as.integer(round(weighted_mean(visit_df$PhysiologicalStressFlag))),
    WaterBalance = weighted_mean(visit_df$WaterBalance),
    EnergyBalance = weighted_mean(visit_df$EnergyBalance),
    EffectiveVisitsPerDay = visitation$effective_visits_per_day,
    stringsAsFactors = FALSE
  )

  list(
    plants = plants_state,
    visit_summary = visit_df,
    aggregated_summary = aggregated
  )
}

normalise_herbivore_daily_output <- function(daily_df,
                                             run_id,
                                             scenario_id,
                                             scenario_slug,
                                             population_mode) {
  out <- daily_df
  out$RunID <- run_id
  out$SchemaVersion <- output_schema_version()
  out$ScenarioID <- scenario_id
  out$ScenarioSlug <- scenario_slug
  out$PopulationMode <- population_mode

  preferred <- c(
    "RunID", "SchemaVersion", "ScenarioID", "ScenarioSlug", "PopulationMode",
    "HerbivoreID", "Day", "HerbType", "DailyDistMoved", "DailyPEI", "DailyNPEI",
    "DailyDMI", "DailyForageWater", "DailyWaterDrinking",
    "MaintenanceEnergyReq", "EnergyBalanceRatio", "WaterRequirement", "WaterBalanceRatio",
    "EnergyDeficitStreakDays", "WaterDeficitStreakDays", "BodyConditionIndex", "PhysiologicalStressFlag",
    "WaterBalance", "EnergyBalance"
  )
  remaining <- setdiff(names(out), preferred)
  out <- out[, c(preferred, remaining), drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Run a validated scenario and write canonical artefacts
#'
#' Executes one scenario under the v1 scenario contract across the configured
#' day range and writes canonical output files plus `run_manifest.json`.
#'
#' @param scenario Scenario list or path/slug to a scenario YAML.
#' @param base_dir Base directory for canonical artefacts.
#' @param write_outputs Logical; when `FALSE`, returns in-memory outputs only.
#'
#' @return A list containing run metadata, output paths, and in-memory tables.
#' @export
run_scenario_v1 <- function(scenario,
                            base_dir = file.path("artefacts", "canonical_runs"),
                            write_outputs = TRUE) {
  validated <- if (is.character(scenario)) {
    compile_scenario_yaml(scenario)
  } else {
    validate_scenario_v1(scenario)
  }

  with_optional_seed(validated$runtime$seed, {
    conditions <- build_conditions_from_scenario(validated)
    plants <- init_plants(veg_types = validated$plot$veg_types)

    run_id <- build_run_id(
      scenario_slug = validated$outputs$scenario_slug,
      seed = validated$runtime$seed,
      scenario_parameters = validated
    )

    run_dir <- file.path(base_dir, validated$outputs$scenario_slug)
    first_day <- validated$runtime$start_day
    last_day <- validated$runtime$start_day + validated$runtime$days - 1L

    herb_daily <- NULL
    metrics_rows <- vector("list", validated$runtime$days)
    visit_detail <- NULL
    final_herbivores <- list()
    first_day_plants <- NULL
    final_plants <- plants

    if (validated$population$mode == "explicit_single") {
      herb <- init_herbivore_from_spec(validated$population$cohort[[1]], feedback = validated$feedback)

      herb_rows <- vector("list", validated$runtime$days)
      for (i in seq_len(validated$runtime$days)) {
        current_day <- first_day + i - 1L
        day_seed <- as.integer(validated$runtime$seed + i * 100000L)

        day_res <- run_daily_herbivore_simulation(
          herbivore = herb,
          plants = final_plants,
          conditions = conditions,
          day_of_simulation = current_day,
          minute_limit = validated$runtime$minute_limit,
          forage_access_scale = validated$runtime$forage_access_scale,
          seed = day_seed,
          apply_growth = TRUE
        )

        herb <- day_res$herbivore
        final_plants <- day_res$plants
        herb_rows[[i]] <- make_herbivore_daily_row(herb, day_res$daily_summary, current_day)
        metrics_rows[[i]] <- derive_structure_fuel_metrics(
          plants = final_plants,
          day_of_simulation = current_day,
          run_id = run_id,
          scenario_id = validated$scenario_id,
          scenario_slug = validated$outputs$scenario_slug,
          population_mode = validated$population$mode
        )

        if (i == 1L) {
          first_day_plants <- final_plants
        }
      }

      herb_daily <- do.call(rbind, herb_rows)
      final_herbivores <- list(herb)

    } else if (validated$population$mode == "explicit_cohort") {
      cohort <- init_cohort_from_scenario(validated)
      cohort_res <- run_herbivore_cohort_days(
        herbivores = cohort,
        plants = final_plants,
        conditions = conditions,
        start_day = first_day,
        days = validated$runtime$days,
        minute_limit = validated$runtime$minute_limit,
        forage_access_scale = validated$runtime$forage_access_scale,
        seed = validated$runtime$seed
      )

      herb_daily <- cohort_res$daily_summary
      first_day_plants <- cohort_res$first_day_plants
      final_plants <- cohort_res$plants
      final_herbivores <- cohort_res$herbivores

      for (i in seq_len(validated$runtime$days)) {
        current_day <- first_day + i - 1L
        metrics_rows[[i]] <- derive_structure_fuel_metrics(
          plants = cohort_res$plants_by_day[[i]],
          day_of_simulation = current_day,
          run_id = run_id,
          scenario_id = validated$scenario_id,
          scenario_slug = validated$outputs$scenario_slug,
          population_mode = validated$population$mode
        )
      }

    } else if (validated$population$mode == "implicit_representative") {
      representative <- validated$population$representative
      visitation <- derive_implicit_visitation(validated)

      daily_rows <- vector("list", validated$runtime$days)
      visit_rows <- vector("list", validated$runtime$days)

      for (i in seq_len(validated$runtime$days)) {
        current_day <- first_day + i - 1L
        day_seed <- as.integer(validated$runtime$seed + i * 100000L)

        day_res <- run_daily_implicit_representative(
          representative_spec = representative,
          visitation = visitation,
          plants = final_plants,
          conditions = conditions,
          day_of_simulation = current_day,
          minute_limit = validated$runtime$minute_limit,
          forage_access_scale = validated$runtime$forage_access_scale,
          feedback = validated$feedback,
          seed = day_seed
        )

        final_plants <- day_res$plants
        daily_rows[[i]] <- day_res$aggregated_summary
        visit_rows[[i]] <- day_res$visit_summary
        metrics_rows[[i]] <- derive_structure_fuel_metrics(
          plants = final_plants,
          day_of_simulation = current_day,
          run_id = run_id,
          scenario_id = validated$scenario_id,
          scenario_slug = validated$outputs$scenario_slug,
          population_mode = validated$population$mode
        )

        if (i == 1L) {
          first_day_plants <- final_plants
        }
      }

      herb_daily <- do.call(rbind, daily_rows)
      visit_detail <- do.call(rbind, visit_rows)
      final_herbivores <- list()

      herb_daily$stocking_density_per_km2 <- visitation$stocking_density_per_km2
      herb_daily$visitation_rate_per_day <- visitation$visitation_rate_per_day
      herb_daily$effective_visits_per_day <- visitation$effective_visits_per_day
    }

    herb_daily <- normalise_herbivore_daily_output(
      daily_df = herb_daily,
      run_id = run_id,
      scenario_id = validated$scenario_id,
      scenario_slug = validated$outputs$scenario_slug,
      population_mode = validated$population$mode
    )

    structure_metrics <- do.call(rbind, metrics_rows)
    rownames(structure_metrics) <- NULL

    if (!isTRUE(write_outputs)) {
      return(list(
        run_id = run_id,
        run_dir = run_dir,
        scenario = validated,
        first_day_plants = first_day_plants,
        final_plants = final_plants,
        final_herbivores = final_herbivores,
        herbivore_daily = herb_daily,
        structure_fuel_metrics = structure_metrics,
        visit_detail = visit_detail
      ))
    }

    dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

    plants_first_path <- file.path(run_dir, sprintf("plants_day%d.csv", first_day))
    plants_last_path <- file.path(run_dir, sprintf("plants_day%d.csv", last_day))
    herb_daily_path <- file.path(run_dir, "herbivore_daily.csv")
    structure_path <- file.path(run_dir, "structure_fuel_daily.csv")

    write_plants_daily(
      plants = first_day_plants,
      day = first_day,
      year = 1L,
      path = plants_first_path,
      run_id = run_id
    )
    write_plants_daily(
      plants = final_plants,
      day = last_day,
      year = 1L,
      path = plants_last_path,
      run_id = run_id
    )
    utils::write.csv(herb_daily, herb_daily_path, row.names = FALSE)
    write_structure_fuel_metrics(structure_metrics, structure_path)

    output_files <- c(
      plants_first_day = file.path(base_dir, validated$outputs$scenario_slug, basename(plants_first_path)),
      plants_last_day = file.path(base_dir, validated$outputs$scenario_slug, basename(plants_last_path)),
      herbivore_daily = file.path(base_dir, validated$outputs$scenario_slug, basename(herb_daily_path)),
      structure_fuel_daily = file.path(base_dir, validated$outputs$scenario_slug, basename(structure_path))
    )

    visit_path <- NULL
    if (!is.null(visit_detail) && nrow(visit_detail) > 0L) {
      visit_path <- file.path(run_dir, "implicit_visit_detail.csv")
      utils::write.csv(visit_detail, visit_path, row.names = FALSE)
      output_files <- c(
        output_files,
        implicit_visit_detail = file.path(base_dir, validated$outputs$scenario_slug, basename(visit_path))
      )
    }

    manifest <- build_run_manifest(
      scenario_slug = validated$outputs$scenario_slug,
      seed = validated$runtime$seed,
      scenario_parameters = validated,
      output_files = output_files,
      run_id = run_id
    )
    manifest_path <- file.path(run_dir, "run_manifest.json")
    write_run_manifest(manifest, manifest_path)

    list(
      run_id = run_id,
      run_dir = run_dir,
      scenario = validated,
      plants_first_path = plants_first_path,
      plants_last_path = plants_last_path,
      herbivore_daily_path = herb_daily_path,
      structure_fuel_path = structure_path,
      implicit_visit_path = visit_path,
      manifest_path = manifest_path,
      final_herbivores = final_herbivores,
      herbivore_daily = herb_daily,
      structure_fuel_metrics = structure_metrics,
      visit_detail = visit_detail
    )
  })
}
