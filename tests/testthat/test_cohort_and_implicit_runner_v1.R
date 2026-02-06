test_that("cohort scenario initialises deterministic unique IDs", {
  scenario <- compile_scenario_yaml(scenario_contract_reference_path("cohort_smoke_v1"))
  cohort_a <- init_cohort_from_scenario(scenario)
  cohort_b <- init_cohort_from_scenario(scenario)

  ids_a <- vapply(cohort_a, `[[`, character(1), "herbivore_id")
  ids_b <- vapply(cohort_b, `[[`, character(1), "herbivore_id")

  expect_identical(ids_a, ids_b)
  expect_identical(anyDuplicated(ids_a), 0L)
  expect_equal(length(ids_a), 3L)
})

test_that("daily cohort runner is deterministic under fixed seed", {
  scenario <- compile_scenario_yaml(scenario_contract_reference_path("cohort_smoke_v1"))
  conditions <- build_conditions_from_scenario(scenario)
  plants <- init_plants(veg_types = scenario$plot$veg_types)
  cohort <- init_cohort_from_scenario(scenario)

  out_a <- run_daily_herbivore_cohort(
    herbivores = cohort,
    plants = plants,
    conditions = conditions,
    day_of_simulation = scenario$runtime$start_day,
    minute_limit = 30L,
    seed = 99L
  )
  out_b <- run_daily_herbivore_cohort(
    herbivores = cohort,
    plants = plants,
    conditions = conditions,
    day_of_simulation = scenario$runtime$start_day,
    minute_limit = 30L,
    seed = 99L
  )

  expect_identical(out_a$daily_summary, out_b$daily_summary)
  expect_identical(out_a$plants, out_b$plants)
})

test_that("run_scenario_v1 explicit cohort writes per-herbivore daily outputs", {
  out <- withr::with_seed(123L, {
    run_scenario_v1(
      scenario = scenario_contract_reference_path("cohort_smoke_v1"),
      base_dir = tempdir()
    )
  })

  expect_true(file.exists(out$herbivore_daily_path))
  expect_true(file.exists(out$structure_fuel_path))
  expect_true(file.exists(out$manifest_path))

  herb <- utils::read.csv(out$herbivore_daily_path, stringsAsFactors = FALSE)
  expect_true("HerbivoreID" %in% names(herb))
  expect_true("RunID" %in% names(herb))
  expect_true(length(unique(herb$HerbivoreID)) >= 3L)
  expect_true(all(herb$PopulationMode == "explicit_cohort"))

  struc <- utils::read.csv(out$structure_fuel_path, stringsAsFactors = FALSE)
  expect_true(all(is.finite(struc$total_shoot_biomass_kg)))
  expect_true(all(struc$total_shoot_biomass_kg >= 0))
})

test_that("implicit mode emits explicit visitation/intensity metadata", {
  scenario <- compile_scenario_yaml(scenario_contract_reference_path("implicit_stocking_v1"))
  visitation <- derive_implicit_visitation(scenario)
  expect_true(is.finite(visitation$effective_visits_per_day))
  expect_true(visitation$effective_visits_per_day >= 0)

  out <- withr::with_seed(123L, {
    run_scenario_v1(
      scenario = scenario,
      base_dir = tempdir()
    )
  })

  herb <- utils::read.csv(out$herbivore_daily_path, stringsAsFactors = FALSE)
  expect_true(all(herb$PopulationMode == "implicit_representative"))
  expect_true("effective_visits_per_day" %in% names(herb))
  expect_true(all(is.finite(herb$effective_visits_per_day)))
  expect_true(all(herb$effective_visits_per_day >= 0))

  if (!is.null(out$implicit_visit_path)) {
    expect_true(file.exists(out$implicit_visit_path))
  }
})
