# Internal runtime, freshness, and replay validation helpers.

repro_abort <- function(message, class, ...) {
  condition <- structure(
    c(list(message = message, call = NULL), list(...)),
    class = c(class, "error", "condition")
  )
  stop(condition)
}

canonicalize_run_path <- function(path, cwd = getwd()) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    repro_abort(
      "Run paths must be non-empty scalar character values.",
      "herbivoreTTR_repro_path_invalid",
      path = path
    )
  }

  portable <- gsub("\\\\", "/", path)
  components <- strsplit(portable, "/", fixed = TRUE)[[1]]
  if (".." %in% components) {
    repro_abort(
      "Run paths must not contain parent-directory components.",
      "herbivoreTTR_repro_path_parent_component",
      path = path
    )
  }

  expanded <- path.expand(portable)
  is_absolute <- grepl("^/", expanded) ||
    grepl("^[A-Za-z]:/", expanded) ||
    grepl("^//", expanded)
  candidate <- if (is_absolute) expanded else file.path(cwd, expanded)
  candidate <- gsub("\\\\", "/", candidate)

  suffix <- character()
  existing <- candidate
  while (!file.exists(existing) && !dir.exists(existing)) {
    parent <- dirname(existing)
    if (identical(parent, existing)) {
      break
    }
    suffix <- c(basename(existing), suffix)
    existing <- parent
  }

  base <- normalizePath(existing, winslash = "/", mustWork = TRUE)
  if (length(suffix) > 0L) {
    base <- do.call(file.path, c(list(base), as.list(suffix)))
  }
  gsub("\\\\", "/", base)
}

validate_repro_run_paths <- function(out_dir, lib_dir, targets_store) {
  paths <- c(out_dir = out_dir, lib_dir = lib_dir, targets_store = targets_store)
  canonical <- vapply(paths, canonicalize_run_path, character(1))

  pairs <- utils::combn(seq_along(canonical), 2L)
  overlaps <- apply(pairs, 2L, function(index) {
    lhs <- canonical[[index[[1]]]]
    rhs <- canonical[[index[[2]]]]
    lhs_prefix <- if (endsWith(lhs, "/")) lhs else paste0(lhs, "/")
    rhs_prefix <- if (endsWith(rhs, "/")) rhs else paste0(rhs, "/")
    identical(lhs, rhs) ||
      startsWith(lhs, rhs_prefix) ||
      startsWith(rhs, lhs_prefix)
  })
  if (any(overlaps)) {
    repro_abort(
      "Reproducibility output, library, and targets paths must not overlap.",
      "herbivoreTTR_repro_path_overlap",
      paths = canonical
    )
  }

  canonical
}

new_cli_run_id <- function(now = Sys.time(), pid = Sys.getpid()) {
  if (length(now) != 1L || is.na(now) ||
      length(pid) != 1L || is.na(pid) || pid < 1L) {
    repro_abort(
      "CLI run IDs require one timestamp and one positive process ID.",
      "herbivoreTTR_cli_run_id_invalid",
      now = now,
      pid = pid
    )
  }

  sprintf(
    "%s-%d",
    format(as.POSIXct(now), "%Y%m%dT%H%M%SZ", tz = "UTC"),
    as.integer(pid)
  )
}

default_repro_run_paths <- function(
    version,
    root = file.path("artefacts", "reproducibility")) {
  version <- match.arg(version, c("v1", "v2"))
  stem <- sprintf("external_run_%s", version)
  c(
    out_dir = file.path(root, stem),
    lib_dir = file.path(root, paste0(stem, "_library")),
    targets_store = file.path(root, paste0(stem, "_targets"))
  )
}

resolve_repro_cli_paths <- function(args = character(),
                                    version) {
  defaults <- default_repro_run_paths(version = version)
  supplied <- rep(NA_character_, length(defaults))
  if (length(args) > 0L) {
    supplied[seq_len(min(length(args), length(defaults)))] <-
      as.character(args[seq_len(min(length(args), length(defaults)))])
  }
  use_supplied <- !is.na(supplied) & nzchar(supplied)
  defaults[use_supplied] <- supplied[use_supplied]
  defaults
}

resolve_current_r_runtime <- function() {
  executable_name <- if (.Platform$OS.type == "windows") "R.exe" else "R"
  executable <- file.path(R.home("bin"), executable_name)
  if (!file.exists(executable)) {
    repro_abort(
      "Unable to locate the R executable for the active installation.",
      "herbivoreTTR_r_executable_missing",
      executable = executable
    )
  }

  list(
    executable = normalizePath(executable, winslash = "/", mustWork = TRUE),
    r_home = normalizePath(R.home(), winslash = "/", mustWork = TRUE),
    r_version = R.version.string
  )
}

