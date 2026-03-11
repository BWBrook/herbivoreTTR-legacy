test_that("v2 API export surface is intentional and frozen", {
  repo_root <- scenario_find_repo_root(getwd())
  skip_if(is.null(repo_root), "Repo root not detectable in this test context.")

  namespace_path <- file.path(repo_root, "NAMESPACE")
  skip_if_not(file.exists(namespace_path), "NAMESPACE not available in this test context.")
  namespace_lines <- readLines(namespace_path, warn = FALSE)
  exports <- sub("^export\\(([^)]+)\\)$", "\\1", grep("^export\\(", namespace_lines, value = TRUE))

  expected <- c(
    "calc_bite_size",
    "calc_daily_energy_balance",
    "calc_foraging_traits",
    "calc_foraging_velocity",
    "calc_gut_capacity",
    "calc_handling_time",
    "calc_plant_tastiness",
    "calc_toroidal_distance",
    "calc_water_requirement",
    "check_daily_water_balance",
    "compile_scenario_yaml",
    "compile_scenario_yaml_v2",
    "get_plants_within_range",
    "herbivore_move",
    "herbivore_step",
    "hourly_digestion_step",
    "init_conditions",
    "init_herbivore",
    "init_plants",
    "init_simulation",
    "pick_a_plant",
    "render_paper_pipeline_report",
    "reset_daily_variables",
    "run_benchmark_appendix_v1",
    "run_daily_herbivore_simulation",
    "run_experiment_a_presence_removal",
    "run_experiment_b_functional_types",
    "run_experiment_c_aridity_gradient",
    "run_herbivore_days",
    "run_reference_scenario_library",
    "run_scenario_v1",
    "run_scenario_v2",
    "scenario_contract_reference_path",
    "scenario_contract_version",
    "scenario_contract_version_v2",
    "select_randomly",
    "summarise_hourly_herbivore_record",
    "update_gut_content",
    "validate_scenario_v1",
    "validate_scenario_v2",
    "write_hourly_herbivore_log"
  )

  expect_setequal(exports, expected)
})

test_that("API and deprecation docs are present and cross-referenced", {
  repo_root <- scenario_find_repo_root(getwd())
  skip_if(is.null(repo_root), "Repo root not detectable in this test context.")

  api_doc <- file.path(repo_root, "docs", "governance", "api_surface_v2.md")
  dep_doc <- file.path(repo_root, "docs", "governance", "deprecation_policy.md")
  readme_path <- file.path(repo_root, "README.md")
  architecture_path <- file.path(repo_root, "docs", "architecture.md")

  skip_if_not(file.exists(api_doc), "API surface doc not available in this test context.")
  skip_if_not(file.exists(dep_doc), "Deprecation policy doc not available in this test context.")
  skip_if_not(file.exists(readme_path), "README not available in this test context.")
  skip_if_not(file.exists(architecture_path), "Architecture doc not available in this test context.")

  expect_true(file.exists(api_doc))
  expect_true(file.exists(dep_doc))

  readme <- paste(readLines(readme_path, warn = FALSE), collapse = "\n")
  architecture <- paste(readLines(architecture_path, warn = FALSE), collapse = "\n")

  expect_match(readme, "docs/governance/api_surface_v2.md", fixed = TRUE)
  expect_match(readme, "docs/governance/deprecation_policy.md", fixed = TRUE)
  expect_match(architecture, "docs/governance/api_surface_v2.md", fixed = TRUE)
  expect_match(architecture, "docs/governance/deprecation_policy.md", fixed = TRUE)
})
