#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
release_label <- if (length(args) >= 1L && nzchar(args[[1]])) args[[1]] else NULL

for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) {
  sys.source(f, envir = globalenv())
}

res <- build_release_bundle_v1(release_label = release_label)

message("Release bundle generated")
message(sprintf("- label: %s", res$release_label))
message(sprintf("- bundle: %s", res$bundle_dir))
message(sprintf("- checklist: %s", res$checklist_path))
message(sprintf("- all checks pass: %s", ifelse(all(res$checklist$pass), "yes", "no")))
