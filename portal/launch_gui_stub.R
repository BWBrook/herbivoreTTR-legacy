#!/usr/bin/env Rscript

full_args <- commandArgs(trailingOnly = FALSE)
script_path <- normalizePath(sub("^--file=", "", grep("^--file=", full_args, value = TRUE)[[1]]), winslash = "/", mustWork = TRUE)
source(file.path(dirname(script_path), "bootstrap_runtime.R"), local = TRUE)
repo_root <- portal_bootstrap_runtime_v1(start = dirname(script_path), envir = globalenv())

if (!requireNamespace("shiny", quietly = TRUE)) {
  stop("Package `shiny` is required for the GUI stub. Install it with install.packages('shiny').", call. = FALSE)
}

shiny::runApp(file.path(repo_root, "portal", "gui"), launch.browser = interactive())
