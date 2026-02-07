test_that("stability scenario builder defines expected variants", {
  scenarios <- build_stability_scenarios_v1(days = 20L, minute_limit = 60L)
  expect_equal(length(scenarios), 4L)
  expect_true(all(c("baseline", "high_aridity", "high_pressure", "low_access") %in% names(scenarios)))
})

test_that("long-horizon stability suite writes summary artefacts", {
  skip_on_cran()

  out <- run_long_horizon_stability_suite_v1(
    base_dir = tempdir(),
    seeds = 801:802,
    days = 10L,
    minute_limit = 60L
  )

  expect_true(file.exists(out$replicate_path))
  expect_true(file.exists(out$summary_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))
  expect_true(all(out$replicates$nan_inf_count >= 0))
})

test_that("scaling profile benchmark writes throughput artefacts", {
  skip_on_cran()

  out <- run_post_v1_scaling_profile(
    base_dir = tempdir(),
    scenario_slug = "scaling_test_v1",
    ensemble_seeds = 1:3,
    stability_days = 8L,
    stability_seeds = 1:2,
    enforce_regression_gate = FALSE
  )

  expect_true(file.exists(out$summary_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))
  expect_true(all(out$summary$elapsed_seconds > 0))
  expect_true(all(out$summary$throughput_herbivore_days_per_sec > 0))
})

test_that("scaling regression checker flags degraded workloads", {
  current <- data.frame(
    workload = c("a", "b"),
    elapsed_seconds = c(12, 10),
    stringsAsFactors = FALSE
  )
  baseline <- data.frame(
    workload = c("a", "b"),
    elapsed_seconds = c(10, 10),
    stringsAsFactors = FALSE
  )

  check <- check_scaling_regression_v1(current, baseline, threshold = 0.1)
  expect_equal(nrow(check), 2L)
  expect_false(all(check$passes))
})
