# Portal plan contract v2: primary portal YAML surface with v1 migration.

portal_plan_schema_version_legacy_v1 <- portal_plan_schema_version_v1
portal_plan_default_legacy_v1 <- portal_plan_default_v1
validate_portal_plan_legacy_v1 <- validate_portal_plan_v1
compile_portal_plan_yaml_legacy_v1 <- compile_portal_plan_yaml

portal_plan_schema_version_v2 <- function() {
  "2.0.0"
}

portal_plan_default_v2 <- function() {
  plan <- portal_plan_default_legacy_v1()
  plan$schema_version <- portal_plan_schema_version_v2()
  plan
}

migrate_portal_plan_v1_to_v2 <- function(plan) {
  if (!is.list(plan)) {
    portal_abort_v1(
      "Portal plan must be a list.",
      class = "herbivoreTTR_portal_plan_invalid"
    )
  }

  out <- plan
  out$schema_version <- portal_plan_schema_version_v2()
  out
}

validate_portal_plan_v2 <- function(plan) {
  if (!is.list(plan)) {
    portal_abort_v1(
      "Portal plan must be a list.",
      class = "herbivoreTTR_portal_plan_invalid"
    )
  }

  schema_version <- as.character(plan$schema_version)
  if (identical(schema_version, portal_plan_schema_version_legacy_v1())) {
    return(validate_portal_plan_v2(migrate_portal_plan_v1_to_v2(plan)))
  }
  if (!identical(schema_version, portal_plan_schema_version_v2())) {
    portal_abort_v1(
      sprintf("Unsupported portal schema version `%s`.", schema_version),
      class = "herbivoreTTR_portal_plan_invalid",
      schema_version = schema_version,
      expected = portal_plan_schema_version_v2()
    )
  }

  legacy_plan <- plan
  legacy_plan$schema_version <- portal_plan_schema_version_legacy_v1()
  validated <- validate_portal_plan_legacy_v1(legacy_plan)
  validated$schema_version <- portal_plan_schema_version_v2()
  validated
}

compile_portal_plan_yaml_v2 <- function(path) {
  resolved_path <- resolve_portal_plan_path_v1(path)
  raw <- yaml::read_yaml(resolved_path)

  if (is.null(raw) || !is.list(raw)) {
    portal_abort_v1(
      "Portal plan YAML must decode to a named list.",
      class = "herbivoreTTR_portal_plan_invalid",
      path = resolved_path
    )
  }

  defaults <- portal_plan_default_v2()
  merged <- portal_merge_defaults_v1(defaults, raw)
  validated <- validate_portal_plan_v2(merged)
  validated$plan_path <- resolved_path
  validated
}

run_portal_sensitivity_v2 <- function(plan,
                                      root_dir = NULL,
                                      base_scenario = NULL) {
  run_portal_sensitivity_v1(plan = plan, root_dir = root_dir, base_scenario = base_scenario)
}

run_portal_plan_v2 <- function(plan,
                               dry_run = NULL,
                               force_mode = NULL) {
  run_portal_plan_v1(plan = plan, dry_run = dry_run, force_mode = force_mode)
}

compile_portal_plan_yaml <- compile_portal_plan_yaml_v2
validate_portal_plan_v1 <- validate_portal_plan_v2
