#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
out_dir <- if (length(args) >= 1L && nzchar(args[[1]])) args[[1]] else file.path("artefacts", "reproducibility", "external_run_v1")
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
    "03_verify_outputs",
    paste(
      "required <- c('artefacts/canonical_runs/smoke_v0/run_manifest.json',",
      "'artefacts/canonical_runs/experiment_a_presence_removal_v1/experiment_a_summary.csv',",
      "'artefacts/canonical_runs/experiment_b_functional_types_v1/experiment_b_summary.csv',",
      "'artefacts/canonical_runs/experiment_c_aridity_gradient_v1/experiment_c_summary.csv',",
      "'artefacts/reports/paper_pipeline.html');",
      "missing <- required[!file.exists(required)];",
      "if (length(missing)) stop(paste('Missing required artefacts:', paste(missing, collapse = ', ')));",
      "plant_paths <- Sys.glob('artefacts/canonical_runs/smoke_v0/plants_day*.csv');",
      "if (!length(plant_paths)) stop('No canonical smoke plant snapshots found.');",
      "plants <- utils::read.csv(plant_paths[[length(plant_paths)]], sep = ';', stringsAsFactors = FALSE);",
      "herb <- utils::read.csv('artefacts/canonical_runs/smoke_v0/herbivore_daily.csv', stringsAsFactors = FALSE);",
      "if (any(!is.finite(plants$Ms)) || any(plants$Ms < 0)) stop('Invalid Ms values in plant output.');",
      "if (any(!is.finite(herb$EnergyBalance)) || any(!is.finite(herb$WaterBalance))) stop('Invalid herbivore balances.');",
      "cat('External reproducibility verification passed\\n')"
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
  "# External Reproducibility Run-through (v1)",
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
  isolated_library = lib_dir,
  summary_csv = summary_path,
  report_md = report_path,
  all_pass = all(summary_df$passed)
)
manifest_path <- file.path(out_dir, "repro_check_manifest.json")
writeLines(jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE), con = manifest_path)

if (!all(summary_df$passed)) {
  stop("External reproducibility run-through failed. Inspect logs under artefacts/reproducibility/.")
}

message("External reproducibility run-through completed successfully.")
message(sprintf("Summary: %s", summary_path))
message(sprintf("Report: %s", report_path))
