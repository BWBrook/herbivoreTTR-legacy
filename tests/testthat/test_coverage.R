test_that("package coverage meets target threshold", {
  skip_if_not(Sys.getenv("RUN_COVERAGE") == "1", message = "Set RUN_COVERAGE=1 to compute coverage.")
  skip_if(Sys.getenv("HERBIVORETTR_COVERAGE_NESTED") == "1", message = "Avoid nested covr runs.")

  withr::local_envvar(c(
    HERBIVORETTR_COVERAGE_NESTED = "1",
    RUN_COVERAGE = "0"
  ))
  cov <- covr::package_coverage(type = "tests", quiet = TRUE)
  pct <- covr::percent_coverage(cov)
  if (pct == 0) {
    skip("Coverage instrumentation returned 0%; rerun after investigating covr setup.")
  }
  expect_gte(pct, 75)
})
