test_that("TTR guardrails enforce defence semantics and bounded pools over stress days", {
  old_flag <- CONSTANTS$DEFENCE_ENABLED
  on.exit({ CONSTANTS$DEFENCE_ENABLED <<- old_flag }, add = TRUE)
  CONSTANTS$DEFENCE_ENABLED <<- 0

  stress <- run_ttr_stress_scenario(
    days = 14L,
    seed = 11L,
    stress_temp = 35,
    stress_sw = 0.95,
    stress_n = 0.95,
    base_dir = tempdir(),
    scenario_slug = sprintf("stress_guardrail_%s", as.integer(Sys.time()))
  )

  metrics <- stress$metrics
  expect_true(all(metrics$non_finite_count == 0))
  expect_true(max(metrics$ms_max) <= CONSTANTS$TTR_MAX_POOL_ABS)
  expect_true(max(metrics$mr_max) <= CONSTANTS$TTR_MAX_POOL_ABS)
  expect_true(max(metrics$cs_max) <= CONSTANTS$TTR_MAX_POOL_ABS)
  expect_true(max(metrics$ns_max) <= CONSTANTS$TTR_MAX_POOL_ABS)
  expect_true(max(metrics$defence_fraction_max) <= CONSTANTS$TTR_MAX_DEFENCE_FRACTION + CONSTANTS$TOLERANCE)

  plants <- stress$plants
  expect_true(all(abs(plants$md - plants$bdef) <= CONSTANTS$TOLERANCE))
  expect_true(all(plants$bdef <= plants$ms + CONSTANTS$TOLERANCE))
  expect_true(file.exists(stress$plants_path))
  expect_true(file.exists(stress$metrics_path))
  expect_true(file.exists(stress$manifest_path))
})

test_that("TTR guardrails fail fast on runaway defence fraction", {
  plants_prev <- init_plants(veg_types = c(0))
  plants_prev <- plants_prev[1, , drop = FALSE]
  plants_bad <- plants_prev
  plants_bad$bdef[1] <- plants_bad$ms[1] * (CONSTANTS$TTR_MAX_DEFENCE_FRACTION + 1)
  plants_bad$md[1] <- plants_bad$bdef[1]

  expect_error(
    assert_ttr_guardrails(
      plants = plants_bad,
      plants_previous = plants_prev,
      day_of_simulation = 1L
    ),
    class = "herbivoreTTR_domain_sanity_violation"
  )
})

test_that("TTR guardrails fail fast on runaway daily multiplier", {
  plants_prev <- init_plants(veg_types = c(0))
  plants_prev <- plants_prev[1, , drop = FALSE]
  plants_bad <- plants_prev
  plants_bad$ms[1] <- plants_prev$ms[1] * (CONSTANTS$TTR_MAX_DAILY_POOL_MULTIPLIER + 1)
  plants_bad$md[1] <- plants_bad$bdef[1]

  expect_error(
    assert_ttr_guardrails(
      plants = plants_bad,
      plants_previous = plants_prev,
      day_of_simulation = 1L
    ),
    class = "herbivoreTTR_domain_sanity_violation"
  )
})

test_that("TTR guardrail payload is stable for absolute pool cap violations", {
  plants_prev <- init_plants(veg_types = c(0))
  plants_prev <- plants_prev[1, , drop = FALSE]
  plants_bad <- plants_prev
  plants_bad$ms[1] <- CONSTANTS$TTR_MAX_POOL_ABS + 1

  cnd <- rlang::catch_cnd(
    assert_ttr_guardrails(
      plants = plants_bad,
      plants_previous = plants_prev,
      day_of_simulation = 9L,
      phase = "payload_test"
    )
  )

  expect_s3_class(cnd, "herbivoreTTR_domain_sanity_violation")
  expect_identical(cnd$component, "ttr$ms")
  expect_match(cnd$reason, "pool exceeded absolute stability cap")
  expect_identical(cnd$day, 9L)
  expect_identical(cnd$phase, "payload_test")
})
