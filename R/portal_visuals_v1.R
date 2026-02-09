# Portal table + figure builders for ecologist-facing outputs.

portal_build_daily_summary_v1 <- function(herbivore_daily,
                                          structure_fuel_metrics) {
  if (!is.data.frame(herbivore_daily) || nrow(herbivore_daily) < 1L) {
    portal_abort_v1(
      "`herbivore_daily` must be a non-empty data.frame.",
      class = "herbivoreTTR_portal_summary_invalid"
    )
  }
  if (!is.data.frame(structure_fuel_metrics) || nrow(structure_fuel_metrics) < 1L) {
    portal_abort_v1(
      "`structure_fuel_metrics` must be a non-empty data.frame.",
      class = "herbivoreTTR_portal_summary_invalid"
    )
  }

  herb <- herbivore_daily
  herb_agg <- stats::aggregate(
    herb[, c(
      "DailyDMI", "DailyDistMoved", "DailyForageWater", "DailyWaterDrinking",
      "EnergyBalance", "WaterBalance", "BodyConditionIndex", "PhysiologicalStressFlag"
    ), drop = FALSE],
    by = list(Day = herb$Day),
    FUN = mean
  )

  names(herb_agg) <- c(
    "Day",
    "mean_daily_dmi",
    "mean_daily_dist_m",
    "mean_daily_forage_water",
    "mean_daily_drinking_water",
    "mean_energy_balance",
    "mean_water_balance",
    "mean_body_condition_index",
    "mean_physiological_stress_flag"
  )

  structure <- structure_fuel_metrics[, c(
    "Day",
    "total_shoot_biomass_kg",
    "grass_shoot_biomass_kg",
    "woody_shoot_biomass_kg",
    "fine_fuel_proxy_kg",
    "browseable_biomass_kg",
    "defended_shoot_biomass_kg",
    "mean_height_m",
    "p90_height_m"
  ), drop = FALSE]

  out <- merge(herb_agg, structure, by = "Day", all = FALSE, sort = TRUE)
  out <- out[order(out$Day), , drop = FALSE]
  rownames(out) <- NULL
  out
}

portal_build_endpoint_summary_v1 <- function(daily_summary,
                                             run_label) {
  if (!is.data.frame(daily_summary) || nrow(daily_summary) < 1L) {
    portal_abort_v1(
      "`daily_summary` must be a non-empty data.frame.",
      class = "herbivoreTTR_portal_summary_invalid"
    )
  }
  final <- daily_summary[which.max(daily_summary$Day), , drop = FALSE]
  final$run_label <- as.character(run_label)

  out <- data.frame(
    run_label = final$run_label,
    final_day = as.integer(final$Day),
    mean_daily_dmi = as.numeric(final$mean_daily_dmi),
    mean_energy_balance = as.numeric(final$mean_energy_balance),
    mean_water_balance = as.numeric(final$mean_water_balance),
    mean_body_condition_index = as.numeric(final$mean_body_condition_index),
    stress_flag_mean = as.numeric(final$mean_physiological_stress_flag),
    final_total_shoot_biomass_kg = as.numeric(final$total_shoot_biomass_kg),
    final_fine_fuel_proxy_kg = as.numeric(final$fine_fuel_proxy_kg),
    final_browseable_biomass_kg = as.numeric(final$browseable_biomass_kg),
    stringsAsFactors = FALSE
  )

  out
}

portal_count_non_finite_df_v1 <- function(df) {
  if (!is.data.frame(df) || nrow(df) < 1L) {
    return(0L)
  }
  numeric_cols <- df[, vapply(df, is.numeric, logical(1L)), drop = FALSE]
  if (ncol(numeric_cols) < 1L) {
    return(0L)
  }
  as.integer(sum(!is.finite(as.matrix(numeric_cols))))
}

portal_count_negative_biomass_v1 <- function(plants,
                                             tolerance = CONSTANTS$TOLERANCE) {
  if (!is.data.frame(plants) || nrow(plants) < 1L) {
    return(0L)
  }
  cols <- intersect(c("ms", "mr", "bleaf", "bstem", "bdef"), names(plants))
  if (length(cols) < 1L) {
    return(0L)
  }
  as.integer(sum(plants[, cols, drop = FALSE] < -tolerance))
}

