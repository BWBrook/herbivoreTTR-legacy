test_that("parity snapshots stay in sync with pipeline outputs", {
  skip_on_cran()
  withr::local_envvar(TARGETS_PROGRESS = "false")
  script <- tryCatch(find_targets_script_for_tests(), error = function(e) NA_character_)
  if (is.na(script) || !nzchar(script) || !file.exists(script)) {
    testthat::skip("Parity test requires a source checkout with '_targets.R'.")
  }

  outputs <- withr::with_dir(dirname(script), {
    targets::tar_make(
      names = c("plants_day1_csv", "herb_day1_csv"),
      callr_function = NULL,
      script = basename(script)
    )

    list(
      plants_path = normalizePath(targets::tar_read(plants_day1_csv), winslash = "/", mustWork = TRUE),
      herb_path = normalizePath(targets::tar_read(herb_day1_csv), winslash = "/", mustWork = TRUE)
    )
  })

  plants_path <- outputs$plants_path
  herb_path <- outputs$herb_path
  current_plants <- utils::read.csv(plants_path, sep = ";")
  current_herb <- utils::read.csv(herb_path, sep = ";")

  expect_true("SchemaVersion" %in% colnames(current_plants))
  expect_true("SchemaVersion" %in% colnames(current_herb))
  expect_true(all(current_plants$SchemaVersion == output_schema_version()))
  expect_true(all(current_herb$SchemaVersion == output_schema_version()))

  repo_root <- tryCatch(scenario_find_repo_root(), error = function(e) NULL)
  parity_candidates <- c(
    if (!is.null(repo_root)) file.path(repo_root, "inst", "extdata", "parity") else character(),
    system.file("extdata", "parity", package = "herbivoreTTR")
  )
  parity_candidates <- unique(parity_candidates[nzchar(parity_candidates)])
  parity_dir <- parity_candidates[dir.exists(parity_candidates)][1]
  if (is.na(parity_dir) || !nzchar(parity_dir) || !dir.exists(parity_dir)) {
    testthat::skip("Parity fixtures unavailable in source checkout or installed package.")
  }

  ref_plants_path <- file.path(parity_dir, "plants_day_sample.csv")
  ref_herb_path <- file.path(parity_dir, "herb_day_sample.csv")
  if (!file.exists(ref_plants_path) || !file.exists(ref_herb_path)) {
    testthat::skip("Parity fixture files unavailable in selected parity directory.")
  }

  ref_plants <- utils::read.csv(ref_plants_path)
  ref_herb <- utils::read.csv(ref_herb_path)

  current_plants_cmp <- head(current_plants, nrow(ref_plants))
  ref_plants_cmp <- ref_plants
  if ("RunID" %in% names(current_plants_cmp) && "RunID" %in% names(ref_plants_cmp)) {
    current_plants_cmp$RunID <- NULL
    ref_plants_cmp$RunID <- NULL
  }

  current_herb_cmp <- current_herb
  ref_herb_cmp <- ref_herb
  if ("RunID" %in% names(current_herb_cmp) && "RunID" %in% names(ref_herb_cmp)) {
    current_herb_cmp$RunID <- NULL
    ref_herb_cmp$RunID <- NULL
  }

  expect_equal(current_plants_cmp, ref_plants_cmp, tolerance = 1e-10)
  expect_equal(current_herb_cmp, ref_herb_cmp, tolerance = 1e-10)
})
