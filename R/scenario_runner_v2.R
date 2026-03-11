# Scenario execution helpers for contract v2 and implicit-pressure outputs.

run_scenario_legacy_v1 <- run_scenario_v1

derive_implicit_visitation_v2 <- function(scenario) {
  validated <- validate_scenario_v2(scenario)
  if (!identical(validated$population$mode, "implicit_pressure")) {
    rlang::abort(
      "Scenario population mode is not implicit pressure mode.",
      class = "herbivoreTTR_implicit_pressure_mode_invalid",
      mode = validated$population$mode
    )
  }

  effective_visits <- validated$population$stocking_density_per_km2 *
    scenario_plot_area_km2(validated) *
    validated$population$visitation_rate_per_day
  effective_visits <- max(effective_visits, 0)

  list(
    plot_area_km2 = scenario_plot_area_km2(validated),
    stocking_density_per_km2 = validated$population$stocking_density_per_km2,
    visitation_rate_per_day = validated$population$visitation_rate_per_day,
    effective_visits_per_day = effective_visits,
    full_visits = floor(effective_visits),
    fractional_visit = effective_visits - floor(effective_visits)
  )
}

build_pressure_daily_row_v2 <- function(template_spec,
                                        visitation,
                                        visit_df,
                                        day_of_simulation) {
  if (!is.data.frame(visit_df) || nrow(visit_df) < 1L) {
    return(data.frame(
      TemplateHerbivoreID = as.character(template_spec$herbivore_id),
      Day = as.integer(day_of_simulation),
      HerbType = as.integer(template_spec$herb_type),
      VisitCount = 0L,
      FullVisits = as.integer(visitation$full_visits),
      FractionalVisit = as.numeric(visitation$fractional_visit),
      EffectiveVisitsPerDay = as.numeric(visitation$effective_visits_per_day),
      TotalPressurePEI = 0,
      TotalPressureNPEI = 0,
      TotalPressureDMI = 0,
      TotalPressureDistMoved = 0,
      TotalPressureForageWater = 0,
      TotalPressureDrinkingWater = 0,
      TotalPressureVisitMinutes = 0,
      stringsAsFactors = FALSE
    ))
  }

  weight_total <- function(column) sum(as.numeric(visit_df[[column]]) * as.numeric(visit_df$VisitWeight))

  data.frame(
    TemplateHerbivoreID = as.character(template_spec$herbivore_id),
    Day = as.integer(day_of_simulation),
    HerbType = as.integer(template_spec$herb_type),
    VisitCount = as.integer(nrow(visit_df)),
    FullVisits = as.integer(visitation$full_visits),
    FractionalVisit = as.numeric(visitation$fractional_visit),
    EffectiveVisitsPerDay = as.numeric(visitation$effective_visits_per_day),
    TotalPressurePEI = weight_total("DailyPEI"),
    TotalPressureNPEI = weight_total("DailyNPEI"),
    TotalPressureDMI = weight_total("DailyDMI"),
    TotalPressureDistMoved = weight_total("DailyDistMoved"),
    TotalPressureForageWater = weight_total("DailyForageWater"),
    TotalPressureDrinkingWater = weight_total("DailyWaterDrinking"),
    TotalPressureVisitMinutes = weight_total("VisitMinutes"),
    stringsAsFactors = FALSE
  )
}

normalise_pressure_daily_output_v2 <- function(pressure_df,
                                               run_id,
                                               scenario_id,
                                               scenario_slug,
                                               population_mode,
                                               visitation) {
  out <- pressure_df
  out$RunID <- run_id
  out$SchemaVersion <- output_schema_version()
  out$ScenarioID <- scenario_id
  out$ScenarioSlug <- scenario_slug
  out$PopulationMode <- population_mode
  out$stocking_density_per_km2 <- as.numeric(visitation$stocking_density_per_km2)
  out$visitation_rate_per_day <- as.numeric(visitation$visitation_rate_per_day)

  preferred <- c(
    "RunID", "SchemaVersion", "ScenarioID", "ScenarioSlug", "PopulationMode",
    "TemplateHerbivoreID", "Day", "HerbType", "VisitCount", "FullVisits",
    "FractionalVisit", "EffectiveVisitsPerDay", "TotalPressurePEI",
    "TotalPressureNPEI", "TotalPressureDMI", "TotalPressureDistMoved",
    "TotalPressureForageWater", "TotalPressureDrinkingWater",
    "TotalPressureVisitMinutes", "stocking_density_per_km2",
    "visitation_rate_per_day"
  )
  out <- out[, preferred, drop = FALSE]
  rownames(out) <- NULL
  out
}

