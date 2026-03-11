test_that("release v2 expected outputs point at the current v2 artefact set", {
  outputs <- release_expected_outputs_v2()

  expect_true(is.character(outputs))
  expect_false(anyDuplicated(outputs) > 0)
  expect_true(any(grepl("experiment_a_presence_removal_v2", outputs, fixed = TRUE)))
  expect_true(any(grepl("experiment_c_aridity_gradient_v2", outputs, fixed = TRUE)))
  expect_true(any(grepl("post_v1_scaling_v2/scaling_summary_v1.csv", outputs, fixed = TRUE)))
  expect_true(any(grepl("reports_v2/paper_pipeline_v2.html", outputs, fixed = TRUE)))
})

test_that("release v2 bundle doc references exist in a source checkout", {
  repo_root <- scenario_find_repo_root(getwd())
  skip_if(is.null(repo_root), "Repo root not detectable in this test context.")

  docs_to_copy <- release_bundle_docs_v2()
  expect_true(all(file.exists(file.path(repo_root, docs_to_copy))))
  expect_true(any(grepl("docs/contracts/observational_data_contract_v1.md", docs_to_copy, fixed = TRUE)))
})

test_that("release v2 bundle output dirs reference the v2 scaling artefacts", {
  output_dirs <- release_bundle_output_dirs_v2()

  expect_true(is.character(output_dirs))
  expect_false(anyDuplicated(output_dirs) > 0)
  expect_true(any(grepl("artefacts/benchmarks/post_v1_scaling_v2", output_dirs, fixed = TRUE)))
  expect_true(any(grepl("artefacts/reports_v2", output_dirs, fixed = TRUE)))
})

test_that("external repro v2 script pins the no-pak restore path and v2 scaling artefacts", {
  repo_root <- scenario_find_repo_root(getwd())
  skip_if(is.null(repo_root), "Repo root not detectable in this test context.")

  script_path <- file.path(repo_root, "scripts", "run_external_repro_check_v2.R")
  skip_if_not(file.exists(script_path), "v2 repro script not available in this test context.")

  script <- paste(readLines(script_path, warn = FALSE), collapse = "\n")
  expect_match(script, "RENV_CONFIG_PAK_ENABLED=FALSE", fixed = TRUE)
  expect_match(script, "scenario_slug = 'post_v1_scaling_v2'", fixed = TRUE)
  expect_match(script, "artefacts/benchmarks/post_v1_scaling_v2/scaling_summary_v1.csv", fixed = TRUE)
})
