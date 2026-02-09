test_that("portal templates compile with v1 schema", {
  repo_root <- scenario_find_repo_root(getwd())
  skip_if(is.null(repo_root), "Repository root not available in this test context.")
  template_dir <- file.path(repo_root, "portal", "plans", "templates")
  template_paths <- list.files(template_dir, pattern = "[.]yaml$", full.names = TRUE)
  skip_if(length(template_paths) < 1L, "Portal template YAML files not available in this context.")

  for (plan_path in template_paths) {
    plan <- compile_portal_plan_yaml(plan_path)
    expect_identical(plan$schema_version, portal_plan_schema_version_v1())
    expect_identical(plan$scenario$source, "reference")
    expect_true(is.list(plan$scenario$overrides))
    expect_true(plan$execution$backend %in% c("internal_ttr", "internal_ttr_compiled"))
    expect_true(plan$execution$compiled$enabled %in% c("auto", "true", "false"))
    expect_true(plan$execution$compiled$kernel_policy %in% c("resistance_only", "all_available"))
    expect_true(is.logical(plan$execution$compiled$strict))
    expect_true(is.logical(plan$execution$compiled$verbose))
    expect_true(is.logical(plan$outputs$render_report))
    expect_true(plan$outputs$acceptance_profile %in% c("standard", "balanced_demo", "stress_demo"))
  }
})

test_that("sensitivity template keeps parameter blocks after default merge", {
  repo_root <- scenario_find_repo_root(getwd())
  skip_if(is.null(repo_root), "Repository root not available in this test context.")
  plan_path <- file.path(repo_root, "portal", "plans", "templates", "sensitivity_template.yaml")
  skip_if_not(file.exists(plan_path), "Sensitivity template YAML not available in this context.")

  plan <- compile_portal_plan_yaml(plan_path)

  expect_true(isTRUE(plan$sensitivity$enabled))
  expect_true(length(plan$sensitivity$parameters) >= 1L)
  expect_identical(plan$sensitivity$parameters[[1]]$path, "runtime.days")
})

test_that("portal validator rejects unsupported schema versions", {
  plan <- portal_plan_default_v1()
  plan$schema_version <- "9.9.9"

  expect_error(
    validate_portal_plan_v1(plan),
    class = "herbivoreTTR_portal_plan_invalid"
  )
})

test_that("portal validator enforces supported acceptance profiles", {
  plan <- portal_plan_default_v1()
  plan$outputs$acceptance_profile <- "unsupported_profile"

  expect_error(
    validate_portal_plan_v1(plan),
    class = "herbivoreTTR_portal_plan_invalid"
  )
})

test_that("portal validator parses compiled execution controls", {
  plan <- portal_plan_default_v1()
  plan$execution$compiled$enabled <- TRUE
  validated_true <- validate_portal_plan_v1(plan)
  expect_identical(validated_true$execution$compiled$enabled, "true")

  plan$execution$compiled$enabled <- FALSE
  validated_false <- validate_portal_plan_v1(plan)
  expect_identical(validated_false$execution$compiled$enabled, "false")

  plan$execution$compiled$enabled <- "auto"
  validated_auto <- validate_portal_plan_v1(plan)
  expect_identical(validated_auto$execution$compiled$enabled, "auto")
  expect_identical(validated_auto$execution$compiled$kernel_policy, "resistance_only")
})

test_that("portal validator rejects compiled backend with compiled disabled", {
  plan <- portal_plan_default_v1()
  plan$execution$backend <- "internal_ttr_compiled"
  plan$execution$compiled$enabled <- "false"

  expect_error(
    validate_portal_plan_v1(plan),
    class = "herbivoreTTR_portal_plan_invalid"
  )
})

test_that("portal validator rejects unsupported compiled kernel policies", {
  plan <- portal_plan_default_v1()
  plan$execution$compiled$kernel_policy <- "unsupported_policy"

  expect_error(
    validate_portal_plan_v1(plan),
    class = "herbivoreTTR_portal_plan_invalid"
  )
})

test_that("scenario overrides update known fields and reject unknown paths", {
  scenario <- compile_scenario_yaml(scenario_contract_reference_path("canonical_smoke_v1"))

  updated <- portal_apply_scenario_overrides_v1(
    scenario,
    overrides = list(runtime = list(days = 3, minute_limit = 30))
  )
  expect_equal(updated$runtime$days, 3L)
  expect_equal(updated$runtime$minute_limit, 30L)

  expect_error(
    portal_apply_scenario_overrides_v1(
      scenario,
      overrides = list(runtime = list(not_a_field = 1))
    ),
    class = "herbivoreTTR_portal_plan_path_invalid"
  )
})

test_that("one-at-a-time sensitivity expansion builds deterministic run specs", {
  plan <- portal_plan_default_v1()
  plan$execution$mode <- "sensitivity"
  plan$scenario$source <- "reference"
  plan$scenario$reference <- "canonical_smoke_v1"
  plan$sensitivity$enabled <- TRUE
  plan$sensitivity$design <- "one_at_a_time"
  plan$sensitivity$keep_baseline <- TRUE
  plan$sensitivity$parameters <- list(
    list(path = "runtime.days", values = c(2, 4)),
    list(path = "runtime.minute_limit", values = c(30))
  )

  validated <- validate_portal_plan_v1(plan)
  scenario <- compile_scenario_yaml(scenario_contract_reference_path("canonical_smoke_v1"))
  design <- portal_expand_sensitivity_design_v1(validated, scenario)

  expect_equal(length(design$specs), 4L)
  expect_identical(design$specs[[1]]$run_label, "baseline")
  expect_equal(design$specs[[2]]$changes[["runtime.days"]], 2)
  expect_equal(design$specs[[4]]$changes[["runtime.minute_limit"]], 30)
  expect_equal(nrow(design$design_table), 4L)
})
