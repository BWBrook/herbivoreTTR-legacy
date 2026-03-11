# Scenario migration helpers for contract v2.

migrate_scenario_v1_to_v2 <- function(scenario) {
  if (!is.list(scenario)) {
    rlang::abort(
      "Scenario must be a list.",
      class = "herbivoreTTR_scenario_v2_not_list"
    )
  }

  raw <- scenario
  population_mode <- as.character(raw$population$mode)

  raw$schema_version <- scenario_contract_version_v2()
  if (identical(population_mode, "implicit_representative")) {
    raw$population$mode <- "implicit_pressure"
    raw$population$template_herbivore <- raw$population$representative
    raw$population$representative <- NULL
  }

  validate_scenario_v2_native(raw)
}
