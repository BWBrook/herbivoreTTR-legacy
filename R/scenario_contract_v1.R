# Scenario contract v1: object schema + YAML compile helpers.

#' Scenario contract schema version
#'
#' Returns the schema version required by scenario YAML files and validated
#' scenario objects.
#'
#' @return Scalar character scenario schema version.
#' @export
scenario_contract_version <- function() {
  "1.0.0"
}

## @noRd
scenario_find_repo_root <- function(start = getwd()) {
  dir <- normalizePath(start, winslash = "/", mustWork = TRUE)
  for (i in 0:12) {
    if (file.exists(file.path(dir, "DESCRIPTION"))) {
      return(dir)
    }
    parent <- dirname(dir)
    if (identical(parent, dir)) {
      break
    }
    dir <- parent
  }
  NULL
}

## @noRd
#' Resolve a packaged/reference scenario YAML path
#'
#' Looks up a scenario YAML by slug under `config/scenarios/` (repo checkout) or
#' `inst/extdata/scenarios/` (installed package fallback).
#'
#' @param name Scenario slug or YAML file name.
#'
#' @return Absolute path to an existing scenario YAML when found, otherwise the
#'   best candidate path for diagnostics.
#' @export
scenario_contract_reference_path <- function(name = "canonical_smoke_v1") {
  if (!is.character(name) || length(name) != 1L || !nzchar(name)) {
    rlang::abort(
      "Argument `name` must be a non-empty scalar character.",
      class = "herbivoreTTR_scenario_v1_name_invalid",
      name = name
    )
  }

  file_name <- if (grepl("\\.ya?ml$", name)) name else sprintf("%s.yaml", name)

  repo_root <- scenario_find_repo_root()
  candidates <- c()
  if (!is.null(repo_root)) {
    candidates <- c(
      candidates,
      file.path(repo_root, "config", "scenarios", file_name),
      file.path(repo_root, "inst", "extdata", "scenarios", file_name)
    )
  }

  installed <- system.file("extdata", "scenarios", file_name, package = "herbivoreTTR")
  if (nzchar(installed)) {
    candidates <- c(candidates, installed)
  }

  existing <- candidates[file.exists(candidates)]
  if (length(existing) > 0L) {
    return(normalizePath(existing[[1]], winslash = "/", mustWork = TRUE))
  }

  if (!is.null(repo_root)) {
    return(file.path(repo_root, "config", "scenarios", file_name))
  }
  file.path("config", "scenarios", file_name)
}

## @noRd
resolve_scenario_yaml_path <- function(path) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
    rlang::abort(
      "Argument `path` must be a non-empty scalar character.",
      class = "herbivoreTTR_scenario_v1_path_invalid",
      path = path
    )
  }

  if (file.exists(path)) {
    return(normalizePath(path, winslash = "/", mustWork = TRUE))
  }

  repo_root <- scenario_find_repo_root()
  if (!is.null(repo_root)) {
    rooted <- file.path(repo_root, path)
    if (file.exists(rooted)) {
      return(normalizePath(rooted, winslash = "/", mustWork = TRUE))
    }
  }

  by_name <- scenario_contract_reference_path(path)
  if (file.exists(by_name)) {
    return(normalizePath(by_name, winslash = "/", mustWork = TRUE))
  }

  rlang::abort(
    "Scenario YAML file does not exist.",
    class = "herbivoreTTR_scenario_v1_path_missing",
    path = path
  )
}