run_command_capture <- function(command, args, env = character()) {
  quoted_env <- vapply(env, function(entry) {
    separator <- regexpr("=", entry, fixed = TRUE)
    if (separator < 2L) {
      repro_abort(
        "Command environment entries must use NAME=VALUE syntax.",
        "herbivoreTTR_command_env_invalid",
        entry = entry
      )
    }

    name <- substr(entry, 1L, separator - 1L)
    value <- substr(entry, separator + 1L, nchar(entry))
    paste0(name, "=", shQuote(value))
  }, character(1), USE.NAMES = FALSE)

  output <- suppressWarnings(system2(
    command,
    args,
    stdout = TRUE,
    stderr = TRUE,
    env = quoted_env
  ))
  status <- attr(output, "status")
  if (is.null(status)) {
    status <- 0L
  }
  list(status = as.integer(status), output = as.character(output))
}

probe_r_home <- function(r_executable, command_runner = run_command_capture) {
  if (!is.character(r_executable) || length(r_executable) != 1L ||
      is.na(r_executable) || !nzchar(r_executable)) {
    repro_abort(
      "The selected R executable must be a non-empty scalar character value.",
      "herbivoreTTR_r_executable_invalid",
      executable = r_executable
    )
  }

  resolved_executable <- r_executable
  if (!grepl("[/\\\\]", r_executable)) {
    resolved_executable <- unname(Sys.which(r_executable))
    if (!nzchar(resolved_executable)) {
      repro_abort(
        "Unable to resolve the selected R executable through PATH.",
        "herbivoreTTR_r_executable_missing",
        executable = r_executable
      )
    }
  }
  resolved_executable <- canonicalize_run_path(resolved_executable)

  expr <- "cat(normalizePath(R.home(), winslash = '/', mustWork = TRUE))"
  result <- command_runner(
    resolved_executable,
    c("--vanilla", "--slave", "-e", shQuote(expr)),
    character()
  )
  if (!identical(as.integer(result$status), 0L)) {
    repro_abort(
      "Failed to inspect the selected R executable.",
      "herbivoreTTR_r_runtime_probe_failed",
      executable = resolved_executable,
      output = result$output
    )
  }

  lines <- trimws(as.character(result$output))
  lines <- lines[nzchar(lines)]
  if (length(lines) < 1L) {
    repro_abort(
      "The selected R executable did not report an R home.",
      "herbivoreTTR_r_runtime_probe_failed",
      executable = resolved_executable
    )
  }
  list(
    r_executable = resolved_executable,
    r_home = canonicalize_run_path(lines[[length(lines)]])
  )
}

assert_shared_r_runtime <- function(r_executable,
                                    expected_r_home = R.home(),
                                    command_runner = run_command_capture) {
  selected_runtime <- probe_r_home(
    r_executable,
    command_runner = command_runner
  )
  selected_home <- selected_runtime$r_home
  active_home <- canonicalize_run_path(expected_r_home)
  if (!identical(selected_home, active_home)) {
    repro_abort(
      sprintf(
        "Selected R home '%s' does not match active Rscript home '%s'.",
        selected_home,
        active_home
      ),
      "herbivoreTTR_r_runtime_mismatch",
      r_executable = selected_runtime$r_executable,
      selected_r_home = selected_home,
      active_r_home = active_home
    )
  }

  invisible(list(
    r_executable = selected_runtime$r_executable,
    r_home = active_home
  ))
}

assert_fresh_run_directory <- function(path, purpose) {
  path <- canonicalize_run_path(path)
  if (file.exists(path) && !dir.exists(path)) {
    repro_abort(
      sprintf("%s path exists but is not a directory.", purpose),
      "herbivoreTTR_fresh_run_path_not_directory",
      path = path,
      purpose = purpose
    )
  }

  entries <- if (dir.exists(path)) {
    list.files(path, all.files = TRUE, no.. = TRUE)
  } else {
    character()
  }
  if (length(entries) > 0L) {
    repro_abort(
      sprintf("%s directory must be empty before work begins.", purpose),
      "herbivoreTTR_fresh_run_directory_not_empty",
      path = path,
      purpose = purpose,
      entries = entries
    )
  }

  invisible(path)
}

