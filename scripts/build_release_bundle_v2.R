#!/usr/bin/env Rscript

for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) {
  sys.source(f, envir = globalenv())
}

status <- run_release_bundle_v2_cli(commandArgs(trailingOnly = TRUE))
if (status != 0L) {
  quit(status = status, save = "no")
}
