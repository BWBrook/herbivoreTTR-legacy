test_that("TTR.PGM benchmark harness runs conditionally and writes artefacts", {
  skip_on_cran()

  out <- run_ttr_pgm_overlap_benchmark(base_dir = tempdir())
  expect_true(file.exists(out$internal_path))
  expect_true(file.exists(out$comparison_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))

  summary <- out$comparison
  expect_true("ttr_pgm_available" %in% summary$metric)
  expect_true("ttr_pgm_adapter_ran" %in% summary$metric)
  expect_true(all(is.finite(summary$value)))
})
