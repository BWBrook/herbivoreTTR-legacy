test_that("parameter reference table remains in sync with constants", {
  refs <- parameter_reference_table()

  expect_true(all(c("parameter", "value", "units", "description", "citation") %in% names(refs)))
  expect_true(nrow(refs) >= 10L)
  expect_identical(anyDuplicated(refs$parameter), 0L)
  expect_true(all(refs$parameter %in% names(CONSTANTS)))

  for (i in seq_len(nrow(refs))) {
    nm <- refs$parameter[[i]]
    expect_equal(refs$value[[i]], CONSTANTS[[nm]])
  }
})

test_that("canonical smoke parameters are deterministic and derived from conditions", {
  conditions <- init_conditions(mode = "flat")
  params <- canonical_smoke_parameters(conditions = conditions)

  expect_identical(params$temp_mode, "flat")
  expect_equal(params$veg_types, c(0L, 1L, 2L))
  expect_equal(params$herbivore_mass, 5e5)
  expect_equal(params$minute_limit, 60L)
  expect_equal(params$days, 7L)
  expect_equal(
    params$start_day,
    as.integer(CONSTANTS$SPIN_UP_LENGTH * nrow(conditions) + 1L)
  )
})

test_that("units convention table exposes expected core quantities", {
  units_tbl <- units_conventions_table()
  expect_true(all(c("quantity", "unit", "notes") %in% names(units_tbl)))
  expect_true(any(units_tbl$quantity == "Herbivore body mass"))
  expect_true(any(units_tbl$quantity == "Plant biomass pools"))
  expect_true(any(units_tbl$quantity == "Energy"))
  expect_true(any(units_tbl$quantity == "Water"))
})

test_that("targets pipeline canonical parameter target uses helper defaults", {
  script <- testthat::test_path("..", "..", "_targets.R")
  skip_if_not(file.exists(script), message = "Requires source checkout with _targets.R")

  withr::with_dir(dirname(script), {
    targets::tar_make(
      names = c("conditions", "canonical_scenario_parameters"),
      callr_function = NULL,
      script = basename(script)
    )
  })

  conditions <- withr::with_dir(dirname(script), {
    targets::tar_read(conditions)
  })
  from_pipeline <- withr::with_dir(dirname(script), {
    targets::tar_read(canonical_scenario_parameters)
  })
  from_helper <- canonical_smoke_parameters(conditions = conditions)

  expect_identical(from_pipeline$temp_mode, from_helper$temp_mode)
  expect_equal(from_pipeline$veg_types, from_helper$veg_types)
  expect_equal(from_pipeline$herbivore_mass, from_helper$herbivore_mass)
  expect_equal(from_pipeline$minute_limit, from_helper$minute_limit)
  expect_equal(from_pipeline$start_day, from_helper$start_day)
  expect_equal(from_pipeline$days, from_helper$days)
})
