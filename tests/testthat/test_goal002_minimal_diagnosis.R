goal002_profile_path <- file.path(
  repo_root_for_tests(),
  "inst",
  "extdata",
  "scenarios",
  "goal002_minimal_coupled_v1.yaml"
)
source(file.path(repo_root_for_tests(), "scripts", "run_goal002_minimal_diagnosis.R"), local = TRUE)

test_that("Goal 002 profile is one explicit fixed-seed constant-forcing system", {
  profile <- read_goal002_profile(goal002_profile_path)
  validated <- validate_goal002_profile(profile)

  expect_identical(validated$runtime$seed, 2002L)
  expect_identical(validated$runtime$days, 120L)
  expect_identical(validated$runtime$start_day, 6L)
  expect_identical(validated$runtime$minute_limit, 720L)
  expect_identical(validated$runtime$plant_backend, "internal_ttr")
  expect_identical(validated$population$herbivore_count, 1L)
  expect_identical(validated$forage$forage_type_count, 1L)
  expect_identical(validated$forage$veg_types, 0L)
  expect_identical(validated$population$herbivore$mass_g, 50000L)
  expect_false(validated$population$herbivore$empirical_parameterisation)
  expect_false(validated$forage$empirical_parameterisation)
  expect_identical(validated$initial_plant_state$plant_id, 1L)
  expect_equal(validated$initial_plant_state$ms, 50)

  forcing <- resolved_goal002_forcing(validated)
  expect_identical(names(forcing), c("temperature", "soil_water", "soil_nitrogen"))
  expect_identical(forcing$temperature, 25)
  expect_identical(forcing$soil_water, 0.5)
  expect_identical(forcing$soil_nitrogen, 0.5)
  expect_true(all(vapply(forcing, function(x) length(unique(x)) == 1L, logical(1))))
})

test_that("Goal 002 profile records the complete resolved initial state contract", {
  profile <- validate_goal002_profile(read_goal002_profile(goal002_profile_path))
  initial <- resolve_goal002_initial_state(profile)
  serialized <- goal002_initial_state_json(profile, initial$herbivore_state, initial$plants_state)
  json_path <- tempfile(fileext = ".json")
  withr::defer(unlink(json_path, force = TRUE))
  goal002_write_json(serialized, json_path)
  json <- paste(readLines(json_path, warn = FALSE), collapse = "\n")
  round_trip <- jsonlite::fromJSON(json, simplifyVector = FALSE)
  resolved_state <- round_trip$resolved_herbivore_state
  missing_schema <- round_trip$resolved_herbivore_state_missing_schema
  required_fields <- c(
    "bite_size", "handling_time", "fv_max", "baseline_time_spent_foraging",
    "time_spent_foraging", "current_hour", "last_hour", "selected_plant_dist",
    "energy_balance", "water_balance", "energy_deficit_streak_days",
    "water_deficit_streak_days", "water_requirement_day"
  )
  missing_fields <- setdiff(names(initial$herbivore_state), names(resolved_state))

  expect_identical(initial$herbivore$state_stage, "before_first_step")
  expect_identical(initial$herbivore$herbivore_id, "goal002_grazer_1")
  expect_equal(initial$herbivore$coordinates_m$xcor, 50)
  expect_equal(initial$herbivore$coordinates_m$ycor, 50)
  expect_identical(initial$herbivore$behaviour, "MOVING")
  expect_true(is.list(initial$herbivore$digestion))
  expect_true(all(c("bleaf", "bstem", "bdef", "dc_leaf", "dc_stem", "dp_leaf", "dp_stem", "dp_def") %in% names(initial$herbivore$digestion)))
  expect_true(is.finite(initial$herbivore$body_condition_index))
  expect_true(is.list(initial$herbivore$feedback_settings))
  expect_true(is.list(initial$herbivore$seeded_draws))
  expect_true(all(required_fields %in% names(initial$herbivore_state)))
  expect_true(
    length(missing_fields) == 0L,
    info = paste("missing pre-step herbivore fields:", paste(missing_fields, collapse = ", "))
  )
  expect_setequal(names(resolved_state), names(initial$herbivore_state))
  expect_setequal(names(resolved_state$digestion), names(initial$herbivore_state$digestion))
  expect_null(resolved_state$selected_plant_id)
  expect_null(resolved_state$selected_plant_dist)
  expect_setequal(names(missing_schema), c("selected_plant_id", "selected_plant_dist"))
  expect_identical(missing_schema$selected_plant_id$r_type, "integer")
  expect_identical(missing_schema$selected_plant_dist$r_type, "double")
  expect_identical(unlist(missing_schema$selected_plant_id$missing_positions), 1L)
  expect_identical(unlist(missing_schema$selected_plant_dist$missing_positions), 1L)
  expect_false(grepl('"NA"', json, fixed = TRUE))
  expect_identical(initial$plants$state_stage, "before_first_step")
  expect_equal(initial$plants$total_shoot_biomass_kg, 50)
})

