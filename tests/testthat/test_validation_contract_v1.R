test_that("observational adapters produce contract-compliant data", {
  veg <- utils::read.csv(
    validation_example_data_path("vegetation_timeseries_example.csv"),
    stringsAsFactors = FALSE
  )
  herb <- utils::read.csv(
    validation_example_data_path("herbivore_timeseries_example.csv"),
    stringsAsFactors = FALSE
  )

  obs_veg <- adapt_vegetation_timeseries_v1(veg)
  obs_herb <- adapt_herbivore_timeseries_v1(herb)
  combined <- rbind(obs_veg, obs_herb)

  expect_true(all(observational_contract_required_columns_v1() %in% names(combined)))
  validated <- validate_observational_data_v1(combined)
  expect_equal(nrow(validated), nrow(obs_veg) + nrow(obs_herb))
})

test_that("observational contract rejects unknown units", {
  data <- data.frame(
    site_id = "x",
    day_index = 1L,
    metric_name = "mean_daily_dmi",
    value = 100,
    unit = "unknown_unit",
    uncertainty = NA_real_,
    stringsAsFactors = FALSE
  )

  expect_error(
    validate_observational_data_v1(data),
    class = "herbivoreTTR_observation_unit_unknown"
  )
})

test_that("validation metrics return expected values on toy vectors", {
  obs <- c(1, 2, 3, 4)
  pred <- c(1, 3, 2, 5)

  rmse <- calc_rmse_v1(obs, pred)
  expect_true(is.finite(rmse))
  expect_gt(rmse, 0)

  nrmse <- calc_normalized_rmse_v1(obs, pred)
  expect_true(is.finite(nrmse))
  expect_gt(nrmse, 0)

  bias <- calc_mean_bias_v1(obs, pred)
  expect_equal(bias, mean(pred - obs))

  direction <- calc_directional_agreement_v1(obs, pred)
  expect_true(direction >= 0 && direction <= 1)
})

test_that("pilot validation benchmark writes artefacts", {
  skip_on_cran()

  out <- run_pilot_validation_benchmark_v1(base_dir = tempdir(), scenario_slug = "pilot_benchmark_test")

  expect_true(file.exists(out$observed_path))
  expect_true(file.exists(out$model_path))
  expect_true(file.exists(out$summary_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))
  expect_true(nrow(out$summary) >= 3L)
})
