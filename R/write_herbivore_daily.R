#' Write daily herbivore outputs to CSV (semicolon-delimited)
#'
#' Produces a one-day snapshot compatible with diff-based parity checks
#' against the reference C++ output. Validates required fields and
#' finite values before writing.
#'
#' @param herbivore list-like herbivore object.
#' @param day integer day-of-year.
#' @param year integer simulation year.
#' @param path file path for output CSV; overwritten if exists.
#' @param run_id output run identifier for schema v1 tracking.
#' @param herbivore_id herbivore identifier for schema v1 tracking.
#' @return Invisibly TRUE on success; errors on validation failure.
write_herbivores_daily <- function(herbivore,
                                   day,
                                   year,
                                   path,
                                   run_id = "run_unknown",
                                   herbivore_id = NULL) {
  schema_version <- output_schema_version()

  required <- c(
    "herb_type", "mass", "xcor", "ycor", "distance_moved", "intake_PE_day",
    "intake_NPE_day", "intake_total_day", "intake_water_forage", "intake_total",
    "water_balance", "energy_balance"
  )
  missing <- setdiff(required, names(herbivore))
  if (length(missing)) {
    rlang::abort(
      paste("Missing herbivore fields:", paste(missing, collapse = ", ")),
      class = "herbivoreTTR_herb_missing_fields",
      missing_fields = missing
    )
  }

  if (is.null(herbivore_id)) {
    herbivore_id <- herbivore$herbivore_id
  }
  if (is.null(herbivore_id) || !length(herbivore_id) || !nzchar(as.character(herbivore_id))) {
    herbivore_id <- "herbivore_1"
  }
  if (!is.character(run_id) || length(run_id) != 1L || !nzchar(run_id)) {
    rlang::abort(
      "Argument `run_id` must be a non-empty scalar character.",
      class = "herbivoreTTR_herb_run_id_invalid",
      run_id = run_id
    )
  }
  if (!is.character(herbivore_id) || length(herbivore_id) != 1L || !nzchar(herbivore_id)) {
    rlang::abort(
      "Argument `herbivore_id` must be a non-empty scalar character.",
      class = "herbivoreTTR_herb_herbivore_id_invalid",
      herbivore_id = herbivore_id
    )
  }

  out <- data.frame(
    RunID = run_id,
    HerbivoreID = herbivore_id,
    SchemaVersion    = schema_version,
    Year            = as.integer(year),
    Day             = as.integer(day),
    HerbType        = herbivore$herb_type,
    Mass            = herbivore$mass,
    xcor            = herbivore$xcor,
    ycor            = herbivore$ycor,
    DailyDistMoved  = herbivore$distance_moved,
    DailyPEI        = herbivore$intake_PE_day,
    DailyNPEI       = herbivore$intake_NPE_day,
    DailyDMI        = herbivore$intake_total_day,
    DailyForageWater = herbivore$intake_water_forage,
    TotalDMI        = herbivore$intake_total,
    WaterBalance    = herbivore$water_balance,
    EnergyBalance   = herbivore$energy_balance,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  # Validation: schema version present and finite numeric state
  if (anyNA(out$SchemaVersion) || any(!nzchar(out$SchemaVersion))) {
    rlang::abort(
      "Missing schema version in herbivore output",
      class = "herbivoreTTR_herb_schema_missing"
    )
  }
  numeric_out <- out[, setdiff(names(out), c("RunID", "HerbivoreID", "SchemaVersion")), drop = FALSE]
  if (any(!vapply(numeric_out, is.numeric, logical(1L)))) {
    rlang::abort(
      "Non-numeric values in herbivore output",
      class = "herbivoreTTR_herb_non_numeric"
    )
  }
  if (any(!is.finite(as.numeric(as.matrix(numeric_out))))) {
    rlang::abort(
      "Non-finite values in herbivore output",
      class = "herbivoreTTR_herb_non_finite"
    )
  }

  utils::write.table(out, file = path, sep = ";", row.names = FALSE, col.names = TRUE,
                     quote = FALSE, fileEncoding = "UTF-8", eol = "\n")

  header_expected <- paste(required_herbivore_output_columns_v1(), collapse = ";")
  hdr <- readLines(path, n = 1L, warn = FALSE)
  if (!identical(hdr, header_expected)) {
    rlang::abort(
      "Header mismatch after write",
      class = "herbivoreTTR_herb_header_mismatch",
      expected_header = header_expected,
      observed_header = hdr
    )
  }
  invisible(TRUE)
}
