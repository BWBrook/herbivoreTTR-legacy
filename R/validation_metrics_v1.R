# Validation metrics battery and pilot ecological benchmark helpers.

validation_example_data_path <- function(file_name) {
  root <- scenario_find_repo_root()
  if (is.null(root)) {
    return(file.path("inst", "extdata", "validation", file_name))
  }
  file.path(root, "inst", "extdata", "validation", file_name)
}

calc_rmse_v1 <- function(observed, predicted) {
  obs <- as.numeric(observed)
  pred <- as.numeric(predicted)
  sqrt(mean((pred - obs)^2))
}

calc_normalized_rmse_v1 <- function(observed, predicted) {
  obs <- as.numeric(observed)
  rmse <- calc_rmse_v1(obs, predicted)
  span <- diff(range(obs))
  if (!is.finite(span) || span <= 0) {
    return(NA_real_)
  }
  rmse / span
}

calc_mean_bias_v1 <- function(observed, predicted) {
  obs <- as.numeric(observed)
  pred <- as.numeric(predicted)
  mean(pred - obs)
}

calc_directional_agreement_v1 <- function(observed, predicted) {
  obs <- as.numeric(observed)
  pred <- as.numeric(predicted)
  if (length(obs) < 2L || length(pred) < 2L) {
    return(NA_real_)
  }
  obs_diff <- diff(obs)
  pred_diff <- diff(pred)
  mean(sign(obs_diff) == sign(pred_diff))
}

calc_interval_coverage_v1 <- function(observed, lower, upper) {
  obs <- as.numeric(observed)
  lo <- as.numeric(lower)
  hi <- as.numeric(upper)
  mean(obs >= lo & obs <= hi)
}

compute_validation_metrics_v1 <- function(observed,
                                          predicted,
                                          lower = NULL,
                                          upper = NULL) {
  out <- c(
    rmse = calc_rmse_v1(observed, predicted),
    normalized_rmse = calc_normalized_rmse_v1(observed, predicted),
    mean_bias = calc_mean_bias_v1(observed, predicted),
    directional_agreement = calc_directional_agreement_v1(observed, predicted)
  )
  if (!is.null(lower) && !is.null(upper)) {
    out <- c(out, interval_coverage = calc_interval_coverage_v1(observed, lower, upper))
  } else {
    out <- c(out, interval_coverage = NA_real_)
  }
  out
}

align_observed_model_series <- function(observed_df, model_df, metric_name) {
  obs <- observed_df[observed_df$metric_name == metric_name, c("day_index", "value"), drop = FALSE]
  pred <- model_df[model_df$metric_name == metric_name, c("day_index", "value"), drop = FALSE]
  merged <- merge(obs, pred, by = "day_index", suffixes = c("_obs", "_pred"))
  merged[order(merged$day_index), , drop = FALSE]
}

