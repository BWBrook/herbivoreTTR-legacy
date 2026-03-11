#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
out_dir <- if (length(args) >= 1L && nzchar(args[[1]])) args[[1]] else file.path("artefacts", "reproducibility", "external_run_v2")
lib_dir <- if (length(args) >= 2L && nzchar(args[[2]])) args[[2]] else file.path(out_dir, "renv_library")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(lib_dir, recursive = TRUE, showWarnings = FALSE)

out_dir <- normalizePath(out_dir, winslash = "/", mustWork = TRUE)
lib_dir <- normalizePath(lib_dir, winslash = "/", mustWork = TRUE)

run_step <- function(step_name, expr, env) {
  log_path <- file.path(out_dir, sprintf("%s.log", step_name))
  start <- Sys.time()
  output <- system2("R", c("-q", "-e", shQuote(expr, type = "sh")), stdout = TRUE, stderr = TRUE, env = env)
  elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))
  status <- attr(output, "status")
  if (is.null(status)) {
    status <- 0L
  }
  writeLines(output, con = log_path)
  list(
    step = step_name,
    status = as.integer(status),
    elapsed_seconds = elapsed,
    log_path = log_path
  )
}

env <- c(
  sprintf("RENV_PATHS_LIBRARY=%s", lib_dir),
  "RENV_CONFIG_REPOS_OVERRIDE=https://cloud.r-project.org",
  "RENV_CONFIG_PAK_ENABLED=FALSE",
  "TARGETS_PROFILE=ci"
)

steps <- list(
  run_step(
    "01_restore",
    "options(renv.consent = TRUE); renv::restore(prompt = FALSE)",
    env
  ),
  run_step(
    "02_targets_smoke",
    "Sys.setenv(TARGETS_PROFILE = 'ci'); targets::tar_make(callr_function = NULL)",
    env
  ),
  run_step(
    "03_run_v2_suites",
    paste(
      "for (f in list.files('R', pattern = '\\\\.R$', full.names = TRUE)) sys.source(f, envir = globalenv());",
      "run_experiment_a_presence_removal_v2(seeds = 301:306);",
      "run_experiment_c_aridity_gradient_v2(seeds = 701:706);",
      "run_pilot_validation_benchmark_v1();",
      "run_long_horizon_stability_suite_v1(days = 90L, seeds = 801:803);",
      "run_post_v1_scaling_profile(scenario_slug = 'post_v1_scaling_v2', ensemble_seeds = 1:8, stability_days = 30L, stability_seeds = 1:2)"
    ),
    env
  ),
  run_step(
    "04_verify_outputs",
    paste(
      "required <- c(",
      "'artefacts/canonical_runs/experiment_a_presence_removal_v2/experiment_a_summary_v2.csv',",
      "'artefacts/canonical_runs/experiment_a_presence_removal_v2/experiment_a_claims_v2.csv',",
      "'artefacts/canonical_runs/experiment_c_aridity_gradient_v2/experiment_c_summary_v2.csv',",
      "'artefacts/canonical_runs/experiment_c_aridity_gradient_v2/experiment_c_claims_v2.csv',",
      "'artefacts/stability/long_horizon_v1/stability_summary_v1.csv',",
      "'artefacts/validation/pilot_benchmark_v1/pilot_metrics_summary_v1.csv',",
      "'artefacts/benchmarks/post_v1_scaling_v2/scaling_summary_v1.csv');",
      "missing <- required[!file.exists(required)];",
      "if (length(missing)) stop(paste('Missing required v2 artefacts:', paste(missing, collapse = ', ')));",
      "a <- utils::read.csv('artefacts/canonical_runs/experiment_a_presence_removal_v2/experiment_a_summary_v2.csv', stringsAsFactors = FALSE);",
      "c <- utils::read.csv('artefacts/canonical_runs/experiment_c_aridity_gradient_v2/experiment_c_summary_v2.csv', stringsAsFactors = FALSE);",
      "if (nrow(a) < 2L) stop('Experiment A v2 summary has insufficient rows.');",
      "if (nrow(c) < 3L) stop('Experiment C v2 summary has insufficient rows.');",
      "cat('External v2 reproducibility verification passed\\n')"
    ),
    env
  )
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
  "# External Reproducibility Run-through (v2)",
  "",
  sprintf("- Run timestamp (UTC): `%s`", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
  sprintf("- Isolated renv library: `%s`", lib_dir),
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
  isolated_library = lib_dir,
  summary_csv = summary_path,
  report_md = report_path,
  all_pass = all(summary_df$passed)
)
manifest_path <- file.path(out_dir, "repro_check_manifest.json")
writeLines(jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE), con = manifest_path)

if (!all(summary_df$passed)) {
  stop("External reproducibility run-through v2 failed. Inspect logs under artefacts/reproducibility/.")
}

message("External reproducibility run-through v2 completed successfully.")
message(sprintf("Summary: %s", summary_path))
message(sprintf("Report: %s", report_path))
