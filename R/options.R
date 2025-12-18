## Global options and reproducibility settings (no side-effects on source)
##
## Define a function to set runtime defaults for pipelines or
## interactive sessions. Not executed automatically on package load.

#' Initialize project-wide options (interactive use)
#' @param seed Integer seed to set for RNG.
#' @return Invisibly TRUE.
init_project_options <- function(seed = 20250811L) {
  RNGkind("L'Ecuyer-CMRG")
  set.seed(as.integer(seed))
  options(
    repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"),
    readr.show_col_types = FALSE,
    scipen = 999
  )
  if (requireNamespace("lgr", quietly = TRUE)) {
    get_logger <- getExportedValue("lgr", "get_logger")
    logger <- get_logger("herbivoreTTR")
    logger$set_threshold("info")
  }
  if (requireNamespace("progressr", quietly = TRUE)) {
    handlers <- getExportedValue("progressr", "handlers")
    handlers(global = TRUE)
  }
  invisible(TRUE)
}