portal_count_gut_violations_v1 <- function(final_herbivores,
                                           tolerance = CONSTANTS$TOLERANCE) {
  if (!is.list(final_herbivores) || length(final_herbivores) < 1L) {
    return(0L)
  }

  flags <- vapply(
    final_herbivores,
    function(h) {
      if (!is.list(h) || !is.finite(h$gut_content) || !is.finite(h$gut_capacity)) {
        return(1L)
      }
      as.integer((h$gut_content - h$gut_capacity) > tolerance)
    },
    integer(1L)
  )
  as.integer(sum(flags))
}

portal_domain_sanity_summary_v1 <- function(run_result,
                                            daily_summary,
                                            run_label) {
  energy_jump <- if (nrow(daily_summary) > 1L) {
    max(abs(diff(daily_summary$mean_energy_balance)))
  } else {
    0
  }
  water_jump <- if (nrow(daily_summary) > 1L) {
    max(abs(diff(daily_summary$mean_water_balance)))
  } else {
    0
  }

  data.frame(
    run_label = as.character(run_label),
    herbivore_non_finite_count = portal_count_non_finite_df_v1(run_result$herbivore_daily),
    structure_non_finite_count = portal_count_non_finite_df_v1(run_result$structure_fuel_metrics),
    negative_biomass_violations = portal_count_negative_biomass_v1(run_result$final_plants),
    gut_capacity_violations = portal_count_gut_violations_v1(run_result$final_herbivores),
    max_abs_daily_energy_jump = as.numeric(energy_jump),
    max_abs_daily_water_jump = as.numeric(water_jump),
    stringsAsFactors = FALSE
  )
}

portal_plot_colormap_v1 <- function(values) {
  if (!is.numeric(values) || length(values) < 1L) {
    return(rep("#457b9d", 1L))
  }
  breaks <- seq(min(values, na.rm = TRUE), max(values, na.rm = TRUE), length.out = 6)
  idx <- findInterval(values, breaks, all.inside = TRUE)
  palette <- c("#264653", "#2a9d8f", "#8ab17d", "#e9c46a", "#f4a261", "#e76f51")
  palette[pmax(1L, pmin(length(palette), idx))]
}

portal_slugify_metric_label_v1 <- function(x) {
  out <- tolower(gsub("[^a-zA-Z0-9]+", "_", as.character(x)))
  out <- gsub("_+", "_", out)
  out <- gsub("^_|_$", "", out)
  if (!nzchar(out)) {
    out <- "parameter"
  }
  out
}

portal_join_endpoint_design_v1 <- function(endpoint_summary,
                                           design_table) {
  if (!is.data.frame(endpoint_summary) || nrow(endpoint_summary) < 1L) {
    portal_abort_v1(
      "`endpoint_summary` must be a non-empty data.frame.",
      class = "herbivoreTTR_portal_summary_invalid"
    )
  }
  if (!is.data.frame(design_table) || nrow(design_table) < 1L) {
    portal_abort_v1(
      "`design_table` must be a non-empty data.frame.",
      class = "herbivoreTTR_portal_summary_invalid"
    )
  }

  keep <- intersect(
    c("run_label", "run_index", "design", "parameter_path", "parameter_value", "change_summary"),
    names(design_table)
  )
  design_small <- unique(design_table[, keep, drop = FALSE])

  merged <- merge(
    endpoint_summary,
    design_small,
    by = "run_label",
    all.x = TRUE,
    sort = FALSE
  )

  if ("run_index" %in% names(merged)) {
    merged <- merged[order(merged$run_index, merged$run_label), , drop = FALSE]
  } else {
    merged <- merged[order(merged$run_label), , drop = FALSE]
  }
  rownames(merged) <- NULL
  merged
}

