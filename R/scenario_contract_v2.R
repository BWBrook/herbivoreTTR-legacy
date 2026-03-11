# Scenario contract v2: primary contract surface with legacy v1 migration.

scenario_contract_version_v1_legacy <- scenario_contract_version
validate_scenario_legacy_v1 <- validate_scenario_v1
compile_scenario_yaml_legacy_v1 <- compile_scenario_yaml
validate_paired_contrast_parity_legacy_v1 <- validate_paired_contrast_parity
scenario_primary_herbivore_legacy_v1 <- scenario_primary_herbivore
scenario_to_canonical_parameters_legacy_v1 <- scenario_to_canonical_parameters

#' Scenario contract schema version (v2)
#'
#' Returns the schema version required by the primary scenario YAML surface.
#'
#' @return Scalar character scenario schema version.
#' @export
scenario_contract_version_v2 <- function() {
  "2.0.0"
}

validate_scenario_v2_native <- function(scenario) {
  if (!is.list(scenario)) {
    rlang::abort(
      "Scenario must be a list.",
      class = "herbivoreTTR_scenario_v2_not_list"
    )
  }

  schema_version <- as.character(scenario$schema_version)
  if (!identical(schema_version, scenario_contract_version_v2())) {
    rlang::abort(
      sprintf("Scenario `schema_version` must be `%s`.", scenario_contract_version_v2()),
      class = "herbivoreTTR_scenario_v2_schema_version_invalid",
      schema_version = schema_version
    )
  }

  runtime <- scenario$runtime
  plot <- scenario$plot
  climate <- scenario$climate
  population <- scenario$population
  outputs <- scenario$outputs
  contrast_raw <- if (is.null(scenario$contrast)) list() else scenario$contrast
  feedback_raw <- if (is.null(scenario$feedback)) list() else scenario$feedback

  if (!is.list(runtime)) {
    rlang::abort("Scenario `runtime` must be a list.", class = "herbivoreTTR_scenario_v2_runtime_invalid")
  }
  if (!is.list(plot)) {
    rlang::abort("Scenario `plot` must be a list.", class = "herbivoreTTR_scenario_v2_plot_invalid")
  }
  if (!is.list(climate)) {
    rlang::abort("Scenario `climate` must be a list.", class = "herbivoreTTR_scenario_v2_climate_invalid")
  }
  if (!is.list(population)) {
    rlang::abort("Scenario `population` must be a list.", class = "herbivoreTTR_scenario_v2_population_invalid")
  }
  if (!is.list(outputs)) {
    rlang::abort("Scenario `outputs` must be a list.", class = "herbivoreTTR_scenario_v2_outputs_invalid")
  }
  if (!is.list(contrast_raw)) {
    rlang::abort("Scenario `contrast` must be a list when provided.", class = "herbivoreTTR_scenario_v2_contrast_invalid")
  }
  if (!is.list(feedback_raw)) {
    rlang::abort("Scenario `feedback` must be a list when provided.", class = "herbivoreTTR_scenario_v2_feedback_invalid")
  }

  seed <- as.integer(runtime$seed)
  minute_limit <- as.integer(runtime$minute_limit)
  days <- as.integer(runtime$days)
  start_day <- as.integer(runtime$start_day)
  forage_access_scale <- as.numeric(if (is.null(runtime$forage_access_scale)) 1 else runtime$forage_access_scale)

  if (length(seed) != 1L || !is.finite(seed)) {
    rlang::abort("Scenario `runtime$seed` must be finite.", class = "herbivoreTTR_scenario_v2_seed_invalid", seed = seed)
  }
  if (length(minute_limit) != 1L || !is.finite(minute_limit) || minute_limit < 1L) {
    rlang::abort("Scenario `runtime$minute_limit` must be >= 1.", class = "herbivoreTTR_scenario_v2_minute_limit_invalid", minute_limit = minute_limit)
  }
  if (length(days) != 1L || !is.finite(days) || days < 1L) {
    rlang::abort("Scenario `runtime$days` must be >= 1.", class = "herbivoreTTR_scenario_v2_days_invalid", days = days)
  }
  if (length(start_day) != 1L || !is.finite(start_day) || start_day < 1L) {
    rlang::abort("Scenario `runtime$start_day` must be >= 1.", class = "herbivoreTTR_scenario_v2_start_day_invalid", start_day = start_day)
  }
  if (length(forage_access_scale) != 1L || !is.finite(forage_access_scale) ||
      forage_access_scale <= 0 || forage_access_scale > 1) {
    rlang::abort(
      "Scenario `runtime$forage_access_scale` must be finite in (0,1].",
      class = "herbivoreTTR_scenario_v2_forage_access_scale_invalid",
      forage_access_scale = forage_access_scale
    )
  }

  veg_types <- as.integer(unlist(plot$veg_types, use.names = FALSE))
  if (length(veg_types) == 0L || any(!veg_types %in% c(0L, 1L, 2L))) {
    rlang::abort(
      "Scenario `plot$veg_types` must be a non-empty vector with values in {0,1,2}.",
      class = "herbivoreTTR_scenario_v2_veg_types_invalid",
      veg_types = veg_types
    )
  }

  plot_size_m2 <- as.numeric(plot$plot_size_m2)
  plants_in_x <- as.integer(plot$plants_in_x)
  plants_in_y <- as.integer(plot$plants_in_y)

  if (length(plot_size_m2) != 1L || !is.finite(plot_size_m2) || plot_size_m2 <= 0) {
    rlang::abort("Scenario `plot$plot_size_m2` must be positive.", class = "herbivoreTTR_scenario_v2_plot_size_invalid", plot_size_m2 = plot_size_m2)
  }
  if (length(plants_in_x) != 1L || !is.finite(plants_in_x) || plants_in_x < 1L ||
      length(plants_in_y) != 1L || !is.finite(plants_in_y) || plants_in_y < 1L) {
    rlang::abort(
      "Scenario `plot$plants_in_x` and `plot$plants_in_y` must be positive integers.",
      class = "herbivoreTTR_scenario_v2_plot_grid_invalid",
      plants_in_x = plants_in_x,
      plants_in_y = plants_in_y
    )
  }

  climate_mode <- as.character(climate$mode)
  if (!climate_mode %in% c("flat", "stochastic", "seasonal")) {
    rlang::abort(
      "Scenario `climate$mode` must be one of: flat, stochastic, seasonal.",
      class = "herbivoreTTR_scenario_v2_climate_mode_invalid",
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
      class = "herbivoreTTR_scenario_v2_climate_temp_invalid",
      mean_temp = mean_temp,
      amplitude = amplitude
    )
  }
  if (!is.finite(sw_scale) || sw_scale < 0 || !is.finite(n_scale) || n_scale < 0) {
    rlang::abort(
      "Scenario climate requires non-negative finite `sw_scale` and `n_scale`.",
      class = "herbivoreTTR_scenario_v2_climate_scaling_invalid",
      sw_scale = sw_scale,
      n_scale = n_scale
    )
  }

  population_mode <- as.character(population$mode)
  if (!population_mode %in% c("explicit_single", "explicit_cohort", "implicit_pressure")) {
    rlang::abort(
      "Scenario `population$mode` must be one of: explicit_single, explicit_cohort, implicit_pressure.",
      class = "herbivoreTTR_scenario_v2_population_mode_invalid",
      mode = population_mode
    )
  }

  cohort <- list()
  template_herbivore <- NULL
  stocking_density_per_km2 <- as.numeric(if (is.null(population$stocking_density_per_km2)) NA_real_ else population$stocking_density_per_km2)
  visitation_rate_per_day <- as.numeric(if (is.null(population$visitation_rate_per_day)) NA_real_ else population$visitation_rate_per_day)

  if (population_mode %in% c("explicit_single", "explicit_cohort")) {
    if (!is.list(population$cohort) || length(population$cohort) < 1L) {
      rlang::abort(
        "Explicit population modes require non-empty `population$cohort`.",
        class = "herbivoreTTR_scenario_v2_cohort_missing"
      )
    }
    cohort <- lapply(population$cohort, normalize_herbivore_spec, context = "cohort")
    ids <- vapply(cohort, `[[`, character(1), "herbivore_id")
    if (anyDuplicated(ids)) {
      rlang::abort(
        "Scenario cohort herbivore IDs must be unique.",
        class = "herbivoreTTR_scenario_v2_herbivore_id_duplicate",
        herbivore_ids = ids
      )
    }
    if (population_mode == "explicit_single" && length(cohort) != 1L) {
      rlang::abort(
        "`explicit_single` requires exactly one cohort herbivore entry.",
        class = "herbivoreTTR_scenario_v2_explicit_single_count_invalid",
        cohort_length = length(cohort)
      )
    }
  }

  if (population_mode == "implicit_pressure") {
    template_herbivore <- normalize_herbivore_spec(population$template_herbivore, context = "template_herbivore")
    if (!is.finite(stocking_density_per_km2) || stocking_density_per_km2 < 0) {
      rlang::abort(
        "Implicit pressure mode requires non-negative `population$stocking_density_per_km2`.",
        class = "herbivoreTTR_scenario_v2_stocking_density_invalid",
        stocking_density_per_km2 = stocking_density_per_km2
      )
    }
    if (!is.finite(visitation_rate_per_day) || visitation_rate_per_day < 0) {
      rlang::abort(
        "Implicit pressure mode requires non-negative `population$visitation_rate_per_day`.",
        class = "herbivoreTTR_scenario_v2_visitation_rate_invalid",
        visitation_rate_per_day = visitation_rate_per_day
      )
    }
  }

  scenario_slug <- as.character(outputs$scenario_slug)
  if (!nzchar(scenario_slug)) {
    rlang::abort(
      "Scenario `outputs$scenario_slug` must be non-empty.",
      class = "herbivoreTTR_scenario_v2_scenario_slug_invalid",
      scenario_slug = scenario_slug
    )
  }

  scenario_id <- as.character(scenario$scenario_id)
  if (!nzchar(scenario_id)) {
    scenario_id <- scenario_slug
  }

  contrast_id <- as.character(if (is.null(contrast_raw$contrast_id)) "" else contrast_raw$contrast_id)
  if (length(contrast_id) != 1L || is.na(contrast_id)) {
    rlang::abort(
      "Scenario `contrast$contrast_id` must be scalar character when provided.",
      class = "herbivoreTTR_scenario_v2_contrast_id_invalid",
      contrast_id = contrast_id
    )
  }
  paired_with <- as.character(if (is.null(contrast_raw$paired_with)) "" else contrast_raw$paired_with)
  if (length(paired_with) != 1L || is.na(paired_with)) {
    rlang::abort(
      "Scenario `contrast$paired_with` must be scalar character when provided.",
      class = "herbivoreTTR_scenario_v2_paired_with_invalid",
      paired_with = paired_with
    )
  }
  paired_contrast_required <- if (is.null(contrast_raw$paired_contrast_required)) {
    FALSE
  } else {
    as.logical(contrast_raw$paired_contrast_required)[1]
  }
  if (is.na(paired_contrast_required)) {
    rlang::abort(
      "Scenario `contrast$paired_contrast_required` must be TRUE/FALSE when provided.",
      class = "herbivoreTTR_scenario_v2_paired_required_invalid",
      paired_contrast_required = paired_contrast_required
    )
  }
  pairing_rules <- if (is.null(contrast_raw$pairing_rules)) {
    scenario_pairing_rules_default()
  } else {
    as.character(unlist(contrast_raw$pairing_rules, use.names = FALSE))
  }
  if (length(pairing_rules) < 1L || any(!nzchar(pairing_rules))) {
    rlang::abort(
      "Scenario `contrast$pairing_rules` must contain at least one non-empty rule path.",
      class = "herbivoreTTR_scenario_v2_pairing_rules_invalid",
      pairing_rules = pairing_rules
    )
  }
  if (isTRUE(paired_contrast_required) && !nzchar(paired_with)) {
    rlang::abort(
      "Scenario requires paired contrast but `contrast$paired_with` is empty.",
      class = "herbivoreTTR_scenario_v2_paired_with_missing"
    )
  }
  if (isTRUE(paired_contrast_required) && paired_with %in% c(scenario_id, scenario_slug)) {
    rlang::abort(
      "Scenario paired contrast cannot reference itself.",
      class = "herbivoreTTR_scenario_v2_paired_self_reference",
      paired_with = paired_with
    )
  }

  feedback_enabled <- if (is.null(feedback_raw$enabled)) TRUE else as.logical(feedback_raw$enabled)[1]
  feedback_initial_bci <- as.numeric(if (is.null(feedback_raw$initial_bci)) CONSTANTS$BODY_CONDITION_INITIAL else feedback_raw$initial_bci)
  feedback_gain_coeff <- as.numeric(if (is.null(feedback_raw$gain_coeff)) CONSTANTS$BODY_CONDITION_GAIN_COEFF else feedback_raw$gain_coeff)
  feedback_loss_coeff <- as.numeric(if (is.null(feedback_raw$loss_coeff)) CONSTANTS$BODY_CONDITION_LOSS_COEFF else feedback_raw$loss_coeff)
  feedback_effort_threshold <- as.numeric(if (is.null(feedback_raw$effort_threshold)) CONSTANTS$BODY_CONDITION_EFFORT_THRESHOLD else feedback_raw$effort_threshold)
  feedback_stress_threshold <- as.numeric(if (is.null(feedback_raw$stress_threshold)) CONSTANTS$BODY_CONDITION_STRESS_THRESHOLD else feedback_raw$stress_threshold)
  feedback_max_foraging_boost <- as.numeric(if (is.null(feedback_raw$max_foraging_boost)) CONSTANTS$BODY_CONDITION_MAX_FORAGING_BOOST else feedback_raw$max_foraging_boost)

  if (is.na(feedback_enabled)) {
    rlang::abort(
      "Scenario `feedback$enabled` must be TRUE/FALSE when provided.",
      class = "herbivoreTTR_scenario_v2_feedback_enabled_invalid",
      enabled = feedback_enabled
    )
  }
  if (!is.finite(feedback_initial_bci) || feedback_initial_bci < 0 || feedback_initial_bci > 1) {
    rlang::abort(
      "Scenario `feedback$initial_bci` must be finite in [0,1].",
      class = "herbivoreTTR_scenario_v2_feedback_initial_bci_invalid",
      initial_bci = feedback_initial_bci
    )
  }
  if (!is.finite(feedback_gain_coeff) || feedback_gain_coeff < 0 ||
      !is.finite(feedback_loss_coeff) || feedback_loss_coeff < 0) {
    rlang::abort(
      "Scenario feedback gain/loss coefficients must be non-negative finite values.",
      class = "herbivoreTTR_scenario_v2_feedback_coeff_invalid",
      gain_coeff = feedback_gain_coeff,
      loss_coeff = feedback_loss_coeff
    )
  }
  if (!is.finite(feedback_effort_threshold) || feedback_effort_threshold <= 0 || feedback_effort_threshold > 1 ||
      !is.finite(feedback_stress_threshold) || feedback_stress_threshold < 0 || feedback_stress_threshold > 1) {
    rlang::abort(
      "Scenario feedback thresholds must be finite and in [0,1], with effort threshold > 0.",
      class = "herbivoreTTR_scenario_v2_feedback_threshold_invalid",
      effort_threshold = feedback_effort_threshold,
      stress_threshold = feedback_stress_threshold
    )
  }
  if (!is.finite(feedback_max_foraging_boost) || feedback_max_foraging_boost < 0) {
    rlang::abort(
      "Scenario `feedback$max_foraging_boost` must be finite and >= 0.",
      class = "herbivoreTTR_scenario_v2_feedback_boost_invalid",
      max_foraging_boost = feedback_max_foraging_boost
    )
  }

  list(
    schema_version = scenario_contract_version_v2(),
    scenario_id = scenario_id,
    runtime = list(
      seed = seed,
      minute_limit = minute_limit,
      days = days,
      start_day = start_day,
      forage_access_scale = forage_access_scale
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
      template_herbivore = template_herbivore,
      stocking_density_per_km2 = stocking_density_per_km2,
      visitation_rate_per_day = visitation_rate_per_day
    ),
    outputs = list(scenario_slug = scenario_slug),
    contrast = list(
      contrast_id = contrast_id,
      paired_with = paired_with,
      paired_contrast_required = paired_contrast_required,
      pairing_rules = pairing_rules
    ),
    feedback = list(
      enabled = feedback_enabled,
      initial_bci = feedback_initial_bci,
      gain_coeff = feedback_gain_coeff,
      loss_coeff = feedback_loss_coeff,
      effort_threshold = feedback_effort_threshold,
      stress_threshold = feedback_stress_threshold,
      max_foraging_boost = feedback_max_foraging_boost
    )
  )
}