test_that("invalid Goal 002 profiles fail clearly", {
  profile <- read_goal002_profile(goal002_profile_path)
  profile$runtime$days <- 119
  expect_error(
    validate_goal002_profile(profile),
    class = "herbivoreTTR_goal002_profile_invalid"
  )

  profile <- read_goal002_profile(goal002_profile_path)
  profile$external_forcing$soil_water <- c(0.5, 0.6)
  expect_error(
    validate_goal002_profile(profile),
    class = "herbivoreTTR_goal002_profile_invalid"
  )

  profile <- read_goal002_profile(goal002_profile_path)
  profile$runtime$start_day <- 7
  expect_error(
    validate_goal002_profile(profile),
    class = "herbivoreTTR_goal002_profile_invalid"
  )

  profile <- read_goal002_profile(goal002_profile_path)
  profile$runtime$plant_backend <- "internal_ttr_compiled"
  expect_error(
    validate_goal002_profile(profile),
    class = "herbivoreTTR_goal002_profile_invalid"
  )

  profile <- read_goal002_profile(goal002_profile_path)
  profile$population$herbivore$empirical_parameterisation <- TRUE
  expect_error(
    validate_goal002_profile(profile),
    class = "herbivoreTTR_goal002_profile_invalid"
  )
})

test_that("Goal 002 runner requires an absent output directory", {
  output_dir <- tempfile("goal002-existing-")
  dir.create(output_dir)
  withr::defer(unlink(output_dir, recursive = TRUE, force = TRUE))

  expect_error(
    run_goal002_minimal_diagnosis(goal002_profile_path, output_dir),
    class = "herbivoreTTR_goal002_output_exists"
  )
})

test_that("Goal 002 validated profile declares the five stable diagnostic artefacts", {
  profile <- validate_goal002_profile(read_goal002_profile(goal002_profile_path))
  expected <- c(
    "run_manifest.json",
    "daily_diagnostics.csv",
    "plant_diagnostics.csv",
    "diagnostic_summary.json",
    "diagnostic_trajectories.png"
  )
  expect_identical(profile$outputs$artefact_names, expected)
})

test_that("Goal 002 summary preserves exact synthetic accounting identities", {
  profile <- validate_goal002_profile(read_goal002_profile(goal002_profile_path))
  daily <- data.frame(
    Day = 1:3,
    temperature = rep(25, 3),
    soil_water = rep(0.5, 3),
    soil_nitrogen = rep(0.5, 3),
    energy_intake_kJ = c(10, 12, 14),
    total_energy_requirement_kJ = c(8, 9, 10),
    energy_delta_kJ = c(2, 3, 4),
    cumulative_energy_balance_kJ = c(2, 5, 9),
    metabolic_water_g = c(1, 2, 3),
    forage_water_g = c(4, 5, 6),
    drinking_water_g = c(2, 2, 2),
    water_requirement_g = c(5, 6, 7),
    daily_net_water_g = c(2, 3, 4),
    cumulative_water_balance_g = c(2, 5, 9),
    BodyConditionIndex = c(0.8, 0.7, 0.6),
    PhysiologicalStressFlag = c(0L, 0L, 1L)
  )
  plants <- data.frame(
    Day = 1:3,
    closing_total_shoot_biomass_kg = c(11, 10, 10),
    plant_accounting_residual_kg = c(0, 0, 0)
  )

  summary <- goal002_summary(daily, plants, profile, "synthetic")
  residuals <- summary$accounting_residual
  residual_names <- c(
    "energy_daily_identity_max_abs_kJ",
    "energy_cumulative_identity_max_abs_kJ",
    "water_daily_identity_max_abs_g",
    "water_cumulative_identity_max_abs_g",
    "plant_max_abs_kg"
  )
  expect_identical(unname(unlist(residuals[residual_names])), rep(0, 5))
  expect_true(all(vapply(residuals[residual_names], is.numeric, logical(1))))
  expect_true(all(vapply(residuals[residual_names], is.finite, logical(1))))
  expect_true(all(vapply(residuals[residual_names], function(x) x >= 0, logical(1))))
  expect_true(grepl("gross TTR growth and gross litter loss", summary$accounting_residual$unavailable_term,
                    fixed = TRUE))
})
