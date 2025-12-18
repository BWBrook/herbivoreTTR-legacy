test_that("intake schedules digestible carbs/protein leading to positive energy", {
  skip_on_cran()
  # Single plant and herbivore with MRT=1 so digestion happens next hour call
  plants <- data.frame(
    plant_id = 1L,
    xcor = 0, ycor = 0,
    ms = 2.0, mr = 1.0, bdef = 0.1, height = 1.0,
    cs = 1.0, cr = 0.5, ns = 0.1, nr = 0.05,
    bleaf = 1.8, bstem = 0.1
  )
  herb <- init_herbivore(mass = 5e5, MRT = 1)
  herb$xcor <- 0; herb$ycor <- 0
  herb$selected_plant_id <- 1L
  herb$behaviour <- "EATING"
  # Make intake not limited by capacity/bite
  herb$gut_capacity <- 1e9
  herb$handling_time <- 1
  herb$bite_size <- 1000
  before_energy <- herb$intake_PE_day + herb$intake_NPE_day
  res <- herbivore_eat(herb, plants)
  # One hour digestion should incorporate scheduled dc/dp in slot MRT
  res$herbivore <- hourly_digestion_step(res$herbivore)
  after_energy <- res$herbivore$intake_PE_day + res$herbivore$intake_NPE_day
  expect_gt(after_energy, before_energy)
})

test_that("daily run after spin-up yields nonzero energy with MRT=1", {
  skip_on_cran()
  sim <- init_simulation()
  sim$herbivore$MRT <- 1
  # run a day beyond spin-up to allow herbivory
  spinup_days <- CONSTANTS$SPIN_UP_LENGTH * nrow(sim$conditions)
  day0 <- spinup_days + 1L
  res <- run_daily_herbivore_simulation(sim$herbivore, sim$plants, sim$conditions,
                                        day_of_simulation = day0, minute_limit = 60)
  expect_true(res$herbivore$intake_PE_day + res$herbivore$intake_NPE_day > 0)
})
