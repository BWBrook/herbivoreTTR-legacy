#' Write daily plant outputs to CSV (semicolon-delimited)
#'
#' Produces a one-day snapshot compatible with diff-based parity checks
#' against the reference C++ output. Validates required columns and
#' finite values before writing.
#'
#' @param plants data.frame of plants.
#' @param day integer day-of-year.
#' @param year integer simulation year.
#' @param path file path for output CSV; overwritten if exists.
#' @param run_id output run identifier for schema v1 tracking.
#' @return Invisibly TRUE on success; errors on validation failure.
write_plants_daily <- function(plants, day, year, path, run_id = "run_unknown") {
  schema_version <- output_schema_version()

  required <- c(
    "plant_id", "veg_type", "height", "bleaf", "bstem", "bdef",
    "ms", "ns", "cs", "mr", "cr", "nr"
  )
  missing <- setdiff(required, names(plants))
  if (length(missing)) {
    rlang::abort(
      paste("Missing plant columns:", paste(missing, collapse = ", ")),
      class = "herbivoreTTR_plants_missing_columns",
      missing_columns = missing
    )
  }

  if (!is.character(run_id) || length(run_id) != 1L || !nzchar(run_id)) {
    rlang::abort(
      "Argument `run_id` must be a non-empty scalar character.",
      class = "herbivoreTTR_plants_run_id_invalid",
      run_id = run_id
    )
  }

  # Build ordered output frame
  out <- data.frame(
    RunID = rep(run_id, nrow(plants)),
    SchemaVersion = rep(schema_version, nrow(plants)),
    Year   = as.integer(rep(year, nrow(plants))),
    Day    = as.integer(rep(day, nrow(plants))),
    Plant  = plants$plant_id,
    VegType = plants$veg_type,
    Height = plants$height,
    BLeaf  = plants$bleaf,
    BStem  = plants$bstem,
    BDef   = plants$bdef,
    Ms     = plants$ms,
    Ns     = plants$ns,
    Cs     = plants$cs,
    Mr     = plants$mr,
    Cr     = plants$cr,
    Nr     = plants$nr,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  # Validation: finite numerics, no NA/Inf/NaN
  # Year/Day/Plant/VegType can be integer; coerce to numeric for finiteness check
  any_bad_numeric <- vapply(
    out,
    function(v) is.numeric(v) && any(!is.finite(v)),
    logical(1L)
  )
  if (anyNA(out) || any(any_bad_numeric)) {
    rlang::abort(
      "Non-finite or NA values present in plant output; refusing to write",
      class = "herbivoreTTR_plants_non_finite"
    )
  }

  # Overwrite file; write headers always; semicolon delimiter; UTF-8
  utils::write.table(out, file = path, sep = ";", row.names = FALSE, col.names = TRUE,
                     quote = FALSE, fileEncoding = "UTF-8", eol = "\n")

  # Post-validate header and column order
  header_expected <- paste(required_plant_output_columns_v1(), collapse = ";")
  hdr <- readLines(path, n = 1L, warn = FALSE)
  if (!identical(hdr, header_expected)) {
    rlang::abort(
      "Header mismatch after write",
      class = "herbivoreTTR_plants_header_mismatch",
      expected_header = header_expected,
      observed_header = hdr
    )
  }

  invisible(TRUE)
}
