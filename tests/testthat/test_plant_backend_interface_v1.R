test_that("plant backend resolver validates interface", {
  backend <- resolve_plant_backend("internal_ttr")
  expect_identical(backend$name, "internal_ttr")
  expect_true(is.function(backend$step_day))
  expect_true(is.function(backend$apply_herbivory))

  expect_error(
    resolve_plant_backend("unknown_backend"),
    class = "herbivoreTTR_backend_unknown"
  )

  expect_error(
    resolve_plant_backend(list(name = "bad")),
    class = "herbivoreTTR_backend_missing_members"
  )
})

test_that("run_daily_herbivore_simulation supports backend swapping without drift", {
  sim <- init_simulation(temp_mode = "flat", veg_types = c(0, 1, 2), herbivore_mass = 5e5)
  day <- CONSTANTS$SPIN_UP_LENGTH * nrow(sim$conditions) + 1L

  out_default <- run_daily_herbivore_simulation(
    herbivore = sim$herbivore,
    plants = sim$plants,
    conditions = sim$conditions,
    day_of_simulation = day,
    minute_limit = 30,
    seed = 123,
    plant_backend = "internal_ttr"
  )

  backend_obj <- resolve_plant_backend("internal_ttr")
  out_object <- run_daily_herbivore_simulation(
    herbivore = sim$herbivore,
    plants = sim$plants,
    conditions = sim$conditions,
    day_of_simulation = day,
    minute_limit = 30,
    seed = 123,
    plant_backend = backend_obj
  )

  expect_identical(out_default$daily_summary, out_object$daily_summary)
  expect_identical(out_default$plants, out_object$plants)
})