snapshot_file_metadata <- function(paths) {
  canonical <- unique(vapply(paths, canonicalize_run_path, character(1)))
  info <- file.info(canonical)
  exists <- !is.na(info$isdir) & !info$isdir
  data.frame(
    path = canonical,
    existed = exists,
    size = ifelse(exists, as.numeric(info$size), NA_real_),
    mtime = ifelse(exists, as.numeric(info$mtime), NA_real_),
    ctime = ifelse(exists, as.numeric(info$ctime), NA_real_),
    stringsAsFactors = FALSE
  )
}

create_repro_run_marker <- function(marker_dir = "artefacts",
                                    sleep_seconds = 1.05,
                                    sleeper = Sys.sleep) {
  dir.create(marker_dir, recursive = TRUE, showWarnings = FALSE)
  marker_path <- tempfile(pattern = ".herbivoreTTR-repro-", tmpdir = marker_dir)
  writeLines(format(Sys.time(), "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC"), marker_path)
  if (sleep_seconds > 0) {
    sleeper(sleep_seconds)
  }
  normalizePath(marker_path, winslash = "/", mustWork = TRUE)
}

assert_files_regenerated_since <- function(paths, before, marker_path, purpose) {
  canonical <- unique(vapply(paths, canonicalize_run_path, character(1)))
  missing <- canonical[!file.exists(canonical)]
  if (length(missing) > 0L) {
    repro_abort(
      sprintf("Required %s files are missing.", purpose),
      "herbivoreTTR_repro_output_missing",
      purpose = purpose,
      missing = missing
    )
  }

  marker_path <- canonicalize_run_path(marker_path)
  marker_info <- file.info(marker_path)
  if (is.na(marker_info$mtime) || marker_info$isdir) {
    repro_abort(
      "The reproducibility run marker is missing or invalid.",
      "herbivoreTTR_repro_marker_invalid",
      marker_path = marker_path
    )
  }

  after <- snapshot_file_metadata(canonical)
  before_index <- match(after$path, before$path)
  existed_before <- !is.na(before_index) & before$existed[before_index]
  unchanged <- existed_before &
    after$size == before$size[before_index] &
    after$mtime == before$mtime[before_index] &
    after$ctime == before$ctime[before_index]
  unchanged[is.na(unchanged)] <- FALSE
  if (any(unchanged)) {
    repro_abort(
      sprintf("Required %s files have unchanged post-run metadata.", purpose),
      "herbivoreTTR_repro_output_unchanged",
      purpose = purpose,
      unchanged = after$path[unchanged]
    )
  }

  marker_time <- as.numeric(marker_info$mtime)
  stale <- after$path[is.na(after$mtime) | after$mtime <= marker_time]
  if (length(stale) > 0L) {
    repro_abort(
      sprintf("Required %s files are not newer than the run marker.", purpose),
      "herbivoreTTR_repro_output_stale",
      purpose = purpose,
      stale = stale,
      marker_path = marker_path
    )
  }

  invisible(after)
}

paper_pipeline_generated_input_files_v2 <- function() {
  c(
    experiment_a_summary = file.path(
      "artefacts", "canonical_runs", "experiment_a_presence_removal_v2",
      "experiment_a_summary_v2.csv"
    ),
    experiment_a_delta = file.path(
      "artefacts", "canonical_runs", "experiment_a_presence_removal_v2",
      "experiment_a_delta_ensemble_v2.csv"
    ),
    experiment_a_claims = file.path(
      "artefacts", "canonical_runs", "experiment_a_presence_removal_v2",
      "experiment_a_claims_v2.csv"
    ),
    experiment_a_summary_units = file.path(
      "artefacts", "canonical_runs", "experiment_a_presence_removal_v2",
      "experiment_a_summary_v2_units.csv"
    ),
    experiment_c_summary = file.path(
      "artefacts", "canonical_runs", "experiment_c_aridity_gradient_v2",
      "experiment_c_summary_v2.csv"
    ),
    experiment_c_claims = file.path(
      "artefacts", "canonical_runs", "experiment_c_aridity_gradient_v2",
      "experiment_c_claims_v2.csv"
    ),
    experiment_c_summary_units = file.path(
      "artefacts", "canonical_runs", "experiment_c_aridity_gradient_v2",
      "experiment_c_summary_v2_units.csv"
    ),
    pilot = file.path(
      "artefacts", "validation", "pilot_benchmark_v1",
      "pilot_metrics_summary_v1.csv"
    ),
    stability = file.path(
      "artefacts", "stability", "long_horizon_v1",
      "stability_summary_v1.csv"
    ),
    experiment_a_figure = file.path(
      "artefacts", "canonical_runs", "experiment_a_presence_removal_v2",
      "experiment_a_presence_removal_v2.png"
    ),
    experiment_c_figure = file.path(
      "artefacts", "canonical_runs", "experiment_c_aridity_gradient_v2",
      "experiment_c_aridity_gradient_v2.png"
    )
  )
}