#' Validate a scenario object against contract v2
#'
#' Performs strict validation and normalization of scenario contract fields.
#' Legacy v1 scenario objects are migrated before validation.
#'
#' @param scenario Scenario list object.
#'
#' @return Validated scenario list with normalized scalar types.
#' @export
validate_scenario_v2 <- function(scenario) {
  if (!is.list(scenario)) {
    rlang::abort(
      "Scenario must be a list.",
      class = "herbivoreTTR_scenario_v2_not_list"
    )
  }

  schema_version <- as.character(scenario$schema_version)
  if (identical(schema_version, scenario_contract_version_v1_legacy())) {
    return(validate_scenario_v2_native(migrate_scenario_v1_to_v2(scenario)))
  }

  validate_scenario_v2_native(scenario)
}

validate_paired_contrast_parity_v2 <- function(primary,
                                               paired,
                                               source_path = NA_character_,
                                               paired_path = NA_character_) {
  primary_validated <- validate_scenario_v2(primary)
  paired_validated <- validate_scenario_v2(paired)

  contrast <- primary_validated$contrast
  if (!isTRUE(contrast$paired_contrast_required) || !nzchar(contrast$paired_with)) {
    return(invisible(TRUE))
  }

  rules <- contrast$pairing_rules
  if (length(rules) < 1L) {
    rules <- scenario_pairing_rules_default()
  }

  for (rule in rules) {
    lhs <- scenario_extract_nested_value(primary_validated, rule)
    rhs <- scenario_extract_nested_value(paired_validated, rule)

    if (!isTRUE(lhs$found) || !isTRUE(rhs$found)) {
      rlang::abort(
        sprintf("Paired contrast rule `%s` could not be resolved in both scenarios.", rule),
        class = "herbivoreTTR_scenario_v2_pair_rule_missing",
        rule = rule,
        source_path = source_path,
        paired_path = paired_path
      )
    }

    if (!scenario_values_equal_for_pairing(lhs$value, rhs$value)) {
      rlang::abort(
        sprintf("Paired contrast rule `%s` mismatch between scenario and paired scenario.", rule),
        class = "herbivoreTTR_scenario_v2_pair_rule_mismatch",
        rule = rule,
        value_primary = lhs$value,
        value_paired = rhs$value,
        source_path = source_path,
        paired_path = paired_path
      )
    }
  }

  paired_contrast <- paired_validated$contrast
  if (isTRUE(paired_contrast$paired_contrast_required) && nzchar(paired_contrast$paired_with)) {
    expected_back_refs <- c(primary_validated$scenario_id, primary_validated$outputs$scenario_slug)
    if (!paired_contrast$paired_with %in% expected_back_refs) {
      rlang::abort(
        "Paired contrast reciprocal reference is invalid.",
        class = "herbivoreTTR_scenario_v2_pair_reciprocal_invalid",
        expected = expected_back_refs,
        actual = paired_contrast$paired_with
      )
    }
  }

  invisible(TRUE)
}

