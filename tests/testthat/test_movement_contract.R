test_that("herbivore_move wraps to nearest toroidal target path", {
  plants <- data.frame(
    plant_id = 1L,
    xcor = 1,
    ycor = 50,
    ms = 6,
    stringsAsFactors = FALSE
  )
  herb <- init_herbivore(mass = 5e5)
  herb$xcor <- 99
  herb$ycor <- 50
  herb$selected_plant_id <- 1L
  herb$fv_max <- 0.05 # 3 m/min
  herb$distance_moved <- 0

  moved <- herbivore_move(herb, plants, time_step_minutes = 1)

  expect_equal(moved$xcor, 1, tolerance = 1e-8)
  expect_equal(moved$ycor, 50, tolerance = 1e-8)
  expect_equal(moved$distance_moved, 2, tolerance = 1e-8)
})

test_that("herbivore_move respects maximum movement per minute", {
  plants <- data.frame(
    plant_id = 1L,
    xcor = 40,
    ycor = 10,
    ms = 6,
    stringsAsFactors = FALSE
  )
  herb <- init_herbivore(mass = 5e5)
  herb$xcor <- 10
  herb$ycor <- 10
  herb$selected_plant_id <- 1L
  herb$fv_max <- 0.05 # 3 m/min
  herb$distance_moved <- 0

  moved <- herbivore_move(herb, plants, time_step_minutes = 1)

  expect_equal(moved$distance_moved, 3, tolerance = 1e-8)
  expect_equal(moved$xcor, 13, tolerance = 1e-8)
  expect_equal(moved$ycor, 10, tolerance = 1e-8)
})

test_that("movement disruption probability modulates retarget frequency", {
  out <- run_movement_contract_scenario(seed = 13L, steps = 300L, base_dir = tempdir())
  disruption <- out$disruption_probe

  rate0 <- disruption$retarget_rate[disruption$disruption_prob == 0]
  rate1 <- disruption$retarget_rate[disruption$disruption_prob == 1]

  expect_equal(rate0, 0, tolerance = 1e-12)
  expect_gt(rate1, rate0 + 0.2)

  out_b <- run_movement_contract_scenario(seed = 13L, steps = 300L, base_dir = tempdir())
  expect_identical(out$disruption_probe, out_b$disruption_probe)
  expect_identical(out$movement_probe, out_b$movement_probe)
})

test_that("movement contract scenario writes expected artefact bundle", {
  out <- run_movement_contract_scenario(seed = 21L, steps = 250L, base_dir = tempdir())

  expect_true(file.exists(out$movement_probe_path))
  expect_true(file.exists(out$disruption_probe_path))
  expect_true(file.exists(out$summary_path))
  expect_true(file.exists(out$manifest_path))

  summary <- out$summary
  expect_equal(summary$value[summary$metric == "wrap_probe_lands_on_wrapped_target"], 1)
  expect_equal(summary$value[summary$metric == "step_limit_respects_max_distance"], 1)
  expect_gt(summary$value[summary$metric == "retarget_rate_prob1_minus_prob0"], 0.2)
})
