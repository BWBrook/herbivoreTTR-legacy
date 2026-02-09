test_that("compiled resistance kernel falls back cleanly when forced unavailable", {
  old_force <- Sys.getenv("HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE", unset = "0")
  old_flag <- Sys.getenv("HERBIVORETTR_USE_COMPILED_TTR", unset = "0")
  on.exit({
    Sys.setenv(HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE = old_force)
    Sys.setenv(HERBIVORETTR_USE_COMPILED_TTR = old_flag)
    reset_compiled_ttr_kernel_v1()
  }, add = TRUE)

  Sys.setenv(HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE = "1")
  Sys.setenv(HERBIVORETTR_USE_COMPILED_TTR = "0")
  reset_compiled_ttr_kernel_v1()

  ms <- c(0, 0.5, 10, 20)
  mr <- c(0, 0.8, 12, 25)
  expect_warning(
    out <- compute_ttr_resistances_kernel_v1(
      ms = ms,
      mr = mr,
      tr_c = CONSTANTS$TR_C,
      tr_n = CONSTANTS$TR_N,
      q_scp = CONSTANTS$Q_SCP,
      use_compiled = TRUE
    ),
    "falling back to pure R"
  )

  expect_identical(out$engine, "r")
  expect_true(isTRUE(out$fallback_used))
  expect_true(all(is.finite(out$rsC)))
  expect_true(all(is.finite(out$rrC)))
  expect_true(all(is.finite(out$rsN)))
  expect_true(all(is.finite(out$rrN)))
})

test_that("compiled resistance parity harness passes for selected candidate", {
  old_force <- Sys.getenv("HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE", unset = "0")
  old_flag <- Sys.getenv("HERBIVORETTR_USE_COMPILED_TTR", unset = "0")
  on.exit({
    Sys.setenv(HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE = old_force)
    Sys.setenv(HERBIVORETTR_USE_COMPILED_TTR = old_flag)
  }, add = TRUE)
  Sys.setenv(HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE = "0")
  Sys.setenv(HERBIVORETTR_USE_COMPILED_TTR = "0")

  parity <- run_compiled_resistance_parity_harness_v1(sample_size = 256L, seed = 915L)
  expect_true(is.data.frame(parity$summary))
  expect_true(is.data.frame(parity$metrics))
  expect_true(parity$summary$parity_pass[[1]])
  expect_true(max(parity$metrics$max_abs_diff) <= parity$summary$tolerance[[1]])
})

test_that("compiled backend name resolves and preserves daily outputs", {
  sim <- init_simulation(temp_mode = "flat", veg_types = c(0, 1, 2), herbivore_mass = 5e5)
  day <- CONSTANTS$SPIN_UP_LENGTH * nrow(sim$conditions) + 1L

  serial <- run_daily_herbivore_simulation(
    herbivore = sim$herbivore,
    plants = sim$plants,
    conditions = sim$conditions,
    day_of_simulation = day,
    minute_limit = 30,
    seed = 2026,
    plant_backend = "internal_ttr"
  )
  compiled <- run_daily_herbivore_simulation(
    herbivore = sim$herbivore,
    plants = sim$plants,
    conditions = sim$conditions,
    day_of_simulation = day,
    minute_limit = 30,
    seed = 2026,
    plant_backend = "internal_ttr_compiled"
  )

  expect_identical(compiled$daily_summary$plant_backend, "internal_ttr_compiled")
  compiled_summary <- compiled$daily_summary
  serial_summary <- serial$daily_summary
  compiled_summary$plant_backend <- NULL
  serial_summary$plant_backend <- NULL
  expect_equal(compiled_summary, serial_summary)
  expect_equal(compiled$plants, serial$plants, tolerance = 1e-12)
})

test_that("compiled candidate selection writes ranked outputs and parity artefacts", {
  tmp <- tempfile("compiled_candidate_v1_")
  dir.create(tmp, recursive = TRUE, showWarnings = FALSE)

  profile_path <- file.path(tmp, "profile_by_self.csv")
  profile_stub <- data.frame(
    call = c("\"calc_RsC\"", "\"calc_RrC\"", "\"calc_tauC\"", "\"assert_domain_sanity_vector\""),
    self.time = c(0.30, 0.25, 0.60, 0.15),
    self.pct = c(12.0, 10.0, 18.0, 4.0),
    total.time = c(0.30, 0.25, 0.60, 0.15),
    total.pct = c(12.0, 10.0, 18.0, 4.0),
    stringsAsFactors = FALSE
  )
  utils::write.csv(profile_stub, profile_path, row.names = FALSE)

  out <- run_compiled_candidate_selection_v1(
    base_dir = tmp,
    scenario_slug = "compiled_candidate_selection_test_v1",
    profile_self_path = profile_path
  )

  expect_true(file.exists(out$ranking_path))
  expect_true(file.exists(out$parity_summary_path))
  expect_true(file.exists(out$parity_metrics_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))
  expect_true("resistance_vector_kernel" %in% out$ranking$candidate_id)
  expect_true(any(out$ranking$selected_for_wp_3_4_2))
})

test_that("fixed-seed scenario parity check passes for compiled path", {
  skip_on_cran()

  tmp <- tempfile("compiled_scenario_parity_v1_")
  dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
  out <- run_compiled_scenario_parity_check_v1(
    base_dir = tmp,
    scenario_slug = "compiled_scenario_parity_test_v1",
    days = 2L,
    minute_limit = 30L,
    seed = 1201L,
    tolerance = 1e-12
  )

  expect_true(file.exists(out$metrics_path))
  expect_true(file.exists(out$summary_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))
  expect_true(out$summary$parity_pass[[1]])
  expect_true(max(out$metrics$max_abs_diff) <= out$summary$tolerance[[1]])
})
