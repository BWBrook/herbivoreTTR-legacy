test_that("tastiness scoring applies functional-type vegetation preferences", {
  plants <- data.frame(
    plant_id = 1:2,
    veg_type = c(0L, 2L),
    xcor = c(0, 0),
    ycor = c(0, 0),
    ms = c(5, 5),
    ns = c(0.1, 0.1),
    cs = c(2.0, 2.0),
    bdef = c(0.1, 0.1),
    distance = c(1, 1),
    stringsAsFactors = FALSE
  )

  grazer <- init_herbivore(mass = 5e5, herb_type = 0L)
  browser <- init_herbivore(mass = 5e5, herb_type = 1L)

  grazer_scores <- calc_plant_tastiness(
    plants_in_range = plants,
    herbivore = grazer,
    desired_dp_dc_ratio = CONSTANTS$DP_TO_DC_TARGET
  )
  browser_scores <- calc_plant_tastiness(
    plants_in_range = plants,
    herbivore = browser,
    desired_dp_dc_ratio = CONSTANTS$DP_TO_DC_TARGET
  )

  expect_gt(grazer_scores[[1]], grazer_scores[[2]])
  expect_gt(browser_scores[[2]], browser_scores[[1]])
})

test_that("controlled functional-type scenario yields grazer/browser diet split", {
  out <- run_functional_type_scenario(
    minute_limit = 120L,
    seed = 41L,
    base_dir = tempdir()
  )
  metrics <- out$metrics

  grazer <- metrics[metrics$herb_type == 0L, , drop = FALSE]
  browser <- metrics[metrics$herb_type == 1L, , drop = FALSE]

  expect_equal(nrow(grazer), 1L)
  expect_equal(nrow(browser), 1L)

  expect_true(grazer$total_intake_kg > 0)
  expect_true(browser$total_intake_kg > 0)

  expect_gt(grazer$grass_share, browser$grass_share + 0.2)
  expect_gt(browser$tree_share, grazer$tree_share + 0.2)
  expect_equal(browser$unreachable_tree_intake_kg, 0, tolerance = 1e-12)
})

test_that("functional-type scenario is deterministic under fixed seed", {
  out_a <- run_functional_type_scenario(
    minute_limit = 60L,
    seed = 99L,
    base_dir = tempdir()
  )
  out_b <- run_functional_type_scenario(
    minute_limit = 60L,
    seed = 99L,
    base_dir = tempdir()
  )

  expect_identical(out_a$metrics, out_b$metrics)
})
