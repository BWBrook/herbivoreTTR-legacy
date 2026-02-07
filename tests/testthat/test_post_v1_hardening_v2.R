test_that("ensemble seed normalization is deterministic", {
  expect_equal(normalise_ensemble_seeds(c(5, 3, 3, 4)), c(3L, 4L, 5L))
  expect_error(
    normalise_ensemble_seeds(c(1, NA)),
    class = "herbivoreTTR_ensemble_seeds_invalid"
  )
})

test_that("scenario ensemble runner writes deterministic seed-ordered summaries", {
  skip_on_cran()

  out_a <- run_scenario_ensemble_v1(
    scenario = scenario_contract_reference_path("canonical_smoke_v1"),
    seeds = c(12L, 11L, 11L),
    base_dir = tempdir(),
    ensemble_label = "ensemble_test_v1"
  )

  out_b <- run_scenario_ensemble_v1(
    scenario = scenario_contract_reference_path("canonical_smoke_v1"),
    seeds = c(11L, 12L),
    base_dir = tempdir(),
    ensemble_label = "ensemble_test_v1_repeat"
  )

  expect_true(file.exists(out_a$seed_manifest_path))
  expect_true(file.exists(out_a$replicate_summary_path))
  expect_true(file.exists(out_a$ensemble_summary_path))
  expect_identical(out_a$seed_manifest$seed_value, c(11L, 12L))
  expect_identical(out_b$seed_manifest$seed_value, c(11L, 12L))
  expect_equal(
    out_a$replicate_summary[, c("seed_value", "mean_daily_dmi", "mean_energy_balance")],
    out_b$replicate_summary[, c("seed_value", "mean_daily_dmi", "mean_energy_balance")]
  )
})

test_that("ensemble runner preserves deterministic summaries across execution modes", {
  skip_on_cran()
  skip_if_not(.Platform$OS.type == "unix")

  serial <- run_scenario_ensemble_v1(
    scenario = scenario_contract_reference_path("canonical_smoke_v1"),
    seeds = 201:204,
    base_dir = tempdir(),
    ensemble_label = "ensemble_mode_serial_v1",
    write_outputs = FALSE,
    execution_mode = "serial"
  )

  multicore <- run_scenario_ensemble_v1(
    scenario = scenario_contract_reference_path("canonical_smoke_v1"),
    seeds = 201:204,
    base_dir = tempdir(),
    ensemble_label = "ensemble_mode_multicore_v1",
    write_outputs = FALSE,
    execution_mode = "multicore",
    workers = 2
  )

  cols <- c("seed_value", "mean_daily_dmi", "mean_energy_balance", "final_total_shoot_biomass_kg")
  expect_equal(serial$replicate_summary[, cols], multicore$replicate_summary[, cols])
  expect_identical(serial$seed_manifest$seed_value, multicore$seed_manifest$seed_value)
  expect_lte(multicore$execution_plan$workers_used, 2L)
  expect_gte(multicore$execution_plan$workers_used, 1L)
})

test_that("parallel execution plan resolves sensible worker bounds", {
  serial_plan <- resolve_parallel_execution_plan_v1(
    execution_mode = "serial",
    workers = 8,
    n_tasks = 4
  )
  expect_equal(serial_plan$workers_used, 1L)
  expect_identical(serial_plan$execution_mode_resolved, "serial")

  multi_plan <- resolve_parallel_execution_plan_v1(
    execution_mode = "multicore",
    workers = 8,
    n_tasks = 3,
    reserve_cores = 0
  )
  expect_gte(multi_plan$workers_used, 1L)
  expect_lte(multi_plan$workers_used, 3L)
})

test_that("claim registry evaluation and required-claim gating work", {
  claims <- read_claim_registry_v1()
  expect_true(nrow(claims) >= 3L)

  metrics_pass <- c(
    n_replicates = 10,
    delta_total_shoot_median = 100,
    delta_fine_fuel_median = 50,
    delta_browseable_median = 10,
    support_share_total_shoot = 0.95,
    support_share_fine_fuel = 0.90,
    support_share_browseable = 0.85
  )
  status_pass <- evaluate_claim_registry_v1("experiment_a_v2", metrics_pass, claims = claims)
  expect_true(all(status_pass$status %in% c("supported", "partially_supported", "not_supported")))
  expect_true(isTRUE(assert_required_claims_supported(status_pass)))

  metrics_fail <- metrics_pass
  metrics_fail[["n_replicates"]] <- 0
  status_fail <- evaluate_claim_registry_v1("experiment_a_v2", metrics_fail, claims = claims)
  expect_error(
    assert_required_claims_supported(status_fail),
    class = "herbivoreTTR_claim_gate_failed"
  )
})

test_that("experiment A v2 writes uncertainty and claim artefacts", {
  skip_on_cran()

  out <- run_experiment_a_presence_removal_v2(
    base_dir = tempdir(),
    seeds = 301:304,
    scenario_slug = "experiment_a_presence_removal_v2_test"
  )

  expect_true(file.exists(out$replicate_path))
  expect_true(file.exists(out$summary_path))
  expect_true(file.exists(out$delta_path))
  expect_true(file.exists(out$claims_path))
  expect_true(file.exists(out$summary_units_path))
  expect_true(file.exists(out$delta_units_path))
  expect_true(file.exists(out$figure_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))
  expect_true(all(is.finite(out$delta_summary$median_delta)))
  expect_true(all(out$delta_summary$support_share >= 0))
  expect_true(all(out$delta_summary$support_share <= 1))
})

