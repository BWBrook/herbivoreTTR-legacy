build_portal_test_plan_v2 <- function(mode,
                                      base_dir,
                                      scenario_reference = "canonical_smoke_v1") {
  plan <- portal_plan_default_v2()
  plan$plan_id <- sprintf("portal_test_%s", mode)

  plan$execution$mode <- mode
  plan$execution$base_dir <- base_dir
  plan$execution$dry_run <- FALSE
  plan$execution$write_outputs <- FALSE
  plan$execution$backend <- "internal_ttr"
  plan$execution$compiled$enabled <- "auto"
  plan$execution$compiled$strict <- FALSE
  plan$execution$compiled$verbose <- FALSE
  plan$execution$parallel$execution_mode <- "serial"
  plan$execution$parallel$workers <- 1L
  plan$execution$parallel$reserve_cores <- 0L

  plan$scenario$source <- "reference"
  plan$scenario$reference <- scenario_reference
  plan$scenario$overrides <- list(
    runtime = list(days = 2, minute_limit = 30),
    climate = list(mode = "flat")
  )

  plan$outputs$render_report <- FALSE
  plan$outputs$report_formats <- c("html")
  plan$outputs$include_interactive <- FALSE

  if (identical(mode, "sensitivity")) {
    plan$sensitivity$enabled <- TRUE
    plan$sensitivity$design <- "one_at_a_time"
    plan$sensitivity$keep_baseline <- TRUE
    plan$sensitivity$parameters <- list(
      list(path = "runtime.days", values = c(2, 3)),
      list(path = "runtime.forage_access_scale", values = c(0.7, 1.0))
    )
  } else {
    plan$sensitivity$enabled <- FALSE
    plan$sensitivity$parameters <- list()
  }

  validate_portal_plan_v2(plan)
}

test_that("portal dry-run resolves scenario metadata without execution", {
  plan <- build_portal_test_plan_v2(mode = "single", base_dir = tempdir())
  out <- run_portal_plan_v2(plan = plan, dry_run = TRUE)

  expect_true(isTRUE(out$dry_run))
  expect_identical(out$mode, "single")
  expect_identical(out$scenario_id, "canonical_smoke_v1")
  expect_equal(out$days, 2L)
  expect_equal(out$minute_limit, 30L)
})

test_that("single explicit portal run writes expected tables, figures, and manifest", {
  base_dir <- tempfile("portal_runner_single_")
  dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
  plan <- build_portal_test_plan_v2(mode = "single", base_dir = base_dir)
  out <- run_portal_plan_v2(plan = plan)

  expect_identical(out$mode, "single")
  expect_true(file.exists(out$run_index_path))
  expect_true(file.exists(out$daily_path))
  expect_true(file.exists(out$endpoint_path))
  expect_true(file.exists(out$sanity_path))
  expect_true(file.exists(out$acceptance_path))
  expect_true(file.exists(out$manifest_path))

  expect_true(length(out$figure_paths) >= 2L)
  expect_true(all(file.exists(unname(out$figure_paths))))

  sanity <- utils::read.csv(out$sanity_path, stringsAsFactors = FALSE)
  expect_equal(nrow(sanity), 1L)
  expect_equal(sanity$daily_output_non_finite_count, 0)
  expect_equal(sanity$structure_non_finite_count, 0)
  expect_equal(sanity$negative_biomass_violations, 0)
  expect_equal(sanity$gut_capacity_violations, 0)

  acceptance <- utils::read.csv(out$acceptance_path, stringsAsFactors = FALSE)
  expect_equal(nrow(acceptance), 4L)
  expect_true(all(acceptance$acceptance_profile == "standard"))
  expect_true(all(acceptance$pass))

  manifest <- jsonlite::fromJSON(out$manifest_path, simplifyVector = TRUE)
  expect_identical(manifest$daily_output_kind, "explicit_individual")
  expect_identical(manifest$execution_context$backend_requested, "internal_ttr")
  expect_true(manifest$execution_context$compiled_enabled %in% c("auto", "true", "false"))
  expect_true(manifest$execution_context$compiled_kernel_policy %in% c("resistance_only", "all_available"))
})

