# Metric-units registry helpers for experiment outputs and reports.

metric_units_registry_v1_path <- function() {
  root <- scenario_find_repo_root()
  if (is.null(root)) {
    return(file.path("config", "units", "metric_units_v1.csv"))
  }
  file.path(root, "config", "units", "metric_units_v1.csv")
}

read_metric_units_registry_v1 <- function(path = metric_units_registry_v1_path()) {
  if (!file.exists(path)) {
    rlang::abort(
      "Metric units registry file does not exist.",
      class = "herbivoreTTR_metric_units_registry_missing",
      path = path
    )
  }

  units <- utils::read.csv(path, stringsAsFactors = FALSE)
  required_cols <- c("metric_name", "unit", "description", "sign_convention")
  missing_cols <- setdiff(required_cols, names(units))
  if (length(missing_cols) > 0L) {
    rlang::abort(
      "Metric units registry is missing required columns.",
      class = "herbivoreTTR_metric_units_registry_columns_missing",
      missing_columns = missing_cols
    )
  }
  units
}

resolve_metric_units_v1 <- function(metric_names, registry = read_metric_units_registry_v1()) {
  requested <- unique(as.character(metric_names))
  requested <- requested[nzchar(requested)]
  matched <- registry[registry$metric_name %in% requested, , drop = FALSE]
  missing <- setdiff(requested, matched$metric_name)
  if (length(missing) > 0L) {
    rlang::abort(
      sprintf("Units metadata missing for metrics: %s", paste(missing, collapse = ", ")),
      class = "herbivoreTTR_metric_units_missing",
      missing_metrics = missing
    )
  }
  matched
}

write_metric_units_sidecar_v1 <- function(metric_names,
                                          output_path,
                                          registry = read_metric_units_registry_v1()) {
  units_df <- resolve_metric_units_v1(metric_names, registry = registry)
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(units_df, output_path, row.names = FALSE)
  output_path
}
