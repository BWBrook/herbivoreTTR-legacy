test_that("domain sanity: coupled run keeps core state finite and non-negative", {
  sim <- init_simulation(temp_mode = "flat", veg_types = c(0, 1, 2), herbivore_mass = 5e5)
  day0 <- CONSTANTS$SPIN_UP_LENGTH * nrow(sim$conditions) + 1L

  res <- run_daily_herbivore_simulation(
    herbivore = sim$herbivore,
    plants = sim$plants,
    conditions = sim$conditions,
    day_of_simulation = day0,
    minute_limit = 60
  )

  plants <- res$plants
  herb <- res$herbivore
  tol <- CONSTANTS$TOLERANCE

  plant_nonneg_cols <- c("ms", "mr", "bleaf", "bstem", "bdef", "cs", "cr", "ns", "nr", "cd", "nd", "md")
  for (col in plant_nonneg_cols) {
    expect_true(col %in% names(plants))
    expect_true(all(is.finite(plants[[col]])))
    expect_true(all(plants[[col]] >= -tol))
  }

  expect_true(is.finite(herb$gut_capacity))
  expect_true(herb$gut_capacity > 0)

  expect_true(is.finite(herb$gut_content))
  expect_true(herb$gut_content >= -tol)
  expect_true(herb$gut_content <= herb$gut_capacity + tol)

  expect_true(is.finite(herb$distance_moved))
  expect_true(herb$distance_moved >= 0)

  # Balances can be negative, but must be finite.
  expect_true(is.finite(herb$energy_balance))
  expect_true(is.finite(herb$water_balance))

  # Digestion queues should be finite and non-negative (within tolerance).
  expect_true(is.list(herb$digestion))
  dig_ok <- vapply(
    herb$digestion,
    function(x) is.numeric(x) && all(is.finite(x)) && all(x >= -tol),
    logical(1)
  )
  expect_true(all(dig_ok))
})
