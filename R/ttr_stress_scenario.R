# Stress scenario helper for TTR stability verification artefacts.

run_ttr_stress_scenario <- function(days = 21L,
                                    seed = 11L,
                                    stress_temp = 35,
                                    stress_sw = 0.95,
                                    stress_n = 0.95,
                                    scenario_slug = "stress_ttr_v0",
                                    base_dir = file.path("artefacts", "canonical_runs")) {
  if (!is.numeric(days) || length(days) != 1L || !is.finite(days) || days < 1) {
    rlang::abort(
      "Argument `days` must be a positive scalar.",
      class = "herbivoreTTR_ttr_stress_days_invalid",
      days = days
    )
  }

  days <- as.integer(days)

  run <- with_optional_seed(seed, {
    conditions <- data.frame(
      day = seq_len(days),
      temp_mean = rep(stress_temp, days),
      sw = rep(stress_sw, days),
      N = rep(stress_n, days)
    )
    plants <- init_plants(veg_types = c(0, 1, 2))
    metrics <- vector("list", days)

    for (d in seq_len(days)) {
      plants <- transport_resistance(plants, conditions, day_index = d)
      defence_fraction <- ifelse(
        plants$ms > CONSTANTS$TOLERANCE,
        plants$bdef / pmax(plants$ms, CONSTANTS$TOLERANCE),
        0
      )
      metrics[[d]] <- data.frame(
        day = d,
        ms_max = max(plants$ms),
        mr_max = max(plants$mr),
        cs_max = max(plants$cs),
        ns_max = max(plants$ns),
        bdef_max = max(plants$bdef),
        defence_fraction_max = max(defence_fraction),
        non_finite_count = sum(!is.finite(as.matrix(plants[, ttr_guardrail_pool_columns(), drop = FALSE]))),
        stringsAsFactors = FALSE
      )
    }

    list(
      plants = plants,
      metrics = do.call(rbind, metrics)
    )
  })

  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  plants_path <- file.path(run_dir, sprintf("plants_day%d.csv", days))
  metrics_path <- file.path(run_dir, "ttr_stability_metrics.csv")
  manifest_path <- file.path(run_dir, "run_manifest.json")

  utils::write.csv(run$plants, file = plants_path, row.names = FALSE)
  utils::write.csv(run$metrics, file = metrics_path, row.names = FALSE)

  scenario_parameters <- list(
    days = days,
      seed = as.integer(seed),
    stress_temp = stress_temp,
    stress_sw = stress_sw,
    stress_n = stress_n,
    ttr_max_pool_abs = CONSTANTS$TTR_MAX_POOL_ABS,
    ttr_max_daily_pool_multiplier = CONSTANTS$TTR_MAX_DAILY_POOL_MULTIPLIER,
    ttr_max_defence_fraction = CONSTANTS$TTR_MAX_DEFENCE_FRACTION
  )

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = seed,
    scenario_parameters = scenario_parameters,
    output_files = c(
      plants_final = normalize_manifest_path(plants_path),
      stability_metrics = normalize_manifest_path(metrics_path)
    )
  )
  write_run_manifest(manifest = manifest, path = manifest_path)

  list(
    run_dir = run_dir,
    plants_path = plants_path,
    metrics_path = metrics_path,
    manifest_path = manifest_path,
    metrics = run$metrics,
    plants = run$plants
  )
}