v2_replay_suite_owned_paths <- function() {
  c(
    paper_pipeline_generated_input_files_v2(),
    scaling = file.path(
      "artefacts", "benchmarks", "post_v1_scaling_v2",
      "scaling_summary_v1.csv"
    ),
    report = file.path("artefacts", "reports_v2", "paper_pipeline_v2.html"),
    manifest = file.path("artefacts", "reports_v2", "figure_table_manifest_v2.csv")
  )
}

assert_v2_replay_phase_freshness <- function(
    target_owned_paths,
    suite_owned_paths,
    overall_before,
    overall_marker_path,
    suite_before,
    suite_marker_path) {
  assert_files_regenerated_since(
    target_owned_paths,
    before = overall_before,
    marker_path = overall_marker_path,
    purpose = "v2 target-owned replay output"
  )
  assert_files_regenerated_since(
    suite_owned_paths,
    before = suite_before,
    marker_path = suite_marker_path,
    purpose = "v2 suite-owned replay output"
  )
  invisible(TRUE)
}

assert_finite_numeric_columns <- function(data, columns, purpose) {
  if (!is.data.frame(data) || nrow(data) < 1L) {
    repro_abort(
      sprintf("Required %s rows are missing.", purpose),
      "herbivoreTTR_repro_required_rows_missing",
      purpose = purpose
    )
  }

  valid_contract <- is.character(columns) &&
    length(columns) > 0L &&
    !anyNA(columns) &&
    all(nzchar(columns)) &&
    !anyDuplicated(columns)
  missing_columns <- if (is.character(columns)) setdiff(columns, names(data)) else columns
  numeric_columns <- valid_contract &&
    length(missing_columns) == 0L &&
    all(vapply(data[columns], is.numeric, logical(1)))
  if (!numeric_columns) {
    repro_abort(
      sprintf("Required named numeric columns are invalid for %s.", purpose),
      "herbivoreTTR_repro_columns_invalid",
      purpose = purpose,
      columns = columns,
      missing_columns = missing_columns
    )
  }

  if (any(!is.finite(as.matrix(data[columns])))) {
    repro_abort(
      sprintf("Non-finite values found in %s.", purpose),
      "herbivoreTTR_repro_non_finite_values",
      purpose = purpose,
      columns = columns
    )
  }

  invisible(data)
}

assert_nonnegative_columns <- function(data, columns, purpose) {
  assert_finite_numeric_columns(data, columns, purpose)
  if (any(as.matrix(data[columns]) < 0)) {
    repro_abort(
      sprintf("Negative values found in %s.", purpose),
      "herbivoreTTR_repro_negative_values",
      purpose = purpose,
      columns = columns
    )
  }

  invisible(data)
}

assert_required_rows_present <- function(data, required_rows, key_columns, purpose) {
  missing_columns <- setdiff(key_columns, intersect(names(data), names(required_rows)))
  if (length(missing_columns) > 0L || nrow(data) < 1L || nrow(required_rows) < 1L) {
    repro_abort(
      sprintf("Required %s rows or key columns are missing.", purpose),
      "herbivoreTTR_repro_required_rows_missing",
      purpose = purpose,
      missing_columns = missing_columns
    )
  }

  row_keys <- function(x) {
    do.call(paste, c(lapply(x[key_columns], as.character), sep = "\034"))
  }
  missing_keys <- setdiff(row_keys(required_rows), row_keys(data))
  if (length(missing_keys) > 0L) {
    repro_abort(
      sprintf("Required %s rows are missing.", purpose),
      "herbivoreTTR_repro_required_rows_missing",
      purpose = purpose,
      missing_keys = missing_keys
    )
  }

  invisible(data)
}

assert_repro_required_claims_supported <- function(data, purpose) {
  required_columns <- c("required", "status")
  if (!is.data.frame(data) || nrow(data) < 1L ||
      !all(required_columns %in% names(data))) {
    repro_abort(
      sprintf("Required %s rows or columns are missing.", purpose),
      "herbivoreTTR_repro_required_rows_missing",
      purpose = purpose
    )
  }
  if (!is.logical(data$required) || anyNA(data$required)) {
    repro_abort(
      sprintf("Required flags are malformed in %s.", purpose),
      "herbivoreTTR_repro_required_flag_invalid",
      purpose = purpose
    )
  }

  required_rows <- data[data$required, , drop = FALSE]
  if (nrow(required_rows) < 1L) {
    repro_abort(
      sprintf("No required %s rows were found.", purpose),
      "herbivoreTTR_repro_required_rows_missing",
      purpose = purpose
    )
  }

  supported <- tolower(trimws(as.character(required_rows$status))) == "supported"
  if (anyNA(supported) || !all(supported)) {
    repro_abort(
      sprintf("At least one required %s claim is not supported.", purpose),
      "herbivoreTTR_repro_required_claim_failed",
      purpose = purpose
    )
  }

  invisible(data)
}

