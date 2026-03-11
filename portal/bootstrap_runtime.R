portal_script_path_v1 <- function(full_args = commandArgs(trailingOnly = FALSE)) {
  file_arg <- grep("^--file=", full_args, value = TRUE)
  if (length(file_arg) < 1L) {
    stop("Unable to resolve invoking script path.", call. = FALSE)
  }

  normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = TRUE)
}

portal_find_repo_root_v1 <- function(start) {
  dir <- normalizePath(start, winslash = "/", mustWork = TRUE)
  for (i in 0:10) {
    if (file.exists(file.path(dir, "DESCRIPTION"))) {
      return(dir)
    }
    parent <- dirname(dir)
    if (identical(parent, dir)) {
      break
    }
    dir <- parent
  }
  NULL
}

portal_source_runtime_v1 <- function(repo_root, envir = globalenv()) {
  files <- list.files(file.path(repo_root, "R"), pattern = "[.]R$", full.names = TRUE)
  for (f in files) {
    sys.source(f, envir = envir)
  }
  invisible(TRUE)
}

portal_bootstrap_runtime_v1 <- function(start, envir = globalenv()) {
  repo_root <- portal_find_repo_root_v1(start)
  if (is.null(repo_root)) {
    stop("Could not locate repository root for portal runtime bootstrap.", call. = FALSE)
  }

  setwd(repo_root)
  portal_source_runtime_v1(repo_root, envir = envir)
  repo_root
}
