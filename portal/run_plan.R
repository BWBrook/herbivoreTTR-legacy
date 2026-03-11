#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L || args[[1]] %in% c("-h", "--help")) {
  cat("Usage: Rscript portal/run_plan.R <plan_yaml> [--dry-run]\n")
  quit(status = 1)
}

full_args <- commandArgs(trailingOnly = FALSE)
script_path <- normalizePath(sub("^--file=", "", grep("^--file=", full_args, value = TRUE)[[1]]), winslash = "/", mustWork = TRUE)
source(file.path(dirname(script_path), "bootstrap_runtime.R"), local = TRUE)
repo_root <- portal_bootstrap_runtime_v1(start = dirname(script_path), envir = globalenv())

plan_path <- args[[1]]
dry_run <- "--dry-run" %in% args

res <- run_portal_plan_v2(plan = plan_path, dry_run = dry_run)

if (isTRUE(res$dry_run)) {
  cat("Dry-run complete.\n")
  cat(sprintf("- mode: %s\n", res$mode))
  cat(sprintf("- scenario_id: %s\n", res$scenario_id))
  cat(sprintf("- seed: %s\n", as.character(res$seed)))
  cat(sprintf("- days: %s\n", as.character(res$days)))
  cat(sprintf("- minute_limit: %s\n", as.character(res$minute_limit)))
  quit(status = 0)
}

cat("Portal run complete.\n")
cat(sprintf("- mode: %s\n", res$mode))
cat(sprintf("- run_dir: %s\n", res$run_dir))
cat(sprintf("- run_index: %s\n", res$run_index_path))
cat(sprintf("- manifest: %s\n", res$manifest_path))
if (!is.null(res$report$html_path) && !is.na(res$report$html_path)) {
  cat(sprintf("- report_html: %s\n", res$report$html_path))
}
if (!is.null(res$report$pdf_path) && !is.na(res$report$pdf_path)) {
  cat(sprintf("- report_pdf: %s\n", res$report$pdf_path))
}
