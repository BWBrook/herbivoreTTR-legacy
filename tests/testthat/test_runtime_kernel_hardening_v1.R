test_that("minute diagnostics capture is opt-in and preserves trajectory outputs", {
  sim <- init_simulation()
  start_day <- CONSTANTS$SPIN_UP_LENGTH * nrow(sim$conditions) + 1L

  no_diag <- run_daily_herbivore_simulation(
    herbivore = sim$herbivore,
    plants = sim$plants,
    conditions = sim$conditions,
    day_of_simulation = start_day,
    minute_limit = 120L,
    seed = 42L,
    capture_diagnostics = FALSE
  )

  with_diag <- run_daily_herbivore_simulation(
    herbivore = sim$herbivore,
    plants = sim$plants,
    conditions = sim$conditions,
    day_of_simulation = start_day,
    minute_limit = 120L,
    seed = 42L,
    capture_diagnostics = TRUE
  )

  expect_null(no_diag$daily_record)
  expect_true(is.list(with_diag$daily_record))
  expect_equal(length(with_diag$daily_record), 120L)
  expect_true(any(vapply(with_diag$daily_record, Negate(is.null), logical(1L))))

  expect_equal(no_diag$daily_summary, with_diag$daily_summary)
  expect_equal(no_diag$herbivore, with_diag$herbivore)
  expect_equal(no_diag$plants, with_diag$plants)
})

test_that("run_herbivore_days does not mutate global pipe alias state", {
  had_pipe <- exists("%>%", envir = .GlobalEnv, inherits = FALSE)

  run_herbivore_days(days = 1L, minute_limit = 10L, seed = 99L)

  expect_identical(exists("%>%", envir = .GlobalEnv, inherits = FALSE), had_pipe)
})
