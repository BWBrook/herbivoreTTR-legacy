#!/usr/bin/env Rscript

full_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", full_args, value = TRUE)
script_path <- normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = TRUE)
repo_root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
setwd(repo_root)

if (!requireNamespace("shiny", quietly = TRUE)) {
  stop("Package `shiny` is required for the GUI stub. Install it with install.packages('shiny').", call. = FALSE)
}

for (f in list.files(file.path(repo_root, "R"), pattern = "[.]R$", full.names = TRUE)) {
  sys.source(f, envir = globalenv())
}

shiny::runApp(file.path(repo_root, "portal", "gui"), launch.browser = interactive())
