test_that("transport kernel performance sentinel catches severe regressions", {
  skip_on_cran()

  set.seed(4242)
  plants <- init_plants(veg_types = rep(c(0L, 1L, 2L), length.out = 300L))
  conditions <- init_conditions(
    days_in_year = 60L,
    mode = "seasonal",
    mean_temp = 19,
    amplitude = 6
  )

  iterations <- 5L
  elapsed <- as.numeric(system.time({
    for (i in seq_len(iterations)) {
      transport_resistance(plants, conditions, day_index = 7L)
    }
  })[["elapsed"]]) / iterations

  # Broad threshold to reduce CI flakiness while still catching severe slowdowns.
  expect_lt(elapsed, 3)
})