test_that("single implicit-pressure portal run writes pressure-aware summaries", {
  base_dir <- tempfile("portal_runner_implicit_")
  dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
  plan <- build_portal_test_plan_v2(
    mode = "single",
    base_dir = base_dir,
    scenario_reference = "implicit_stocking_v1"
  )
  out <- run_portal_plan_v2(plan = plan)

  daily <- utils::read.csv(out$daily_path, stringsAsFactors = FALSE)
  endpoint <- utils::read.csv(out$endpoint_path, stringsAsFactors = FALSE)
  sanity <- utils::read.csv(out$sanity_path, stringsAsFactors = FALSE)
  acceptance <- utils::read.csv(out$acceptance_path, stringsAsFactors = FALSE)
  manifest <- jsonlite::fromJSON(out$manifest_path, simplifyVector = TRUE)

  expect_true(all(daily$daily_output_kind == "implicit_pressure"))
  expect_true(all(c(
    "total_pressure_dmi",
    "total_pressure_dist_m",
    "effective_visits_per_day"
  ) %in% names(daily)))
  expect_false(any(c("mean_energy_balance", "mean_body_condition_index") %in% names(daily)))

  expect_true(all(endpoint$daily_output_kind == "implicit_pressure"))
  expect_true(all(c("total_pressure_dmi", "effective_visits_per_day") %in% names(endpoint)))
  expect_false(any(c("mean_energy_balance", "mean_body_condition_index") %in% names(endpoint)))

  expect_equal(sanity$daily_output_non_finite_count, 0)
  expect_equal(sanity$structure_non_finite_count, 0)
  expect_equal(sanity$negative_biomass_violations, 0)
  expect_equal(nrow(acceptance), 3L)
  expect_true(all(acceptance$pass))
  expect_identical(manifest$daily_output_kind, "implicit_pressure")
})

test_that("sensitivity portal run writes deterministic design and endpoint bundles", {
  base_dir <- tempfile("portal_runner_sensitivity_")
  dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
  plan <- build_portal_test_plan_v2(mode = "sensitivity", base_dir = base_dir)
  out <- run_portal_plan_v2(plan = plan)

  expect_identical(out$mode, "sensitivity")
  expect_true(file.exists(out$run_index_path))
  expect_true(file.exists(out$design_path))
  expect_true(file.exists(out$endpoint_path))
  expect_true(file.exists(out$sanity_path))
  expect_true(file.exists(out$acceptance_path))
  expect_true(file.exists(out$manifest_path))

  design <- utils::read.csv(out$design_path, stringsAsFactors = FALSE)
  expect_true("baseline" %in% design$run_label)
  expect_equal(nrow(design), 5L)

  run_index <- utils::read.csv(out$run_index_path, stringsAsFactors = FALSE)
  expect_equal(nrow(run_index), 5L)
  expect_identical(run_index$run_index, as.integer(seq_len(nrow(run_index))))
  expect_true(all(run_index$daily_output_kind == "explicit_individual"))

  endpoint <- utils::read.csv(out$endpoint_path, stringsAsFactors = FALSE)
  expect_true(all(c(
    "parameter_path",
    "parameter_value",
    "delta_final_total_shoot_biomass_kg",
    "delta_mean_daily_dmi"
  ) %in% names(endpoint)))
  baseline_row <- endpoint[endpoint$run_label == "baseline", , drop = FALSE]
  expect_equal(nrow(baseline_row), 1L)
  expect_equal(baseline_row$delta_final_total_shoot_biomass_kg, 0)
  expect_equal(baseline_row$delta_mean_daily_dmi, 0)

  sanity <- utils::read.csv(out$sanity_path, stringsAsFactors = FALSE)
  expect_true(all(sanity$daily_output_non_finite_count == 0))
  expect_true(all(sanity$structure_non_finite_count == 0))
  acceptance <- utils::read.csv(out$acceptance_path, stringsAsFactors = FALSE)
  expect_equal(nrow(acceptance), nrow(run_index) * 4L)
  expect_true(all(acceptance$acceptance_profile == "standard"))
  expect_true(all(acceptance$pass))

  expect_true(any(grepl("sensitivity_effects_runtime_days", basename(unname(out$figure_paths)))))
  expect_true(any(grepl("sensitivity_effects_runtime_forage_access_scale", basename(unname(out$figure_paths)))))
})

