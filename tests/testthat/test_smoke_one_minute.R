test_that("one-minute herbivore simulation runs without error", {
  skip_on_cran()
  # Basic init
  sim <- init_simulation(temp_mode = "flat", veg_types = c(0, 1, 2), herbivore_mass = 5e5)
  expect_type(sim, "list")

  # Run a 1-minute simulation
  res <- run_daily_herbivore_simulation(
    herbivore = sim$herbivore,
    plants = sim$plants,
    conditions = sim$conditions,
    minute_limit = 1
  )

  expect_true(is.list(res))
  expect_true(all(c("herbivore", "plants", "daily_record", "daily_summary") %in% names(res)))
})
