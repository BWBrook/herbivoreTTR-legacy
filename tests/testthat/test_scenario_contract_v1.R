test_that("reference scenario YAML compiles deterministically", {
  path <- scenario_contract_reference_path("canonical_smoke_v1")
  expect_true(file.exists(path))

  scenario_a <- compile_scenario_yaml(path)
  scenario_b <- compile_scenario_yaml(path)

  expect_identical(scenario_a, scenario_b)
  expect_identical(scenario_a$schema_version, scenario_contract_version())
  expect_equal(scenario_a$runtime$seed, 1L)
  expect_equal(scenario_a$runtime$minute_limit, 60L)
  expect_identical(scenario_a$outputs$scenario_slug, "smoke_v0")
  expect_identical(scenario_a$population$mode, "explicit_single")
  expect_equal(length(scenario_a$population$cohort), 1L)
})

test_that("scenario validator rejects missing required runtime fields", {
  path <- scenario_contract_reference_path("canonical_smoke_v1")
  raw <- yaml::read_yaml(path)
  raw$runtime$days <- NULL

  expect_error(
    validate_scenario_v1(raw),
    class = "herbivoreTTR_scenario_v1_days_invalid"
  )
})

test_that("scenario-to-parameters mapping provides canonical runtime values", {
  scenario <- compile_scenario_yaml(scenario_contract_reference_path("canonical_smoke_v1"))
  conditions <- init_conditions(mode = scenario$climate$mode)
  params <- scenario_to_canonical_parameters(scenario, conditions)

  expect_equal(params$veg_types, c(0L, 1L, 2L))
  expect_equal(params$herbivore_mass, 5e5)
  expect_equal(params$herb_type, 0L)
  expect_equal(params$herbivore_mrt, 24L)
  expect_identical(params$herbivore_foraging_mode, "nutrient_targeting")
  expect_equal(params$minute_limit, 60L)
  expect_equal(params$days, 7L)
  expect_equal(params$start_day, 1826L)
  expect_equal(params$seed, 1L)
  expect_identical(params$scenario_slug, "smoke_v0")
  expect_identical(params$climate_mode, "flat")
  expect_identical(params$temp_mode, "flat")
  expect_equal(params$condition_rows, nrow(conditions))
})

test_that("cohort scenarios require unique herbivore IDs", {
  scenario <- compile_scenario_yaml(scenario_contract_reference_path("cohort_smoke_v1"))
  bad <- scenario
  bad$population$cohort[[2]]$herbivore_id <- bad$population$cohort[[1]]$herbivore_id

  expect_error(
    validate_scenario_v1(bad),
    class = "herbivoreTTR_scenario_v1_herbivore_id_duplicate"
  )
})

test_that("implicit scenarios require stocking-density and visitation fields", {
  scenario <- compile_scenario_yaml(scenario_contract_reference_path("implicit_stocking_v1"))

  bad_density <- scenario
  bad_density$population$stocking_density_per_km2 <- -1
  expect_error(
    validate_scenario_v1(bad_density),
    class = "herbivoreTTR_scenario_v1_stocking_density_invalid"
  )

  bad_visit <- scenario
  bad_visit$population$visitation_rate_per_day <- -0.1
  expect_error(
    validate_scenario_v1(bad_visit),
    class = "herbivoreTTR_scenario_v1_visitation_rate_invalid"
  )
})