## @noRd
normalize_herbivore_spec <- function(spec, context = "cohort") {
  if (!is.list(spec)) {
    rlang::abort(
      sprintf("Scenario `%s` herbivore entry must be a list.", context),
      class = "herbivoreTTR_scenario_v1_herbivore_spec_invalid",
      context = context
    )
  }

  herbivore_id <- as.character(spec$herbivore_id)
  if (!nzchar(herbivore_id)) {
    rlang::abort(
      sprintf("Scenario `%s` herbivore entry requires non-empty `herbivore_id`.", context),
      class = "herbivoreTTR_scenario_v1_herbivore_id_missing",
      context = context
    )
  }

  mass_g <- as.numeric(spec$mass_g)
  herb_type <- as.integer(spec$herb_type)
  mrt_hours <- as.integer(spec$MRT_hours)
  foraging_mode <- if (is.null(spec$foraging_mode)) {
    "nutrient_targeting"
  } else {
    as.character(spec$foraging_mode)
  }

  if (!is.finite(mass_g) || mass_g <= 0) {
    rlang::abort(
      sprintf("Scenario `%s` herbivore `%s` requires positive `mass_g`.", context, herbivore_id),
      class = "herbivoreTTR_scenario_v1_mass_invalid",
      herbivore_id = herbivore_id,
      mass_g = mass_g
    )
  }

  if (!is.finite(herb_type) || !herb_type %in% c(0L, 1L, 2L)) {
    rlang::abort(
      sprintf("Scenario `%s` herbivore `%s` requires `herb_type` in {0,1,2}.", context, herbivore_id),
      class = "herbivoreTTR_scenario_v1_herb_type_invalid",
      herbivore_id = herbivore_id,
      herb_type = herb_type
    )
  }

  if (!is.finite(mrt_hours) || mrt_hours < 1L) {
    rlang::abort(
      sprintf("Scenario `%s` herbivore `%s` requires positive `MRT_hours`.", context, herbivore_id),
      class = "herbivoreTTR_scenario_v1_mrt_invalid",
      herbivore_id = herbivore_id,
      MRT_hours = mrt_hours
    )
  }

  if (!foraging_mode %in% foraging_mode_levels()) {
    rlang::abort(
      sprintf(
        "Scenario `%s` herbivore `%s` has invalid `foraging_mode` (expected one of: %s).",
        context,
        herbivore_id,
        paste(foraging_mode_levels(), collapse = ", ")
      ),
      class = "herbivoreTTR_scenario_v1_foraging_mode_invalid",
      herbivore_id = herbivore_id,
      foraging_mode = foraging_mode
    )
  }

  list(
    herbivore_id = herbivore_id,
    mass_g = mass_g,
    herb_type = herb_type,
    MRT_hours = mrt_hours,
    foraging_mode = foraging_mode
  )
}