portal_add_sensitivity_deltas_v1 <- function(endpoint_with_design) {
  if (!is.data.frame(endpoint_with_design) || nrow(endpoint_with_design) < 1L) {
    portal_abort_v1(
      "`endpoint_with_design` must be a non-empty data.frame.",
      class = "herbivoreTTR_portal_summary_invalid"
    )
  }

  baseline_idx <- which(endpoint_with_design$parameter_path == "baseline")
  if (length(baseline_idx) < 1L) {
    baseline_idx <- which(endpoint_with_design$run_label == "baseline")
  }
  if (length(baseline_idx) < 1L) {
    baseline_idx <- 1L
  }
  baseline_idx <- baseline_idx[[1]]

  baseline_biomass <- as.numeric(endpoint_with_design$final_total_shoot_biomass_kg[[baseline_idx]])
  baseline_dmi <- as.numeric(endpoint_with_design$mean_daily_dmi[[baseline_idx]])
  baseline_run <- as.character(endpoint_with_design$run_label[[baseline_idx]])

  out <- endpoint_with_design
  out$baseline_run_label <- baseline_run
  out$delta_final_total_shoot_biomass_kg <- as.numeric(out$final_total_shoot_biomass_kg) - baseline_biomass
  out$delta_mean_daily_dmi <- as.numeric(out$mean_daily_dmi) - baseline_dmi
  out
}

portal_eval_acceptance_check_v1 <- function(observed,
                                            comparator,
                                            threshold) {
  if (!is.finite(observed)) {
    return(FALSE)
  }
  if (identical(comparator, "<=")) {
    return(observed <= threshold)
  }
  if (identical(comparator, ">=")) {
    return(observed >= threshold)
  }
  if (identical(comparator, "==")) {
    return(observed == threshold)
  }
  FALSE
}

portal_make_acceptance_row_v1 <- function(run_label,
                                          acceptance_profile,
                                          check_id,
                                          metric,
                                          comparator,
                                          threshold,
                                          observed,
                                          severity = "advisory",
                                          note = "") {
  data.frame(
    run_label = as.character(run_label),
    acceptance_profile = as.character(acceptance_profile),
    check_id = as.character(check_id),
    metric = as.character(metric),
    comparator = as.character(comparator),
    threshold = as.numeric(threshold),
    observed_value = as.numeric(observed),
    pass = as.logical(portal_eval_acceptance_check_v1(observed, comparator, threshold)),
    severity = as.character(severity),
    note = as.character(note),
    stringsAsFactors = FALSE
  )
}

