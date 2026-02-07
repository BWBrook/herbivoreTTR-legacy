# Post-1.0 reference experiment extensions with uncertainty and claim gating.

interval_stats <- function(values) {
  vals <- as.numeric(values)
  c(
    median = stats::median(vals),
    p05 = stats::quantile(vals, probs = 0.05, names = FALSE, type = 7),
    p95 = stats::quantile(vals, probs = 0.95, names = FALSE, type = 7),
    n = length(vals)
  )
}

read_final_structure_metrics_from_result <- function(run_result) {
  metrics <- run_result$structure_fuel_metrics
  metrics[which.max(metrics$Day), , drop = FALSE]
}

build_experiment_a_v2_metrics <- function(delta_summary, n_replicates) {
  get_metric <- function(metric_name, column_name) {
    rows <- delta_summary[delta_summary$metric == metric_name, column_name, drop = TRUE]
    if (length(rows) < 1L) {
      return(NA_real_)
    }
    as.numeric(rows[[1]])
  }

  c(
    n_replicates = as.numeric(n_replicates),
    delta_total_shoot_median = get_metric("delta_total_shoot_biomass_kg", "median_delta"),
    delta_fine_fuel_median = get_metric("delta_fine_fuel_proxy_kg", "median_delta"),
    delta_browseable_median = get_metric("delta_browseable_biomass_kg", "median_delta"),
    support_share_total_shoot = get_metric("delta_total_shoot_biomass_kg", "support_share"),
    support_share_fine_fuel = get_metric("delta_fine_fuel_proxy_kg", "support_share"),
    support_share_browseable = get_metric("delta_browseable_biomass_kg", "support_share")
  )
}

