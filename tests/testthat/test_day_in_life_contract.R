test_that("foraging mode resolver validates supported levels", {
  expect_equal(resolve_foraging_mode(list()), "nutrient_targeting")
  expect_equal(resolve_foraging_mode(list(foraging_mode = "nutrient_targeting")), "nutrient_targeting")
  expect_equal(resolve_foraging_mode(list(foraging_mode = "energy_only")), "energy_only")
  expect_equal(resolve_foraging_mode(list(foraging_mode = "invalid_mode")), "nutrient_targeting")
})

test_that("calc_plant_tastiness changes ranking between nutrient and energy-only modes", {
  balanced_ns <- CONSTANTS$DP_TO_DC_TARGET * CONSTANTS$N_TO_PROTEIN * 0.4 * CONSTANTS$PROP_DIGEST_SC
  high_ratio_ns <- 2 * CONSTANTS$N_TO_PROTEIN * 0.6 * CONSTANTS$PROP_DIGEST_SC

  plants <- data.frame(
    plant_id = c(1L, 2L),
    veg_type = c(0L, 0L),
    height = c(1, 1),
    ms = c(4, 8),
    bdef = c(0.05, 0.05),
    distance = c(2, 2),
    cs = c(0.4, 0.6),
    ns = c(balanced_ns, high_ratio_ns),
    stringsAsFactors = FALSE
  )

  herb <- init_herbivore(mass = 5e5, herb_type = 2L)
  herb$foraging_mode <- "nutrient_targeting"
  nutrient_scores <- calc_plant_tastiness(plants, herb, CONSTANTS$DP_TO_DC_TARGET)

  herb$foraging_mode <- "energy_only"
  energy_scores <- calc_plant_tastiness(plants, herb, CONSTANTS$DP_TO_DC_TARGET)

  expect_gt(nutrient_scores[[1]], nutrient_scores[[2]])
  expect_gt(energy_scores[[2]], energy_scores[[1]])
})

test_that("day-in-life comparison artefacts are deterministic and mode-distinct", {
  out_a <- run_day_in_life_comparison(seed = 37L, minute_limit = 360L, base_dir = tempdir())
  out_b <- run_day_in_life_comparison(seed = 37L, minute_limit = 360L, base_dir = tempdir())

  expect_true(file.exists(out_a$comparison_path))
  expect_true(file.exists(out_a$report_path))
  expect_true(file.exists(out_a$manifest_path))
  expect_true(file.exists(out_a$nutrient_run$summary_path))
  expect_true(file.exists(out_a$energy_run$summary_path))

  expect_identical(out_a$comparison, out_b$comparison)

  cmp <- out_a$comparison
  expect_equal(cmp$value[cmp$metric == "modes_measurably_different"], 1)
  expect_gt(
    cmp$value[cmp$metric == "nutrient_balanced_intake_share"],
    cmp$value[cmp$metric == "energy_balanced_intake_share"]
  )

  nutrient_hourly <- utils::read.csv(out_a$nutrient_run$hourly_path)
  expect_true(all(is.finite(nutrient_hourly$balanced_consumed_kg)))
  expect_true(all(is.finite(nutrient_hourly$high_ratio_consumed_kg)))
  expect_true(all(nutrient_hourly$selected_group %in% c("balanced", "high_ratio", "none")))
})