portal_acceptance_rows_for_run_v1 <- function(run_result,
                                              acceptance_profile = c("standard", "balanced_demo", "stress_demo")) {
  profile <- match.arg(acceptance_profile)
  if (!is.list(run_result) || is.null(run_result$daily_summary) || is.null(run_result$endpoint_summary) ||
      is.null(run_result$sanity_summary)) {
    portal_abort_v1(
      "`run_result` must include `daily_summary`, `endpoint_summary`, and `sanity_summary`.",
      class = "herbivoreTTR_portal_summary_invalid"
    )
  }

  run_label <- as.character(run_result$endpoint_summary$run_label[[1]])
  daily <- run_result$daily_summary
  endpoint <- run_result$endpoint_summary[1, , drop = FALSE]
  sanity <- run_result$sanity_summary[1, , drop = FALSE]
  stress_fraction <- mean(as.numeric(daily$mean_physiological_stress_flag) >= 0.5, na.rm = TRUE)

  rows <- list(
    portal_make_acceptance_row_v1(
      run_label = run_label,
      acceptance_profile = profile,
      check_id = "herbivore_non_finite_count_zero",
      metric = "herbivore_non_finite_count",
      comparator = "<=",
      threshold = 0,
      observed = sanity$herbivore_non_finite_count[[1]],
      severity = "critical"
    ),
    portal_make_acceptance_row_v1(
      run_label = run_label,
      acceptance_profile = profile,
      check_id = "structure_non_finite_count_zero",
      metric = "structure_non_finite_count",
      comparator = "<=",
      threshold = 0,
      observed = sanity$structure_non_finite_count[[1]],
      severity = "critical"
    ),
    portal_make_acceptance_row_v1(
      run_label = run_label,
      acceptance_profile = profile,
      check_id = "negative_biomass_violations_zero",
      metric = "negative_biomass_violations",
      comparator = "<=",
      threshold = 0,
      observed = sanity$negative_biomass_violations[[1]],
      severity = "critical"
    ),
    portal_make_acceptance_row_v1(
      run_label = run_label,
      acceptance_profile = profile,
      check_id = "gut_capacity_violations_zero",
      metric = "gut_capacity_violations",
      comparator = "<=",
      threshold = 0,
      observed = sanity$gut_capacity_violations[[1]],
      severity = "critical"
    )
  )

  if (identical(profile, "balanced_demo")) {
    rows <- c(
      rows,
      list(
        portal_make_acceptance_row_v1(
          run_label = run_label,
          acceptance_profile = profile,
          check_id = "final_body_condition_at_least_0_5",
          metric = "mean_body_condition_index",
          comparator = ">=",
          threshold = 0.5,
          observed = endpoint$mean_body_condition_index[[1]],
          note = "Balanced demo should retain moderate body condition over short horizon."
        ),
        portal_make_acceptance_row_v1(
          run_label = run_label,
          acceptance_profile = profile,
          check_id = "final_mean_energy_balance_at_least_minus_1e5",
          metric = "mean_energy_balance",
          comparator = ">=",
          threshold = -1e5,
          observed = endpoint$mean_energy_balance[[1]],
          note = "Balanced demo should avoid extreme energy deficits."
        ),
        portal_make_acceptance_row_v1(
          run_label = run_label,
          acceptance_profile = profile,
          check_id = "stress_fraction_at_most_1_0",
          metric = "stress_fraction",
          comparator = "<=",
          threshold = 1.0,
          observed = stress_fraction,
          note = "Short-run demo stress prevalence reported for interpretation."
        )
      )
    )
  }

  if (identical(profile, "stress_demo")) {
    rows <- c(
      rows,
      list(
        portal_make_acceptance_row_v1(
          run_label = run_label,
          acceptance_profile = profile,
          check_id = "final_body_condition_at_most_0_05",
          metric = "mean_body_condition_index",
          comparator = "<=",
          threshold = 0.05,
          observed = endpoint$mean_body_condition_index[[1]],
          note = "Stress demo is expected to show severe body-condition decline."
        ),
        portal_make_acceptance_row_v1(
          run_label = run_label,
          acceptance_profile = profile,
          check_id = "final_mean_energy_balance_at_most_minus_2e5",
          metric = "mean_energy_balance",
          comparator = "<=",
          threshold = -2e5,
          observed = endpoint$mean_energy_balance[[1]],
          note = "Stress demo is expected to show pronounced energy deficit."
        ),
        portal_make_acceptance_row_v1(
          run_label = run_label,
          acceptance_profile = profile,
          check_id = "stress_fraction_at_least_0_9",
          metric = "stress_fraction",
          comparator = ">=",
          threshold = 0.9,
          observed = stress_fraction,
          note = "Stress demo should sustain high physiological stress prevalence."
        )
      )
    )
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

portal_build_acceptance_summary_v1 <- function(run_results,
                                               acceptance_profile = c("standard", "balanced_demo", "stress_demo")) {
  profile <- match.arg(acceptance_profile)
  if (!is.list(run_results) || length(run_results) < 1L) {
    portal_abort_v1(
      "`run_results` must be a non-empty list.",
      class = "herbivoreTTR_portal_summary_invalid"
    )
  }

  rows <- lapply(
    run_results,
    function(result) portal_acceptance_rows_for_run_v1(result, acceptance_profile = profile)
  )
  out <- do.call(rbind, rows)
  out <- out[order(out$run_label, out$check_id), , drop = FALSE]
  rownames(out) <- NULL
  out
}

portal_write_single_figures_v1 <- function(run_result,
                                           daily_summary,
                                           figure_dir,
                                           run_label) {
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

  time_path <- file.path(figure_dir, sprintf("%s_time_series.png", run_label))
  grDevices::png(time_path, width = 1400, height = 1000, res = 130)
  old_par <- graphics::par(no.readonly = TRUE)

  graphics::par(mfrow = c(2, 2), mar = c(4.2, 4.2, 2.2, 1.2))

  graphics::plot(
    daily_summary$Day,
    daily_summary$mean_daily_dmi,
    type = "l",
    lwd = 2,
    col = "#2a9d8f",
    xlab = "Day",
    ylab = "kg/day",
    main = "Daily dry matter intake"
  )
  graphics::plot(
    daily_summary$Day,
    daily_summary$mean_energy_balance,
    type = "l",
    lwd = 2,
    col = "#457b9d",
    xlab = "Day",
    ylab = "kJ/day",
    main = "Energy balance"
  )
  graphics::abline(h = 0, lty = 2, col = "#6c757d")

  graphics::plot(
    daily_summary$Day,
    daily_summary$mean_water_balance,
    type = "l",
    lwd = 2,
    col = "#1d3557",
    xlab = "Day",
    ylab = "L/day",
    main = "Water balance"
  )
  graphics::abline(h = 0, lty = 2, col = "#6c757d")

  graphics::plot(
    daily_summary$Day,
    daily_summary$total_shoot_biomass_kg,
    type = "l",
    lwd = 2,
    col = "#6a994e",
    xlab = "Day",
    ylab = "kg",
    main = "Total shoot biomass"
  )

  graphics::par(old_par)
  grDevices::dev.off()

  spatial_path <- file.path(figure_dir, sprintf("%s_spatial_snapshots.png", run_label))
  grDevices::png(spatial_path, width = 1400, height = 700, res = 130)
  old_par2 <- graphics::par(no.readonly = TRUE)

  graphics::par(mfrow = c(1, 2), mar = c(4.2, 4.2, 2.2, 1.2))

  start_plants <- run_result$first_day_plants
  final_plants <- run_result$final_plants

  if (is.data.frame(start_plants) && all(c("xcor", "ycor", "ms") %in% names(start_plants))) {
    graphics::plot(
      start_plants$xcor,
      start_plants$ycor,
      pch = 16,
      cex = 0.55,
      col = portal_plot_colormap_v1(start_plants$ms),
      xlab = "x",
      ylab = "y",
      main = "Initial plant shoot biomass"
    )
  } else {
    graphics::plot.new()
    graphics::title(main = "Initial spatial snapshot unavailable")
  }

  if (is.data.frame(final_plants) && all(c("xcor", "ycor", "ms") %in% names(final_plants))) {
    graphics::plot(
      final_plants$xcor,
      final_plants$ycor,
      pch = 16,
      cex = 0.55,
      col = portal_plot_colormap_v1(final_plants$ms),
      xlab = "x",
      ylab = "y",
      main = "Final plant shoot biomass"
    )
  } else {
    graphics::plot.new()
    graphics::title(main = "Final spatial snapshot unavailable")
  }

  graphics::par(old_par2)
  grDevices::dev.off()

  c(time_series = time_path, spatial = spatial_path)
}

portal_write_sensitivity_figures_v1 <- function(endpoint_summary,
                                                design_table,
                                                figure_dir,
                                                prefix = "sensitivity") {
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

  merged <- endpoint_summary
  if (!all(c("parameter_path", "parameter_value") %in% names(merged))) {
    merged <- portal_join_endpoint_design_v1(endpoint_summary, design_table)
  }
  if (!all(c("delta_final_total_shoot_biomass_kg", "delta_mean_daily_dmi") %in% names(merged))) {
    merged <- portal_add_sensitivity_deltas_v1(merged)
  }

  compare_path <- file.path(figure_dir, sprintf("%s_endpoint_comparison.png", prefix))
  grDevices::png(compare_path, width = 1400, height = 800, res = 130)
  old_par <- graphics::par(no.readonly = TRUE)

  ord <- order(merged$final_total_shoot_biomass_kg, decreasing = TRUE)
  graphics::barplot(
    height = merged$final_total_shoot_biomass_kg[ord],
    names.arg = merged$run_label[ord],
    las = 2,
    col = "#6a994e",
    border = NA,
    ylab = "kg",
    main = "Final total shoot biomass by sensitivity run"
  )
  graphics::par(old_par)
  grDevices::dev.off()

  effects_path <- file.path(figure_dir, sprintf("%s_effects.png", prefix))
  grDevices::png(effects_path, width = 1400, height = 900, res = 130)
  old_par2 <- graphics::par(no.readonly = TRUE)

  graphics::par(mfrow = c(2, 1), mar = c(4.2, 4.2, 2.2, 1.2))
  run_ord <- order(merged$delta_final_total_shoot_biomass_kg, decreasing = TRUE)
  bar_cols <- ifelse(merged$parameter_path == "baseline", "#a8a8a8", "#457b9d")
  graphics::barplot(
    height = merged$delta_final_total_shoot_biomass_kg[run_ord],
    names.arg = merged$run_label[run_ord],
    las = 2,
    col = bar_cols[run_ord],
    border = NA,
    ylab = "kg",
    main = "Delta final shoot biomass vs baseline"
  )
  graphics::abline(h = 0, lty = 2, col = "#6c757d")

  graphics::barplot(
    height = merged$delta_mean_daily_dmi[run_ord],
    names.arg = merged$run_label[run_ord],
    las = 2,
    col = bar_cols[run_ord],
    border = NA,
    ylab = "kg/day",
    main = "Delta mean daily DMI vs baseline"
  )
  graphics::abline(h = 0, lty = 2, col = "#6c757d")

  graphics::par(old_par2)
  grDevices::dev.off()

  effect_paths <- c(sensitivity_effects = effects_path)
  params <- unique(merged$parameter_path)
  params <- params[is.finite(nchar(params)) & params != "baseline"]

  for (param in params) {
    idx <- which(merged$parameter_path == param)
    values <- suppressWarnings(as.numeric(merged$parameter_value[idx]))
    finite_idx <- idx[is.finite(values)]

    param_slug <- portal_slugify_metric_label_v1(param)
    param_path <- file.path(figure_dir, sprintf("%s_effects_%s.png", prefix, param_slug))
    grDevices::png(param_path, width = 1400, height = 900, res = 130)
    old_par_param <- graphics::par(no.readonly = TRUE)
    graphics::par(mfrow = c(2, 1), mar = c(4.2, 4.2, 2.2, 1.2))

    if (length(finite_idx) > 0L) {
      graphics::plot(
        as.numeric(merged$parameter_value[finite_idx]),
        merged$delta_final_total_shoot_biomass_kg[finite_idx],
        pch = 19,
        col = "#1d3557",
        xlab = "Parameter value",
        ylab = "Delta kg",
        main = sprintf("%s effect on final shoot biomass", param)
      )
      graphics::abline(h = 0, lty = 2, col = "#6c757d")

      graphics::plot(
        as.numeric(merged$parameter_value[finite_idx]),
        merged$delta_mean_daily_dmi[finite_idx],
        pch = 19,
        col = "#2a9d8f",
        xlab = "Parameter value",
        ylab = "Delta kg/day",
        main = sprintf("%s effect on mean daily DMI", param)
      )
      graphics::abline(h = 0, lty = 2, col = "#6c757d")
    } else {
      graphics::plot.new()
      graphics::title(main = sprintf("No numeric values for `%s`", param))
      graphics::plot.new()
      graphics::title(main = sprintf("No numeric values for `%s`", param))
    }

    graphics::par(old_par_param)
    grDevices::dev.off()
    effect_paths <- c(effect_paths, setNames(param_path, sprintf("sensitivity_effects_%s", param_slug)))
  }

  c(endpoint_comparison = compare_path, effect_paths)
}

portal_write_interactive_note_v1 <- function(run_dir,
                                             include_interactive = TRUE) {
  out_path <- file.path(run_dir, "reports", "interactive_notes.md")
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  lines <- c(
    "# Interactive exploration notes",
    "",
    if (isTRUE(include_interactive)) {
      "- Launch `Rscript portal/launch_gui_stub.R` for an interactive run/report browser and YAML editor."
    } else {
      "- Interactive outputs were disabled for this run."
    },
    "- Static CSV/PNG outputs in this run are the reproducible analysis source of truth."
  )
  writeLines(lines, con = out_path)
  out_path
}
