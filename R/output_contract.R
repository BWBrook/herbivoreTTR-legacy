# Output contract helpers for schema-versioned simulation artefacts.

#' Output schema version for canonical run artefacts
#' @keywords internal
#' @noRd
OUTPUT_SCHEMA_VERSION <- "0.1.0"

#' Return the current output schema version
#' @keywords internal
#' @noRd
output_schema_version <- function() {
  OUTPUT_SCHEMA_VERSION
}

#' Required plant snapshot columns for output contract v0
#' @keywords internal
#' @noRd
required_plant_output_columns_v0 <- function() {
  c(
    "SchemaVersion", "Year", "Day", "Plant", "VegType", "Height", "BLeaf",
    "BStem", "BDef", "Ms", "Ns", "Cs", "Mr", "Cr", "Nr"
  )
}

#' Required herbivore snapshot columns for output contract v0
#' @keywords internal
#' @noRd
required_herbivore_output_columns_v0 <- function() {
  c(
    "SchemaVersion", "Year", "Day", "HerbType", "Mass", "xcor", "ycor",
    "DailyDistMoved", "DailyPEI", "DailyNPEI", "DailyDMI", "DailyForageWater",
    "TotalDMI", "WaterBalance", "EnergyBalance"
  )
}

#' Canonicalize a path for manifest serialization
#' @keywords internal
#' @noRd
normalize_manifest_path <- function(path) {
  out <- gsub("\\\\", "/", path)
  out <- sub("^\\./", "", out)
  out
}

#' Hash scenario parameters deterministically
#' @param scenario_parameters List or object defining the scenario.
#' @return Scalar character MD5 hash.
#' @keywords internal
#' @noRd
hash_scenario_parameters <- function(scenario_parameters) {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(scenario_parameters, path, version = 2)
  unname(tools::md5sum(path))
}

#' Resolve package version for manifest metadata
#' @keywords internal
#' @noRd
resolve_package_version <- function() {
  desc <- file.path(getwd(), "DESCRIPTION")
  if (file.exists(desc)) {
    dcf <- read.dcf(desc, fields = "Version")
    return(as.character(dcf[1, 1]))
  }
  tryCatch(
    as.character(utils::packageVersion("herbivoreTTR")),
    error = function(e) "unknown"
  )
}

#' Resolve git SHA for manifest metadata
#' @keywords internal
#' @noRd
resolve_git_sha <- function() {
  sha <- tryCatch(
    system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE),
    error = function(e) character()
  )
  if (length(sha) == 1L && nzchar(sha)) {
    return(sha)
  }
  "unknown"
}

#' Build a canonical run manifest list
#' @param scenario_slug Scenario identifier.
#' @param seed Scalar integer seed used for the run.
#' @param scenario_parameters List of scenario parameters.
#' @param output_files Named character vector of relative output paths.
#' @param created_utc UTC timestamp in ISO-8601-like format.
#' @return Named list suitable for JSON serialization.
#' @keywords internal
#' @noRd
build_run_manifest <- function(scenario_slug,
                               seed,
                               scenario_parameters,
                               output_files,
                               created_utc = format(
                                 Sys.time(),
                                 "%Y-%m-%dT%H:%M:%SZ",
                                 tz = "UTC"
                               )) {
  if (!is.character(scenario_slug) || length(scenario_slug) != 1L || !nzchar(scenario_slug)) {
    rlang::abort(
      "Argument `scenario_slug` must be a non-empty scalar character.",
      class = "herbivoreTTR_manifest_slug_invalid",
      scenario_slug = scenario_slug
    )
  }
  if (!is.numeric(seed) || length(seed) != 1L || is.na(seed) || !is.finite(seed)) {
    rlang::abort(
      "Argument `seed` must be a finite scalar numeric value.",
      class = "herbivoreTTR_manifest_seed_invalid",
      seed = seed
    )
  }
  if (!is.character(output_files) || length(output_files) < 1L) {
    rlang::abort(
      "Argument `output_files` must be a non-empty character vector.",
      class = "herbivoreTTR_manifest_outputs_invalid",
      output_files = output_files
    )
  }
  if (is.null(names(output_files)) || any(!nzchar(names(output_files)))) {
    rlang::abort(
      "Argument `output_files` must be a named character vector.",
      class = "herbivoreTTR_manifest_outputs_names_invalid",
      output_files = output_files
    )
  }

  outputs <- stats::setNames(
    as.list(vapply(output_files, normalize_manifest_path, character(1L))),
    names(output_files)
  )

  list(
    schema_version = output_schema_version(),
    package_version = resolve_package_version(),
    git_sha = resolve_git_sha(),
    seed = as.integer(seed),
    scenario_slug = scenario_slug,
    scenario_parameters_hash = hash_scenario_parameters(scenario_parameters),
    outputs = outputs,
    created_utc = created_utc
  )
}

#' Write a run manifest JSON to disk
#' @param manifest Manifest list from `build_run_manifest()`.
#' @param path Destination path for JSON.
#' @return Written file path (invisible).
#' @keywords internal
#' @noRd
write_run_manifest <- function(manifest, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  json <- jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE, null = "null")
  writeLines(text = json, con = path, useBytes = TRUE)
  invisible(path)
}
