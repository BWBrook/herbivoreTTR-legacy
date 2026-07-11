source_all_R <- function(
    base = repo_root_for_tests(),
    envir = environment(source_all_R)) {
  # Source all R/ files to make internal helpers available to tests.
  # This avoids brittle per-file sourcing after refactors.
  rdir <- file.path(base, "R")
  files <- list.files(rdir, pattern = "\\.R$", full.names = TRUE)
  for (f in files) {
    sys.source(f, envir = envir)
  }
  # Ensure the magrittr pipe is available for any sourced code using %>%.
  if (!exists("%>%", envir = envir, inherits = TRUE)) {
    if (requireNamespace("magrittr", quietly = TRUE)) {
      assign("%>%", magrittr::`%>%`, envir = envir)
    }
  }
  invisible(TRUE)
}

repo_root_for_tests <- function(start = testthat::test_path("..", "..")) {
  base <- normalizePath(start, winslash = "/", mustWork = TRUE)
  check_source_root <- find_check_source_root_for_tests(base)
  if (!is.na(check_source_root)) {
    return(check_source_root)
  }

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

find_check_source_root_for_tests <- function(start = getwd()) {
  check_root <- find_check_root_for_tests(start)
  if (is.na(check_root)) {
    return(NA_character_)
  }

  source_root <- file.path(check_root, "00_pkg_src", "herbivoreTTR")
  if (!file.exists(file.path(source_root, "DESCRIPTION")) ||
      !dir.exists(file.path(source_root, "R"))) {
    return(NA_character_)
  }

  normalizePath(source_root, winslash = "/", mustWork = TRUE)
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

find_source_makefile_for_tests <- function(
    repo_root = repo_root_for_tests(),
    check_root = find_check_root_for_tests()) {
  candidates <- c(
    if (!is.na(check_root)) {
      file.path(check_root, "00_pkg_src", "herbivoreTTR", "Makefile")
    } else {
      NA_character_
    },
    file.path(repo_root, "Makefile")
  )
  candidates <- unique(candidates[!is.na(candidates) & nzchar(candidates)])
  makefile <- candidates[file.exists(candidates)][1]
  if (is.na(makefile) || !nzchar(makefile)) {
    return(NA_character_)
  }
  normalizePath(makefile, winslash = "/", mustWork = TRUE)
}

# Automatically source all R files when tests start.
load_pkg_or_source <- function(base = repo_root_for_tests()) {
  if (!is.na(find_check_source_root_for_tests(base))) {
    source_all_R(base = base, envir = environment(load_pkg_or_source))
    return(invisible(TRUE))
  }

  if (requireNamespace("pkgload", quietly = TRUE)) {
    # Try to load the package in dev mode; fall back to sourcing on error
    ok <- TRUE
    tryCatch({
      pkgload::load_all(base, quiet = TRUE, helpers = FALSE)
    }, error = function(e) {
      ok <<- FALSE
    })
    if (ok) return(invisible(TRUE))
  }
  source_all_R(base = base, envir = topenv())
}

localize_check_source_root_for_tests <- function(
    start = getwd(),
    .local_envir = testthat::teardown_env()) {
  source_root <- find_check_source_root_for_tests(start)
  if (is.na(source_root)) {
    return(invisible(FALSE))
  }

  testthat::local_mocked_bindings(
    scenario_find_repo_root = function(start = getwd()) source_root,
    .package = "herbivoreTTR",
    .env = .local_envir
  )
  invisible(TRUE)
}

# Prefer dev-mode load; otherwise source R/ directly
test_repo_root <- repo_root_for_tests()
load_pkg_or_source(base = test_repo_root)
localize_check_source_root_for_tests()
