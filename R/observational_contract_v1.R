# Observational dataset contract v1 and adapter helpers.

observational_contract_required_columns_v1 <- function() {
  c("site_id", "day_index", "metric_name", "value", "unit", "uncertainty")
}

validate_observational_data_v1 <- function(data, registry = read_metric_units_registry_v1()) {
  if (!is.data.frame(data)) {
    rlang::abort(
      "Observational data must be a data.frame.",
      class = "herbivoreTTR_observation_not_dataframe"
    )
  }

  required <- observational_contract_required_columns_v1()
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    rlang::abort(
      "Observational data is missing required columns.",
      class = "herbivoreTTR_observation_columns_missing",
      missing_columns = missing
    )
  }

  out <- data
  out$site_id <- as.character(out$site_id)
  out$day_index <- as.integer(out$day_index)
  out$metric_name <- as.character(out$metric_name)
  out$value <- as.numeric(out$value)
  out$unit <- as.character(out$unit)
  out$uncertainty <- as.numeric(out$uncertainty)

  if (any(!nzchar(out$site_id))) {
    rlang::abort(
      "Observational `site_id` must be non-empty.",
      class = "herbivoreTTR_observation_site_invalid"
    )
  }
  if (any(!is.finite(out$day_index)) || any(out$day_index < 1L)) {
    rlang::abort(
      "Observational `day_index` must be positive integers.",
      class = "herbivoreTTR_observation_day_invalid"
    )
  }
  if (any(!nzchar(out$metric_name))) {
    rlang::abort(
      "Observational `metric_name` must be non-empty.",
      class = "herbivoreTTR_observation_metric_invalid"
    )
  }
  if (any(!is.finite(out$value))) {
    rlang::abort(
      "Observational `value` must be finite.",
      class = "herbivoreTTR_observation_value_invalid"
    )
  }

  known_units <- unique(as.character(registry$unit))
  unknown_units <- setdiff(unique(out$unit), known_units)
  if (length(unknown_units) > 0L) {
    rlang::abort(
      sprintf("Unknown observational units: %s", paste(unknown_units, collapse = ", ")),
      class = "herbivoreTTR_observation_unit_unknown",
      unknown_units = unknown_units
    )
  }

  out
}

adapt_vegetation_timeseries_v1 <- function(raw_data,
                                           site_col = "site_id",
                                           day_col = "day",
                                           biomass_col = "total_shoot_biomass_kg",
                                           unit = "kg_dm",
                                           uncertainty_col = NULL) {
  required <- c(site_col, day_col, biomass_col)
  missing <- setdiff(required, names(raw_data))
  if (length(missing) > 0L) {
    rlang::abort(
      "Vegetation adapter missing required input columns.",
      class = "herbivoreTTR_observation_vegetation_columns_missing",
      missing_columns = missing
    )
  }

  uncertainty <- if (is.null(uncertainty_col) || !uncertainty_col %in% names(raw_data)) {
    rep(NA_real_, nrow(raw_data))
  } else {
    raw_data[[uncertainty_col]]
  }

  out <- data.frame(
    site_id = as.character(raw_data[[site_col]]),
    day_index = as.integer(raw_data[[day_col]]),
    metric_name = "total_shoot_biomass_kg",
    value = as.numeric(raw_data[[biomass_col]]),
    unit = unit,
    uncertainty = as.numeric(uncertainty),
    stringsAsFactors = FALSE
  )
  validate_observational_data_v1(out)
}

adapt_herbivore_timeseries_v1 <- function(raw_data,
                                          site_col = "site_id",
                                          day_col = "day",
                                          dmi_col = "daily_dmi_g_dm",
                                          drinking_col = "daily_drinking_water_g_h2o",
                                          dmi_unit = "g_dm_per_day",
                                          drinking_unit = "g_h2o_per_day",
                                          uncertainty_col = NULL) {
  required <- c(site_col, day_col, dmi_col, drinking_col)
  missing <- setdiff(required, names(raw_data))
  if (length(missing) > 0L) {
    rlang::abort(
      "Herbivore adapter missing required input columns.",
      class = "herbivoreTTR_observation_herbivore_columns_missing",
      missing_columns = missing
    )
  }

  uncertainty <- if (is.null(uncertainty_col) || !uncertainty_col %in% names(raw_data)) {
    rep(NA_real_, nrow(raw_data))
  } else {
    raw_data[[uncertainty_col]]
  }

  dmi <- data.frame(
    site_id = as.character(raw_data[[site_col]]),
    day_index = as.integer(raw_data[[day_col]]),
    metric_name = "mean_daily_dmi",
    value = as.numeric(raw_data[[dmi_col]]),
    unit = dmi_unit,
    uncertainty = as.numeric(uncertainty),
    stringsAsFactors = FALSE
  )

  drinking <- data.frame(
    site_id = as.character(raw_data[[site_col]]),
    day_index = as.integer(raw_data[[day_col]]),
    metric_name = "mean_daily_drinking_water",
    value = as.numeric(raw_data[[drinking_col]]),
    unit = drinking_unit,
    uncertainty = as.numeric(uncertainty),
    stringsAsFactors = FALSE
  )

  validate_observational_data_v1(rbind(dmi, drinking))
}