test_that("body-condition feedback increases effort when condition is low", {
  herb <- init_herbivore()
  herb$body_condition_index <- 0.1
  herb$baseline_time_spent_foraging <- 12
  herb$time_spent_foraging <- 12
  herb$body_condition_feedback_enabled <- TRUE

  out <- apply_body_condition_feedback(herb, minute_limit = 1440)
  expect_gte(out$time_spent_foraging, 12)
  expect_lte(out$time_spent_foraging, 12 * (1 + CONSTANTS$BODY_CONDITION_MAX_FORAGING_BOOST) + 1e-8)
})

test_that("daily diagnostics update streaks and stress flag", {
  herb <- init_herbivore()
  herb$daily_energy_delta <- -100
  herb$daily_net_water_balance <- -10
  herb$energy_balance_ratio <- -0.5
  herb$body_condition_index <- 0.3
  out <- update_herbivore_daily_diagnostics(herb)

  expect_equal(out$energy_deficit_streak_days, 1L)
  expect_equal(out$water_deficit_streak_days, 1L)
  expect_equal(out$physiological_stress_flag, 1L)
  expect_lt(out$body_condition_index, 0.3)

  out$daily_energy_delta <- 100
  out$daily_net_water_balance <- 1
  out$energy_balance_ratio <- 0.2
  out2 <- update_herbivore_daily_diagnostics(out)
  expect_equal(out2$energy_deficit_streak_days, 0L)
  expect_equal(out2$water_deficit_streak_days, 0L)
})

test_that("scenario outputs include herbivore diagnostics columns", {
  skip_on_cran()

  out <- run_scenario_v1(
    scenario = scenario_contract_reference_path("canonical_smoke_v1"),
    base_dir = tempdir()
  )

  required_diag_cols <- c(
    "MaintenanceEnergyReq",
    "EnergyBalanceRatio",
    "WaterRequirement",
    "WaterBalanceRatio",
    "EnergyDeficitStreakDays",
    "WaterDeficitStreakDays",
    "BodyConditionIndex",
    "PhysiologicalStressFlag"
  )
  expect_true(all(required_diag_cols %in% names(out$herbivore_daily)))
  values <- unlist(out$herbivore_daily[, required_diag_cols, drop = FALSE], use.names = FALSE)
  expect_true(all(is.finite(values)))
})

test_that("run_scenario_v1 is deterministic and restores caller RNG", {
  scenario <- compile_scenario_yaml(scenario_contract_reference_path("canonical_smoke_v1"))
  scenario$runtime$days <- 6L
  scenario$runtime$minute_limit <- 60L
  scenario$outputs$scenario_slug <- "scenario_determinism_v2"

  set.seed(2026)
  baseline_seed <- .Random.seed
  run_scenario_v1(scenario, base_dir = tempdir(), write_outputs = FALSE)
  expect_identical(.Random.seed, baseline_seed)

  set.seed(77)
  out_a <- run_scenario_v1(scenario, base_dir = tempdir(), write_outputs = FALSE)

  set.seed(77)
  runif(15)
  out_b <- run_scenario_v1(scenario, base_dir = tempdir(), write_outputs = FALSE)

  expect_identical(out_a$run_id, out_b$run_id)
  expect_equal(out_a$herbivore_daily, out_b$herbivore_daily)
  expect_equal(out_a$structure_fuel_metrics, out_b$structure_fuel_metrics)
})

test_that("aridity-access matrix builder defines 3x3 scenario design", {
  matrix_bundle <- build_aridity_access_matrix_v2()
  expect_equal(nrow(matrix_bundle$matrix), 9L)
  expect_true(all(c("low", "mid", "high") %in% matrix_bundle$matrix$aridity_level))
  expect_true(all(c("low", "mid", "high") %in% matrix_bundle$matrix$access_level))
})

test_that("forage access scaling changes intake opportunity", {
  scenario <- compile_scenario_yaml(scenario_contract_reference_path("canonical_smoke_v1"))
  scenario$runtime$minute_limit <- 20L
  scenario$runtime$days <- 3L
  high_access <- scenario
  high_access$runtime$forage_access_scale <- 1
  high_access$outputs$scenario_slug <- "access_high_test"

  low_access <- scenario
  low_access$runtime$forage_access_scale <- 0.2
  low_access$outputs$scenario_slug <- "access_low_test"

  run_high <- run_scenario_v1(high_access, base_dir = tempdir(), write_outputs = FALSE)
  run_low <- run_scenario_v1(low_access, base_dir = tempdir(), write_outputs = FALSE)

  expect_gt(mean(run_high$herbivore_daily$DailyDMI), mean(run_low$herbivore_daily$DailyDMI))
})

test_that("experiment C v2 writes matrix and claim artefacts", {
  skip_on_cran()

  out <- run_experiment_c_aridity_gradient_v2(
    base_dir = tempdir(),
    seeds = 701:703,
    scenario_slug = "experiment_c_aridity_gradient_v2_test"
  )

  expect_true(file.exists(out$matrix_path))
  expect_true(file.exists(out$replicate_path))
  expect_true(file.exists(out$summary_path))
  expect_true(file.exists(out$expected_path))
  expect_true(file.exists(out$claims_path))
  expect_true(file.exists(out$summary_units_path))
  expect_true(file.exists(out$expected_units_path))
  expect_true(file.exists(out$figure_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))
  expect_true(any(out$claim_status$experiment_id == "experiment_c_v2"))
})

test_that("metric units registry resolves required metrics", {
  registry <- read_metric_units_registry_v1()
  expect_true(nrow(registry) > 5L)

  resolved <- resolve_metric_units_v1(c("mean_daily_dmi", "delta_total_shoot_biomass_kg"), registry = registry)
  expect_equal(nrow(resolved), 2L)
  expect_true(all(c("unit", "description", "sign_convention") %in% names(resolved)))
})
