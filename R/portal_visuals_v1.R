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

  compare_path <- file.path(figure_dir, sprintf("%s_endpoint_comparison.png", prefix))
  grDevices::png(compare_path, width = 1400, height = 800, res = 130)
  old_par <- graphics::par(no.readonly = TRUE)

  ord <- order(endpoint_summary$final_total_shoot_biomass_kg, decreasing = TRUE)
  graphics::barplot(
    height = endpoint_summary$final_total_shoot_biomass_kg[ord],
    names.arg = endpoint_summary$run_label[ord],
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

  merged <- merge(endpoint_summary, design_table, by = "run_label", all.x = TRUE)
  numeric_value <- suppressWarnings(as.numeric(merged$parameter_value))
  finite_rows <- which(is.finite(numeric_value) & merged$parameter_path != "baseline")

  graphics::par(mfrow = c(2, 1), mar = c(4.2, 4.2, 2.2, 1.2))

  if (length(finite_rows) > 0L) {
    graphics::plot(
      numeric_value[finite_rows],
      merged$final_total_shoot_biomass_kg[finite_rows],
      pch = 19,
      col = "#1d3557",
      xlab = "Parameter value",
      ylab = "kg",
      main = "Sensitivity effect on final total shoot biomass"
    )

    graphics::plot(
      numeric_value[finite_rows],
      merged$mean_daily_dmi[finite_rows],
      pch = 19,
      col = "#2a9d8f",
      xlab = "Parameter value",
      ylab = "kg/day",
      main = "Sensitivity effect on daily DMI"
    )
  } else {
    graphics::plot.new()
    graphics::title(main = "No numeric sensitivity parameter values for effect plot")
    graphics::plot.new()
    graphics::title(main = "No numeric sensitivity parameter values for effect plot")
  }

  graphics::par(old_par2)
  grDevices::dev.off()

  c(endpoint_comparison = compare_path, sensitivity_effects = effects_path)
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