#' Compile and validate a scenario YAML file against contract v2
#'
#' Loads a YAML scenario definition from disk, migrates legacy v1 input when
#' needed, and validates it against scenario contract v2.
#'
#' @param path Path to a scenario YAML file or a scenario slug.
#' @param enforce_pairing Logical; when `TRUE`, paired-contrast scenarios are
#'   resolved and validated against declared pairing rules.
#'
#' @return Validated scenario list.
#' @export
compile_scenario_yaml_v2 <- function(path, enforce_pairing = TRUE) {
  resolved_path <- resolve_scenario_yaml_path(path)

  if (!requireNamespace("yaml", quietly = TRUE)) {
    rlang::abort(
      "Package `yaml` is required to compile scenario YAML files.",
      class = "herbivoreTTR_scenario_v2_yaml_package_missing"
    )
  }

  raw <- yaml::read_yaml(resolved_path)
  scenario <- validate_scenario_v2(raw)
  scenario$source_yaml <- resolved_path

  if (isTRUE(enforce_pairing) &&
      isTRUE(scenario$contrast$paired_contrast_required) &&
      nzchar(scenario$contrast$paired_with)) {
    paired_path <- resolve_scenario_yaml_path(scenario$contrast$paired_with)
    paired <- compile_scenario_yaml_v2(paired_path, enforce_pairing = FALSE)
    validate_paired_contrast_parity_v2(
      primary = scenario,
      paired = paired,
      source_path = resolved_path,
      paired_path = paired_path
    )
  }

  scenario
}

scenario_primary_herbivore_v2 <- function(scenario) {
  validated <- validate_scenario_v2(scenario)
  mode <- validated$population$mode
  if (mode == "implicit_pressure") {
    return(validated$population$template_herbivore)
  }
  validated$population$cohort[[1]]
}

scenario_to_canonical_parameters_v2 <- function(scenario, conditions) {
  validated <- validate_scenario_v2(scenario)
  herb <- scenario_primary_herbivore_v2(validated)

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
    forage_access_scale = validated$runtime$forage_access_scale,
    seed = validated$runtime$seed,
    scenario_slug = validated$outputs$scenario_slug,
    climate_mode = validated$climate$mode,
    temp_mode = validated$climate$mode,
    condition_rows = nrow(conditions)
  )
}

# Generic primary scenario surface now points at contract v2.
scenario_contract_version <- scenario_contract_version_v2
validate_scenario_v1 <- validate_scenario_v2
compile_scenario_yaml <- compile_scenario_yaml_v2
validate_paired_contrast_parity <- validate_paired_contrast_parity_v2
scenario_primary_herbivore <- scenario_primary_herbivore_v2
scenario_to_canonical_parameters <- scenario_to_canonical_parameters_v2
