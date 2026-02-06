test_that("pipeline manifest lists expected targets and file formats", {
  find_targets_script <- function() {
    find_up <- function(filename, start = getwd()) {
      dir <- normalizePath(start, winslash = "/", mustWork = TRUE)
      for (i in 0:10) {
        candidate <- file.path(dir, filename)
        if (file.exists(candidate)) return(candidate)
        parent <- dirname(dir)
        if (identical(parent, dir)) break
        dir <- parent
      }
      NA_character_
    }

    find_check_root <- function(start = getwd()) {
      dir <- normalizePath(start, winslash = "/", mustWork = TRUE)
      for (i in 0:10) {
        if (dir.exists(file.path(dir, "00_pkg_src"))) return(dir)
        parent <- dirname(dir)
        if (identical(parent, dir)) break
        dir <- parent
      }
      NA_character_
    }

    candidates <- c(
      find_up("_targets.R"),
      file.path(find_check_root(), "00_pkg_src", "herbivoreTTR", "_targets.R")
    )
    candidates <- unique(candidates[!is.na(candidates) & nzchar(candidates)])
    script <- candidates[file.exists(candidates)][1]
    if (is.na(script) || !nzchar(script)) {
      stop("Unable to locate '_targets.R' for pipeline manifest test.")
    }
    normalizePath(script, winslash = "/", mustWork = TRUE)
  }

  script <- tryCatch(find_targets_script(), error = function(e) NA_character_)
  if (is.na(script) || !nzchar(script) || !file.exists(script)) {
    testthat::skip("Pipeline manifest test requires a source checkout with '_targets.R'.")
  }
  manifest <- withr::with_dir(dirname(script), {
    targets::tar_manifest(
      fields = c("name", "format"),
      callr_function = NULL,
    script = basename(script)
  )
})
  expect_true(all(c(
    "canonical_seed",
    "canonical_scenario_slug",
    "canonical_scenario_parameters",
    "conditions",
    "plants0",
    "herb0",
    "day_after_spinup",
    "sim_day1",
    "plants_day1_csv",
    "herb_day1_csv",
    "sim_day7",
    "plants_day7_csv",
    "herb_day7_csv",
    "canonical_bundle_files"
  ) %in% manifest$name))

  file_targets <- manifest[
    manifest$name %in% c("plants_day1_csv", "herb_day1_csv", "plants_day7_csv", "herb_day7_csv", "canonical_bundle_files"),
  ]
  expect_true(all(file_targets$format == "file"))
})
