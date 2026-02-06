## Internals available via helper-ttr.R (source_all_R)

make_plants <- function() data.frame(
  plant_id = 1:2,
  veg_type = c(0, 2),
  height = c(1.0, 2.0),
  bleaf = c(1.2, 0.8),
  bstem = c(0.2, 0.5),
  bdef  = c(0.1, 0.1),
  ms = c(1.5, 1.4), ns = c(0.05, 0.06), cs = c(0.6, 0.55),
  mr = c(1.0, 1.1), cr = c(0.4, 0.45), nr = c(0.04, 0.045)
)

make_herb <- function() list(
  herbivore_id = "herbivore_test",
  herb_type = 0, mass = 5e5, xcor = 0, ycor = 0,
  distance_moved = 10,
  intake_PE_day = 100, intake_NPE_day = 300,
  intake_total_day = 500, intake_water_forage = 200,
  intake_total = 1000,
  water_balance = 0, energy_balance = 0
)

test_that("write_plants_daily writes semicolon CSV with correct header order", {
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)
  expect_silent(write_plants_daily(make_plants(), day = 1, year = 1, path = f, run_id = "run_test"))
  hdr <- readLines(f, n = 1L, warn = FALSE)
  expect_identical(hdr, paste(required_plant_output_columns_v1(), collapse = ";"))
  body <- readLines(f, warn = FALSE)
  expect_true(all(grepl(";", body)))
  expect_false(any(grepl("NA|NaN|Inf", body)))
})

test_that("write_herbivores_daily writes semicolon CSV with correct header order", {
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)
  expect_silent(write_herbivores_daily(make_herb(), day = 1, year = 1, path = f, run_id = "run_test"))
  hdr <- readLines(f, n = 1L, warn = FALSE)
  expect_identical(hdr, paste(required_herbivore_output_columns_v1(), collapse = ";"))
  body <- readLines(f, warn = FALSE)
  expect_true(all(grepl(";", body)))
  expect_false(any(grepl("NA|NaN|Inf", body)))
})

test_that("writers error on missing columns/fields", {
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)
  plants_bad <- make_plants()[, setdiff(names(make_plants()), "veg_type"), drop = FALSE]
  expect_error(write_plants_daily(plants_bad, 1, 1, f, run_id = "run_test"))
  herb_bad <- make_herb(); herb_bad$mass <- NA_real_
  expect_error(write_herbivores_daily(herb_bad, 1, 1, f, run_id = "run_test"))
})