#' Run pilot ecological validation benchmark v1
#'
#' @param base_dir Base directory for validation artefacts.
#' @param scenario_slug Slug for pilot benchmark output folder.
#'
#' @return List with benchmark artefact paths and summary tables.
run_pilot_validation_benchmark_v1 <- function(base_dir = file.path("artefacts", "validation"),
                                              scenario_slug = "pilot_benchmark_v1") {
  veg_path <- validation_example_data_path("vegetation_timeseries_example.csv")
  herb_path <- validation_example_data_path("herbivore_timeseries_example.csv")

  if (!file.exists(veg_path) || !file.exists(herb_path)) {
    rlang::abort(
      "Pilot validation example datasets are missing.",
      class = "herbivoreTTR_validation_example_missing",
      vegetation_path = veg_path,
      herbivore_path = herb_path
    )
  }

  veg_raw <- utils::read.csv(veg_path, stringsAsFactors = FALSE)
  herb_raw <- utils::read.csv(herb_path, stringsAsFactors = FALSE)

  obs_veg <- adapt_vegetation_timeseries_v1(veg_raw)
  obs_herb <- adapt_herbivore_timeseries_v1(herb_raw)
  observed <- validate_observational_data_v1(rbind(obs_veg, obs_herb))

  model_run <- run_scenario_v1(
    scenario = scenario_contract_reference_path("canonical_smoke_v1"),
    base_dir = base_dir
  )

  herb_model <- model_run$herbivore_daily
  structure_model <- model_run$structure_fuel_metrics
  days <- seq_len(nrow(herb_model))

  model_df <- rbind(
    data.frame(
      day_index = days,
      metric_name = "mean_daily_dmi",
      value = as.numeric(herb_model$DailyDMI),
      stringsAsFactors = FALSE
    ),
    data.frame(
      day_index = days,
      metric_name = "mean_daily_drinking_water",
      value = as.numeric(herb_model$DailyWaterDrinking),
      stringsAsFactors = FALSE
    ),
    data.frame(
      day_index = seq_len(nrow(structure_model)),
      metric_name = "total_shoot_biomass_kg",
      value = as.numeric(structure_model$total_shoot_biomass_kg),
      stringsAsFactors = FALSE
    )
  )

  metrics_to_compare <- c("total_shoot_biomass_kg", "mean_daily_dmi", "mean_daily_drinking_water")
  summary_rows <- lapply(metrics_to_compare, function(metric_name) {
    aligned <- align_observed_model_series(observed, model_df, metric_name)
    metric_values <- compute_validation_metrics_v1(
      observed = aligned$value_obs,
      predicted = aligned$value_pred
    )
    data.frame(
      metric_name = metric_name,
      rmse = metric_values[["rmse"]],
      normalized_rmse = metric_values[["normalized_rmse"]],
      mean_bias = metric_values[["mean_bias"]],
      directional_agreement = metric_values[["directional_agreement"]],
      interval_coverage = metric_values[["interval_coverage"]],
      n = nrow(aligned),
      stringsAsFactors = FALSE
    )
  })
  summary_df <- do.call(rbind, summary_rows)
  rownames(summary_df) <- NULL

  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  observed_path <- file.path(run_dir, "observed_contract_data_v1.csv")
  model_path <- file.path(run_dir, "model_series_v1.csv")
  summary_path <- file.path(run_dir, "pilot_metrics_summary_v1.csv")
  report_path <- file.path(run_dir, "pilot_validation_report_v1.md")

  utils::write.csv(observed, observed_path, row.names = FALSE)
  utils::write.csv(model_df, model_path, row.names = FALSE)
  utils::write.csv(summary_df, summary_path, row.names = FALSE)

  report_lines <- c(
    "# Pilot Ecological Validation Benchmark v1",
    "",
    "## Inputs",
    sprintf("- Observational vegetation sample: `%s`", veg_path),
    sprintf("- Observational herbivore sample: `%s`", herb_path),
    sprintf("- Model scenario: `%s`", scenario_contract_reference_path("canonical_smoke_v1")),
    "",
    "## Metric summary",
    paste0(
      "- `", summary_df$metric_name,
      "`: RMSE=", format(round(summary_df$rmse, 4), trim = TRUE),
      ", NRMSE=", format(round(summary_df$normalized_rmse, 4), trim = TRUE),
      ", bias=", format(round(summary_df$mean_bias, 4), trim = TRUE),
      ", directional agreement=", format(round(summary_df$directional_agreement, 4), trim = TRUE)
    ),
    "",
    "## Interpretation",
    "- This benchmark is a pilot contract check using synthetic observations.",
    "- It validates adapter + metric battery wiring before external dataset integration."
  )
  writeLines(report_lines, report_path)

  manifest <- build_run_manifest(
    scenario_slug = file.path("validation", scenario_slug),
    seed = model_run$scenario$runtime$seed,
    scenario_parameters = list(validation_metrics = metrics_to_compare),
    output_files = c(
      observed = file.path(base_dir, scenario_slug, basename(observed_path)),
      model = file.path(base_dir, scenario_slug, basename(model_path)),
      summary = file.path(base_dir, scenario_slug, basename(summary_path)),
      report = file.path(base_dir, scenario_slug, basename(report_path))
    )
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    run_dir = run_dir,
    observed_path = observed_path,
    model_path = model_path,
    summary_path = summary_path,
    report_path = report_path,
    manifest_path = manifest_path,
    summary = summary_df
  )
}
