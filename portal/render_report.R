#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L || args[[1]] %in% c("-h", "--help")) {
  cat("Usage: Rscript portal/render_report.R <run_dir> [html,pdf]\n")
  quit(status = 1)
}

full_args <- commandArgs(trailingOnly = FALSE)
script_path <- normalizePath(sub("^--file=", "", grep("^--file=", full_args, value = TRUE)[[1]]), winslash = "/", mustWork = TRUE)
source(file.path(dirname(script_path), "bootstrap_runtime.R"), local = TRUE)
repo_root <- portal_bootstrap_runtime_v1(start = dirname(script_path), envir = globalenv())

run_dir <- args[[1]]
formats <- if (length(args) >= 2L) strsplit(args[[2]], ",", fixed = TRUE)[[1]] else c("html")
formats <- trimws(formats)

res <- render_portal_report_v1(run_dir = run_dir, report_formats = formats)
cat("Portal report render finished.\n")
if (!is.na(res$html_path)) {
  cat(sprintf("- html: %s\n", res$html_path))
}
if (!is.na(res$pdf_path)) {
  cat(sprintf("- pdf: %s\n", res$pdf_path))
}
cat(sprintf("- notes: %s\n", res$note_path))
