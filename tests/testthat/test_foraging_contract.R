test_that("defence fraction reduces one-minute intake under matched conditions", {
  out <- run_foraging_contract_scenario(seed = 11L, base_dir = tempdir())
  probe <- out$probe

  low <- probe[probe$probe_id == "defence_low", , drop = FALSE]
  high <- probe[probe$probe_id == "defence_high", , drop = FALSE]

  expect_gt(low$observed_intake_kg, high$observed_intake_kg)
  expect_equal(
    low$observed_intake_kg,
    low$expected_limit_kg,
    tolerance = 1e-10
  )
})

test_that("capacity and residual-floor limits are enforced", {
  out <- run_foraging_contract_scenario(seed = 17L, base_dir = tempdir())
  probe <- out$probe
  summary <- out$summary

  expect_equal(
    summary$value[summary$metric == "capacity_probe_matches_expected_limit"],
    1
  )
  expect_equal(
    summary$value[summary$metric == "residual_probe_respects_min_shoot"],
    1
  )
  expect_equal(
    summary$value[summary$metric == "residual_probe_not_limited_by_ms_drift"],
    1
  )

  residual <- probe[probe$probe_id == "residual_floor_with_ms_drift", , drop = FALSE]
  expect_gte(residual$residual_shoot_kg, CONSTANTS$MIN_SHOOT - CONSTANTS$TOLERANCE)
})

test_that("foraging contract scenario writes deterministic artefact bundle", {
  out_a <- run_foraging_contract_scenario(seed = 29L, base_dir = tempdir())
  out_b <- run_foraging_contract_scenario(seed = 29L, base_dir = tempdir())

  expect_true(file.exists(out_a$probe_path))
  expect_true(file.exists(out_a$summary_path))
  expect_true(file.exists(out_a$manifest_path))

  expect_identical(out_a$probe, out_b$probe)
  expect_identical(out_a$summary, out_b$summary)
})

test_that("herbivore_eat records defence intake and honors shoot floor with ms drift", {
  plants <- build_foraging_contract_plant(
    total_shoot_kg = CONSTANTS$MIN_SHOOT + 4e-4,
    defence_fraction = 0.1,
    ms_override = CONSTANTS$MIN_SHOOT + 0.25
  )

  herb <- init_herbivore(mass = 5e5)
  herb$selected_plant_id <- 1L
  herb$behaviour <- "EATING"
  herb$gut_capacity <- 1e6
  herb$gut_content <- 0
  herb$handling_time <- 0.1

  out <- herbivore_eat(herbivore = herb, plants = plants)

  residual <- out$plants$bleaf + out$plants$bstem + out$plants$bdef
  expect_gte(residual, CONSTANTS$MIN_SHOOT - CONSTANTS$TOLERANCE)
  expect_gt(out$herbivore$intake_defence_day, 0)
})
