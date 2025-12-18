## Package bootstrap helpers (no side-effects on source)
##
## This file declares helper functions for interactive workflows.
## It MUST NOT install or attach packages at top-level to keep the
## package load deterministic and offline-friendly.

#' Ensure required packages are installed (interactive use)
#' @param pkgs Character vector of package names.
#' @return Invisibly TRUE. No-op if pkgs is NULL/empty.
ensure_packages_installed <- function(pkgs = NULL) {
  if (is.null(pkgs) || length(pkgs) == 0) return(invisible(TRUE))
  pkgs <- unique(pkgs)
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    utils::install.packages(missing)
  }
  invisible(TRUE)
}

#' Ensure common analysis packages are available (interactive use)
#'
#' This helper silently checks that packages are installed and loads their
#' namespaces (without attaching them to the search path). Users should access
#' functions via `pkg::fun()` or `import::from()`.
#'
#' @param pkgs Character vector of package names. Defaults to a curated set used
#'   during development.
#' @return Invisibly returns the vector of packages whose namespaces were loaded.
lib <- function(pkgs = c(
                      "targets", "tarchetypes", "dplyr", "readr", "purrr", "tidyr",
                      "sf", "terra", "arrow", "duckdb", "config", "qs", "lgr", "progressr"
                    )) {
  if (is.null(pkgs) || length(pkgs) == 0) return(invisible(character()))
  ensure_packages_installed(pkgs)
  loaded <- vapply(
    pkgs,
    function(pkg) {
      requireNamespace(pkg, quietly = TRUE)
      pkg
    },
    character(1)
  )
  invisible(loaded)
}

#' Bootstrap renv for this project (interactive use)
#' @param action One of "restore" (default) or "init".
#' @param lockfile Path to lockfile; used for restore if present.
#' @param bare Logical; if TRUE, creates a bare project when initialising.
#' @return Invisibly TRUE.
bootstrap_renv <- function(action = c("restore", "init"), lockfile = "renv.lock", bare = TRUE) {
  action <- match.arg(action)
  if (!requireNamespace("renv", quietly = TRUE)) utils::install.packages("renv")
  if (action == "restore" && file.exists(lockfile)) {
    restore <- getExportedValue("renv", "restore")
    restore(lockfile = lockfile, prompt = FALSE)
  } else if (action == "init") {
    init <- getExportedValue("renv", "init")
    init(bare = bare)
  } else {
    message("Lockfile not found; call bootstrap_renv('init') to initialise.")
  }
  invisible(TRUE)
}
