test_that("performance guard baseline file is readable and complete", {
  baseline <- read_perf_guard_baseline_v1()
  expect_true(is.data.frame(baseline))
  expect_true(all(c("metric", "max_elapsed_seconds") %in% names(baseline)))
  expect_true(all(baseline$max_elapsed_seconds > 0))
})

test_that("performance guard evaluator flags threshold exceedance", {
  current <- data.frame(
    metric = c("a", "b"),
    elapsed_seconds = c(1.0, 3.0),
    stringsAsFactors = FALSE
  )
  baseline <- data.frame(
    metric = c("a", "b"),
    max_elapsed_seconds = c(1.5, 2.5),
    stringsAsFactors = FALSE
  )

  report <- evaluate_perf_guard_v1(current_metrics = current, baseline = baseline)
  expect_true(report$within_baseline[report$metric == "a"])
  expect_false(report$within_baseline[report$metric == "b"])
})

test_that("run_performance_guard_v1 executes and returns report", {
  skip_on_cran()

  out <- run_performance_guard_v1(
    transport_iterations = 2L,
    tastiness_iterations = 20L,
    enforce_guard = FALSE
  )

  expect_true(is.data.frame(out$current))
  expect_true(is.data.frame(out$report))
  expect_true(all(c("metric", "within_baseline") %in% names(out$report)))
  expect_true(all(out$current$elapsed_seconds > 0))
})
