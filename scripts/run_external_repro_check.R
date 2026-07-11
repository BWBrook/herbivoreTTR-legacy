#!/usr/bin/env Rscript

sys.source(file.path("R", "repro_runtime.R"), envir = globalenv())

args <- commandArgs(trailingOnly = TRUE)
cli_paths <- resolve_repro_cli_paths(args, version = "v1")
out_dir <- cli_paths[["out_dir"]]
lib_dir <- cli_paths[["lib_dir"]]
targets_store <- cli_paths[["targets_store"]]

paths <- validate_repro_run_paths(out_dir, lib_dir, targets_store)
out_dir <- paths[["out_dir"]]
lib_dir <- paths[["lib_dir"]]
targets_store <- paths[["targets_store"]]

assert_fresh_run_directory(out_dir, purpose = "v1 reproducibility output")
assert_fresh_run_directory(lib_dir, purpose = "v1 isolated renv library")
assert_fresh_run_directory(targets_store, purpose = "v1 targets store")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(lib_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(targets_store, recursive = TRUE, showWarnings = FALSE)

paths <- validate_repro_run_paths(out_dir, lib_dir, targets_store)
out_dir <- normalizePath(paths[["out_dir"]], winslash = "/", mustWork = TRUE)
lib_dir <- normalizePath(paths[["lib_dir"]], winslash = "/", mustWork = TRUE)
targets_store <- normalizePath(paths[["targets_store"]], winslash = "/", mustWork = TRUE)
r_runtime <- resolve_current_r_runtime()
selected_r <- Sys.getenv(
  "HERBIVORETTR_R_EXECUTABLE",
  unset = r_runtime$executable
)
selected_runtime <- assert_shared_r_runtime(
  selected_r,
  expected_r_home = r_runtime$r_home
)
r_runtime$executable <- selected_runtime$r_executable

required_outputs <- c(
  file.path("artefacts", "canonical_runs", "smoke_v0", "run_manifest.json"),
  file.path(
    "artefacts",
    "canonical_runs",
    "experiment_a_presence_removal_v1",
    "experiment_a_summary.csv"
  ),
  file.path(
    "artefacts",
    "canonical_runs",
    "experiment_b_functional_types_v1",
    "experiment_b_summary.csv"
  ),
  file.path(
    "artefacts",
    "canonical_runs",
    "experiment_c_aridity_gradient_v1",
    "experiment_c_summary.csv"
  ),
  file.path("artefacts", "reports", "paper_pipeline.html")
)
snapshot_paths_before <- canonical_replay_snapshot_paths()
snapshot_path <- file.path(out_dir, "pre_run_file_snapshot.rds")
saveRDS(
  snapshot_file_metadata(c(required_outputs, unlist(snapshot_paths_before))),
  snapshot_path
)
marker_path <- create_repro_run_marker(marker_dir = "artefacts")
run_started_at <- file.info(marker_path)$mtime

env <- c(
  sprintf("RENV_PATHS_LIBRARY=%s", lib_dir),
  sprintf("HERBIVORETTR_TARGETS_STORE=%s", targets_store),
  sprintf("HERBIVORETTR_REPRO_SNAPSHOT=%s", snapshot_path),
  sprintf("HERBIVORETTR_REPRO_MARKER=%s", marker_path),
  "RENV_CONFIG_REPOS_OVERRIDE=https://cloud.r-project.org",
  "RENV_CONFIG_PAK_ENABLED=FALSE",
  "TARGETS_PROFILE=ci"
)

steps <- list(
  list(
    step = "01_restore",
    expr = paste(
      "options(renv.consent = TRUE, renv.config.pak.enabled = FALSE);",
      "Sys.setenv(RENV_CONFIG_PAK_ENABLED = 'FALSE');",
      "renv::restore(prompt = FALSE, clean = TRUE);",
      "library_root <- normalizePath(Sys.getenv('RENV_PATHS_LIBRARY'), winslash = '/', mustWork = TRUE);",
      "active_library <- normalizePath(.libPaths()[[1]], winslash = '/', mustWork = TRUE);",
      "if (!(identical(active_library, library_root) || startsWith(active_library, paste0(library_root, '/'))))",
      "stop('renv restore did not activate the isolated library');",
      "status <- renv::status();",
      "if (!isTRUE(status$synchronized)) stop('renv restore left project unsynchronized')"
    )
  ),
  list(
    step = "02_targets_smoke",
    expr = paste(
      "Sys.setenv(TARGETS_PROFILE = 'ci');",
      "targets_store <- Sys.getenv('HERBIVORETTR_TARGETS_STORE');",
      "targets::tar_make(store = targets_store, callr_function = NULL);",
      "sys.source(file.path('R', 'repro_runtime.R'), envir = globalenv());",
      "assert_targets_store_metadata(targets_store)"
    )
  ),
  list(
    step = "03_verify_outputs",
    expr = paste(
      "sys.source(file.path('R', 'repro_runtime.R'), envir = globalenv());",
      "before <- readRDS(Sys.getenv('HERBIVORETTR_REPRO_SNAPSHOT'));",
      "marker <- Sys.getenv('HERBIVORETTR_REPRO_MARKER');",
      "required <- c('artefacts/canonical_runs/smoke_v0/run_manifest.json',",
      "'artefacts/canonical_runs/experiment_a_presence_removal_v1/experiment_a_summary.csv',",
      "'artefacts/canonical_runs/experiment_b_functional_types_v1/experiment_b_summary.csv',",
      "'artefacts/canonical_runs/experiment_c_aridity_gradient_v1/experiment_c_summary.csv',",
      "'artefacts/reports/paper_pipeline.html');",
      "snapshots <- canonical_replay_snapshot_paths();",
      "plant_paths <- snapshots$plant_paths;",
      "herbivore_paths <- snapshots$herbivore_paths;",
      "if (!length(plant_paths)) stop('No canonical smoke plant snapshots found.');",
      "if (!length(herbivore_paths)) stop('No canonical smoke herbivore snapshots found.');",
      "assert_files_regenerated_since(c(required, plant_paths, herbivore_paths),",
      "before, marker, 'v1 replay output');",
      "assert_plant_snapshot_contract(plant_paths, 'v1 plant snapshots');",
      "assert_herbivore_snapshot_contract(herbivore_paths, 'v1 herbivore snapshots');",
      "cat('External reproducibility verification passed\\n')"
    )
  )
)

steps <- run_repro_steps(
  steps,
  r_executable = r_runtime$executable,
  env = env,
  out_dir = out_dir
)

summary_df <- do.call(
  rbind,
  lapply(steps, function(x) {
    data.frame(
      step = x$step,
      status_code = x$status,
      passed = as.logical(x$status == 0L),
      elapsed_seconds = x$elapsed_seconds,
      log_path = x$log_path,
      stringsAsFactors = FALSE
    )
  })
)

summary_path <- file.path(out_dir, "repro_check_summary.csv")
utils::write.csv(summary_df, summary_path, row.names = FALSE)

report_path <- file.path(out_dir, "repro_check_report.md")
report_lines <- c(
  "# External Reproducibility Run-through (v1)",
  "",
  sprintf("- Run timestamp (UTC): `%s`", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
  sprintf("- R executable: `%s`", r_runtime$executable),
  sprintf("- R home: `%s`", r_runtime$r_home),
  sprintf("- R version: `%s`", r_runtime$r_version),
  sprintf("- Isolated renv library: `%s`", lib_dir),
  sprintf("- Fresh targets store: `%s`", targets_store),
  sprintf("- Pre-run metadata snapshot: `%s`", snapshot_path),
  sprintf("- Same-tree run marker: `%s`", marker_path),
  "",
  "## Step outcomes",
  paste0(
    "- ",
    summary_df$step,
    ": `",
    ifelse(summary_df$passed, "PASS", "FAIL"),
    "` (",
    sprintf("%.2f", summary_df$elapsed_seconds),
    "s)"
  ),
  "",
  "## Required outputs verified",
  "- `artefacts/canonical_runs/smoke_v0/run_manifest.json`",
  "- `artefacts/canonical_runs/experiment_a_presence_removal_v1/experiment_a_summary.csv`",
  "- `artefacts/canonical_runs/experiment_b_functional_types_v1/experiment_b_summary.csv`",
  "- `artefacts/canonical_runs/experiment_c_aridity_gradient_v1/experiment_c_summary.csv`",
  "- `artefacts/reports/paper_pipeline.html`",
  "",
  "## Logs",
  paste0("- `", summary_df$log_path, "`")
)
writeLines(report_lines, con = report_path)

manifest <- list(
  schema_version = "1.0.0",
  created_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  run_started_utc = format(run_started_at, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  r_executable = r_runtime$executable,
  r_home = r_runtime$r_home,
  r_version = r_runtime$r_version,
  isolated_library = lib_dir,
  targets_store = targets_store,
  pre_run_snapshot = snapshot_path,
  run_marker = marker_path,
  summary_csv = summary_path,
  report_md = report_path,
  all_pass = all(summary_df$passed)
)
manifest_path <- file.path(out_dir, "repro_check_manifest.json")
writeLines(jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE), con = manifest_path)

if (!all(summary_df$passed)) {
  message("External reproducibility run-through v1 failed.")
  print(summary_df)
  message(sprintf("Summary: %s", summary_path))
  message(sprintf("Report: %s", report_path))
  stop("External reproducibility run-through failed. Inspect logs under artefacts/reproducibility/.")
}

message("External reproducibility run-through completed successfully.")
message(sprintf("Summary: %s", summary_path))
message(sprintf("Report: %s", report_path))
