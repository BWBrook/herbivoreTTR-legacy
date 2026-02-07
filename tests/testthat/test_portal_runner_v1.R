build_portal_test_plan_v1 <- function(mode,
                                      base_dir) {
  plan <- portal_plan_default_v1()
  plan$plan_id <- sprintf("portal_test_%s", mode)

  plan$execution$mode <- mode
  plan$execution$base_dir <- base_dir
  plan$execution$dry_run <- FALSE
  plan$execution$write_outputs <- FALSE
  plan$execution$parallel$execution_mode <- "serial"
  plan$execution$parallel$workers <- 1L
  plan$execution$parallel$reserve_cores <- 0L

  plan$scenario$source <- "reference"
  plan$scenario$reference <- "canonical_smoke_v1"
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
      list(path = "runtime.days", values = c(2, 3))
    )
  } else {
    plan$sensitivity$enabled <- FALSE
    plan$sensitivity$parameters <- list()
  }

  validate_portal_plan_v1(plan)
}

test_that("portal dry-run resolves scenario metadata without execution", {
  plan <- build_portal_test_plan_v1(mode = "single", base_dir = tempdir())
  out <- run_portal_plan_v1(plan = plan, dry_run = TRUE)

  expect_true(isTRUE(out$dry_run))
  expect_identical(out$mode, "single")
  expect_identical(out$scenario_id, "canonical_smoke_v1")
  expect_equal(out$days, 2L)
  expect_equal(out$minute_limit, 30L)
})

test_that("single portal run writes expected tables, figures, and manifest", {
  base_dir <- tempfile("portal_runner_single_")
  dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
  plan <- build_portal_test_plan_v1(mode = "single", base_dir = base_dir)
  out <- run_portal_plan_v1(plan = plan)

  expect_identical(out$mode, "single")
  expect_true(file.exists(out$run_index_path))
  expect_true(file.exists(out$daily_path))
  expect_true(file.exists(out$endpoint_path))
  expect_true(file.exists(out$sanity_path))
  expect_true(file.exists(out$manifest_path))

  expect_true(length(out$figure_paths) >= 2L)
  expect_true(all(file.exists(unname(out$figure_paths))))

  sanity <- utils::read.csv(out$sanity_path, stringsAsFactors = FALSE)
  expect_equal(nrow(sanity), 1L)
  expect_equal(sanity$herbivore_non_finite_count, 0)
  expect_equal(sanity$structure_non_finite_count, 0)
  expect_equal(sanity$negative_biomass_violations, 0)
  expect_equal(sanity$gut_capacity_violations, 0)
})

test_that("sensitivity portal run writes deterministic design and endpoint bundles", {
  base_dir <- tempfile("portal_runner_sensitivity_")
  dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
  plan <- build_portal_test_plan_v1(mode = "sensitivity", base_dir = base_dir)
  out <- run_portal_plan_v1(plan = plan)

  expect_identical(out$mode, "sensitivity")
  expect_true(file.exists(out$run_index_path))
  expect_true(file.exists(out$design_path))
  expect_true(file.exists(out$endpoint_path))
  expect_true(file.exists(out$sanity_path))
  expect_true(file.exists(out$manifest_path))

  design <- utils::read.csv(out$design_path, stringsAsFactors = FALSE)
  expect_true("baseline" %in% design$run_label)
  expect_equal(nrow(design), 3L)

  run_index <- utils::read.csv(out$run_index_path, stringsAsFactors = FALSE)
  expect_equal(nrow(run_index), 3L)
  expect_identical(run_index$run_index, as.integer(seq_len(nrow(run_index))))

  sanity <- utils::read.csv(out$sanity_path, stringsAsFactors = FALSE)
  expect_true(all(sanity$herbivore_non_finite_count == 0))
  expect_true(all(sanity$structure_non_finite_count == 0))
})

test_that("HTML-only portal report rendering does not require PDF output", {
  skip_if(!nzchar(Sys.which("quarto")), "Quarto not available in this test environment.")

  base_dir <- tempfile("portal_runner_report_")
  dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
  plan <- build_portal_test_plan_v1(mode = "single", base_dir = base_dir)
  out <- run_portal_plan_v1(plan = plan)

  report <- render_portal_report_v1(run_dir = out$run_dir, report_formats = c("html"))
  expect_true(file.exists(report$html_path))
  expect_true(is.na(report$pdf_path))
  expect_false(file.exists(file.path(out$run_dir, "reports", "ecologist_report_v1.pdf")))
})
