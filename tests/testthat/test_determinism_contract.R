test_that("run_herbivore_days is deterministic with fixed seed", {
  run_a <- run_herbivore_days(days = 3L, minute_limit = 60, seed = 101L)
  run_b <- run_herbivore_days(days = 3L, minute_limit = 60, seed = 101L)

  expect_identical(run_a$daily_summary, run_b$daily_summary)
  expect_identical(run_a$start_day, run_b$start_day)
  expect_identical(run_a$herbivore$selected_plant_id, run_b$herbivore$selected_plant_id)
  expect_equal(run_a$herbivore$xcor, run_b$herbivore$xcor)
  expect_equal(run_a$herbivore$ycor, run_b$herbivore$ycor)
})

test_that("seeded runs restore caller RNG state", {
  set.seed(123)
  first_draw <- runif(1)
  expected_next <- runif(1)

  set.seed(123)
  first_draw_replay <- runif(1)
  expect_identical(first_draw_replay, first_draw)

  run_herbivore_days(days = 1L, minute_limit = 10, seed = 99L)
  observed_next <- runif(1)
  expect_identical(observed_next, expected_next)
})

build_smoke_bundle_once <- function(root_dir, seed) {
  sim <- with_optional_seed(
    seed,
    init_simulation(temp_mode = "flat", veg_types = c(0, 1, 2), herbivore_mass = 5e5)
  )
  start_day <- CONSTANTS$SPIN_UP_LENGTH * nrow(sim$conditions) + 1L

  day1 <- run_daily_herbivore_simulation(
    herbivore = sim$herbivore,
    plants = sim$plants,
    conditions = sim$conditions,
    day_of_simulation = start_day,
    minute_limit = 60,
    seed = seed
  )
  day7 <- run_herbivore_days(
    days = 7L,
    minute_limit = 60,
    temp_mode = "flat",
    veg_types = c(0, 1, 2),
    herbivore_mass = 5e5,
    seed = seed
  )

  output_dir <- file.path(root_dir, "outputs")
  plants_day1 <- write_plants_snapshot_target(day1$plants, day = start_day, base_dir = output_dir)
  herb_day1 <- write_herbivore_snapshot_target(day1$herbivore, day = start_day, base_dir = output_dir)
  plants_day7 <- write_plants_snapshot_target(day7$plants, day = start_day + 6L, base_dir = output_dir)
  herb_day7 <- write_herbivore_snapshot_target(day7$herbivore, day = start_day + 6L, base_dir = output_dir)

  run_base <- file.path(root_dir, "artefacts", "canonical_runs")
  write_canonical_run_bundle(
    output_files = c(
      plants_day1 = plants_day1,
      herb_day1 = herb_day1,
      plants_day7 = plants_day7,
      herb_day7 = herb_day7
    ),
    scenario_slug = "smoke_v0",
    seed = seed,
    scenario_parameters = list(
      temp_mode = "flat",
      veg_types = c(0, 1, 2),
      herbivore_mass = 5e5,
      minute_limit = 60,
      start_day = start_day,
      days = 7L
    ),
    base_dir = run_base
  )

  file.path(run_base, "smoke_v0")
}

test_that("canonical smoke artefacts are reproducible under fixed seed", {
  dir_a <- tempfile("determinism-a-")
  dir_b <- tempfile("determinism-b-")
  dir.create(dir_a, recursive = TRUE, showWarnings = FALSE)
  dir.create(dir_b, recursive = TRUE, showWarnings = FALSE)
  withr::defer(unlink(c(dir_a, dir_b), recursive = TRUE, force = TRUE))

  run_dir_a <- build_smoke_bundle_once(dir_a, seed = 1L)
  run_dir_b <- build_smoke_bundle_once(dir_b, seed = 1L)

  csv_files <- c(
    "plants_day1826.csv",
    "herb_day1826.csv",
    "plants_day1832.csv",
    "herb_day1832.csv"
  )
  for (file_name in csv_files) {
    expect_identical(
      readLines(file.path(run_dir_a, file_name), warn = FALSE),
      readLines(file.path(run_dir_b, file_name), warn = FALSE)
    )
  }

  manifest_a <- jsonlite::fromJSON(file.path(run_dir_a, "run_manifest.json"), simplifyVector = FALSE)
  manifest_b <- jsonlite::fromJSON(file.path(run_dir_b, "run_manifest.json"), simplifyVector = FALSE)
  manifest_a$created_utc <- NULL
  manifest_b$created_utc <- NULL
  expect_identical(manifest_a, manifest_b)
})
