#' Write a plant snapshot CSV for the targets pipeline
#'
#' Wraps `write_plants_daily()` with directory management so `_targets.R`
#' can remain side-effect free apart from calling this helper.
#'
#' @param plants Plant state tibble or data.frame.
#' @param day Integer day index.
#' @param base_dir Output directory; defaults to `data/outputs`.
#' @param year Simulation year (default 1).
#' @param run_id output run identifier for schema v1 tracking.
#' @return The file path that was written (invisible character scalar).
#' @noRd
write_plants_snapshot_target <- function(plants,
                                         day,
                                         base_dir = "data/outputs",
                                         year = 1L,
                                         run_id = "run_unknown") {
  if (!dir.exists(base_dir)) {
    created <- dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
    if (!created) {
      rlang::abort(
        "Failed to create plant output directory",
        class = "herbivoreTTR_plants_output_dir_create",
        output_dir = base_dir
      )
    }
  }

  path <- file.path(base_dir, sprintf("plants_day%03d.csv", as.integer(day)))
  write_plants_daily(
    plants = plants,
    day = day,
    year = year,
    path = path,
    run_id = run_id
  ) # nolint: object_usage_linter
  path
}
