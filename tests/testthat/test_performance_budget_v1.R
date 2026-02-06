test_that("small scenario remains within CI-friendly runtime budget", {
  skip_on_cran()

  scenario <- compile_scenario_yaml(scenario_contract_reference_path("canonical_smoke_v1"))
  scenario$runtime$days <- 2L
  scenario$runtime$minute_limit <- 30L
  scenario$outputs$scenario_slug <- "perf_budget_smoke_v1"

  elapsed <- as.numeric(system.time({
    run_scenario_v1(scenario = scenario, base_dir = tempdir())
  })[["elapsed"]])

  # Conservative gate to catch major regressions while limiting CI flakiness.
  expect_lt(elapsed, 30)
})
