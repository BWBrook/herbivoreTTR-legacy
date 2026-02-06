test_that("output contract v0 required columns are stable", {
  expect_identical(
    required_plant_output_columns_v0(),
    c(
      "SchemaVersion", "Year", "Day", "Plant", "VegType", "Height", "BLeaf",
      "BStem", "BDef", "Ms", "Ns", "Cs", "Mr", "Cr", "Nr"
    )
  )

  expect_identical(
    required_herbivore_output_columns_v0(),
    c(
      "SchemaVersion", "Year", "Day", "HerbType", "Mass", "xcor", "ycor",
      "DailyDistMoved", "DailyPEI", "DailyNPEI", "DailyDMI", "DailyForageWater",
      "TotalDMI", "WaterBalance", "EnergyBalance"
    )
  )
})

test_that("snapshot writers include schema version in required columns", {
  sim <- init_simulation(temp_mode = "flat", herbivore_mass = 5e5, veg_types = c(0, 1, 2))
  plants_path <- tempfile(fileext = ".csv")
  herb_path <- tempfile(fileext = ".csv")
  on.exit(unlink(c(plants_path, herb_path)), add = TRUE)

  write_plants_daily(sim$plants, day = 1, year = 1, path = plants_path)
  write_herbivores_daily(sim$herbivore, day = 1, year = 1, path = herb_path)

  plants <- utils::read.csv(plants_path, sep = ";")
  herb <- utils::read.csv(herb_path, sep = ";")

  expect_identical(colnames(plants), required_plant_output_columns_v0())
  expect_identical(colnames(herb), required_herbivore_output_columns_v0())
  expect_true(all(plants$SchemaVersion == output_schema_version()))
  expect_true(all(herb$SchemaVersion == output_schema_version()))
})

test_that("run manifest includes required metadata and outputs", {
  outputs <- c(
    plants_day1 = "artefacts/canonical_runs/smoke_v0/plants_day1826.csv",
    herb_day1 = "artefacts/canonical_runs/smoke_v0/herb_day1826.csv"
  )

  manifest <- build_run_manifest(
    scenario_slug = "smoke_v0",
    seed = 1L,
    scenario_parameters = list(minute_limit = 60, days = 7L),
    output_files = outputs,
    created_utc = "2026-02-06T00:00:00Z"
  )

  expect_identical(manifest$schema_version, output_schema_version())
  expect_true(all(c(
    "schema_version",
    "package_version",
    "git_sha",
    "seed",
    "scenario_slug",
    "scenario_parameters_hash",
    "outputs",
    "created_utc"
  ) %in% names(manifest)))
  expect_identical(manifest$seed, 1L)
  expect_identical(manifest$scenario_slug, "smoke_v0")
  expect_identical(manifest$outputs$plants_day1, outputs[["plants_day1"]])
  expect_identical(manifest$created_utc, "2026-02-06T00:00:00Z")
})

test_that("write_run_manifest writes valid JSON", {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path), add = TRUE)
  manifest <- build_run_manifest(
    scenario_slug = "smoke_v0",
    seed = 1L,
    scenario_parameters = list(example = TRUE),
    output_files = c(example = "artefacts/canonical_runs/smoke_v0/example.csv")
  )

  write_run_manifest(manifest, path)
  expect_true(file.exists(path))

  parsed <- jsonlite::fromJSON(path)
  expect_identical(parsed$schema_version, output_schema_version())
  expect_identical(parsed$scenario_slug, "smoke_v0")
  expect_identical(parsed$seed, 1L)
  expect_true(nzchar(parsed$scenario_parameters_hash))
})
