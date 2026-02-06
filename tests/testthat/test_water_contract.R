test_that("herbivore_eat accrues forage water and reduces plant qshoot", {
  plants <- build_water_contract_plant(
    qshoot_to_shoot_ratio = 8,
    total_shoot_kg = 3,
    defence_fraction = 0.05
  )
  herb <- init_herbivore(mass = 5e5, herb_type = 0L)
  herb$selected_plant_id <- 1L
  herb$behaviour <- "EATING"
  herb$handling_time <- 0.2
  herb$gut_capacity <- max(herb$gut_capacity, 2e5)

  start_qshoot <- plants$qshoot
  start_forage_water <- herb$intake_water_forage
  out <- herbivore_eat(herbivore = herb, plants = plants)

  expect_gt(out$herbivore$intake_water_forage, start_forage_water)
  expect_lt(out$plants$qshoot, start_qshoot)
})

test_that("check_daily_water_balance records daily net and adds drinking trip", {
  herb <- init_herbivore(mass = 5e5)
  herb$distance_moved <- 10
  herb$daily_water_requirement <- 100
  herb$metabolic_water_day <- 20
  herb$intake_water_forage <- 10
  herb$water_balance <- 5

  out <- check_daily_water_balance(herb)

  expect_equal(out$intake_water_drinking, 70)
  expect_equal(out$distance_moved, 10 + CONSTANTS$DIST_TO_WATER)
  expect_equal(out$daily_net_water_balance, 0)
  expect_equal(out$water_balance, 5)
})

test_that("drinking imposes measurable energetic cost under deficit", {
  deficit <- simulate_water_balance_probe(
    probe_id = "water_deficit",
    qshoot_to_shoot_ratio = 0.5,
    minute_limit = 360L,
    seed = 123L
  )
  sufficient <- simulate_water_balance_probe(
    probe_id = "water_sufficient",
    qshoot_to_shoot_ratio = 12,
    minute_limit = 360L,
    seed = 123L
  )

  expect_equal(deficit$drinking_triggered, 1)
  expect_gt(deficit$water_drinking_g, 0)
  expect_gt(deficit$observed_drinking_energy_penalty_kj, 0)
  expect_equal(
    deficit$observed_drinking_energy_penalty_kj,
    deficit$expected_drinking_energy_penalty_kj,
    tolerance = 1e-6
  )

  expect_equal(sufficient$drinking_triggered, 0)
  expect_equal(sufficient$water_drinking_g, 0)
  expect_equal(sufficient$observed_drinking_energy_penalty_kj, 0, tolerance = 1e-8)
})

test_that("water contract scenario writes deterministic artefact bundle", {
  out_a <- run_water_contract_scenario(seed = 31L, minute_limit = 360L, base_dir = tempdir())
  out_b <- run_water_contract_scenario(seed = 31L, minute_limit = 360L, base_dir = tempdir())

  expect_true(file.exists(out_a$probe_path))
  expect_true(file.exists(out_a$summary_path))
  expect_true(file.exists(out_a$manifest_path))

  expect_identical(out_a$probe, out_b$probe)
  expect_identical(out_a$summary, out_b$summary)

  summary <- out_a$summary
  expect_equal(summary$value[summary$metric == "deficit_probe_drinking_triggered"], 1)
  expect_equal(summary$value[summary$metric == "sufficient_probe_no_drinking"], 1)
  expect_equal(summary$value[summary$metric == "deficit_probe_energy_penalty_matches_expected"], 1)
  expect_equal(summary$value[summary$metric == "forage_water_positive_for_both_probes"], 1)
  expect_equal(summary$value[summary$metric == "daily_water_balance_components_finite"], 1)
})