run_daily_implicit_pressure_v2 <- function(template_spec,
                                           visitation,
                                           plants,
                                           conditions,
                                           day_of_simulation,
                                           minute_limit,
                                           forage_access_scale = 1,
                                           feedback = NULL,
                                           seed = NULL,
                                           plant_backend = "internal_ttr") {
  backend <- resolve_plant_backend(plant_backend)
  day_index <- ((day_of_simulation - 1L) %% nrow(conditions)) + 1L
  plants_state <- backend$step_day(plants, conditions, day_index)

  visit_rows <- list()
  visit_counter <- 0L

  run_visit <- function(weight, minutes, tag, visit_seed_offset) {
    herb <- init_herbivore_from_spec(template_spec, feedback = feedback)
    herb$herbivore_id <- sprintf("%s_%s", template_spec$herbivore_id, tag)

    res <- run_daily_herbivore_simulation(
      herbivore = herb,
      plants = plants_state,
      conditions = conditions,
      day_of_simulation = day_of_simulation,
      minute_limit = minutes,
      forage_access_scale = forage_access_scale,
      seed = if (is.null(seed)) NULL else as.integer(seed + visit_seed_offset),
      apply_growth = FALSE,
      plant_backend = plant_backend
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
    empty_visit <- data.frame(
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

    return(list(
      plants = plants_state,
      visit_summary = empty_visit,
      pressure_daily = build_pressure_daily_row_v2(
        template_spec = template_spec,
        visitation = visitation,
        visit_df = empty_visit,
        day_of_simulation = day_of_simulation
      )
    ))
  }

  visit_df <- do.call(rbind, visit_rows)
  rownames(visit_df) <- NULL

  list(
    plants = plants_state,
    visit_summary = visit_df,
    pressure_daily = build_pressure_daily_row_v2(
      template_spec = template_spec,
      visitation = visitation,
      visit_df = visit_df,
      day_of_simulation = day_of_simulation
    )
  )
}

#' Run a validated scenario and write canonical artefacts (v2)
#'
#' Executes one scenario under the v2 scenario contract across the configured
#' day range and writes canonical output files plus `run_manifest.json`.
#'
#' @param scenario Scenario list or path/slug to a scenario YAML.
#' @param base_dir Base directory for canonical artefacts.
#' @param write_outputs Logical; when `FALSE`, returns in-memory outputs only.
#' @param plant_backend Plant backend name or backend interface list passed
#'   through to daily runner helpers.
#'
#' @return A list containing run metadata, output paths, and in-memory tables.
#' @export
run_scenario_v2 <- function(scenario,
                            base_dir = file.path("artefacts", "canonical_runs"),
                            write_outputs = TRUE,
                            plant_backend = "internal_ttr") {
  validated <- if (is.character(scenario)) {
    compile_scenario_yaml_v2(scenario)
  } else {
    validate_scenario_v2(scenario)
  }
  backend <- resolve_plant_backend(plant_backend)

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
    pressure_daily <- NULL
    metrics_rows <- vector("list", validated$runtime$days)
    visit_detail <- NULL
    final_herbivores <- list()
    first_day_plants <- NULL
    final_plants <- plants
    daily_output_kind <- "explicit_individual"
    daily_output <- NULL

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
          apply_growth = TRUE,
          plant_backend = backend
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
        seed = validated$runtime$seed,
        plant_backend = backend
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

    } else if (validated$population$mode == "implicit_pressure") {
      template <- validated$population$template_herbivore
      visitation <- derive_implicit_visitation_v2(validated)

      pressure_rows <- vector("list", validated$runtime$days)
      visit_rows <- vector("list", validated$runtime$days)
      daily_output_kind <- "implicit_pressure"

      for (i in seq_len(validated$runtime$days)) {
        current_day <- first_day + i - 1L
        day_seed <- as.integer(validated$runtime$seed + i * 100000L)

        day_res <- run_daily_implicit_pressure_v2(
          template_spec = template,
          visitation = visitation,
          plants = final_plants,
          conditions = conditions,
          day_of_simulation = current_day,
          minute_limit = validated$runtime$minute_limit,
          forage_access_scale = validated$runtime$forage_access_scale,
          feedback = validated$feedback,
          seed = day_seed,
          plant_backend = backend
        )

        final_plants <- day_res$plants
        pressure_rows[[i]] <- day_res$pressure_daily
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

      pressure_daily <- do.call(rbind, pressure_rows)
      pressure_daily <- normalise_pressure_daily_output_v2(
        pressure_df = pressure_daily,
        run_id = run_id,
        scenario_id = validated$scenario_id,
        scenario_slug = validated$outputs$scenario_slug,
        population_mode = validated$population$mode,
        visitation = visitation
      )
      visit_detail <- do.call(rbind, visit_rows)
      if (!is.null(visit_detail)) {
        rownames(visit_detail) <- NULL
      }
      final_herbivores <- list()
    }

    if (daily_output_kind == "explicit_individual") {
      herb_daily <- normalise_herbivore_daily_output(
        daily_df = herb_daily,
        run_id = run_id,
        scenario_id = validated$scenario_id,
        scenario_slug = validated$outputs$scenario_slug,
        population_mode = validated$population$mode
      )
      daily_output <- herb_daily
    } else {
      daily_output <- pressure_daily
    }

    structure_metrics <- do.call(rbind, metrics_rows)
    rownames(structure_metrics) <- NULL

    if (!isTRUE(write_outputs)) {
      return(list(
        run_id = run_id,
        run_dir = run_dir,
        plant_backend = backend$name,
        scenario = validated,
        daily_output_kind = daily_output_kind,
        daily_output = daily_output,
        herbivore_daily = herb_daily,
        pressure_daily = pressure_daily,
        first_day_plants = first_day_plants,
        final_plants = final_plants,
        final_herbivores = final_herbivores,
        structure_fuel_metrics = structure_metrics,
        visit_detail = visit_detail
      ))
    }

    dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

    plants_first_path <- file.path(run_dir, sprintf("plants_day%d.csv", first_day))
    plants_last_path <- file.path(run_dir, sprintf("plants_day%d.csv", last_day))
    daily_output_filename <- if (identical(daily_output_kind, "implicit_pressure")) {
      "pressure_daily.csv"
    } else {
      "herbivore_daily.csv"
    }
    daily_output_path <- file.path(run_dir, daily_output_filename)
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
    utils::write.csv(daily_output, daily_output_path, row.names = FALSE)
    write_structure_fuel_metrics(structure_metrics, structure_path)

    output_files <- c(
      plants_first_day = file.path(base_dir, validated$outputs$scenario_slug, basename(plants_first_path)),
      plants_last_day = file.path(base_dir, validated$outputs$scenario_slug, basename(plants_last_path)),
      structure_fuel_daily = file.path(base_dir, validated$outputs$scenario_slug, basename(structure_path))
    )
    if (identical(daily_output_kind, "implicit_pressure")) {
      output_files <- c(
        output_files,
        pressure_daily = file.path(base_dir, validated$outputs$scenario_slug, basename(daily_output_path))
      )
    } else {
      output_files <- c(
        output_files,
        herbivore_daily = file.path(base_dir, validated$outputs$scenario_slug, basename(daily_output_path))
      )
    }

    visit_path <- NULL
    if (!is.null(visit_detail) && nrow(visit_detail) > 0L) {
      visit_path <- file.path(run_dir, "implicit_visit_detail.csv")
      utils::write.csv(visit_detail, visit_path, row.names = FALSE)
      output_files <- c(
        output_files,
        implicit_visit_detail = file.path(base_dir, validated$outputs$scenario_slug, basename(visit_path))
      )
    }

    manifest_parameters <- validated
    manifest_parameters$runtime$plant_backend <- backend$name
    manifest <- build_run_manifest(
      scenario_slug = validated$outputs$scenario_slug,
      seed = validated$runtime$seed,
      scenario_parameters = manifest_parameters,
      output_files = output_files,
      run_id = run_id,
      daily_output_kind = daily_output_kind
    )
    manifest_path <- file.path(run_dir, "run_manifest.json")
    write_run_manifest(manifest, manifest_path)

    list(
      run_id = run_id,
      run_dir = run_dir,
      plant_backend = backend$name,
      scenario = validated,
      daily_output_kind = daily_output_kind,
      daily_output = daily_output,
      daily_output_path = daily_output_path,
      plants_first_path = plants_first_path,
      plants_last_path = plants_last_path,
      herbivore_daily_path = if (identical(daily_output_kind, "explicit_individual")) daily_output_path else NULL,
      pressure_daily_path = if (identical(daily_output_kind, "implicit_pressure")) daily_output_path else NULL,
      structure_fuel_path = structure_path,
      implicit_visit_path = visit_path,
      manifest_path = manifest_path,
      first_day_plants = first_day_plants,
      final_plants = final_plants,
      final_herbivores = final_herbivores,
      herbivore_daily = herb_daily,
      pressure_daily = pressure_daily,
      structure_fuel_metrics = structure_metrics,
      visit_detail = visit_detail
    )
  })
}

derive_implicit_visitation <- derive_implicit_visitation_v2
run_scenario_v1 <- run_scenario_v2
