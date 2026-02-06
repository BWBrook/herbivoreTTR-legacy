selection_frequency <- function(plants, herbivore, draws = 6000L, seed = 1L) {
  with_optional_seed(seed, {
    scores <- calc_plant_tastiness(
      plants_in_range = plants,
      herbivore = herbivore,
      desired_dp_dc_ratio = CONSTANTS$DP_TO_DC_TARGET
    )
    picked <- vapply(
      seq_len(draws),
      function(i) pick_a_plant(plants, scores),
      integer(1)
    )
    tab <- table(factor(picked, levels = plants$plant_id))
    as.numeric(tab) / draws
  })
}

test_that("plants outside selection constraints receive zero probability", {
  herb <- init_herbivore(mass = 5e5, herb_type = 1L)
  plants <- data.frame(
    plant_id = 1:4,
    veg_type = c(2L, 2L, 2L, 2L),
    height = c(1.0, 1.0, CONSTANTS$BROWSE_HEIGHT / CONSTANTS$LEAF_HEIGHT + 0.5, 1.0),
    ms = c(6, 6, 6, CONSTANTS$MIN_SHOOT / 2),
    ns = c(0.12, 0.12, 0.12, 0.12),
    cs = c(2.5, 2.5, 2.5, 2.5),
    bdef = c(0.1, 0.1, 0.1, 0.1),
    distance = c(2, CONSTANTS$DETECTION_DISTANCE + 2, 2, 2),
    stringsAsFactors = FALSE
  )

  scores <- calc_plant_tastiness(
    plants_in_range = plants,
    herbivore = herb,
    desired_dp_dc_ratio = CONSTANTS$DP_TO_DC_TARGET
  )

  expect_gt(scores[[1]], 0)
  expect_equal(scores[[2]], 0)
  expect_equal(scores[[3]], 0)
  expect_equal(scores[[4]], 0)

  freq <- selection_frequency(plants, herb, draws = 1000L, seed = 42L)
  expect_gt(freq[[1]], 0.99)
  expect_equal(sum(freq[2:4]), 0, tolerance = 1e-12)
})

test_that("higher defence decreases expected selection frequency", {
  herb <- init_herbivore(mass = 5e5, herb_type = 0L)
  plants <- data.frame(
    plant_id = 1:2,
    veg_type = c(0L, 0L),
    height = c(0.8, 0.8),
    ms = c(6, 6),
    ns = c(0.12, 0.12),
    cs = c(2.5, 2.5),
    bdef = c(0.05, 1.25),
    distance = c(2, 2),
    stringsAsFactors = FALSE
  )

  freq <- selection_frequency(plants, herb, draws = 8000L, seed = 92L)

  expect_gt(freq[[1]], freq[[2]])
  expect_gt(freq[[1]] - freq[[2]], 0.2)
})

test_that("greater distance decreases expected selection frequency", {
  herb <- init_herbivore(mass = 5e5, herb_type = 0L)
  plants <- data.frame(
    plant_id = 1:2,
    veg_type = c(0L, 0L),
    height = c(0.8, 0.8),
    ms = c(6, 6),
    ns = c(0.12, 0.12),
    cs = c(2.5, 2.5),
    bdef = c(0.1, 0.1),
    distance = c(1, 9),
    stringsAsFactors = FALSE
  )

  freq <- selection_frequency(plants, herb, draws = 8000L, seed = 93L)

  expect_gt(freq[[1]], freq[[2]])
  expect_gt(freq[[1]] - freq[[2]], 0.2)
})

test_that("selection remains stochastic but deterministic under fixed seed", {
  herb <- init_herbivore(mass = 5e5, herb_type = 0L)
  plants <- data.frame(
    plant_id = 1:3,
    veg_type = c(0L, 0L, 0L),
    height = c(0.8, 0.8, 0.8),
    ms = c(6, 6, 6),
    ns = c(0.12, 0.12, 0.12),
    cs = c(2.5, 2.5, 2.5),
    bdef = c(0.1, 0.2, 0.3),
    distance = c(1, 2, 3),
    stringsAsFactors = FALSE
  )

  freq_a <- selection_frequency(plants, herb, draws = 4000L, seed = 11L)
  freq_b <- selection_frequency(plants, herb, draws = 4000L, seed = 11L)
  freq_c <- selection_frequency(plants, herb, draws = 4000L, seed = 12L)

  expect_equal(freq_a, freq_b)
  expect_false(isTRUE(all.equal(freq_a, freq_c)))
  expect_gt(sum(freq_a > 0), 1)
})

test_that("selection-contract scenario artefact is deterministic and directional", {
  out_a <- run_selection_contract_scenario(seed = 7L, n_draws = 3000L, base_dir = tempdir())
  out_b <- run_selection_contract_scenario(seed = 7L, n_draws = 3000L, base_dir = tempdir())

  expect_identical(out_a$summary, out_b$summary)
  expect_true(file.exists(out_a$candidates_path))
  expect_true(file.exists(out_a$frequency_path))
  expect_true(file.exists(out_a$summary_path))
  expect_true(file.exists(out_a$manifest_path))

  summary <- out_a$summary
  expect_gt(summary$value[summary$metric == "defence_low_minus_high_frequency"], 0)
  expect_gt(summary$value[summary$metric == "distance_near_minus_far_frequency"], 0)
  expect_equal(
    summary$value[summary$metric == "constraint_invalid_total_frequency"],
    0,
    tolerance = 1e-12
  )
})