assert_zero_stability_violations <- function(data,
                                             purpose = "stability summary") {
  violation_columns <- c(
    "nan_inf_count_total",
    "negative_biomass_violations_total",
    "gut_capacity_violations_total",
    "any_violation_runs"
  )
  assert_finite_numeric_columns(data, violation_columns, purpose)
  if (any(as.matrix(data[violation_columns]) != 0)) {
    repro_abort(
      sprintf("Existing stability violations found in %s.", purpose),
      "herbivoreTTR_repro_stability_violation",
      purpose = purpose,
      columns = violation_columns
    )
  }

  invisible(data)
}

canonical_replay_snapshot_paths <- function(
    canonical_dir = file.path("artefacts", "canonical_runs", "smoke_v0")) {
  list(
    plant_paths = sort(Sys.glob(file.path(canonical_dir, "plants_day*.csv"))),
    herbivore_paths = sort(Sys.glob(file.path(canonical_dir, "herb_day*.csv")))
  )
}

assert_plant_snapshot_contract <- function(paths,
                                           purpose,
                                           reader = function(path) {
                                             utils::read.csv(
                                               path,
                                               sep = ";",
                                               stringsAsFactors = FALSE
                                             )
                                           }) {
  if (length(paths) < 1L || any(!file.exists(paths))) {
    repro_abort(
      sprintf("Required %s files are missing.", purpose),
      "herbivoreTTR_repro_output_missing",
      purpose = purpose,
      missing = paths[!file.exists(paths)]
    )
  }

  biomass_columns <- c("BLeaf", "BStem", "BDef", "Ms", "Mr")
  for (path in paths) {
    snapshot <- reader(path)
    numeric_columns <- names(snapshot)[vapply(snapshot, is.numeric, logical(1))]
    assert_finite_numeric_columns(snapshot, numeric_columns, purpose)
    assert_nonnegative_columns(snapshot, biomass_columns, purpose)
  }

  invisible(paths)
}

assert_herbivore_snapshot_contract <- function(paths,
                                               purpose,
                                               reader = function(path) {
                                                 utils::read.csv(
                                                   path,
                                                   sep = ";",
                                                   stringsAsFactors = FALSE
                                                 )
                                               }) {
  if (length(paths) < 1L || any(!file.exists(paths))) {
    repro_abort(
      sprintf("Required %s files are missing.", purpose),
      "herbivoreTTR_repro_output_missing",
      purpose = purpose,
      missing = paths[!file.exists(paths)]
    )
  }

  required_columns <- c("Mass", "EnergyBalance", "WaterBalance")
  for (path in paths) {
    snapshot <- reader(path)
    assert_finite_numeric_columns(snapshot, required_columns, purpose)
    assert_nonnegative_columns(snapshot, "Mass", purpose)
  }

  invisible(paths)
}

assert_targets_store_metadata <- function(
    targets_store,
    metadata_reader = function(path) targets::tar_meta(store = path)) {
  metadata <- tryCatch(metadata_reader(targets_store), error = identity)
  if (inherits(metadata, "error") || !is.data.frame(metadata) || nrow(metadata) < 1L) {
    repro_abort(
      "Fresh targets store metadata is missing or unreadable.",
      "herbivoreTTR_targets_store_metadata_missing",
      targets_store = targets_store
    )
  }

  invisible(metadata)
}

run_repro_steps <- function(steps,
                            r_executable,
                            env,
                            out_dir,
                            command_runner = run_command_capture,
                            clock = Sys.time) {
  results <- list()
  for (step in steps) {
    if (length(results) > 0L && results[[length(results)]]$status != 0L) {
      break
    }

    log_path <- file.path(out_dir, sprintf("%s.log", step$step))
    started <- clock()
    command <- command_runner(
      r_executable,
      c("-q", "-e", shQuote(step$expr)),
      env
    )
    elapsed <- as.numeric(difftime(clock(), started, units = "secs"))
    writeLines(as.character(command$output), log_path)
    results[[length(results) + 1L]] <- list(
      step = step$step,
      status = as.integer(command$status),
      elapsed_seconds = elapsed,
      log_path = log_path
    )
  }

  results
}