summarise_experiment_a_v2_scenarios <- function(replicate_df) {
  scenarios <- c("present", "removal")
  rows <- lapply(scenarios, function(scenario_name) {
    prefix <- paste0(scenario_name, "_")
    data.frame(
      scenario = scenario_name,
      total_shoot_biomass_kg_median = interval_stats(replicate_df[[paste0(prefix, "total_shoot_biomass_kg")]])[["median"]],
      total_shoot_biomass_kg_p05 = interval_stats(replicate_df[[paste0(prefix, "total_shoot_biomass_kg")]])[["p05"]],
      total_shoot_biomass_kg_p95 = interval_stats(replicate_df[[paste0(prefix, "total_shoot_biomass_kg")]])[["p95"]],
      fine_fuel_proxy_kg_median = interval_stats(replicate_df[[paste0(prefix, "fine_fuel_proxy_kg")]])[["median"]],
      fine_fuel_proxy_kg_p05 = interval_stats(replicate_df[[paste0(prefix, "fine_fuel_proxy_kg")]])[["p05"]],
      fine_fuel_proxy_kg_p95 = interval_stats(replicate_df[[paste0(prefix, "fine_fuel_proxy_kg")]])[["p95"]],
      browseable_biomass_kg_median = interval_stats(replicate_df[[paste0(prefix, "browseable_biomass_kg")]])[["median"]],
      browseable_biomass_kg_p05 = interval_stats(replicate_df[[paste0(prefix, "browseable_biomass_kg")]])[["p05"]],
      browseable_biomass_kg_p95 = interval_stats(replicate_df[[paste0(prefix, "browseable_biomass_kg")]])[["p95"]],
      n = interval_stats(replicate_df[[paste0(prefix, "total_shoot_biomass_kg")]])[["n"]],
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

summarise_experiment_a_v2_deltas <- function(replicate_df) {
  delta_cols <- c(
    delta_total_shoot_biomass_kg = "removal_total_shoot_biomass_kg",
    delta_fine_fuel_proxy_kg = "removal_fine_fuel_proxy_kg",
    delta_browseable_biomass_kg = "removal_browseable_biomass_kg"
  )
  present_cols <- c(
    delta_total_shoot_biomass_kg = "present_total_shoot_biomass_kg",
    delta_fine_fuel_proxy_kg = "present_fine_fuel_proxy_kg",
    delta_browseable_biomass_kg = "present_browseable_biomass_kg"
  )

  rows <- lapply(names(delta_cols), function(metric_name) {
    delta <- replicate_df[[delta_cols[[metric_name]]]] - replicate_df[[present_cols[[metric_name]]]]
    stats <- interval_stats(delta)
    data.frame(
      metric = metric_name,
      median_delta = stats[["median"]],
      p05_delta = stats[["p05"]],
      p95_delta = stats[["p95"]],
      support_share = mean(delta > 0),
      expected_positive = 1,
      supported = as.integer(mean(delta > 0) >= 0.8),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Run Experiment A v2 (paired-seed ensemble presence vs removal)
#'
#' @param base_dir Base artefact directory.
#' @param seeds Integer vector of seeds for paired ensembles.
#' @param scenario_slug Output scenario slug for this experiment bundle.
#' @param gate_claims Logical; when `TRUE`, required claims must be supported.
#'
#' @return List of summary and artefact paths.
run_experiment_a_presence_removal_v2 <- function(base_dir = file.path("artefacts", "canonical_runs"),
                                                 seeds = 301:330,
                                                 scenario_slug = "experiment_a_presence_removal_v2",
                                                 gate_claims = TRUE) {
  present_base <- compile_scenario_yaml(scenario_contract_reference_path("reference_presence_present_v1"))
  removal_base <- compile_scenario_yaml(scenario_contract_reference_path("reference_presence_removed_v1"))
  validate_paired_contrast_parity(present_base, removal_base)

  seed_vec <- normalise_ensemble_seeds(seeds)
  run_rows <- vector("list", length(seed_vec))

  for (i in seq_along(seed_vec)) {
    seed <- seed_vec[[i]]

    present_scenario <- present_base
    present_scenario$runtime$seed <- seed
    present_scenario$outputs$scenario_slug <- file.path(scenario_slug, sprintf("present_seed_%03d", seed))

    removal_scenario <- removal_base
    removal_scenario$runtime$seed <- seed
    removal_scenario$outputs$scenario_slug <- file.path(scenario_slug, sprintf("removal_seed_%03d", seed))

    present_run <- run_scenario_v1(present_scenario, base_dir = base_dir)
    removal_run <- run_scenario_v1(removal_scenario, base_dir = base_dir)

    present_final <- read_final_structure_metrics_from_result(present_run)
    removal_final <- read_final_structure_metrics_from_result(removal_run)

    run_rows[[i]] <- data.frame(
      seed_index = as.integer(i),
      seed_value = as.integer(seed),
      present_run_id = as.character(present_run$run_id),
      removal_run_id = as.character(removal_run$run_id),
      present_total_shoot_biomass_kg = as.numeric(present_final$total_shoot_biomass_kg),
      removal_total_shoot_biomass_kg = as.numeric(removal_final$total_shoot_biomass_kg),
      present_fine_fuel_proxy_kg = as.numeric(present_final$fine_fuel_proxy_kg),
      removal_fine_fuel_proxy_kg = as.numeric(removal_final$fine_fuel_proxy_kg),
      present_browseable_biomass_kg = as.numeric(present_final$browseable_biomass_kg),
      removal_browseable_biomass_kg = as.numeric(removal_final$browseable_biomass_kg),
      stringsAsFactors = FALSE
    )
  }

  replicate_df <- do.call(rbind, run_rows)
  rownames(replicate_df) <- NULL
  scenario_summary <- summarise_experiment_a_v2_scenarios(replicate_df)
  delta_summary <- summarise_experiment_a_v2_deltas(replicate_df)

  claim_metrics <- build_experiment_a_v2_metrics(
    delta_summary = delta_summary,
    n_replicates = nrow(replicate_df)
  )
  claim_status <- evaluate_claim_registry_v1(
    experiment_id = "experiment_a_v2",
    metrics = claim_metrics
  )
  if (isTRUE(gate_claims)) {
    assert_required_claims_supported(claim_status)
  }

  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  replicate_path <- file.path(run_dir, "experiment_a_replicates_v2.csv")
  summary_path <- file.path(run_dir, "experiment_a_summary_v2.csv")
  delta_path <- file.path(run_dir, "experiment_a_delta_ensemble_v2.csv")
  claims_path <- file.path(run_dir, "experiment_a_claims_v2.csv")
  summary_units_path <- file.path(run_dir, "experiment_a_summary_v2_units.csv")
  delta_units_path <- file.path(run_dir, "experiment_a_delta_ensemble_v2_units.csv")
  figure_path <- file.path(run_dir, "experiment_a_presence_removal_v2.png")
  report_path <- file.path(run_dir, "experiment_a_report_v2.md")

  utils::write.csv(replicate_df, replicate_path, row.names = FALSE)
  utils::write.csv(scenario_summary, summary_path, row.names = FALSE)
  utils::write.csv(delta_summary, delta_path, row.names = FALSE)
  utils::write.csv(claim_status, claims_path, row.names = FALSE)
  write_metric_units_sidecar_v1(
    metric_names = c("total_shoot_biomass_kg", "fine_fuel_proxy_kg", "browseable_biomass_kg"),
    output_path = summary_units_path
  )
  write_metric_units_sidecar_v1(
    metric_names = c(
      "delta_total_shoot_biomass_kg",
      "delta_fine_fuel_proxy_kg",
      "delta_browseable_biomass_kg",
      "support_share"
    ),
    output_path = delta_units_path
  )

  delta_total <- replicate_df$removal_total_shoot_biomass_kg - replicate_df$present_total_shoot_biomass_kg
  delta_fuel <- replicate_df$removal_fine_fuel_proxy_kg - replicate_df$present_fine_fuel_proxy_kg

  grDevices::png(figure_path, width = 1300, height = 700)
  op <- graphics::par(mfrow = c(1, 2), mar = c(5, 5, 3, 1))
  graphics::boxplot(
    delta_total,
    col = "#4f772d",
    ylab = "removal - present (kg)",
    main = "Total Shoot Biomass Delta"
  )
  graphics::abline(h = 0, lty = 2, col = "grey40")
  graphics::boxplot(
    delta_fuel,
    col = "#bc6c25",
    ylab = "removal - present (kg)",
    main = "Fine Fuel Delta"
  )
  graphics::abline(h = 0, lty = 2, col = "grey40")
  graphics::par(op)
  grDevices::dev.off()

  report_lines <- c(
    "# Experiment A v2: Presence vs Removal (Paired Ensemble)",
    "",
    "## Design",
    sprintf("- Paired scenario ensemble with shared seed vector (`n = %d`).", length(seed_vec)),
    "- Seed, runtime, and climate parity enforced by scenario contract pairing rules.",
    "",
    "## Directional outcomes (removal - present)",
    "- Units: biomass in `kg_dm`; support share in `unitless_share`.",
    sprintf(
      "- Total shoot biomass: median `%.3f` kg (p05 `%.3f`, p95 `%.3f`), support share `%.2f`.",
      delta_summary$median_delta[delta_summary$metric == "delta_total_shoot_biomass_kg"],
      delta_summary$p05_delta[delta_summary$metric == "delta_total_shoot_biomass_kg"],
      delta_summary$p95_delta[delta_summary$metric == "delta_total_shoot_biomass_kg"],
      delta_summary$support_share[delta_summary$metric == "delta_total_shoot_biomass_kg"]
    ),
    sprintf(
      "- Fine fuel proxy: median `%.3f` kg (p05 `%.3f`, p95 `%.3f`), support share `%.2f`.",
      delta_summary$median_delta[delta_summary$metric == "delta_fine_fuel_proxy_kg"],
      delta_summary$p05_delta[delta_summary$metric == "delta_fine_fuel_proxy_kg"],
      delta_summary$p95_delta[delta_summary$metric == "delta_fine_fuel_proxy_kg"],
      delta_summary$support_share[delta_summary$metric == "delta_fine_fuel_proxy_kg"]
    ),
    "",
    "## Claim status",
    paste0(
      "- `",
      claim_status$claim_id,
      "`: ",
      claim_status$status,
      " (observed=",
      format(round(claim_status$observed_value, 4), trim = TRUE),
      ", threshold=",
      claim_status$threshold,
      ")"
    ),
    "",
    "## Notes",
    "- Results are uncertainty-aware mechanism checks for treatment directionality.",
    "- Long-horizon demographic interpretation remains out of scope."
  )
  writeLines(report_lines, report_path)

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = as.integer(seed_vec[[1]]),
    scenario_parameters = list(
      seeds = seed_vec,
      treatment = c("present", "removal")
    ),
    output_files = c(
      replicate_summary = file.path(base_dir, scenario_slug, basename(replicate_path)),
      scenario_summary = file.path(base_dir, scenario_slug, basename(summary_path)),
      delta_summary = file.path(base_dir, scenario_slug, basename(delta_path)),
      claim_status = file.path(base_dir, scenario_slug, basename(claims_path)),
      summary_units = file.path(base_dir, scenario_slug, basename(summary_units_path)),
      delta_units = file.path(base_dir, scenario_slug, basename(delta_units_path)),
      figure = file.path(base_dir, scenario_slug, basename(figure_path)),
      report = file.path(base_dir, scenario_slug, basename(report_path))
    )
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    run_dir = run_dir,
    replicate_path = replicate_path,
    summary_path = summary_path,
    delta_path = delta_path,
    claims_path = claims_path,
    summary_units_path = summary_units_path,
    delta_units_path = delta_units_path,
    figure_path = figure_path,
    report_path = report_path,
    manifest_path = manifest_path,
    replicates = replicate_df,
    summary = scenario_summary,
    delta_summary = delta_summary,
    claim_status = claim_status
  )
}

build_aridity_access_matrix_v2 <- function() {
  aridity_levels <- c(
    low = "reference_aridity_low_v1",
    mid = "reference_aridity_mid_v1",
    high = "reference_aridity_high_v1"
  )
  access_levels <- data.frame(
    access_level = c("high", "mid", "low"),
    forage_access_scale = c(1.0, 0.8, 0.6),
    stringsAsFactors = FALSE
  )

  rows <- list()
  scenarios <- list()
  idx <- 0L

  for (aridity_level in names(aridity_levels)) {
    base <- compile_scenario_yaml(scenario_contract_reference_path(aridity_levels[[aridity_level]]))
    for (j in seq_len(nrow(access_levels))) {
      idx <- idx + 1L
      access_level <- access_levels$access_level[[j]]
      access_scale <- access_levels$forage_access_scale[[j]]
      scenario_id <- sprintf("reference_aridity_%s_access_%s_v2", aridity_level, access_level)

      scenario <- base
      scenario$scenario_id <- scenario_id
      scenario$outputs$scenario_slug <- scenario_id
      scenario$runtime$forage_access_scale <- access_scale

      rows[[idx]] <- data.frame(
        scenario_id = scenario_id,
        aridity_level = aridity_level,
        aridity_index = match(aridity_level, c("low", "mid", "high")),
        access_level = access_level,
        access_index = match(access_level, c("low", "mid", "high")),
        forage_access_scale = access_scale,
        stringsAsFactors = FALSE
      )
      scenarios[[scenario_id]] <- scenario
    }
  }

  matrix <- do.call(rbind, rows)
  rownames(matrix) <- NULL
  matrix <- matrix[order(matrix$aridity_index, matrix$access_index), , drop = FALSE]

  list(
    matrix = matrix,
    scenarios = scenarios
  )
}

summarise_experiment_c_v2_matrix <- function(replicate_df) {
  keys <- unique(replicate_df[, c("aridity_level", "aridity_index", "access_level", "access_index", "forage_access_scale"), drop = FALSE])
  keys <- keys[order(keys$aridity_index, keys$access_index), , drop = FALSE]

  rows <- vector("list", nrow(keys))
  for (i in seq_len(nrow(keys))) {
    key <- keys[i, , drop = FALSE]
    subset <- replicate_df[
      replicate_df$aridity_level == key$aridity_level &
        replicate_df$access_level == key$access_level,
      ,
      drop = FALSE
    ]

    dmi_stats <- interval_stats(subset$mean_daily_dmi)
    drink_stats <- interval_stats(subset$mean_daily_drinking_water)
    energy_stats <- interval_stats(subset$mean_energy_balance)
    shoot_stats <- interval_stats(subset$final_total_shoot_biomass_kg)
    fuel_stats <- interval_stats(subset$final_fine_fuel_proxy_kg)

    rows[[i]] <- data.frame(
      aridity_level = key$aridity_level,
      aridity_index = key$aridity_index,
      access_level = key$access_level,
      access_index = key$access_index,
      forage_access_scale = key$forage_access_scale,
      mean_daily_dmi_median = dmi_stats[["median"]],
      mean_daily_dmi_p05 = dmi_stats[["p05"]],
      mean_daily_dmi_p95 = dmi_stats[["p95"]],
      mean_daily_drinking_water_median = drink_stats[["median"]],
      mean_daily_drinking_water_p05 = drink_stats[["p05"]],
      mean_daily_drinking_water_p95 = drink_stats[["p95"]],
      mean_energy_balance_median = energy_stats[["median"]],
      final_total_shoot_biomass_kg_median = shoot_stats[["median"]],
      final_fine_fuel_proxy_kg_median = fuel_stats[["median"]],
      n = as.integer(dmi_stats[["n"]]),
      stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

derive_experiment_c_v2_claim_metrics <- function(summary_df) {
  full_access <- summary_df[summary_df$access_level == "high", , drop = FALSE]
  full_access <- full_access[order(full_access$aridity_index), , drop = FALSE]

  water_monotonic <- as.numeric(
    nrow(full_access) == 3L &&
      all(diff(full_access$mean_daily_drinking_water_median) > 0)
  )

  aridity_levels <- unique(summary_df$aridity_level)
  intake_monotonic_any <- FALSE
  for (level in aridity_levels) {
    subset <- summary_df[summary_df$aridity_level == level, , drop = FALSE]
    subset <- subset[order(subset$access_index), , drop = FALSE]
    if (nrow(subset) == 3L && all(diff(subset$mean_daily_dmi_median) > 0)) {
      intake_monotonic_any <- TRUE
      break
    }
  }

  high_low <- summary_df[
    summary_df$aridity_level == "high" & summary_df$access_level == "low",
    "mean_daily_dmi_median",
    drop = TRUE
  ]
  low_high <- summary_df[
    summary_df$aridity_level == "low" & summary_df$access_level == "high",
    "mean_daily_dmi_median",
    drop = TRUE
  ]
  delta_low_high <- if (length(high_low) == 1L && length(low_high) == 1L) {
    as.numeric(high_low - low_high)
  } else {
    NA_real_
  }

  c(
    water_monotonic_signal = water_monotonic,
    intake_monotonic_signal = as.numeric(isTRUE(intake_monotonic_any)),
    delta_intake_low_vs_high = delta_low_high
  )
}

#' Run Experiment C v2 (aridity x forage-access matrix)
#'
#' @param base_dir Base artefact directory.
#' @param seeds Integer vector of seeds for matrix runs.
#' @param scenario_slug Output scenario slug for this experiment bundle.
#' @param gate_claims Logical; when `TRUE`, required claims must be supported.
#'
#' @return List of summary and artefact paths.
run_experiment_c_aridity_gradient_v2 <- function(base_dir = file.path("artefacts", "canonical_runs"),
                                                 seeds = 701:720,
                                                 scenario_slug = "experiment_c_aridity_gradient_v2",
                                                 gate_claims = TRUE) {
  matrix_bundle <- build_aridity_access_matrix_v2()
  matrix <- matrix_bundle$matrix
  seed_vec <- normalise_ensemble_seeds(seeds)

  rows <- list()
  idx <- 0L
  for (i in seq_len(nrow(matrix))) {
    scenario_id <- matrix$scenario_id[[i]]
    base_scenario <- matrix_bundle$scenarios[[scenario_id]]

    for (seed in seed_vec) {
      idx <- idx + 1L
      scenario <- base_scenario
      scenario$runtime$seed <- as.integer(seed)
      scenario$outputs$scenario_slug <- file.path(scenario_slug, sprintf("%s_seed_%03d", scenario_id, seed))

      run <- run_scenario_v1(scenario = scenario, base_dir = base_dir)
      herb <- run$herbivore_daily
      final <- read_final_structure_metrics_from_result(run)

      rows[[idx]] <- data.frame(
        scenario_id = scenario_id,
        aridity_level = matrix$aridity_level[[i]],
        aridity_index = matrix$aridity_index[[i]],
        access_level = matrix$access_level[[i]],
        access_index = matrix$access_index[[i]],
        forage_access_scale = matrix$forage_access_scale[[i]],
        seed_value = as.integer(seed),
        run_id = as.character(run$run_id),
        mean_daily_dmi = mean(herb$DailyDMI),
        mean_daily_dist_m = mean(herb$DailyDistMoved),
        mean_daily_forage_water = mean(herb$DailyForageWater),
        mean_daily_drinking_water = mean(herb$DailyWaterDrinking),
        mean_energy_balance = mean(herb$EnergyBalance),
        final_total_shoot_biomass_kg = as.numeric(final$total_shoot_biomass_kg),
        final_fine_fuel_proxy_kg = as.numeric(final$fine_fuel_proxy_kg),
        stringsAsFactors = FALSE
      )
    }
  }

  replicate_df <- do.call(rbind, rows)
  rownames(replicate_df) <- NULL
  summary_df <- summarise_experiment_c_v2_matrix(replicate_df)
  claim_metrics <- derive_experiment_c_v2_claim_metrics(summary_df)
  claim_status <- evaluate_claim_registry_v1(
    experiment_id = "experiment_c_v2",
    metrics = claim_metrics
  )
  if (isTRUE(gate_claims)) {
    assert_required_claims_supported(claim_status)
  }

  expected_direction <- data.frame(
    metric = names(claim_metrics),
    observed_value = as.numeric(claim_metrics),
    stringsAsFactors = FALSE
  )

  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  matrix_path <- file.path(run_dir, "experiment_c_matrix_v2.csv")
  replicate_path <- file.path(run_dir, "experiment_c_replicates_v2.csv")
  summary_path <- file.path(run_dir, "experiment_c_summary_v2.csv")
  expected_path <- file.path(run_dir, "experiment_c_expected_direction_v2.csv")
  claims_path <- file.path(run_dir, "experiment_c_claims_v2.csv")
  summary_units_path <- file.path(run_dir, "experiment_c_summary_v2_units.csv")
  expected_units_path <- file.path(run_dir, "experiment_c_expected_direction_v2_units.csv")
  figure_path <- file.path(run_dir, "experiment_c_aridity_gradient_v2.png")
  report_path <- file.path(run_dir, "experiment_c_report_v2.md")

  utils::write.csv(matrix, matrix_path, row.names = FALSE)
  utils::write.csv(replicate_df, replicate_path, row.names = FALSE)
  utils::write.csv(summary_df, summary_path, row.names = FALSE)
  utils::write.csv(expected_direction, expected_path, row.names = FALSE)
  utils::write.csv(claim_status, claims_path, row.names = FALSE)
  write_metric_units_sidecar_v1(
    metric_names = c(
      "mean_daily_dmi",
      "mean_daily_drinking_water",
      "mean_energy_balance",
      "final_total_shoot_biomass_kg",
      "final_fine_fuel_proxy_kg"
    ),
    output_path = summary_units_path
  )
  write_metric_units_sidecar_v1(
    metric_names = c("water_monotonic_signal", "intake_monotonic_signal", "delta_intake_low_vs_high"),
    output_path = expected_units_path
  )

  grDevices::png(figure_path, width = 1400, height = 700)
  op <- graphics::par(mfrow = c(1, 2), mar = c(5, 5, 3, 1))

  plot_df <- summary_df[summary_df$access_level == "high", , drop = FALSE]
  plot_df <- plot_df[order(plot_df$aridity_index), , drop = FALSE]
  graphics::plot(
    plot_df$aridity_index,
    plot_df$mean_daily_drinking_water_median,
    type = "b",
    xaxt = "n",
    pch = 19,
    col = "#bc4749",
    xlab = "Aridity gradient",
    ylab = "Median daily drinking water (g)",
    main = "Water-demand signal (high access)"
  )
  graphics::axis(1, at = plot_df$aridity_index, labels = plot_df$aridity_level)

  template <- summary_df[summary_df$aridity_level == "low", , drop = FALSE]
  template <- template[order(template$access_index), , drop = FALSE]
  graphics::plot(
    template$access_index,
    template$mean_daily_dmi_median,
    type = "n",
    xaxt = "n",
    xlab = "Access level",
    ylab = "Median daily DMI (g DM)",
    main = "DMI by access level (within aridity)"
  )
  for (level in c("low", "mid", "high")) {
    subset <- summary_df[summary_df$aridity_level == level, , drop = FALSE]
    subset <- subset[order(subset$access_index), , drop = FALSE]
    graphics::lines(
      subset$access_index,
      subset$mean_daily_dmi_median,
      type = "b",
      lwd = 2,
      col = c(low = "#386641", mid = "#6a994e", high = "#a7c957")[[level]]
    )
  }
  graphics::axis(1, at = c(1, 2, 3), labels = c("low", "mid", "high"))
  graphics::legend(
    "topright",
    legend = c("aridity low", "aridity mid", "aridity high"),
    col = c("#386641", "#6a994e", "#a7c957"),
    lty = 1,
    lwd = 2,
    cex = 0.9
  )

  graphics::par(op)
  grDevices::dev.off()

  supported <- claim_status[claim_status$status == "supported", , drop = FALSE]
  unsupported <- claim_status[claim_status$status != "supported", , drop = FALSE]
  report_lines <- c(
    "# Experiment C v2: Aridity x Forage-Access Matrix",
    "",
    "## Design",
    sprintf("- Matrix size: `%d` scenarios (`3 aridity x 3 access`), each with `%d` seeds.", nrow(matrix), length(seed_vec)),
    "- Forage-access scale levels: `1.0`, `0.8`, `0.6`.",
    "",
    "## Supported findings",
    "- Units: intake in `g_dm_per_day`; water in `g_h2o_per_day`; biomass in `kg_dm`.",
    if (nrow(supported) == 0L) "- None." else paste0(
      "- `", supported$claim_id, "` (observed=", format(round(supported$observed_value, 4), trim = TRUE), ")."
    ),
    "",
    "## Non-supported or partial findings",
    if (nrow(unsupported) == 0L) "- None." else paste0(
      "- `", unsupported$claim_id, "`: ", unsupported$status,
      " (observed=", format(round(unsupported$observed_value, 4), trim = TRUE),
      ", threshold=", unsupported$threshold, ")."
    ),
    "",
    "## Interpretation boundary",
    "- Required claims are gated; optional intake-limitation claims are reported explicitly if not supported.",
    "- Outputs remain mechanism-focused and not population-demographic forecasts."
  )
  writeLines(report_lines, report_path)

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = as.integer(seed_vec[[1]]),
    scenario_parameters = list(
      seeds = seed_vec,
      matrix = matrix
    ),
    output_files = c(
      matrix = file.path(base_dir, scenario_slug, basename(matrix_path)),
      replicates = file.path(base_dir, scenario_slug, basename(replicate_path)),
      summary = file.path(base_dir, scenario_slug, basename(summary_path)),
      expected_direction = file.path(base_dir, scenario_slug, basename(expected_path)),
      claim_status = file.path(base_dir, scenario_slug, basename(claims_path)),
      summary_units = file.path(base_dir, scenario_slug, basename(summary_units_path)),
      expected_units = file.path(base_dir, scenario_slug, basename(expected_units_path)),
      figure = file.path(base_dir, scenario_slug, basename(figure_path)),
      report = file.path(base_dir, scenario_slug, basename(report_path))
    )
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    run_dir = run_dir,
    matrix_path = matrix_path,
    replicate_path = replicate_path,
    summary_path = summary_path,
    expected_path = expected_path,
    claims_path = claims_path,
    summary_units_path = summary_units_path,
    expected_units_path = expected_units_path,
    figure_path = figure_path,
    report_path = report_path,
    manifest_path = manifest_path,
    matrix = matrix,
    replicates = replicate_df,
    summary = summary_df,
    claim_status = claim_status
  )
}
