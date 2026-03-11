test_that("pipeline manifest lists expected targets and file formats", {
  script <- tryCatch(find_targets_script_for_tests(), error = function(e) NA_character_)
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
    "canonical_bundle_files",
    "day_in_life_bundle_files",
    "cohort_bundle_files",
    "implicit_bundle_files",
    "reference_library_bundle_files",
    "experiment_a_bundle_files",
    "experiment_b_bundle_files",
    "experiment_c_bundle_files",
    "benchmark_appendix_bundle_files",
    "performance_budget_bundle_files",
    "paper_pipeline_bundle_files"
  ) %in% manifest$name))

  file_targets <- manifest[
    manifest$name %in% c(
      "canonical_bundle_files",
      "day_in_life_bundle_files",
      "cohort_bundle_files",
      "implicit_bundle_files",
      "reference_library_bundle_files",
      "experiment_a_bundle_files",
      "experiment_b_bundle_files",
      "experiment_c_bundle_files",
      "benchmark_appendix_bundle_files",
      "performance_budget_bundle_files",
      "paper_pipeline_bundle_files"
    ),
  ]
  expect_true(all(file_targets$format == "file"))
})
