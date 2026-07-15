goal003_profile_path <- file.path(
  repo_root_for_tests(),
  "inst", "extdata", "scenarios", "goal003_herbivore_reference_v1.yaml"
)

source(file.path(repo_root_for_tests(), "scripts", "run_goal003_herbivore_reference.R"), local = TRUE)

test_that("Goal 003 profile fixes the approved daily-clamped reference", {
  profile <- goal003_validate_profile(goal003_read_profile(goal003_profile_path))

  expect_identical(profile$goal_id, "003-herbivore-only-daily-clamped-forage-reference")
  expect_identical(profile$runtime$seed, 2002L)
  expect_identical(profile$runtime$days, 120L)
  expect_identical(profile$runtime$start_day, 6L)
  expect_identical(profile$runtime$minute_limit, 720L)
  expect_identical(profile$runtime$daily_seed_offset, 100000L)
  expect_identical(profile$runtime$plant_backend, "internal_ttr")
  expect_false(profile$runtime$apply_growth)
  expect_true(profile$runtime$daily_plant_reset)
  expect_identical(profile$population$herbivore_count, 1L)
  expect_identical(profile$forage$forage_type_count, 1L)
  expect_identical(profile$initial_plant_state$plant_id, 1L)
  expect_equal(profile$initial_plant_state$ms, 50)
  expect_identical(profile$nonbinding$min_shoot_kg, 0.001)
  expect_identical(profile$nonbinding$m_ref_kg, 10)
  expect_identical(profile$nonbinding$tolerance, 1e-10)
  expect_identical(profile$outputs$artefact_names, c(
    "run_manifest.json", "daily_diagnostics.csv", "plant_diagnostics.csv",
    "diagnostic_summary.json", "diagnostic_trajectories.png"
  ))
})

test_that("resolved Goal 003 initial state retains the Goal 002 herbivore queues", {
  profile <- goal003_validate_profile(goal003_read_profile(goal003_profile_path))
  initial <- goal003_resolve_initial_state(profile)
  goal002_manifest <- jsonlite::read_json(
    file.path(repo_root_for_tests(), "artefacts", "goal002_minimal_coupled", "run-a", "run_manifest.json"),
    simplifyVector = FALSE
  )
  expected <- goal002_manifest$initial_herbivore_state$resolved_herbivore_state

  expect_identical(initial$herbivore_state$herbivore_id, expected$herbivore_id)
  expect_equal(initial$herbivore_state$mass, as.numeric(expected$mass), tolerance = 0)
  expect_equal(initial$herbivore_state$gut_content, as.numeric(expected$gut_content), tolerance = 0)
  expect_equal(initial$herbivore_state$gut_capacity, as.numeric(expected$gut_capacity), tolerance = 0)
  expect_equal(initial$herbivore_state$body_condition_index, as.numeric(expected$body_condition_index), tolerance = 0)
  expect_setequal(names(initial$herbivore_state$digestion), c(
    "bleaf", "bstem", "bdef", "dc_leaf", "dc_stem", "dp_leaf", "dp_stem", "dp_def"
  ))
  for (queue_name in names(initial$herbivore_state$digestion)) {
    expect_equal(initial$herbivore_state$digestion[[queue_name]],
                 as.numeric(unlist(expected$digestion[[queue_name]], use.names = FALSE)), tolerance = 0)
  }
  expect_equal(initial$herbivore_state$xcor, 50, tolerance = 0)
  expect_equal(initial$herbivore_state$ycor, 50, tolerance = 0)
  expect_identical(initial$plants_state, goal003_initial_plants(profile))
})

test_that("daily reset is an exact frozen copy and does not consume RNG", {
  profile <- goal003_validate_profile(goal003_read_profile(goal003_profile_path))
  initial <- goal003_resolve_initial_state(profile)
  sentinel <- initial$herbivore_state
  set.seed(73003)
  before_rng <- .Random.seed
  reset <- goal003_reset_day(initial$plants_state, sentinel)
  expect_identical(reset$plants, initial$plants_state)
  expect_identical(reset$herbivore, sentinel)
  expect_identical(reset$opening_source, "frozen_snapshot")
  expect_identical(reset$opening_identical_to_prior_closing, FALSE)
  expect_identical(.Random.seed, before_rng)

  altered_closing <- initial$plants_state
  altered_closing$ms <- 1
  altered_closing$bleaf <- 0.999
  next_opening <- goal003_reset_day(initial$plants_state, sentinel,
                                    prior_closing = altered_closing)
  expect_identical(next_opening$plants, initial$plants_state)
  expect_false(identical(next_opening$plants, altered_closing))

  zero_intake_closing <- initial$plants_state
  equal_state <- goal003_reset_day(initial$plants_state, sentinel,
                                   prior_closing = zero_intake_closing)
  expect_identical(equal_state$opening_source, "frozen_snapshot")
  expect_true(equal_state$opening_identical_to_prior_closing)
})

