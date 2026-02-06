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
    stop("Unable to locate '_targets.R' for canonical bundle tests.")
  }
  normalizePath(script, winslash = "/", mustWork = TRUE)
}

test_that("canonical smoke bundle target writes required artefacts", {
  skip_on_cran()
  withr::local_envvar(TARGETS_PROGRESS = "false")
  script <- tryCatch(find_targets_script(), error = function(e) NA_character_)
  if (is.na(script) || !nzchar(script) || !file.exists(script)) {
    testthat::skip("Canonical bundle tests require a source checkout with '_targets.R'.")
  }

  bundle_files <- withr::with_dir(dirname(script), {
    targets::tar_make(
      names = "canonical_bundle_files",
      callr_function = NULL,
      script = basename(script)
    )
    targets::tar_read(canonical_bundle_files)
  })
  expect_true(all(file.exists(bundle_files)))

  run_dir <- file.path(dirname(script), "artefacts", "canonical_runs", "smoke_v0")
  required_files <- c(
    "run_manifest.json",
    "plants_day1826.csv",
    "herb_day1826.csv",
    "plants_day1832.csv",
    "herb_day1832.csv"
  )
  expect_true(all(file.exists(file.path(run_dir, required_files))))
})

test_that("canonical run manifest references valid output files", {
  skip_on_cran()
  withr::local_envvar(TARGETS_PROGRESS = "false")
  script <- tryCatch(find_targets_script(), error = function(e) NA_character_)
  if (is.na(script) || !nzchar(script) || !file.exists(script)) {
    testthat::skip("Canonical bundle tests require a source checkout with '_targets.R'.")
  }

  manifest_path <- withr::with_dir(dirname(script), {
    targets::tar_make(
      names = "canonical_bundle_files",
      callr_function = NULL,
      script = basename(script)
    )
    file.path("artefacts", "canonical_runs", "smoke_v0", "run_manifest.json")
  })
  manifest_path <- file.path(dirname(script), manifest_path)
  manifest <- jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)

  expect_identical(manifest$schema_version, output_schema_version())
  expect_identical(manifest$scenario_slug, "smoke_v0")
  expect_identical(manifest$seed, 1L)
  expect_true(nzchar(manifest$scenario_parameters_hash))
  expect_true(nzchar(manifest$git_sha))
  expect_true(nzchar(manifest$package_version))

  output_paths <- unlist(manifest$outputs, use.names = FALSE)
  expect_true(length(output_paths) >= 4L)
  expect_true(all(file.exists(file.path(dirname(script), output_paths))))
})
