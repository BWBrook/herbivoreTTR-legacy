make_sample_plants <- function() {
  data.frame(
    plant_id = 1L,
    veg_type = 0L,
    height = 1,
    bleaf = 2,
    bstem = 0,
    bdef = 0.1,
    ms = 2,
    ns = 0.2,
    cs = 1.5,
    mr = 1.5,
    cr = 0.8,
    nr = 0.1
  )
}

make_sample_herbivore <- function() {
  list(
    herbivore_id = "herbivore_test",
    herb_type = 0L,
    mass = 5e5,
    xcor = 0,
    ycor = 0,
    distance_moved = 0,
    intake_PE_day = 100,
    intake_NPE_day = 200,
    intake_total_day = 5,
    intake_water_forage = 1,
    intake_total = 10,
    water_balance = 0,
    energy_balance = 0
  )
}

test_that("snapshot helpers create directories and return file paths", {
  tmp_dir <- withr::local_tempdir()
  plants <- make_sample_plants()
  herb <- make_sample_herbivore()

  path_plants <- write_plants_snapshot_target(plants, day = 1, base_dir = tmp_dir)
  expect_true(file.exists(path_plants))
  expect_match(basename(path_plants), "plants_day001.csv")

  path_herb <- write_herbivore_snapshot_target(herb, day = 1, base_dir = tmp_dir)
  expect_true(file.exists(path_herb))
  expect_match(basename(path_herb), "herb_day001.csv")
})

test_that("snapshot helpers fail with informative errors when directory unwritable", {
  existing_file <- withr::local_tempfile()
  writeLines("lock", existing_file)
  plants <- make_sample_plants()
  herb <- make_sample_herbivore()

  expect_error(
    write_plants_snapshot_target(plants, day = 2, base_dir = existing_file),
    class = "herbivoreTTR_plants_output_dir_create"
  )
  expect_error(
    write_herbivore_snapshot_target(herb, day = 2, base_dir = existing_file),
    class = "herbivoreTTR_herb_output_dir_create"
  )
})
