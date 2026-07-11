#!/usr/bin/env Rscript

sys.source(file.path("R", "repro_runtime.R"), envir = globalenv())

args <- commandArgs(trailingOnly = TRUE)
cli_paths <- resolve_repro_cli_paths(args, version = "v2")
out_dir <- cli_paths[["out_dir"]]
lib_dir <- cli_paths[["lib_dir"]]
targets_store <- cli_paths[["targets_store"]]

paths <- validate_repro_run_paths(out_dir, lib_dir, targets_store)
out_dir <- paths[["out_dir"]]
lib_dir <- paths[["lib_dir"]]
targets_store <- paths[["targets_store"]]

assert_fresh_run_directory(out_dir, purpose = "v2 reproducibility output")
assert_fresh_run_directory(lib_dir, purpose = "v2 isolated renv library")
assert_fresh_run_directory(targets_store, purpose = "v2 targets store")

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

required_outputs <- v2_replay_suite_owned_paths()
snapshot_paths_before <- canonical_replay_snapshot_paths()
snapshot_path <- file.path(out_dir, "pre_run_file_snapshot.rds")
post_targets_snapshot <- file.path(out_dir, "post_targets_file_snapshot.rds")
post_targets_marker_record <- file.path(out_dir, "post_targets_marker_path.txt")
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
  sprintf("HERBIVORETTR_POST_TARGETS_SNAPSHOT=%s", post_targets_snapshot),
  sprintf("HERBIVORETTR_POST_TARGETS_MARKER_RECORD=%s", post_targets_marker_record),
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
    step = "03_capture_v2_suite_boundary",
    expr = paste(
      "sys.source(file.path('R', 'repro_runtime.R'), envir = globalenv());",
      "suite_owned <- v2_replay_suite_owned_paths();",
      "saveRDS(snapshot_file_metadata(suite_owned),",
      "Sys.getenv('HERBIVORETTR_POST_TARGETS_SNAPSHOT'));",
      "post_targets_marker <- create_repro_run_marker(marker_dir = 'artefacts');",
      "writeLines(post_targets_marker,",
      "Sys.getenv('HERBIVORETTR_POST_TARGETS_MARKER_RECORD'))"
    )
  ),
  list(
    step = "04_run_v2_suites",
    expr = paste(
      "for (f in list.files('R', pattern = '[.]R$', full.names = TRUE))",
      "sys.source(f, envir = globalenv());",
      "run_experiment_a_presence_removal_v2(seeds = 301:306);",
      "run_experiment_c_aridity_gradient_v2(seeds = 701:706);",
      "run_pilot_validation_benchmark_v1();",
      "run_long_horizon_stability_suite_v1(days = 90L, seeds = 801:803);",
      "run_post_v1_scaling_profile(scenario_slug = 'post_v1_scaling_v2',",
      "ensemble_seeds = 1:8, stability_days = 30L, stability_seeds = 1:2);",
      "render_paper_pipeline_report_v2()"
    )
  ),
  list(
    step = "05_verify_outputs",
    expr = paste(
      "sys.source(file.path('R', 'repro_runtime.R'), envir = globalenv());",
      "sys.source(file.path('R', 'report_manifest_v2.R'), envir = globalenv());",
      "overall_before <- readRDS(Sys.getenv('HERBIVORETTR_REPRO_SNAPSHOT'));",
      "overall_marker <- Sys.getenv('HERBIVORETTR_REPRO_MARKER');",
      "suite_before <- readRDS(Sys.getenv('HERBIVORETTR_POST_TARGETS_SNAPSHOT'));",
      "post_targets_marker <- trimws(readLines(",
      "Sys.getenv('HERBIVORETTR_POST_TARGETS_MARKER_RECORD'), n = 1L));",
      "required <- v2_replay_suite_owned_paths();",
      "snapshots <- canonical_replay_snapshot_paths();",
      "plant_paths <- snapshots$plant_paths;",
      "herbivore_paths <- snapshots$herbivore_paths;",
      "if (!length(plant_paths)) stop('No canonical smoke plant snapshots found.');",
      "if (!length(herbivore_paths)) stop('No canonical smoke herbivore snapshots found.');",
      "assert_v2_replay_phase_freshness(",
      "target_owned_paths = c(plant_paths, herbivore_paths),",
      "suite_owned_paths = required, overall_before = overall_before,",
      "overall_marker_path = overall_marker, suite_before = suite_before,",
      "suite_marker_path = post_targets_marker);",
      "assert_plant_snapshot_contract(plant_paths, 'v2 plant snapshots');",
      "assert_herbivore_snapshot_contract(herbivore_paths, 'v2 herbivore snapshots');",
      "a <- utils::read.csv(required[['experiment_a_summary']], stringsAsFactors = FALSE);",
      "a_claims <- utils::read.csv(required[['experiment_a_claims']], stringsAsFactors = FALSE);",
      "c_summary <- utils::read.csv(required[['experiment_c_summary']], stringsAsFactors = FALSE);",
      "c_claims <- utils::read.csv(required[['experiment_c_claims']], stringsAsFactors = FALSE);",
      "stability <- utils::read.csv(required[['stability']], stringsAsFactors = FALSE);",
      "pilot <- utils::read.csv(required[['pilot']], stringsAsFactors = FALSE);",
      "scaling <- utils::read.csv(required[['scaling']], stringsAsFactors = FALSE);",
      "assert_finite_numeric_columns(a, names(a)[vapply(a, is.numeric, logical(1))],",
      "'experiment A summary');",
      "assert_finite_numeric_columns(c_summary,",
      "names(c_summary)[vapply(c_summary, is.numeric, logical(1))], 'experiment C summary');",
      "assert_finite_numeric_columns(a_claims, c('threshold', 'observed_value'),",
      "'experiment A claims');",
      "assert_finite_numeric_columns(c_claims, c('threshold', 'observed_value'),",
      "'experiment C claims');",
      "assert_finite_numeric_columns(stability,",
      "names(stability)[vapply(stability, is.numeric, logical(1))], 'stability summary');",
      "assert_finite_numeric_columns(pilot,",
      "c('rmse', 'normalized_rmse', 'mean_bias', 'directional_agreement', 'n'),",
      "'pilot summary');",
      "assert_finite_numeric_columns(scaling,",
      "names(scaling)[vapply(scaling, is.numeric, logical(1))], 'scaling summary');",
      "assert_required_rows_present(a, data.frame(scenario = c('present', 'removal')),",
      "'scenario', 'experiment A summary');",
      "required_c <- expand.grid(aridity_level = c('low', 'mid', 'high'),",
      "access_level = c('low', 'mid', 'high'), stringsAsFactors = FALSE);",
      "assert_required_rows_present(c_summary, required_c,",
      "c('aridity_level', 'access_level'), 'experiment C summary');",
      "assert_repro_required_claims_supported(a_claims, 'experiment A');",
      "assert_repro_required_claims_supported(c_claims, 'experiment C');",
      "assert_zero_stability_violations(stability);",
      "if (!check_report_content_v2(required[['report']]))",
      "stop('Rendered v2 report is missing required scientific sections.');",
      "validate_report_artifact_manifest_v2(required[['manifest']]);",
      "cat('External v2 reproducibility verification passed\\n')"
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

post_targets_marker <- if (file.exists(post_targets_marker_record)) {
  trimws(readLines(post_targets_marker_record, n = 1L, warn = FALSE))
} else {
  NA_character_
}
report_path <- file.path(out_dir, "repro_check_report.md")
report_lines <- c(
  "# External Reproducibility Run-through (v2)",
  "",
  sprintf("- Run timestamp (UTC): `%s`", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
  sprintf("- R executable: `%s`", r_runtime$executable),
  sprintf("- R home: `%s`", r_runtime$r_home),
  sprintf("- R version: `%s`", r_runtime$r_version),
  sprintf("- Isolated renv library: `%s`", lib_dir),
  sprintf("- Fresh targets store: `%s`", targets_store),
  sprintf("- Pre-run metadata snapshot: `%s`", snapshot_path),
  sprintf("- Same-tree run marker: `%s`", marker_path),
  sprintf("- Post-target metadata snapshot: `%s`", post_targets_snapshot),
  sprintf("- Post-target same-tree marker: `%s`", post_targets_marker),
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
  post_targets_snapshot = post_targets_snapshot,
  post_targets_marker = post_targets_marker,
  summary_csv = summary_path,
  report_md = report_path,
  all_pass = all(summary_df$passed)
)
manifest_path <- file.path(out_dir, "repro_check_manifest.json")
writeLines(jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE), con = manifest_path)

if (!all(summary_df$passed)) {
  message("External reproducibility run-through v2 failed.")
  print(summary_df)
  message(sprintf("Summary: %s", summary_path))
  message(sprintf("Report: %s", report_path))
  stop("External reproducibility run-through v2 failed. Inspect logs under artefacts/reproducibility/.")
}

message("External reproducibility run-through v2 completed successfully.")
message(sprintf("Summary: %s", summary_path))
message(sprintf("Report: %s", report_path))
