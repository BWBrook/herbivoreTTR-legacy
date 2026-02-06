test_that("summarise_hourly_herbivore_record aggregates minute data", {
  set.seed(123)
  sim <- init_simulation()
  start_day <- CONSTANTS$SPIN_UP_LENGTH * nrow(sim$conditions) + 1L
  res <- run_daily_herbivore_simulation(
    herbivore = sim$herbivore,
    plants = sim$plants,
    conditions = sim$conditions,
    day_of_simulation = start_day,
    minute_limit = 120L
  )

  hourly <- summarise_hourly_herbivore_record(
    daily_record = res$daily_record,
    day_of_simulation = res$daily_summary$day_of_simulation
  )

  expect_equal(nrow(hourly), 2L)
  expect_equal(hourly$day_of_simulation, rep(start_day, 2L))
  expect_true(all(hourly$hour == c(1L, 2L)))
  expect_true(all(hourly$distance_moved_hour >= 0))
  expect_true(all(hourly$intake_total_hour >= 0))
  expect_equal(
    tail(hourly$intake_total_cumulative, 1),
    sum(hourly$intake_total_hour)
  )
})

test_that("summarise_hourly_herbivore_record handles empty/NULL-only records", {
  expect_equal(
    nrow(summarise_hourly_herbivore_record(list(), day_of_simulation = 1L)),
    0L
  )
  expect_equal(
    nrow(summarise_hourly_herbivore_record(list(NULL, NULL), day_of_simulation = 1L)),
    0L
  )
})

test_that("write_hourly_herbivore_log writes csv and validates input", {
  expect_error(
    write_hourly_herbivore_log(list(), day_of_simulation = 1L, base_dir = tempfile("hourly-empty-")),
    class = "herbivoreTTR_hourly_no_records"
  )

  set.seed(123)
  sim <- init_simulation()
  start_day <- CONSTANTS$SPIN_UP_LENGTH * nrow(sim$conditions) + 1L
  res <- run_daily_herbivore_simulation(
    herbivore = sim$herbivore,
    plants = sim$plants,
    conditions = sim$conditions,
    day_of_simulation = start_day,
    minute_limit = 60L
  )

  out_dir <- file.path(tempdir(), "hourly-write-test", as.character(Sys.getpid()))
  path <- write_hourly_herbivore_log(
    daily_record = res$daily_record,
    day_of_simulation = start_day,
    base_dir = out_dir,
    prefix = "hourly_test"
  )

  expect_true(file.exists(path))
  written <- read.csv(path, stringsAsFactors = FALSE)
  expect_true(nrow(written) >= 1L)
  expect_true(all(c("hour", "distance_moved_hour", "intake_total_hour") %in% names(written)))
})
