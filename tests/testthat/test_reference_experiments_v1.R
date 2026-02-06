test_that("reference scenario library builds curated index and artefacts", {
  skip_on_cran()

  out <- run_reference_scenario_library(base_dir = tempdir())

  expect_true(file.exists(out$index_path))
  expect_true(file.exists(out$index_md_path))
  expect_equal(nrow(out$metadata), 5L)
  expect_equal(length(out$runs), 5L)

  manifests <- vapply(out$runs, `[[`, character(1L), "manifest_path")
  expect_true(all(file.exists(manifests)))
})

test_that("experiment A writes paired artefacts with expected-direction table", {
  skip_on_cran()

  out <- run_experiment_a_presence_removal(base_dir = tempdir())

  expect_true(file.exists(out$summary_path))
  expect_true(file.exists(out$direction_path))
  expect_true(file.exists(out$plot_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))

  expect_true(all(is.finite(out$expected_direction$removal_minus_present)))
  expect_true(any(out$expected_direction$removal_minus_present != 0))
})

test_that("experiment B yields functional-type composition contrasts", {
  skip_on_cran()

  out <- run_experiment_b_functional_types(base_dir = tempdir())

  expect_true(file.exists(out$summary_path))
  expect_true(file.exists(out$plot_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))

  summary <- out$summary
  grazer_grass <- summary$grass_share[summary$strategy == "grazer"]
  browser_grass <- summary$grass_share[summary$strategy == "browser"]
  mixed_grass <- summary$grass_share[summary$strategy == "mixed"]

  expect_true(length(grazer_grass) == 1L)
  expect_true(length(browser_grass) == 1L)
  expect_true(length(mixed_grass) == 1L)
  expect_true(grazer_grass >= browser_grass)
  expect_true(mixed_grass >= min(grazer_grass, browser_grass) - 1e-8)
  expect_true(mixed_grass <= max(grazer_grass, browser_grass) + 1e-8)
})

test_that("experiment C aridity gradient outputs are finite and ordered", {
  skip_on_cran()

  out <- run_experiment_c_aridity_gradient(base_dir = tempdir())

  expect_true(file.exists(out$summary_path))
  expect_true(file.exists(out$plot_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))

  summary <- out$summary
  expect_identical(summary$gradient, c("low", "mid", "high"))
  numeric_cols <- vapply(summary, is.numeric, logical(1L))
  vals <- unlist(summary[, numeric_cols, drop = FALSE], use.names = FALSE)
  expect_true(all(is.finite(vals)))
})
