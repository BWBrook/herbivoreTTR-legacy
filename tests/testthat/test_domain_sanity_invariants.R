test_that("domain sanity: coupled run keeps core state finite and non-negative", {
  sim <- init_simulation(temp_mode = "flat", veg_types = c(0, 1, 2), herbivore_mass = 5e5)
  day0 <- CONSTANTS$SPIN_UP_LENGTH * nrow(sim$conditions) + 1L

  res <- run_daily_herbivore_simulation(
    herbivore = sim$herbivore,
    plants = sim$plants,
    conditions = sim$conditions,
    day_of_simulation = day0,
    minute_limit = 60
  )

  plants <- res$plants
  herb <- res$herbivore
  tol <- CONSTANTS$TOLERANCE

  plant_nonneg_cols <- c("ms", "mr", "bleaf", "bstem", "bdef", "cs", "cr", "ns", "nr", "cd", "nd", "md")
  for (col in plant_nonneg_cols) {
    expect_true(col %in% names(plants))
    expect_true(all(is.finite(plants[[col]])))
    expect_true(all(plants[[col]] >= -tol))
  }

  expect_true(is.finite(herb$gut_capacity))
  expect_true(herb$gut_capacity > 0)

  expect_true(is.finite(herb$gut_content))
  expect_true(herb$gut_content >= -tol)
  expect_true(herb$gut_content <= herb$gut_capacity + tol)

  expect_true(is.finite(herb$distance_moved))
  expect_true(herb$distance_moved >= 0)

  # Balances can be negative, but must be finite.
  expect_true(is.finite(herb$energy_balance))
  expect_true(is.finite(herb$water_balance))

  # Digestion queues should be finite and non-negative (within tolerance).
  expect_true(is.list(herb$digestion))
  dig_ok <- vapply(
    herb$digestion,
    function(x) is.numeric(x) && all(is.finite(x)) && all(x >= -tol),
    logical(1)
  )
  expect_true(all(dig_ok))
})

test_that("domain sanity runtime checks include component and timestep context", {
  sim <- init_simulation(temp_mode = "flat", veg_types = c(0, 1, 2), herbivore_mass = 5e5)
  herb <- calc_foraging_traits(reset_daily_variables(sim$herbivore))
  plants <- sim$plants

  plants$ms[1] <- NaN
  cnd_plants <- rlang::catch_cnd(
    assert_domain_sanity_state(
      plants = plants,
      herbivore = herb,
      day_of_simulation = 42L,
      minute_of_day = 17L,
      phase = "unit_test"
    )
  )
  expect_s3_class(cnd_plants, "herbivoreTTR_domain_sanity_violation")
  expect_match(cnd_plants$message, "plants\\$ms")
  expect_equal(cnd_plants$day, 42L)
  expect_equal(cnd_plants$minute, 17L)
  expect_equal(cnd_plants$phase, "unit_test")

  plants$ms[1] <- max(sim$plants$ms[1], CONSTANTS$TOLERANCE)
  herb$gut_content <- herb$gut_capacity + 10
  cnd_herb <- rlang::catch_cnd(
    assert_domain_sanity_state(
      plants = plants,
      herbivore = herb,
      day_of_simulation = 99L,
      minute_of_day = 3L,
      phase = "unit_test"
    )
  )
  expect_s3_class(cnd_herb, "herbivoreTTR_domain_sanity_violation")
  expect_match(cnd_herb$message, "herbivore\\$gut_content")
  expect_match(cnd_herb$message, "day 99 minute 3")
})

test_that("domain sanity: canonical daily balance jumps stay within guardrails", {
  res <- run_herbivore_days(days = 7L, minute_limit = 60, seed = 1L)
  summary <- res$daily_summary

  energy_jump <- abs(diff(summary$energy_balance))
  water_jump <- abs(diff(summary$water_balance))

  expect_true(all(is.finite(energy_jump)))
  expect_true(all(is.finite(water_jump)))
  expect_true(all(energy_jump <= CONSTANTS$SANITY_MAX_DAILY_ENERGY_JUMP))
  expect_true(all(water_jump <= CONSTANTS$SANITY_MAX_DAILY_WATER_JUMP))
})