test_that("all Goal 002 configuration and plant invariants are locked", {
  profile <- goal003_read_profile(goal003_profile_path)

  invalid <- profile
  invalid$runtime$forage_access_scale <- 0.9
  expect_error(goal003_validate_profile(invalid), class = "herbivoreTTR_goal003_profile_invalid")

  invalid <- profile
  invalid$initial_plant_state$bleaf <- invalid$initial_plant_state$bleaf - 1
  expect_error(goal003_validate_profile(invalid), class = "herbivoreTTR_goal003_profile_invalid")

  invalid <- profile
  invalid$initial_plant_state$xcor <- invalid$initial_plant_state$xcor + 1
  expect_error(goal003_validate_profile(invalid), class = "herbivoreTTR_goal003_profile_invalid")

  invalid <- profile
  invalid$population$herbivore$movement_disruption_prob <- 0.2
  expect_error(goal003_validate_profile(invalid), class = "herbivoreTTR_goal003_profile_invalid")

  invalid <- profile
  invalid$population$herbivore$behaviour <- "REST"
  expect_error(goal003_validate_profile(invalid), class = "herbivoreTTR_goal003_profile_invalid")
})

test_that("invalid profile interventions are rejected", {
  profile <- goal003_read_profile(goal003_profile_path)

  invalid <- profile
  invalid$runtime$apply_growth <- TRUE
  expect_error(goal003_validate_profile(invalid), class = "herbivoreTTR_goal003_profile_invalid")

  invalid <- profile
  invalid$runtime$daily_plant_reset <- FALSE
  expect_error(goal003_validate_profile(invalid), class = "herbivoreTTR_goal003_profile_invalid")

  invalid <- profile
  invalid$runtime$extra_digestion_ticks <- 1L
  expect_error(goal003_validate_profile(invalid), class = "herbivoreTTR_goal003_profile_invalid")

  invalid <- profile
  invalid$initial_plant_state$ms <- 500
  expect_error(goal003_validate_profile(invalid), class = "herbivoreTTR_goal003_profile_invalid")
})

test_that("runner requires an absent output directory", {
  output_dir <- tempfile("goal003-existing-")
  dir.create(output_dir)
  withr::defer(unlink(output_dir, recursive = TRUE, force = TRUE))
  expect_error(
    run_goal003_herbivore_reference(goal003_profile_path, output_dir),
    class = "herbivoreTTR_goal003_output_exists"
  )
})

test_that("runner emits the stable five-artefact evidence contract", {
  profile <- goal003_validate_profile(goal003_read_profile(goal003_profile_path))
  output_dir <- tempfile("goal003-run-")
  withr::defer(unlink(output_dir, recursive = TRUE, force = TRUE))
  result <- run_goal003_herbivore_reference(goal003_profile_path, output_dir)
  expected <- profile$outputs$artefact_names

  expect_identical(basename(result$artefacts), expected)
  expect_true(all(file.exists(result$artefacts)))
  expect_identical(nrow(result$daily), 120L)
  expect_identical(nrow(result$plants), 120L)
  expect_identical(result$manifest$status, "complete")
  expect_false(result$manifest$apply_growth)
  expect_true(result$manifest$daily_plant_reset)
  expect_true(result$manifest$all_nonbinding_checks_passed)
  expect_true(result$manifest$goal002_reference$manifest_sha256 %in%
                c("4c61f2c866a5b3209608b4b7d29fc82209de749e3ecbefdd324d982ca2f4fb39"))
  expect_true(all(c("opening_source", "opening_identical_to_prior_closing",
                    "max_all_minute_plant_distance_m", "detectable_throughout_active_loop",
                    "reachable_throughout_active_loop", "minimum_all_minute_selection_score",
                    "positive_selection_minutes", "positive_intake_within_eat_radius",
                    "opening_shoot_component_residual_kg") %in% names(result$plants)))
  expect_true(all(result$plants$opening_source == "frozen_snapshot"))
  expect_true(all(result$plants$apply_growth == FALSE))
  expect_true(all(!result$plants$opening_identical_to_prior_closing))
  expect_true(all(result$plants$detectable_throughout_active_loop))
  expect_true(all(result$plants$reachable_throughout_active_loop))
  expect_true(all(result$plants$minimum_all_minute_selection_score > 0))
  expect_true(all(result$plants$positive_intake_within_eat_radius))
  expect_true(all(result$plants$positive_selection_minutes > 0))
  expect_true(max(abs(result$plants$opening_shoot_component_residual_kg)) <= 1e-12)
  expect_true(all(result$plants$opening_from_frozen_snapshot))
  expect_true(all(result$plants$closing_ms > result$plants$min_shoot_kg))
  expect_true(all(result$plants$closing_ms > result$plants$m_ref_kg))
  expect_true(all(result$plants$closing_qshoot > 0))
  expect_true(all(abs(result$plants$qshoot_shoot_ratio_change) <= 1e-10))
  expect_true(all(abs(result$plants$selection_nutrient_ratio_change) <= 1e-10))
  expect_true(all(result$plants$single_plant_eligible,
                  result$plants$positive_selection_score,
                  result$plants$co_located_for_eating))
  expect_true(all(result$daily$gut_content_g <= result$daily$gut_capacity_g + 1e-8))
  expect_true(all(is.finite(result$daily$energy_daily_residual_kJ)))
  expect_true(all(is.finite(result$daily$water_daily_residual_g)))
})
