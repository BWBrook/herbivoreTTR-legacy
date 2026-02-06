# Derived vegetation structure and fuel proxy metrics.

derive_structure_fuel_metrics <- function(plants,
                                          day_of_simulation,
                                          run_id,
                                          scenario_id,
                                          scenario_slug,
                                          population_mode) {
  if (!is.data.frame(plants)) {
    rlang::abort(
      "Argument `plants` must be a data.frame.",
      class = "herbivoreTTR_structure_plants_not_df"
    )
  }

  needed <- c("veg_type", "height", "ms", "bleaf", "bstem", "bdef")
  missing <- setdiff(needed, names(plants))
  if (length(missing) > 0L) {
    rlang::abort(
      paste("Missing columns for structure/fuel metrics:", paste(missing, collapse = ", ")),
      class = "herbivoreTTR_structure_missing_columns",
      missing_columns = missing
    )
  }

  grass_idx <- plants$veg_type %in% c(0L, 1L)
  woody_idx <- plants$veg_type == 2L
  browseable_idx <- (plants$height * CONSTANTS$LEAF_HEIGHT) <= CONSTANTS$BROWSE_HEIGHT

  fine_fuel <- pmax(plants$bleaf, 0)
  grass_stem_fuel <- ifelse(grass_idx, pmax(plants$bstem, 0), 0)
  browseable <- ifelse(browseable_idx, pmax(plants$bleaf + plants$bstem, 0), 0)

  out <- data.frame(
    RunID = as.character(run_id),
    SchemaVersion = output_schema_version(),
    ScenarioID = as.character(scenario_id),
    ScenarioSlug = as.character(scenario_slug),
    PopulationMode = as.character(population_mode),
    Day = as.integer(day_of_simulation),
    total_shoot_biomass_kg = sum(pmax(plants$ms, 0)),
    grass_shoot_biomass_kg = sum(pmax(plants$ms[grass_idx], 0)),
    woody_shoot_biomass_kg = sum(pmax(plants$ms[woody_idx], 0)),
    fine_fuel_proxy_kg = sum(fine_fuel + grass_stem_fuel),
    browseable_biomass_kg = sum(browseable),
    defended_shoot_biomass_kg = sum(pmax(plants$bdef, 0)),
    mean_height_m = mean(plants$height),
    p90_height_m = as.numeric(stats::quantile(plants$height, probs = 0.9, names = FALSE)),
    stringsAsFactors = FALSE
  )

  numeric_cols <- vapply(out, is.numeric, logical(1L))
  vals <- unlist(out[, numeric_cols, drop = FALSE], use.names = FALSE)
  if (any(!is.finite(vals))) {
    rlang::abort(
      "Structure/fuel metrics contain non-finite numeric values.",
      class = "herbivoreTTR_structure_non_finite"
    )
  }
  if (any(out$total_shoot_biomass_kg < -CONSTANTS$TOLERANCE) ||
      any(out$fine_fuel_proxy_kg < -CONSTANTS$TOLERANCE) ||
      any(out$browseable_biomass_kg < -CONSTANTS$TOLERANCE)) {
    rlang::abort(
      "Structure/fuel metrics violated non-negativity contract.",
      class = "herbivoreTTR_structure_negative"
    )
  }

  out
}

write_structure_fuel_metrics <- function(metrics_df, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(metrics_df, path, row.names = FALSE)
  invisible(path)
}
