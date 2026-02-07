# Long-horizon stability suite for post-1.0 reliability checks.

build_stability_scenarios_v1 <- function(days = 365L, minute_limit = 120L) {
  canonical <- compile_scenario_yaml(scenario_contract_reference_path("canonical_smoke_v1"))
  aridity_high <- compile_scenario_yaml(scenario_contract_reference_path("reference_aridity_high_v1"))

  make_variant <- function(base, scenario_id, slug, forage_access_scale = 1, minute_limit_override = minute_limit) {
    out <- base
    out$scenario_id <- scenario_id
    out$outputs$scenario_slug <- slug
    out$runtime$days <- as.integer(days)
    out$runtime$minute_limit <- as.integer(minute_limit_override)
    out$runtime$forage_access_scale <- as.numeric(forage_access_scale)
    out
  }

  scenarios <- list(
    baseline = make_variant(canonical, "stability_baseline_v1", "stability_baseline_v1"),
    high_aridity = make_variant(aridity_high, "stability_high_aridity_v1", "stability_high_aridity_v1"),
    high_pressure = make_variant(canonical, "stability_high_pressure_v1", "stability_high_pressure_v1", minute_limit_override = 240L),
    low_access = make_variant(canonical, "stability_low_access_v1", "stability_low_access_v1", forage_access_scale = 0.6)
  )

  scenarios
}

count_non_finite_values <- function(df) {
  numeric_cols <- df[, vapply(df, is.numeric, logical(1L)), drop = FALSE]
  if (ncol(numeric_cols) == 0L) {
    return(0L)
  }
  as.integer(sum(!is.finite(as.matrix(numeric_cols))))
}

count_negative_biomass_violations <- function(plants, tolerance = CONSTANTS$TOLERANCE) {
  cols <- intersect(c("ms", "mr", "bleaf", "bstem", "bdef"), names(plants))
  if (length(cols) == 0L) {
    return(0L)
  }
  as.integer(sum(plants[, cols, drop = FALSE] < -tolerance))
}

count_gut_capacity_violations <- function(final_herbivores, tolerance = CONSTANTS$TOLERANCE) {
  if (length(final_herbivores) < 1L) {
    return(0L)
  }
  violations <- vapply(
    final_herbivores,
    function(h) as.integer((h$gut_content - h$gut_capacity) > tolerance),
    integer(1L)
  )
  as.integer(sum(violations))
}

#' Run the long-horizon stability suite v1
#'
#' @param base_dir Base directory for stability artefacts.
#' @param seeds Integer vector of seeds.
#' @param days Number of simulated days per scenario.
#' @param minute_limit Daily minute budget for baseline scenarios.
#'
#' @return List with summary and artefact paths.
run_long_horizon_stability_suite_v1 <- function(base_dir = file.path("artefacts", "stability"),
                                                seeds = 801:810,
                                                days = 365L,
                                                minute_limit = 120L) {
  scenarios <- build_stability_scenarios_v1(days = days, minute_limit = minute_limit)
  seed_vec <- normalise_ensemble_seeds(seeds)

  rows <- list()
  idx <- 0L
  run_base <- file.path(base_dir, "long_horizon_v1", "runs")

  for (scenario_name in names(scenarios)) {
    scenario_base <- scenarios[[scenario_name]]
    for (seed in seed_vec) {
      idx <- idx + 1L
      scenario <- scenario_base
      scenario$runtime$seed <- as.integer(seed)
      scenario$outputs$scenario_slug <- file.path("long_horizon_v1", "runs", sprintf("%s_seed_%03d", scenario_name, seed))

      run <- run_scenario_v1(scenario = scenario, base_dir = base_dir)
      herb <- run$herbivore_daily

      nan_inf_count <- count_non_finite_values(herb) + count_non_finite_values(run$structure_fuel_metrics)
      negative_biomass <- count_negative_biomass_violations(run$final_plants)
      gut_capacity_violations <- count_gut_capacity_violations(run$final_herbivores)
      prolonged_stress_days <- as.integer(sum(herb$PhysiologicalStressFlag > 0))

      rows[[idx]] <- data.frame(
        scenario_name = scenario_name,
        seed_value = as.integer(seed),
        run_id = as.character(run$run_id),
        nan_inf_count = nan_inf_count,
        negative_biomass_violations = negative_biomass,
        gut_capacity_violations = gut_capacity_violations,
        prolonged_stress_days = prolonged_stress_days,
        min_energy_balance = min(herb$EnergyBalance),
        min_water_balance = min(herb$WaterBalance),
        any_violation = as.integer(
          nan_inf_count > 0L ||
            negative_biomass > 0L ||
            gut_capacity_violations > 0L
        ),
        stringsAsFactors = FALSE
      )
    }
  }

  replicate_df <- do.call(rbind, rows)
  rownames(replicate_df) <- NULL

  scenario_summary <- do.call(
    rbind,
    lapply(split(replicate_df, replicate_df$scenario_name), function(df) {
      data.frame(
        scenario_name = df$scenario_name[[1]],
        runs = nrow(df),
        nan_inf_count_total = sum(df$nan_inf_count),
        negative_biomass_violations_total = sum(df$negative_biomass_violations),
        gut_capacity_violations_total = sum(df$gut_capacity_violations),
        prolonged_stress_days_median = stats::median(df$prolonged_stress_days),
        any_violation_runs = sum(df$any_violation),
        stringsAsFactors = FALSE
      )
    })
  )
  rownames(scenario_summary) <- NULL

  run_dir <- file.path(base_dir, "long_horizon_v1")
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  replicate_path <- file.path(run_dir, "stability_replicates_v1.csv")
  summary_path <- file.path(run_dir, "stability_summary_v1.csv")
  report_path <- file.path(run_dir, "stability_report_v1.md")

  utils::write.csv(replicate_df, replicate_path, row.names = FALSE)
  utils::write.csv(scenario_summary, summary_path, row.names = FALSE)

  report_lines <- c(
    "# Long-Horizon Stability Suite v1",
    "",
    sprintf("- Scenarios: `%d`", length(scenarios)),
    sprintf("- Seeds per scenario: `%d`", length(seed_vec)),
    sprintf("- Days per run: `%d`", as.integer(days)),
    "",
    "## Summary",
    paste0(
      "- `", scenario_summary$scenario_name,
      "`: nan/inf=", scenario_summary$nan_inf_count_total,
      ", negative biomass=", scenario_summary$negative_biomass_violations_total,
      ", gut violations=", scenario_summary$gut_capacity_violations_total,
      ", median stress-days=", scenario_summary$prolonged_stress_days_median
    ),
    "",
    "## Interpretation",
    "- Any non-zero hard violation counts should be treated as model faults.",
    "- Stress-day counts are ecological signals, not numerical faults, and must be interpreted in context."
  )
  writeLines(report_lines, report_path)

  manifest <- build_run_manifest(
    scenario_slug = file.path("stability", "long_horizon_v1"),
    seed = as.integer(seed_vec[[1]]),
    scenario_parameters = list(
      scenarios = names(scenarios),
      seeds = seed_vec,
      days = as.integer(days)
    ),
    output_files = c(
      replicates = file.path(base_dir, "long_horizon_v1", basename(replicate_path)),
      summary = file.path(base_dir, "long_horizon_v1", basename(summary_path)),
      report = file.path(base_dir, "long_horizon_v1", basename(report_path))
    )
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    run_dir = run_dir,
    run_base = run_base,
    replicate_path = replicate_path,
    summary_path = summary_path,
    report_path = report_path,
    manifest_path = manifest_path,
    replicates = replicate_df,
    summary = scenario_summary
  )
}
