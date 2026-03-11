test_that("reference scenario YAML compiles deterministically under v2", {
  path <- scenario_contract_reference_path("canonical_smoke_v1")
  expect_true(file.exists(path))

  scenario_a <- compile_scenario_yaml_v2(path)
  scenario_b <- compile_scenario_yaml_v2(path)

  expect_identical(scenario_a, scenario_b)
  expect_identical(scenario_a$schema_version, scenario_contract_version_v2())
  expect_equal(scenario_a$runtime$seed, 1L)
  expect_equal(scenario_a$runtime$minute_limit, 60L)
  expect_identical(scenario_a$outputs$scenario_slug, "smoke_v0")
  expect_identical(scenario_a$population$mode, "explicit_single")
  expect_equal(length(scenario_a$population$cohort), 1L)
})

test_that("scenario v2 validator rejects missing required runtime fields", {
  path <- scenario_contract_reference_path("canonical_smoke_v1")
  raw <- yaml::read_yaml(path)
  raw$runtime$days <- NULL

  expect_error(
    validate_scenario_v2(raw),
    class = "herbivoreTTR_scenario_v2_days_invalid"
  )
})

test_that("scenario-to-parameters mapping provides canonical runtime values", {
  scenario <- compile_scenario_yaml_v2(scenario_contract_reference_path("canonical_smoke_v1"))
  conditions <- init_conditions(mode = scenario$climate$mode)
  params <- scenario_to_canonical_parameters_v2(scenario, conditions)

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
  scenario <- compile_scenario_yaml_v2(scenario_contract_reference_path("cohort_smoke_v1"))
  bad <- scenario
  bad$population$cohort[[2]]$herbivore_id <- bad$population$cohort[[1]]$herbivore_id

  expect_error(
    validate_scenario_v2(bad),
    class = "herbivoreTTR_scenario_v2_herbivore_id_duplicate"
  )
})

test_that("implicit pressure scenarios require density, visitation, and template herbivore", {
  scenario <- compile_scenario_yaml_v2(scenario_contract_reference_path("implicit_stocking_v1"))

  bad_density <- scenario
  bad_density$population$stocking_density_per_km2 <- -1
  expect_error(
    validate_scenario_v2(bad_density),
    class = "herbivoreTTR_scenario_v2_stocking_density_invalid"
  )

  bad_visit <- scenario
  bad_visit$population$visitation_rate_per_day <- -0.1
  expect_error(
    validate_scenario_v2(bad_visit),
    class = "herbivoreTTR_scenario_v2_visitation_rate_invalid"
  )

  bad_template <- scenario
  bad_template$population$template_herbivore <- NULL
  expect_error(
    validate_scenario_v2(bad_template),
    class = "herbivoreTTR_scenario_v1_herbivore_spec_invalid"
  )
})

test_that("paired reference scenarios compile with enforced parity under v2", {
  present <- compile_scenario_yaml_v2(scenario_contract_reference_path("reference_presence_present_v1"))
  removed <- compile_scenario_yaml_v2(scenario_contract_reference_path("reference_presence_removed_v1"))

  expect_true(isTRUE(present$contrast$paired_contrast_required))
  expect_true(isTRUE(removed$contrast$paired_contrast_required))
  expect_equal(present$runtime$seed, removed$runtime$seed)
  expect_true(isTRUE(validate_paired_contrast_parity_v2(present, removed)))
})

test_that("paired contrast parity validator rejects rule mismatch", {
  present <- compile_scenario_yaml_v2(scenario_contract_reference_path("reference_presence_present_v1"))
  removed <- compile_scenario_yaml_v2(scenario_contract_reference_path("reference_presence_removed_v1"), enforce_pairing = FALSE)
  removed$runtime$seed <- removed$runtime$seed + 1L

  expect_error(
    validate_paired_contrast_parity_v2(present, removed),
    class = "herbivoreTTR_scenario_v2_pair_rule_mismatch"
  )
})

test_that("legacy v1 implicit scenarios migrate cleanly to implicit pressure", {
  legacy <- list(
    schema_version = "1.0.0",
    scenario_id = "legacy_implicit",
    runtime = list(seed = 12, minute_limit = 60, days = 5, start_day = 1826),
    plot = list(veg_types = c(0L, 1L, 2L), plot_size_m2 = 10000, plants_in_x = 20L, plants_in_y = 20L),
    climate = list(mode = "flat", mean_temp = 15, amplitude = 10, sw_scale = 1, n_scale = 1),
    population = list(
      mode = "implicit_representative",
      representative = list(
        herbivore_id = "legacy_rep",
        mass_g = 500000,
        herb_type = 0L,
        MRT_hours = 24L,
        foraging_mode = "nutrient_targeting"
      ),
      stocking_density_per_km2 = 60,
      visitation_rate_per_day = 0.4
    ),
    outputs = list(scenario_slug = "legacy_implicit")
  )

  migrated <- migrate_scenario_v1_to_v2(legacy)
  expect_identical(migrated$schema_version, "2.0.0")
  expect_identical(migrated$population$mode, "implicit_pressure")
  expect_true(is.null(migrated$population$template_herbivore) == FALSE)
  expect_true(length(migrated$population$cohort) == 0L)

  validated <- validate_scenario_v2(legacy)
  expect_identical(validated$population$mode, "implicit_pressure")
  expect_identical(validated$population$template_herbivore$herbivore_id, "legacy_rep")
})

test_that("scenario feedback config validates and normalizes defaults under v2", {
  scenario <- compile_scenario_yaml_v2(scenario_contract_reference_path("canonical_smoke_v1"))

  expect_true(isTRUE(scenario$feedback$enabled))
  expect_true(is.finite(scenario$feedback$initial_bci))

  bad <- scenario
  bad$feedback$initial_bci <- 2
  expect_error(
    validate_scenario_v2(bad),
    class = "herbivoreTTR_scenario_v2_feedback_initial_bci_invalid"
  )
})
