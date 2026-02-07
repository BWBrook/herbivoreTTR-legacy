# Deterministic report artefact manifest helpers.

report_artifact_files_v2 <- function(output_dir) {
  patterns <- c("\\.html$", "\\.png$", "\\.csv$", "\\.md$")
  files <- list.files(output_dir, recursive = TRUE, full.names = TRUE)
  files[Reduce(`|`, lapply(patterns, grepl, x = files, perl = TRUE))]
}

hash_file_md5 <- function(path) {
  unname(tools::md5sum(path))
}

write_report_artifact_manifest_v2 <- function(output_dir,
                                              input_files = character(),
                                              manifest_path = file.path(output_dir, "figure_table_manifest_v2.csv")) {
  if (!dir.exists(output_dir)) {
    rlang::abort(
      "Report output directory does not exist.",
      class = "herbivoreTTR_report_manifest_output_dir_missing",
      output_dir = output_dir
    )
  }

  files <- report_artifact_files_v2(output_dir)
  files <- files[file.exists(files)]
  files <- sort(unique(files))
  if (length(files) < 1L) {
    rlang::abort(
      "No report artefacts found for manifest generation.",
      class = "herbivoreTTR_report_manifest_no_files",
      output_dir = output_dir
    )
  }

  input_hash <- if (length(input_files) > 0L) {
    hash_scenario_parameters(normalize_manifest_path(input_files))
  } else {
    hash_scenario_parameters("none")
  }

  rows <- lapply(files, function(path) {
    info <- file.info(path)
    data.frame(
      artifact_id = basename(path),
      path = normalize_manifest_path(path),
      checksum_md5 = hash_file_md5(path),
      bytes = as.numeric(info$size),
      modified_utc = format(info$mtime, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      input_files_hash = input_hash,
      stringsAsFactors = FALSE
    )
  })
  manifest <- do.call(rbind, rows)
  rownames(manifest) <- NULL

  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(manifest, manifest_path, row.names = FALSE)
  manifest_path
}

check_report_manifest_determinism_v2 <- function(current_manifest_path, previous_manifest_path) {
  if (!file.exists(current_manifest_path) || !file.exists(previous_manifest_path)) {
    rlang::abort(
      "Both current and previous report manifests must exist.",
      class = "herbivoreTTR_report_manifest_compare_missing",
      current_manifest_path = current_manifest_path,
      previous_manifest_path = previous_manifest_path
    )
  }

  current <- utils::read.csv(current_manifest_path, stringsAsFactors = FALSE)
  previous <- utils::read.csv(previous_manifest_path, stringsAsFactors = FALSE)
  merged <- merge(
    current[, c("artifact_id", "checksum_md5")],
    previous[, c("artifact_id", "checksum_md5")],
    by = "artifact_id",
    suffixes = c("_current", "_previous")
  )
  merged$matches <- merged$checksum_md5_current == merged$checksum_md5_previous
  merged
}
