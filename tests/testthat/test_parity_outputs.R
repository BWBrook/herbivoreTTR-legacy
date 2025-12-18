test_that("parity snapshots stay in sync with pipeline outputs", {
  skip_on_cran()
  withr::local_envvar(TARGETS_PROGRESS = "false")
  targets::tar_make(
    names = c("plants_day1_csv", "herb_day1_csv"),
    callr_function = NULL
  )

  plants_path <- targets::tar_read(plants_day1_csv)
  herb_path <- targets::tar_read(herb_day1_csv)
  current_plants <- utils::read.csv(plants_path, sep = ";")
  current_herb <- utils::read.csv(herb_path, sep = ";")

  parity_dir <- testthat::test_path("..", "..", "inst", "extdata", "parity")
  ref_plants <- utils::read.csv(file.path(parity_dir, "plants_day_sample.csv"))
  ref_herb <- utils::read.csv(file.path(parity_dir, "herb_day_sample.csv"))

  expect_equal(head(current_plants, nrow(ref_plants)), ref_plants)
  expect_equal(current_herb, ref_herb)
})
