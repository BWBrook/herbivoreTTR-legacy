## Internals available via helper-ttr.R (source_all_R)

test_that("herbivore_eat converts kg intake to g in gut and reduces plant in kg", {
  # Single plant setup
  plants <- data.frame(
    plant_id = 1L,
    xcor = 0, ycor = 0,
    ms = 2.0, mr = 1.0, bdef = 0.2, height = 1.0,
    cs = 1.0, cr = 0.5, ns = 0.1, nr = 0.05,
    bleaf = 1.5, bstem = 0.3
  )
  herb <- init_herbivore(mass = 5e5)
  herb$xcor <- 0; herb$ycor <- 0
  herb$selected_plant_id <- 1L
  herb$behaviour <- "EATING"
  # Generous capacity; handling_time moderate
  herb$gut_capacity <- 1e6  # g
  herb$handling_time <- 1   # min/g
  herb$bite_size <- 100     # g
  before_ms <- plants$ms
  res <- herbivore_eat(herb, plants)
  after_ms <- res$plants$ms
  expect_lt(after_ms, before_ms)
  # Gut content equals sum of digestion vectors (g)
  expect_equal(res$herbivore$gut_content,
               sum(res$herbivore$digestion$bleaf) + sum(res$herbivore$digestion$bstem) + sum(res$herbivore$digestion$bdef))
  expect_true(res$herbivore$gut_content >= 0)
})

test_that("browser and mixed feeders exclude unreachable plants", {
  plants <- data.frame(
    plant_id = 1:2,
    xcor = c(0, 1), ycor = c(0, 1),
    ms = c(1, 1), mr = c(1, 1), bdef = c(0, 0), height = c(3, 1),
    cs = c(0.5, 0.5), cr = c(0.5, 0.5), ns = c(0.05, 0.05), nr = c(0.05, 0.05),
    bleaf = c(0.8, 0.8), bstem = c(0.2, 0.2)
  )
  browser <- init_herbivore(mass = 5e5, herb_type = 1)
  browser$xcor <- 0; browser$ycor <- 0
  browser_range <- get_plants_within_range(browser, plants)
  expect_true(all(browser_range$plant_id != 1L))

  mixed <- init_herbivore(mass = 5e5, herb_type = 2)
  mixed$xcor <- 0; mixed$ycor <- 0
  mixed_range <- get_plants_within_range(mixed, plants)
  # Plant 1 has height 3 -> LEAF_HEIGHT * 3 > BROWSE_HEIGHT (2) -> excluded
  expect_true(all(mixed_range$plant_id != 1L))
})

test_that("herbivore_step calls eat and updates kg/g consistently", {
  plants <- data.frame(
    plant_id = 1L,
    xcor = 0, ycor = 0,
    ms = 2.0, mr = 1.0, bdef = 0.1, height = 1.0,
    cs = 1.0, cr = 0.5, ns = 0.1, nr = 0.05,
    bleaf = 1.8, bstem = 0.1
  )
  herb <- init_herbivore(mass = 5e5)
  herb$xcor <- 0; herb$ycor <- 0
  herb$selected_plant_id <- 1L
  herb$behaviour <- "EATING"
  herb$gut_capacity <- 2000  # g
  herb$handling_time <- 1    # min/g
  herb$bite_size <- 100      # g
  res <- herbivore_step(herb, plants)
  expect_true(res$plants$ms <= plants$ms)
  expect_true(res$herbivore$gut_content <= res$herbivore$gut_capacity + CONSTANTS$TOLERANCE)
})