test_that("acceptance profiles add demo-specific ecological checks for explicit runs only", {
  base_dir <- tempfile("portal_runner_acceptance_")
  dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
  plan <- build_portal_test_plan_v2(mode = "single", base_dir = base_dir)
  out <- run_portal_plan_v2(plan = plan)
  run_result <- out$run_results[[1]]

  balanced <- portal_acceptance_rows_for_run_v1(run_result, acceptance_profile = "balanced_demo")
  stress <- portal_acceptance_rows_for_run_v1(run_result, acceptance_profile = "stress_demo")

  expect_true("final_body_condition_at_least_0_5" %in% balanced$check_id)
  expect_true("final_mean_energy_balance_at_least_minus_1e5" %in% balanced$check_id)
  expect_true("stress_fraction_at_most_1_0" %in% balanced$check_id)
  expect_true("final_body_condition_at_most_0_05" %in% stress$check_id)
  expect_true("final_mean_energy_balance_at_most_minus_2e5" %in% stress$check_id)
  expect_true("stress_fraction_at_least_0_9" %in% stress$check_id)

  implicit_plan <- build_portal_test_plan_v2(
    mode = "single",
    base_dir = tempfile("portal_runner_acceptance_implicit_"),
    scenario_reference = "implicit_stocking_v1"
  )
  implicit_out <- run_portal_plan_v2(plan = implicit_plan)
  implicit_run_result <- implicit_out$run_results[[1]]
  implicit_balanced <- portal_acceptance_rows_for_run_v1(implicit_run_result, acceptance_profile = "balanced_demo")
  expect_false(any(grepl("body_condition|energy_balance|stress_fraction", implicit_balanced$check_id)))
})

test_that("HTML-only portal report rendering does not require PDF output", {
  skip_if(!nzchar(Sys.which("quarto")), "Quarto not available in this test environment.")

  base_dir <- tempfile("portal_runner_report_")
  dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
  plan <- build_portal_test_plan_v2(mode = "single", base_dir = base_dir)
  out <- run_portal_plan_v2(plan = plan)

  report <- render_portal_report_v1(run_dir = out$run_dir, report_formats = c("html"))
  expect_true(file.exists(report$html_path))
  expect_true(is.na(report$pdf_path))
  expect_false(file.exists(file.path(out$run_dir, "reports", "ecologist_report_v1.pdf")))
})

test_that("portal strict compiled mode fails when compiled helper unavailable", {
  base_dir <- tempfile("portal_runner_compiled_strict_")
  dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
  plan <- build_portal_test_plan_v2(mode = "single", base_dir = base_dir)
  plan$execution$compiled$enabled <- "true"
  plan$execution$compiled$strict <- TRUE

  old_force <- Sys.getenv("HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE", unset = "0")
  on.exit(Sys.setenv(HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE = old_force), add = TRUE)
  Sys.setenv(HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE = "1")

  expect_error(
    run_portal_plan_v2(plan = plan),
    class = "herbivoreTTR_portal_compiled_unavailable"
  )
})

test_that("portal backend and compiled fallback metadata are recorded in manifest", {
  base_dir <- tempfile("portal_runner_compiled_manifest_")
  dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
  plan <- build_portal_test_plan_v2(mode = "single", base_dir = base_dir)
  plan$execution$backend <- "internal_ttr_compiled"
  plan$execution$compiled$enabled <- "true"
  plan$execution$compiled$kernel_policy <- "resistance_only"
  plan$execution$compiled$strict <- FALSE
  plan$execution$compiled$verbose <- TRUE

  old_force <- Sys.getenv("HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE", unset = "0")
  on.exit(Sys.setenv(HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE = old_force), add = TRUE)
  Sys.setenv(HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE = "1")

  expect_warning(
    out <- run_portal_plan_v2(plan = plan),
    regexp = "Compiled TTR kernel requested but unavailable"
  )

  manifest <- jsonlite::fromJSON(out$manifest_path, simplifyVector = TRUE)
  params <- manifest$execution_context
  expect_identical(params$backend_requested, "internal_ttr_compiled")
  expect_true(params$compiled_requested)
  expect_identical(params$compiled_kernel_policy, "resistance_only")
  expect_true(params$compiled_last_fallback_used)
  expect_identical(params$compiled_last_engine, "r")
})