#' Validate a scenario object against contract v1
#'
#' Performs strict validation and normalization of scenario contract fields.
#'
#' @param scenario Scenario list object.
#'
#' @return Validated scenario list with normalized scalar types.
#' @export
validate_scenario_v1 <- function(scenario) {
  if (!is.list(scenario)) {
    rlang::abort(
      "Scenario must be a list.",
      class = "herbivoreTTR_scenario_v1_not_list"
    )
  }

  schema_version <- as.character(scenario$schema_version)
  if (!identical(schema_version, scenario_contract_version())) {
    rlang::abort(
      sprintf("Scenario `schema_version` must be `%s`.", scenario_contract_version()),
      class = "herbivoreTTR_scenario_v1_schema_version_invalid",
      schema_version = schema_version
    )
  }

  runtime <- scenario$runtime
  plot <- scenario$plot
  climate <- scenario$climate
  population <- scenario$population
  outputs <- scenario$outputs

  if (!is.list(runtime)) {
    rlang::abort("Scenario `runtime` must be a list.", class = "herbivoreTTR_scenario_v1_runtime_invalid")
  }
  if (!is.list(plot)) {
    rlang::abort("Scenario `plot` must be a list.", class = "herbivoreTTR_scenario_v1_plot_invalid")
  }
  if (!is.list(climate)) {
    rlang::abort("Scenario `climate` must be a list.", class = "herbivoreTTR_scenario_v1_climate_invalid")
  }
  if (!is.list(population)) {
    rlang::abort("Scenario `population` must be a list.", class = "herbivoreTTR_scenario_v1_population_invalid")
  }
  if (!is.list(outputs)) {
    rlang::abort("Scenario `outputs` must be a list.", class = "herbivoreTTR_scenario_v1_outputs_invalid")
  }

  seed <- as.integer(runtime$seed)
  minute_limit <- as.integer(runtime$minute_limit)
  days <- as.integer(runtime$days)
  start_day <- as.integer(runtime$start_day)

  if (length(seed) != 1L || !is.finite(seed)) {
    rlang::abort("Scenario `runtime$seed` must be finite.", class = "herbivoreTTR_scenario_v1_seed_invalid", seed = seed)
  }
  if (length(minute_limit) != 1L || !is.finite(minute_limit) || minute_limit < 1L) {
    rlang::abort("Scenario `runtime$minute_limit` must be >= 1.", class = "herbivoreTTR_scenario_v1_minute_limit_invalid", minute_limit = minute_limit)
  }
  if (length(days) != 1L || !is.finite(days) || days < 1L) {
    rlang::abort("Scenario `runtime$days` must be >= 1.", class = "herbivoreTTR_scenario_v1_days_invalid", days = days)
  }
  if (length(start_day) != 1L || !is.finite(start_day) || start_day < 1L) {
    rlang::abort("Scenario `runtime$start_day` must be >= 1.", class = "herbivoreTTR_scenario_v1_start_day_invalid", start_day = start_day)
  }

  veg_types <- as.integer(unlist(plot$veg_types, use.names = FALSE))
  if (length(veg_types) == 0L || any(!veg_types %in% c(0L, 1L, 2L))) {
    rlang::abort(
      "Scenario `plot$veg_types` must be a non-empty vector with values in {0,1,2}.",
      class = "herbivoreTTR_scenario_v1_veg_types_invalid",
      veg_types = veg_types
    )
  }

  plot_size_m2 <- as.numeric(plot$plot_size_m2)
  plants_in_x <- as.integer(plot$plants_in_x)
  plants_in_y <- as.integer(plot$plants_in_y)

  if (length(plot_size_m2) != 1L || !is.finite(plot_size_m2) || plot_size_m2 <= 0) {
    rlang::abort("Scenario `plot$plot_size_m2` must be positive.", class = "herbivoreTTR_scenario_v1_plot_size_invalid", plot_size_m2 = plot_size_m2)
  }
  if (length(plants_in_x) != 1L || !is.finite(plants_in_x) || plants_in_x < 1L ||
      length(plants_in_y) != 1L || !is.finite(plants_in_y) || plants_in_y < 1L) {
    rlang::abort(
      "Scenario `plot$plants_in_x` and `plot$plants_in_y` must be positive integers.",
      class = "herbivoreTTR_scenario_v1_plot_grid_invalid",
      plants_in_x = plants_in_x,
      plants_in_y = plants_in_y
    )
  }

  climate_mode <- as.character(climate$mode)
  if (!climate_mode %in% c("flat", "stochastic", "seasonal")) {
    rlang::abort(
      "Scenario `climate$mode` must be one of: flat, stochastic, seasonal.",
      class = "herbivoreTTR_scenario_v1_climate_mode_invalid",
      mode = climate_mode
    )
  }
  mean_temp <- as.numeric(if (is.null(climate$mean_temp)) 15 else climate$mean_temp)
  amplitude <- as.numeric(if (is.null(climate$amplitude)) 10 else climate$amplitude)
  sw_scale <- as.numeric(if (is.null(climate$sw_scale)) 1 else climate$sw_scale)
  n_scale <- as.numeric(if (is.null(climate$n_scale)) 1 else climate$n_scale)

  if (!is.finite(mean_temp) || !is.finite(amplitude) || amplitude < 0) {
    rlang::abort(
      "Scenario climate requires finite `mean_temp` and non-negative `amplitude`.",
      class = "herbivoreTTR_scenario_v1_climate_temp_invalid",
      mean_temp = mean_temp,
      amplitude = amplitude
    )
  }
  if (!is.finite(sw_scale) || sw_scale < 0 || !is.finite(n_scale) || n_scale < 0) {
    rlang::abort(
      "Scenario climate requires non-negative finite `sw_scale` and `n_scale`.",
      class = "herbivoreTTR_scenario_v1_climate_scaling_invalid",
      sw_scale = sw_scale,
      n_scale = n_scale
    )
  }

  population_mode <- as.character(population$mode)
  if (!population_mode %in% c("explicit_single", "explicit_cohort", "implicit_representative")) {
    rlang::abort(
      "Scenario `population$mode` must be one of: explicit_single, explicit_cohort, implicit_representative.",
      class = "herbivoreTTR_scenario_v1_population_mode_invalid",
      mode = population_mode
    )
  }

  cohort <- list()
  representative <- NULL
  stocking_density_per_km2 <- as.numeric(if (is.null(population$stocking_density_per_km2)) NA_real_ else population$stocking_density_per_km2)
  visitation_rate_per_day <- as.numeric(if (is.null(population$visitation_rate_per_day)) NA_real_ else population$visitation_rate_per_day)

  if (population_mode %in% c("explicit_single", "explicit_cohort")) {
    if (!is.list(population$cohort) || length(population$cohort) < 1L) {
      rlang::abort(
        "Explicit population modes require non-empty `population$cohort`.",
        class = "herbivoreTTR_scenario_v1_cohort_missing"
      )
    }
    cohort <- lapply(population$cohort, normalize_herbivore_spec, context = "cohort")
    ids <- vapply(cohort, `[[`, character(1), "herbivore_id")
    if (anyDuplicated(ids)) {
      rlang::abort(
        "Scenario cohort herbivore IDs must be unique.",
        class = "herbivoreTTR_scenario_v1_herbivore_id_duplicate",
        herbivore_ids = ids
      )
    }
    if (population_mode == "explicit_single" && length(cohort) != 1L) {
      rlang::abort(
        "`explicit_single` requires exactly one cohort herbivore entry.",
        class = "herbivoreTTR_scenario_v1_explicit_single_count_invalid",
        cohort_length = length(cohort)
      )
    }
  }

  if (population_mode == "implicit_representative") {
    representative <- normalize_herbivore_spec(population$representative, context = "representative")
    if (!is.finite(stocking_density_per_km2) || stocking_density_per_km2 < 0) {
      rlang::abort(
        "Implicit mode requires non-negative `population$stocking_density_per_km2`.",
        class = "herbivoreTTR_scenario_v1_stocking_density_invalid",
        stocking_density_per_km2 = stocking_density_per_km2
      )
    }
    if (!is.finite(visitation_rate_per_day) || visitation_rate_per_day < 0) {
      rlang::abort(
        "Implicit mode requires non-negative `population$visitation_rate_per_day`.",
        class = "herbivoreTTR_scenario_v1_visitation_rate_invalid",
        visitation_rate_per_day = visitation_rate_per_day
      )
    }
  }

  scenario_slug <- as.character(outputs$scenario_slug)
  if (!nzchar(scenario_slug)) {
    rlang::abort(
      "Scenario `outputs$scenario_slug` must be non-empty.",
      class = "herbivoreTTR_scenario_v1_scenario_slug_invalid",
      scenario_slug = scenario_slug
    )
  }

  scenario_id <- as.character(scenario$scenario_id)
  if (!nzchar(scenario_id)) {
    scenario_id <- scenario_slug
  }

  list(
    schema_version = scenario_contract_version(),
    scenario_id = scenario_id,
    runtime = list(
      seed = seed,
      minute_limit = minute_limit,
      days = days,
      start_day = start_day
    ),
    plot = list(
      veg_types = veg_types,
      plot_size_m2 = plot_size_m2,
      plants_in_x = plants_in_x,
      plants_in_y = plants_in_y
    ),
    climate = list(
      mode = climate_mode,
      mean_temp = mean_temp,
      amplitude = amplitude,
      sw_scale = sw_scale,
      n_scale = n_scale
    ),
    population = list(
      mode = population_mode,
      cohort = cohort,
      representative = representative,
      stocking_density_per_km2 = stocking_density_per_km2,
      visitation_rate_per_day = visitation_rate_per_day
    ),
    outputs = list(scenario_slug = scenario_slug)
  )
}

