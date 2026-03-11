test_that("cohort scenario initialises deterministic unique IDs", {
  scenario <- compile_scenario_yaml_v2(scenario_contract_reference_path("cohort_smoke_v1"))
  cohort_a <- init_cohort_from_scenario(scenario)
  cohort_b <- init_cohort_from_scenario(scenario)

  ids_a <- vapply(cohort_a, `[[`, character(1), "herbivore_id")
  ids_b <- vapply(cohort_b, `[[`, character(1), "herbivore_id")

  expect_identical(ids_a, ids_b)
  expect_identical(anyDuplicated(ids_a), 0L)
  expect_equal(length(ids_a), 3L)
})

test_that("daily cohort runner is deterministic under fixed seed", {
  scenario <- compile_scenario_yaml_v2(scenario_contract_reference_path("cohort_smoke_v1"))
  conditions <- build_conditions_from_scenario(scenario)
  plants <- init_plants(veg_types = scenario$plot$veg_types)
  cohort <- init_cohort_from_scenario(scenario)

  out_a <- run_daily_herbivore_cohort(
    herbivores = cohort,
    plants = plants,
    conditions = conditions,
    day_of_simulation = scenario$runtime$start_day,
    minute_limit = 30L,
    seed = 99L
  )
  out_b <- run_daily_herbivore_cohort(
    herbivores = cohort,
    plants = plants,
    conditions = conditions,
    day_of_simulation = scenario$runtime$start_day,
    minute_limit = 30L,
    seed = 99L
  )

  expect_identical(out_a$daily_summary, out_b$daily_summary)
  expect_identical(out_a$plants, out_b$plants)
})

test_that("run_scenario_v2 explicit cohort writes per-herbivore daily outputs", {
  out <- withr::with_seed(123L, {
    run_scenario_v2(
      scenario = scenario_contract_reference_path("cohort_smoke_v1"),
      base_dir = tempdir()
    )
  })

  expect_identical(out$daily_output_kind, "explicit_individual")
  expect_true(file.exists(out$herbivore_daily_path))
  expect_true(file.exists(out$daily_output_path))
  expect_true(file.exists(out$structure_fuel_path))
  expect_true(file.exists(out$manifest_path))

  herb <- utils::read.csv(out$herbivore_daily_path, stringsAsFactors = FALSE)
  expect_true("HerbivoreID" %in% names(herb))
  expect_true("RunID" %in% names(herb))
  expect_true(length(unique(herb$HerbivoreID)) >= 3L)
  expect_true(all(herb$PopulationMode == "explicit_cohort"))

  struc <- utils::read.csv(out$structure_fuel_path, stringsAsFactors = FALSE)
  expect_true(all(is.finite(struc$total_shoot_biomass_kg)))
  expect_true(all(struc$total_shoot_biomass_kg >= 0))
})

test_that("implicit pressure mode writes pressure_daily output without faux physiology fields", {
  scenario <- compile_scenario_yaml_v2(scenario_contract_reference_path("implicit_stocking_v1"))
  visitation <- derive_implicit_visitation_v2(scenario)
  expect_true(is.finite(visitation$effective_visits_per_day))
  expect_true(visitation$effective_visits_per_day >= 0)

  out <- withr::with_seed(123L, {
    run_scenario_v2(
      scenario = scenario,
      base_dir = tempdir()
    )
  })

  expect_identical(out$daily_output_kind, "implicit_pressure")
  expect_true(is.null(out$herbivore_daily_path))
  expect_true(file.exists(out$pressure_daily_path))
  expect_true(file.exists(out$structure_fuel_path))
  expect_true(file.exists(out$manifest_path))

  pressure <- utils::read.csv(out$pressure_daily_path, stringsAsFactors = FALSE)
  expect_true(all(pressure$PopulationMode == "implicit_pressure"))
  expect_true(all(is.finite(pressure$EffectiveVisitsPerDay)))
  expect_true(all(pressure$EffectiveVisitsPerDay >= 0))
  expect_true(all(c(
    "TemplateHerbivoreID",
    "VisitCount",
    "TotalPressureDMI",
    "TotalPressureDistMoved"
  ) %in% names(pressure)))
  expect_false(any(c(
    "BodyConditionIndex",
    "EnergyDeficitStreakDays",
    "WaterDeficitStreakDays",
    "PhysiologicalStressFlag",
    "MaintenanceEnergyReq",
    "WaterBalanceRatio"
  ) %in% names(pressure)))

  manifest <- jsonlite::fromJSON(out$manifest_path, simplifyVector = FALSE)
  expect_identical(manifest$daily_output_kind, "implicit_pressure")
  expect_true("pressure_daily" %in% names(manifest$outputs))
  expect_false("herbivore_daily" %in% names(manifest$outputs))

  if (!is.null(out$implicit_visit_path)) {
    expect_true(file.exists(out$implicit_visit_path))
  }
})

test_that("implicit pressure totals equal weighted sums of visit detail", {
  scenario <- compile_scenario_yaml_v2(scenario_contract_reference_path("implicit_stocking_v1"))

  out <- run_scenario_v2(
    scenario = scenario,
    base_dir = tempdir(),
    write_outputs = FALSE
  )

  expect_identical(out$daily_output_kind, "implicit_pressure")
  expect_true(is.data.frame(out$visit_detail))
  expect_true(is.data.frame(out$pressure_daily))

  expected_dmi <- stats::aggregate(
    out$visit_detail$DailyDMI * out$visit_detail$VisitWeight,
    by = list(Day = out$visit_detail$Day),
    FUN = sum
  )
  observed <- out$pressure_daily[, c("Day", "TotalPressureDMI"), drop = FALSE]
  merged <- merge(observed, expected_dmi, by = "Day", all = TRUE, sort = TRUE)
  expect_equal(merged$TotalPressureDMI, merged$x, tolerance = 1e-10)
})

test_that("zero-visitation implicit pressure scenario produces zero pressure totals", {
  scenario <- compile_scenario_yaml_v2(scenario_contract_reference_path("reference_presence_removed_v1"))
  out <- run_scenario_v2(
    scenario = scenario,
    base_dir = tempdir(),
    write_outputs = FALSE
  )

  expect_identical(out$daily_output_kind, "implicit_pressure")
  expect_true(all(out$pressure_daily$EffectiveVisitsPerDay == 0))
  expect_true(all(out$pressure_daily$TotalPressureDMI == 0))
  expect_true(all(out$pressure_daily$TotalPressureDistMoved == 0))
  expect_true(all(out$pressure_daily$TotalPressureVisitMinutes == 0))
})
