test_that("v0 fixtures migrate to schema v1 with run/herbivore identifiers", {
  migration_dir <- system.file("extdata", "migration_v0", package = "herbivoreTTR")
  skip_if_not(nzchar(migration_dir) && dir.exists(migration_dir), "migration fixtures unavailable")

  plants_v0 <- utils::read.csv(
    file.path(migration_dir, "plants_day_sample_v0.csv"),
    stringsAsFactors = FALSE
  )
  herb_v0 <- utils::read.csv(
    file.path(migration_dir, "herb_day_sample_v0.csv"),
    stringsAsFactors = FALSE
  )

  run_id <- "run_migration_test"
  plants_v1 <- migrate_plants_output_v0_to_v1(plants_v0, run_id = run_id)
  herb_v1 <- migrate_herbivore_output_v0_to_v1(herb_v0, run_id = run_id, herbivore_id = "herb_migration")

  expect_identical(colnames(plants_v1), required_plant_output_columns_v1())
  expect_identical(colnames(herb_v1), required_herbivore_output_columns_v1())
  expect_true(all(plants_v1$RunID == run_id))
  expect_true(all(herb_v1$RunID == run_id))
  expect_true(all(herb_v1$HerbivoreID == "herb_migration"))
  expect_true(all(plants_v1$SchemaVersion == output_schema_version()))
  expect_true(all(herb_v1$SchemaVersion == output_schema_version()))
})

test_that("CSV migration helper writes semicolon-delimited schema v1 outputs", {
  migration_dir <- system.file("extdata", "migration_v0", package = "herbivoreTTR")
  skip_if_not(nzchar(migration_dir) && dir.exists(migration_dir), "migration fixtures unavailable")

  plants_in <- file.path(migration_dir, "plants_day_sample_v0.csv")
  herb_in <- file.path(migration_dir, "herb_day_sample_v0.csv")

  plants_out <- tempfile(fileext = ".csv")
  herb_out <- tempfile(fileext = ".csv")
  on.exit(unlink(c(plants_out, herb_out)), add = TRUE)

  migrate_output_csv_v0_to_v1(
    input_path = plants_in,
    output_path = plants_out,
    table = "plants",
    run_id = "run_file_migration"
  )
  migrate_output_csv_v0_to_v1(
    input_path = herb_in,
    output_path = herb_out,
    table = "herbivore",
    run_id = "run_file_migration",
    herbivore_id = "herb_file"
  )

  plants_new <- utils::read.csv(plants_out, sep = ";", stringsAsFactors = FALSE)
  herb_new <- utils::read.csv(herb_out, sep = ";", stringsAsFactors = FALSE)

  expect_identical(colnames(plants_new), required_plant_output_columns_v1())
  expect_identical(colnames(herb_new), required_herbivore_output_columns_v1())
})