#' Compile and validate a scenario YAML file
#'
#' Loads a YAML scenario definition from disk and validates it against scenario
#' contract v1.
#'
#' @param path Path to a scenario YAML file or a scenario slug.
#'
#' @return Validated scenario list.
#' @export
compile_scenario_yaml <- function(path) {
  resolved_path <- resolve_scenario_yaml_path(path)

  if (!requireNamespace("yaml", quietly = TRUE)) {
    rlang::abort(
      "Package `yaml` is required to compile scenario YAML files.",
      class = "herbivoreTTR_scenario_v1_yaml_package_missing"
    )
  }

  raw <- yaml::read_yaml(resolved_path)
  scenario <- validate_scenario_v1(raw)
  scenario$source_yaml <- resolved_path
  scenario
}

scenario_primary_herbivore <- function(scenario) {
  validated <- validate_scenario_v1(scenario)
  mode <- validated$population$mode
  if (mode == "implicit_representative") {
    return(validated$population$representative)
  }
  validated$population$cohort[[1]]
}

scenario_to_canonical_parameters <- function(scenario, conditions) {
  validated <- validate_scenario_v1(scenario)
  herb <- scenario_primary_herbivore(validated)

  list(
    scenario_id = validated$scenario_id,
    veg_types = validated$plot$veg_types,
    herbivore_mass = herb$mass_g,
    herb_type = herb$herb_type,
    herbivore_mrt = herb$MRT_hours,
    herbivore_foraging_mode = herb$foraging_mode,
    minute_limit = validated$runtime$minute_limit,
    days = validated$runtime$days,
    start_day = validated$runtime$start_day,
    seed = validated$runtime$seed,
    scenario_slug = validated$outputs$scenario_slug,
    climate_mode = validated$climate$mode,
    temp_mode = validated$climate$mode,
    condition_rows = nrow(conditions)
  )
}