test_that("domain sanity: balance jump helper handles failure and non-finite bypass", {
  expect_error(
    assert_daily_balance_jump(
      previous_value = 0,
      current_value = CONSTANTS$SANITY_MAX_DAILY_ENERGY_JUMP + 1,
      max_jump = CONSTANTS$SANITY_MAX_DAILY_ENERGY_JUMP,
      component = "herbivore$energy_balance",
      day_of_simulation = 7L
    ),
    class = "herbivoreTTR_domain_sanity_violation"
  )

  expect_true(
    isTRUE(
      assert_daily_balance_jump(
        previous_value = Inf,
        current_value = 100,
        max_jump = 1,
        component = "herbivore$energy_balance",
        day_of_simulation = 7L
      )
    )
  )
})

test_that("domain sanity: state helper validates error branches", {
  sim <- init_simulation(temp_mode = "flat", veg_types = c(0, 1, 2), herbivore_mass = 5e5)
  valid_plants <- sim$plants
  valid_herb <- calc_foraging_traits(reset_daily_variables(sim$herbivore))

  expect_error(
    assert_domain_sanity_state(
      plants = list(),
      herbivore = valid_herb,
      day_of_simulation = 1L,
      phase = "unit_test"
    ),
    class = "herbivoreTTR_domain_sanity_violation"
  )

  missing_col <- valid_plants
  missing_col$ms <- NULL
  expect_error(
    assert_domain_sanity_state(
      plants = missing_col,
      herbivore = valid_herb,
      day_of_simulation = 1L,
      phase = "unit_test"
    ),
    class = "herbivoreTTR_domain_sanity_violation"
  )

  bad_type <- valid_plants
  bad_type$ms <- as.character(bad_type$ms)
  expect_error(
    assert_domain_sanity_state(
      plants = bad_type,
      herbivore = valid_herb,
      day_of_simulation = 1L,
      phase = "unit_test"
    ),
    class = "herbivoreTTR_domain_sanity_violation"
  )

  expect_error(
    assert_domain_sanity_state(
      plants = valid_plants,
      herbivore = 1,
      day_of_simulation = 1L,
      phase = "unit_test"
    ),
    class = "herbivoreTTR_domain_sanity_violation"
  )

  herb_bad_gut <- valid_herb
  herb_bad_gut$gut_capacity <- 0
  expect_error(
    assert_domain_sanity_state(
      plants = valid_plants,
      herbivore = herb_bad_gut,
      day_of_simulation = 1L,
      phase = "unit_test"
    ),
    class = "herbivoreTTR_domain_sanity_violation"
  )

  herb_bad_digest <- valid_herb
  herb_bad_digest$digestion <- 5
  expect_error(
    assert_domain_sanity_state(
      plants = valid_plants,
      herbivore = herb_bad_digest,
      day_of_simulation = 1L,
      phase = "unit_test"
    ),
    class = "herbivoreTTR_domain_sanity_violation"
  )

  herb_bad_queue <- valid_herb
  herb_bad_queue$digestion$leaf <- as.character(herb_bad_queue$digestion$leaf)
  expect_error(
    assert_domain_sanity_state(
      plants = valid_plants,
      herbivore = herb_bad_queue,
      day_of_simulation = 1L,
      phase = "unit_test"
    ),
    class = "herbivoreTTR_domain_sanity_violation"
  )

  expect_true(
    isTRUE(
      assert_domain_sanity_state(
        plants = list(),
        herbivore = 1,
        day_of_simulation = 1L,
        phase = "unit_test",
        check_plants = FALSE,
        check_herbivore = FALSE
      )
    )
  )
})

test_that("domain sanity failure payload stays stable for missing required column", {
  sim <- init_simulation(temp_mode = "flat", veg_types = c(0, 1, 2), herbivore_mass = 5e5)
  plants <- sim$plants
  plants$ms <- NULL
  herb <- calc_foraging_traits(reset_daily_variables(sim$herbivore))

  cnd <- rlang::catch_cnd(
    assert_domain_sanity_state(
      plants = plants,
      herbivore = herb,
      day_of_simulation = 5L,
      minute_of_day = 11L,
      phase = "payload_test"
    )
  )

  expect_s3_class(cnd, "herbivoreTTR_domain_sanity_violation")
  expect_identical(cnd$component, "plants$ms")
  expect_identical(cnd$reason, "required plant column is missing")
  expect_identical(cnd$day, 5L)
  expect_identical(cnd$minute, 11L)
  expect_identical(cnd$phase, "payload_test")
})
