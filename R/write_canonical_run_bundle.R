#' Write canonical smoke artefacts and run manifest
#'
#' Copies required output tables into the canonical run folder and writes a
#' schema-versioned manifest that captures provenance and scenario metadata.
#'
#' @param output_files Named character vector of existing file paths to include.
#' @param scenario_slug Scenario identifier for the canonical run folder.
#' @param seed Scalar integer seed used for the run.
#' @param scenario_parameters List of scenario parameters to hash in manifest.
#' @param run_id Optional run identifier for schema v1 tracking.
#' @param base_dir Root folder for canonical runs.
#' @return Character vector of written file paths (including manifest path).
#' @keywords internal
#' @noRd
write_canonical_run_bundle <- function(output_files,
                                       scenario_slug = "smoke_v0",
                                       seed = 1L,
                                       scenario_parameters = list(),
                                       run_id = NULL,
                                       base_dir = file.path("artefacts", "canonical_runs")) {
  if (!is.character(output_files) || length(output_files) < 1L) {
    rlang::abort(
      "Argument `output_files` must be a non-empty character vector.",
      class = "herbivoreTTR_bundle_output_files_invalid",
      output_files = output_files
    )
  }
  if (is.null(names(output_files)) || any(!nzchar(names(output_files)))) {
    rlang::abort(
      "Argument `output_files` must be named.",
      class = "herbivoreTTR_bundle_output_files_names_invalid",
      output_files = output_files
    )
  }

  missing_files <- output_files[!file.exists(output_files)]
  if (length(missing_files)) {
    rlang::abort(
      paste("Output files do not exist:", paste(missing_files, collapse = ", ")),
      class = "herbivoreTTR_bundle_output_files_missing",
      missing_files = unname(missing_files)
    )
  }

  run_dir <- file.path(base_dir, scenario_slug)
  if (!dir.exists(run_dir)) {
    created <- dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)
    if (!created) {
      rlang::abort(
        "Failed to create canonical run directory.",
        class = "herbivoreTTR_bundle_run_dir_create",
        run_dir = run_dir
      )
    }
  }

  if (is.null(run_id)) {
    run_id <- build_run_id(
      scenario_slug = scenario_slug,
      seed = seed,
      scenario_parameters = scenario_parameters
    )
  }

  copied_paths <- stats::setNames(character(length(output_files)), names(output_files))
  for (nm in names(output_files)) {
    src <- output_files[[nm]]
    dest <- file.path(run_dir, basename(src))
    ok <- file.copy(src, dest, overwrite = TRUE)
    if (!isTRUE(ok)) {
      rlang::abort(
        "Failed to copy canonical output file.",
        class = "herbivoreTTR_bundle_copy_failed",
        source_path = src,
        dest_path = dest
      )
    }
    copied_paths[[nm]] <- normalizePath(dest, winslash = "/", mustWork = TRUE)
  }

  relative_outputs <- stats::setNames(
    file.path("artefacts", "canonical_runs", scenario_slug, basename(copied_paths)),
    names(copied_paths)
  )

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = seed,
    scenario_parameters = scenario_parameters,
    output_files = relative_outputs,
    run_id = run_id
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest = manifest, path = manifest_path)

  written <- c(copied_paths, run_manifest = normalizePath(manifest_path, winslash = "/", mustWork = TRUE))
  unname(written)
}
