test_that("summarise_plant_day_states validates required inputs", {
  expect_error(
    summarise_plant_day_states(NULL, data.frame()),
    class = "herbivoreTTR_forensics_missing_plants"
  )
  expect_error(
    summarise_plant_day_states(data.frame(), NULL),
    class = "herbivoreTTR_forensics_missing_plants"
  )
})

test_that("summarise_plant_day_states computes deltas and coalesces metadata", {
  plants_start <- data.frame(
    plant_id = c(1L, 2L),
    veg_type = c(0L, 1L),
    xcor = c(10, 20),
    ycor = c(5, 15),
    ms = c(10, 5),
    bleaf = c(4, 2),
    bstem = c(5, 2),
    bdef = c(1, 1),
    stringsAsFactors = FALSE
  )
  plants_end <- data.frame(
    plant_id = c(1L, 3L),
    veg_type = c(0L, 2L),
    xcor = c(10, 30),
    ycor = c(5, 25),
    ms = c(7.5, 9),
    bleaf = c(3.5, 4),
    bstem = c(3.0, 4),
    bdef = c(1.0, 1),
    stringsAsFactors = FALSE
  )

  out <- summarise_plant_day_states(plants_start, plants_end, tolerance = 1e-6)

  expect_equal(nrow(out), 3L)
  expect_true(all(c("delta_ms", "delta_bleaf", "delta_bstem", "delta_bdef", "was_eaten") %in% names(out)))

  row1 <- out[out$plant_id == 1L, , drop = FALSE]
  expect_equal(row1$delta_ms, -2.5)
  expect_true(row1$was_eaten)
  expect_equal(row1$veg_type, 0L)
  expect_equal(row1$xcor, 10)
  expect_equal(row1$ycor, 5)

  row3 <- out[out$plant_id == 3L, , drop = FALSE]
  expect_equal(row3$veg_type, 2L)
  expect_equal(row3$xcor, 30)
  expect_equal(row3$ycor, 25)
})

test_that("build_daily_record_table handles empty and sparse records", {
  expect_equal(nrow(build_daily_record_table(list())), 0L)

  daily_record <- list(
    list(minute = 1L, behaviour = "MOVING", selected_plant_id = NULL),
    NULL,
    list(minute = 2L, behaviour = NULL, selected_plant_id = 7L)
  )

  out <- build_daily_record_table(daily_record)
  expect_equal(nrow(out), 2L)
  expect_true("minute" %in% names(out))
  expect_true("behaviour" %in% names(out))
  expect_true("selected_plant_id" %in% names(out))
  expect_true(is.na(out$selected_plant_id[1]))
  expect_true(is.na(out$behaviour[2]))
  expect_equal(out$selected_plant_id[2], 7L)
})
