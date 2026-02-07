#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L || args[[1]] %in% c("-h", "--help")) {
  cat("Usage: Rscript portal/run_sensitivity.R <plan_yaml> [--dry-run]\n")
  quit(status = 1)
}

full_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", full_args, value = TRUE)
script_path <- normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = TRUE)
repo_root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
setwd(repo_root)

for (f in list.files(file.path(repo_root, "R"), pattern = "[.]R$", full.names = TRUE)) {
  sys.source(f, envir = globalenv())
}

plan_path <- args[[1]]
dry_run <- "--dry-run" %in% args

res <- run_portal_plan_v1(plan = plan_path, dry_run = dry_run, force_mode = "sensitivity")

if (isTRUE(res$dry_run)) {
  cat("Sensitivity dry-run complete.\n")
  cat(sprintf("- mode: %s\n", res$mode))
  cat(sprintf("- scenario_id: %s\n", res$scenario_id))
  cat(sprintf("- seed: %s\n", as.character(res$seed)))
  quit(status = 0)
}

cat("Sensitivity run complete.\n")
cat(sprintf("- run_dir: %s\n", res$run_dir))
cat(sprintf("- run_index: %s\n", res$run_index_path))
cat(sprintf("- design_table: %s\n", res$design_path))
cat(sprintf("- endpoint_summary: %s\n", res$endpoint_path))
cat(sprintf("- manifest: %s\n", res$manifest_path))
if (!is.null(res$report$html_path) && !is.na(res$report$html_path)) {
  cat(sprintf("- report_html: %s\n", res$report$html_path))
}
