test_that("init_herbivore seeds realistic digestion state and bounded gut content", {
  herb <- init_herbivore(mass = 5e5, MRT = CONSTANTS$HERBIVORE_MRT)
  tol <- max(CONSTANTS$TOLERANCE, 1e-8)

  expect_true(herb$gut_content > 0)
  expect_true(herb$gut_content <= herb$gut_capacity + tol)
  expect_true(all(vapply(herb$digestion, length, integer(1L)) == herb$MRT))
  expect_true(all(vapply(
    herb$digestion,
    function(x) is.numeric(x) && all(is.finite(x)) && all(x >= -tol),
    logical(1L)
  )))
})

test_that("MRT policy is explicit and validated", {
  herb_default <- init_herbivore(mass = 5e5)
  expect_equal(herb_default$MRT, as.integer(CONSTANTS$HERBIVORE_MRT))

  expect_error(
    init_herbivore(mass = 5e5, MRT = NA_real_),
    class = "herbivoreTTR_mrt_invalid"
  )
  expect_error(
    init_herbivore(mass = 5e5, MRT = CONSTANTS$MRT_MAX_HOURS + 100),
    class = "herbivoreTTR_mrt_out_of_bounds"
  )
})

test_that("set_herbivore_MRT preserves queued mass when requested", {
  herb <- init_herbivore(mass = 5e5, MRT = 24)
  totals_before <- vapply(
    digestion_queue_names(),
    function(nm) sum(herb$digestion[[nm]]),
    numeric(1L)
  )

  resized <- set_herbivore_MRT(herb, MRT = 12, preserve_content = TRUE)
  totals_after <- vapply(
    digestion_queue_names(),
    function(nm) sum(resized$digestion[[nm]]),
    numeric(1L)
  )

  expect_equal(resized$MRT, 12L)
  expect_equal(totals_after, totals_before, tolerance = 1e-8)
})

test_that("hourly digestion eventually processes queued digestible material", {
  herb <- init_herbivore(mass = 5e5, MRT = 6)
  k <- herb$MRT

  herb$digestion$bleaf <- rep(3, k)
  herb$digestion$bstem <- rep(2, k)
  herb$digestion$bdef <- rep(1, k)
  herb$digestion$dc_leaf <- seq(0.2, 0.7, length.out = k)
  herb$digestion$dc_stem <- seq(0.1, 0.6, length.out = k)
  herb$digestion$dp_leaf <- seq(0.05, 0.3, length.out = k)
  herb$digestion$dp_stem <- seq(0.03, 0.2, length.out = k)
  herb$digestion$dp_def <- seq(0.02, 0.1, length.out = k)
  herb$intake_digest_carbs_day <- 0
  herb$intake_digest_protein_day <- 0
  herb$intake_NPE_day <- 0
  herb$intake_PE_day <- 0
  herb$metabolic_water_day <- 0
  herb <- update_gut_content(herb)

  initial_carbs <- sum(herb$digestion$dc_leaf + herb$digestion$dc_stem)
  initial_protein <- sum(herb$digestion$dp_leaf + herb$digestion$dp_stem + herb$digestion$dp_def)

  for (i in seq_len(k)) {
    herb <- hourly_digestion_step(herb)
  }

  expect_equal(herb$intake_digest_carbs_day, initial_carbs, tolerance = 1e-8)
  expect_equal(herb$intake_digest_protein_day, initial_protein, tolerance = 1e-8)
  expect_true(all(vapply(herb$digestion, function(x) all(abs(x) <= 1e-8), logical(1L))))
})

test_that("digestion contract scenario captures plausible timing and MRT sensitivity", {
  out_a <- run_digestion_contract_scenario(seed = 33L, base_dir = tempdir())
  out_b <- run_digestion_contract_scenario(seed = 33L, base_dir = tempdir())

  expect_true(file.exists(out_a$hourly_path))
  expect_true(file.exists(out_a$probe_summary_path))
  expect_true(file.exists(out_a$contract_summary_path))
  expect_true(file.exists(out_a$manifest_path))

  expect_identical(out_a$hourly, out_b$hourly)
  expect_identical(out_a$probe_summary, out_b$probe_summary)
  expect_identical(out_a$contract_summary, out_b$contract_summary)

  metrics <- out_a$contract_summary
  expect_equal(metrics$value[metrics$metric == "default_first_hour_energy_positive"], 1)
  expect_equal(metrics$value[metrics$metric == "default_day_energy_positive"], 1)
  expect_equal(metrics$value[metrics$metric == "long_day_energy_positive"], 1)
  expect_gt(metrics$value[metrics$metric == "short_minus_long_day_energy_kj"], 0)
})
