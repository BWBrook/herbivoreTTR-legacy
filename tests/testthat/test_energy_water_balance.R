make_test_herbivore <- function(MRT = 4) {
  herb <- init_herbivore(mass = 5e5, MRT = MRT)
  herb$digestion$bleaf <- rep(2, MRT)
  herb$digestion$bstem <- rep(1, MRT)
  herb$digestion$bdef <- rep(0.5, MRT)
  herb$digestion$dc_leaf <- rep(0.2, MRT)
  herb$digestion$dc_stem <- rep(0.1, MRT)
  herb$digestion$dp_leaf <- rep(0.05, MRT)
  herb$digestion$dp_stem <- rep(0.03, MRT)
  herb$digestion$dp_def <- rep(0.02, MRT)
  herb
}

test_that("calc_daily_energy_balance matches manual computation", {
  herb <- init_herbivore(mass = 5e5)
  herb$intake_PE_day <- 1500
  herb$intake_NPE_day <- 3000
  herb$distance_moved <- 1000
  mass_kg <- herb$mass / 1000
  maintenance_cost <- CONSTANTS$ENERGY_MAINTENANCE_A * (mass_kg ^ CONSTANTS$ENERGY_MAINTENANCE_B)
  locomotion_cost <- (herb$distance_moved / 1000) *
    (CONSTANTS$ICL_A * (mass_kg ^ CONSTANTS$ICL_B)) / 100
  expected <- herb$energy_balance + 4500 - (maintenance_cost + locomotion_cost)
  updated <- calc_daily_energy_balance(herb)
  expect_equal(updated$energy_balance, expected)
})

test_that("check_daily_water_balance adds drinking distance penalty", {
  herb <- init_herbivore(mass = 5e5)
  herb$distance_moved <- 0
  herb$daily_water_requirement <- 100
  herb$metabolic_water_day <- 20
  herb$intake_water_forage <- 10
  res <- check_daily_water_balance(herb)
  expect_equal(res$intake_water_drinking, 70)
  expect_equal(res$distance_moved, CONSTANTS$DIST_TO_WATER)
  expect_equal(
    res$water_balance,
    20 + 10 + 70 - 100
  )

  res$metabolic_water_day <- 200
  res$intake_water_forage <- 0
  res2 <- check_daily_water_balance(res)
  expect_equal(res2$intake_water_drinking, 0)
  expect_equal(res2$distance_moved, res$distance_moved) # unchanged when no deficit
})

test_that("reset_daily_variables clears daily trackers and recomputes gut content", {
  herb <- make_test_herbivore(MRT = 4)
  herb$intake_total_day <- 500
  herb$intake_water_forage <- 40
  herb$metabolic_water_day <- 10
  herb$gut_content <- 999
  herb$behaviour <- "EATING"
  res <- reset_daily_variables(herb)
  expect_equal(res$intake_total_day, 0)
  expect_equal(res$intake_water_forage, 0)
  expect_equal(res$metabolic_water_day, 0)
  expect_equal(res$behaviour, "MOVING")
  expected_gut <- sum(res$digestion$bleaf + res$digestion$bstem + res$digestion$bdef)
  expect_equal(res$gut_content, expected_gut)
})

test_that("hourly_digestion_step shifts queues and updates intakes", {
  herb <- make_test_herbivore(MRT = 3)
  before_carbs <- herb$intake_digest_carbs_day
  before_protein <- herb$intake_digest_protein_day
  res <- hourly_digestion_step(herb)
  expect_gt(res$intake_digest_carbs_day, before_carbs)
  expect_gt(res$intake_digest_protein_day, before_protein)
  expect_equal(res$digestion$bleaf[1], 0)
  expect_equal(res$digestion$bleaf[3], 2)
})

test_that("update_gut_content sums digestion biomass", {
  herb <- make_test_herbivore(MRT = 2)
  herb$digestion$bleaf <- c(3, 1)
  herb$digestion$bstem <- c(2, 0)
  herb$digestion$bdef <- c(1, 1)
  res <- update_gut_content(herb)
  expect_equal(res$gut_content, 3 + 1 + 2 + 0 + 1 + 1)
})
