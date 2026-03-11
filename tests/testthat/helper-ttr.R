source_all_R <- function() {
  # Source all R/ files to make internal helpers available to tests.
  # This avoids brittle per-file sourcing after refactors.
  base <- testthat::test_path("..", "..")
  rdir <- file.path(base, "R")
  files <- list.files(rdir, pattern = "\\.R$", full.names = TRUE)
  for (f in files) {
    sys.source(f, envir = topenv())
  }
  # Ensure the magrittr pipe is available for any sourced code using %>%.
  if (!exists("%>%", inherits = TRUE)) {
    if (requireNamespace("magrittr", quietly = TRUE)) {
      `%>%` <<- magrittr::`%>%`
    }
  }
  invisible(TRUE)
}

repo_root_for_tests <- function(start = testthat::test_path("..", "..")) {
  base <- normalizePath(start, winslash = "/", mustWork = TRUE)
  if (file.exists(file.path(base, "DESCRIPTION"))) {
    return(base)
  }

  if (exists("scenario_find_repo_root", mode = "function", inherits = TRUE)) {
    root <- tryCatch(scenario_find_repo_root(base), error = function(e) NULL)
    if (!is.null(root) && nzchar(root)) {
      return(root)
    }
  }

  base
}

find_check_root_for_tests <- function(start = getwd()) {
  dir <- normalizePath(start, winslash = "/", mustWork = TRUE)
  for (i in 0:10) {
    if (dir.exists(file.path(dir, "00_pkg_src"))) {
      return(dir)
    }
    parent <- dirname(dir)
    if (identical(parent, dir)) {
      break
    }
    dir <- parent
  }
  NA_character_
}

find_targets_script_for_tests <- function() {
  repo_root <- repo_root_for_tests()
  check_root <- find_check_root_for_tests()
  candidates <- c(
    file.path(repo_root, "_targets.R"),
    if (!is.na(check_root)) file.path(check_root, "00_pkg_src", "herbivoreTTR", "_targets.R") else NA_character_
  )
  candidates <- unique(candidates[!is.na(candidates) & nzchar(candidates)])
  script <- candidates[file.exists(candidates)][1]
  if (is.na(script) || !nzchar(script)) {
    stop("Unable to locate '_targets.R' for tests.")
  }
  normalizePath(script, winslash = "/", mustWork = TRUE)
}

# Automatically source all R files when tests start.
load_pkg_or_source <- function() {
  if (requireNamespace("pkgload", quietly = TRUE)) {
    # Try to load the package in dev mode; fall back to sourcing on error
    ok <- TRUE
    tryCatch({
      pkgload::load_all(".", quiet = TRUE, helpers = FALSE)
    }, error = function(e) {
      ok <<- FALSE
    })
    if (ok) return(invisible(TRUE))
  }
  source_all_R()
}

# Prefer dev-mode load; otherwise source R/ directly
load_pkg_or_source()
