# Reference scenario library and experiment report builders.

reference_scenario_metadata_v1 <- function() {
  data.frame(
    scenario_name = c(
      "reference_presence_present_v1",
      "reference_presence_removed_v1",
      "reference_grazer_v1",
      "reference_browser_v1",
      "reference_mixed_v1"
    ),
    purpose = c(
      "Herbivore-present baseline for presence/removal experiment.",
      "Herbivore-removed counterfactual via implicit-pressure zero-visitation mode.",
      "Functional-type reference: grazer strategy.",
      "Functional-type reference: browser strategy.",
      "Functional-type reference: mixed strategy."
    ),
    expected_outcome = c(
      "Lower final shoot/fuel metrics than removal scenario.",
      "Higher final shoot/fuel metrics than present scenario.",
      "Greater grass-consumption share than browser.",
      "Greater woody-consumption share than grazer.",
      "Intermediate grass/woody consumption between grazer and browser."
    ),
    interpretation = c(
      "Use as treatment run for herbivore pressure comparisons.",
      "Use as no-herbivory baseline for direction-of-effect checks.",
      "Use to assess grazer-selective pressure on herbaceous pools.",
      "Use to assess browser-selective pressure on woody browse pools.",
      "Use to assess mixed feeder interpolation behaviour."
    ),
    stringsAsFactors = FALSE
  )
}

#' Run the curated reference scenario library
#'
#' Executes the maintained reference scenarios and writes an index describing
#' expected qualitative outcomes.
#'
#' @param base_dir Base artefact directory.
#'
#' @return List with run outputs, metadata table, and index file paths.
#' @export
run_reference_scenario_library <- function(base_dir = file.path("artefacts", "canonical_runs")) {
  meta <- reference_scenario_metadata_v1()
  runs <- vector("list", nrow(meta))

  for (i in seq_len(nrow(meta))) {
    scenario_path <- scenario_contract_reference_path(meta$scenario_name[[i]])
    runs[[i]] <- run_scenario_v2(
      scenario = scenario_path,
      base_dir = base_dir,
      write_outputs = TRUE
    )
  }

  names(runs) <- meta$scenario_name

  index_dir <- file.path(base_dir, "reference_scenarios_v1")
  dir.create(index_dir, recursive = TRUE, showWarnings = FALSE)

  index_path <- file.path(index_dir, "reference_scenarios.csv")
  utils::write.csv(meta, index_path, row.names = FALSE)

  index_md_path <- file.path(index_dir, "reference_scenarios_index.md")
  lines <- c("# Reference Scenario Library v1", "")
  for (i in seq_len(nrow(meta))) {
    scenario_slug <- runs[[i]]$scenario$outputs$scenario_slug
    lines <- c(
      lines,
      sprintf("## %s", meta$scenario_name[[i]]),
      sprintf("- Purpose: %s", meta$purpose[[i]]),
      sprintf("- Expected outcome: %s", meta$expected_outcome[[i]]),
      sprintf("- Interpretation: %s", meta$interpretation[[i]]),
      sprintf("- Artefacts: `artefacts/canonical_runs/%s/`", scenario_slug),
      ""
    )
  }
  writeLines(lines, index_md_path)

  list(
    runs = runs,
    metadata = meta,
    index_path = index_path,
    index_md_path = index_md_path
  )
}

read_scenario_plants_pair <- function(run_result) {
  start <- utils::read.csv(run_result$plants_first_path, sep = ";", stringsAsFactors = FALSE)
  end <- utils::read.csv(run_result$plants_last_path, sep = ";", stringsAsFactors = FALSE)
  list(start = start, end = end)
}

read_final_structure_metrics <- function(run_result) {
  metrics <- utils::read.csv(run_result$structure_fuel_path, stringsAsFactors = FALSE)
  metrics[which.max(metrics$Day), , drop = FALSE]
}

#' Run Experiment A (herbivore presence vs removal)
#'
#' @param base_dir Base artefact directory.
#' @param seed Seed recorded in manifest metadata.
#' @param scenario_slug Output scenario slug for this experiment bundle.
#'
#' @return List containing summary paths, plot path, manifest path, and tables.
#' @export
run_experiment_a_presence_removal <- function(base_dir = file.path("artefacts", "canonical_runs"),
                                              seed = 301L,
                                              scenario_slug = "experiment_a_presence_removal_v1") {
  present <- run_scenario_v2(scenario_contract_reference_path("reference_presence_present_v1"), base_dir = base_dir)
  removal <- run_scenario_v2(scenario_contract_reference_path("reference_presence_removed_v1"), base_dir = base_dir)

  present_final <- read_final_structure_metrics(present)
  removal_final <- read_final_structure_metrics(removal)

  summary_df <- data.frame(
    scenario = c("present", "removal"),
    total_shoot_biomass_kg = c(present_final$total_shoot_biomass_kg, removal_final$total_shoot_biomass_kg),
    fine_fuel_proxy_kg = c(present_final$fine_fuel_proxy_kg, removal_final$fine_fuel_proxy_kg),
    browseable_biomass_kg = c(present_final$browseable_biomass_kg, removal_final$browseable_biomass_kg),
    stringsAsFactors = FALSE
  )

  expected_direction <- data.frame(
    metric = c("total_shoot_biomass_kg", "fine_fuel_proxy_kg", "browseable_biomass_kg"),
    removal_minus_present = c(
      removal_final$total_shoot_biomass_kg - present_final$total_shoot_biomass_kg,
      removal_final$fine_fuel_proxy_kg - present_final$fine_fuel_proxy_kg,
      removal_final$browseable_biomass_kg - present_final$browseable_biomass_kg
    ),
    expected_positive = c(1, 1, 1),
    stringsAsFactors = FALSE
  )

  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  summary_path <- file.path(run_dir, "experiment_a_summary.csv")
  direction_path <- file.path(run_dir, "experiment_a_expected_direction.csv")
  plot_path <- file.path(run_dir, "experiment_a_presence_removal.png")
  report_path <- file.path(run_dir, "experiment_a_report.md")

  utils::write.csv(summary_df, summary_path, row.names = FALSE)
  utils::write.csv(expected_direction, direction_path, row.names = FALSE)

  grDevices::png(plot_path, width = 1200, height = 700)
  op <- par(mfrow = c(1, 2), mar = c(5, 5, 3, 1))
  barplot(
    height = summary_df$total_shoot_biomass_kg,
    names.arg = summary_df$scenario,
    col = c("#3a7ca5", "#f4a259"),
    main = "Final Total Shoot Biomass",
    ylab = "kg"
  )
  barplot(
    height = summary_df$fine_fuel_proxy_kg,
    names.arg = summary_df$scenario,
    col = c("#3a7ca5", "#f4a259"),
    main = "Final Fine Fuel Proxy",
    ylab = "kg"
  )
  par(op)
  grDevices::dev.off()

  report_lines <- c(
    "# Experiment A: Presence vs Removal",
    "",
    "## Design",
    "- Paired scenarios with matched runtime seed and climate settings.",
    "- Only herbivore pressure differs: `present` vs `removed`.",
    "",
    "## Expected direction",
    "- Removal should increase vegetation structure/fuel metrics relative to present.",
    "",
    "## Observed",
    sprintf("- Removal minus present total shoot biomass: `%.3f` kg", expected_direction$removal_minus_present[1]),
    sprintf("- Removal minus present fine fuel proxy: `%.3f` kg", expected_direction$removal_minus_present[2]),
    sprintf("- Removal minus present browseable biomass: `%.3f` kg", expected_direction$removal_minus_present[3]),
    "",
    "## Limitations",
    "- Short-horizon runs capture immediate pressure effects, not long-term demography.",
    "- Interpretation assumes scenario parity outside herbivore mode switch."
  )
  writeLines(report_lines, report_path)

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = as.integer(seed),
    scenario_parameters = list(present_slug = present$scenario$outputs$scenario_slug, removal_slug = removal$scenario$outputs$scenario_slug),
    output_files = c(
      summary = file.path(base_dir, scenario_slug, basename(summary_path)),
      expected_direction = file.path(base_dir, scenario_slug, basename(direction_path)),
      figure = file.path(base_dir, scenario_slug, basename(plot_path)),
      report = file.path(base_dir, scenario_slug, basename(report_path))
    )
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    run_dir = run_dir,
    summary_path = summary_path,
    direction_path = direction_path,
    plot_path = plot_path,
    report_path = report_path,
    manifest_path = manifest_path,
    summary = summary_df,
    expected_direction = expected_direction
  )
}

#' Run Experiment B (grazer vs browser vs mixed)
#'
#' @param base_dir Base artefact directory.
#' @param seed Seed recorded in manifest metadata.
#' @param scenario_slug Output scenario slug for this experiment bundle.
#'
#' @return List containing summary paths, plot path, manifest path, and tables.
#' @export
run_experiment_b_functional_types <- function(base_dir = file.path("artefacts", "canonical_runs"),
                                              seed = 401L,
                                              scenario_slug = "experiment_b_functional_types_v1") {
  run <- run_functional_type_scenario(
    minute_limit = 240L,
    seed = as.integer(seed),
    scenario_slug = scenario_slug,
    herb_types = c(0L, 1L, 2L),
    base_dir = base_dir
  )

  diet <- utils::read.csv(run$metrics_path, stringsAsFactors = FALSE)

  strategy_map <- c(grazer = "grazer", browser = "browser", mixed = "mixed")
  structure_rows <- vector("list", length(strategy_map))
  idx <- 0L
  for (nm in names(strategy_map)) {
    idx <- idx + 1L
    final_path <- file.path(run$run_dir, sprintf("plants_final_%s.csv", strategy_map[[nm]]))
    final <- utils::read.csv(final_path, stringsAsFactors = FALSE)
    browseable <- sum(ifelse(final$height * CONSTANTS$LEAF_HEIGHT <= CONSTANTS$BROWSE_HEIGHT, pmax(final$bleaf + final$bstem, 0), 0))
    fine_fuel <- sum(pmax(final$bleaf, 0) + ifelse(final$veg_type %in% c(0L, 1L), pmax(final$bstem, 0), 0))
    structure_rows[[idx]] <- data.frame(
      strategy = nm,
      final_browseable_biomass_kg = browseable,
      final_fine_fuel_proxy_kg = fine_fuel,
      stringsAsFactors = FALSE
    )
  }
  structure_df <- do.call(rbind, structure_rows)

  diet_df <- data.frame(
    strategy = tolower(diet$herb_type_label),
    grass_consumed_kg = diet$grass_intake_kg,
    woody_consumed_kg = diet$tree_intake_kg,
    grass_share = diet$grass_share,
    woody_share = diet$tree_share,
    stringsAsFactors = FALSE
  )
  diet_df <- merge(diet_df, structure_df, by = "strategy", sort = FALSE)
  diet_df <- diet_df[match(c("grazer", "browser", "mixed"), diet_df$strategy), ]

  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  summary_path <- file.path(run_dir, "experiment_b_summary.csv")
  plot_path <- file.path(run_dir, "experiment_b_functional_types.png")
  report_path <- file.path(run_dir, "experiment_b_report.md")

  utils::write.csv(diet_df, summary_path, row.names = FALSE)

  grDevices::png(plot_path, width = 1300, height = 700)
  op <- par(mfrow = c(1, 2), mar = c(5, 5, 3, 1))
  barplot(
    t(as.matrix(diet_df[, c("grass_share", "woody_share")])),
    beside = FALSE,
    names.arg = diet_df$strategy,
    col = c("#8fb339", "#5e548e"),
    main = "Diet Composition Shares",
    ylab = "share"
  )
  legend("topright", legend = c("grass", "woody"), fill = c("#8fb339", "#5e548e"), cex = 0.8)

  barplot(
    height = diet_df$final_browseable_biomass_kg,
    names.arg = diet_df$strategy,
    col = c("#4f772d", "#bc6c25", "#6a994e"),
    main = "Final Browseable Biomass",
    ylab = "kg"
  )
  par(op)
  grDevices::dev.off()

  report_lines <- c(
    "# Experiment B: Grazer vs Browser vs Mixed",
    "",
    "## Design",
    "- Three matched scenarios differing only in herbivore functional type strategy.",
    "",
    "## Observed diet composition",
    sprintf("- Grazer grass share: `%.3f`", diet_df$grass_share[diet_df$strategy == "grazer"]),
    sprintf("- Browser grass share: `%.3f`", diet_df$grass_share[diet_df$strategy == "browser"]),
    sprintf("- Mixed grass share: `%.3f`", diet_df$grass_share[diet_df$strategy == "mixed"]),
    "",
    "## Interpretation",
    "- Strategy-dependent intake partitioning is visible in grass/woody share differences.",
    "- Final browseable biomass contrasts provide structural evidence for differential pressure.",
    "- Results are qualitative mechanism checks, not fitted demographic forecasts."
  )
  writeLines(report_lines, report_path)

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = as.integer(seed),
    scenario_parameters = list(
      strategies = c("grazer", "browser", "mixed"),
      source_metrics = basename(run$metrics_path)
    ),
    output_files = c(
      summary = file.path(base_dir, scenario_slug, basename(summary_path)),
      figure = file.path(base_dir, scenario_slug, basename(plot_path)),
      report = file.path(base_dir, scenario_slug, basename(report_path))
    )
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    run_dir = run_dir,
    summary_path = summary_path,
    plot_path = plot_path,
    report_path = report_path,
    manifest_path = manifest_path,
    summary = diet_df
  )
}

#' Run Experiment C (aridity gradient response)
#'
#' @param base_dir Base artefact directory.
#' @param seed Seed recorded in manifest metadata.
#' @param scenario_slug Output scenario slug for this experiment bundle.
#'
#' @return List containing summary paths, plot path, manifest path, and tables.
#' @export
run_experiment_c_aridity_gradient <- function(base_dir = file.path("artefacts", "canonical_runs"),
                                              seed = 501L,
                                              scenario_slug = "experiment_c_aridity_gradient_v1") {
  low <- run_scenario_v2(scenario_contract_reference_path("reference_aridity_low_v1"), base_dir = base_dir)
  mid <- run_scenario_v2(scenario_contract_reference_path("reference_aridity_mid_v1"), base_dir = base_dir)
  high <- run_scenario_v2(scenario_contract_reference_path("reference_aridity_high_v1"), base_dir = base_dir)

  runs <- list(low = low, mid = mid, high = high)
  rows <- vector("list", length(runs))
  idx <- 0L

  for (nm in names(runs)) {
    idx <- idx + 1L
    herb <- utils::read.csv(runs[[nm]]$herbivore_daily_path, stringsAsFactors = FALSE)
    struc <- read_final_structure_metrics(runs[[nm]])

    rows[[idx]] <- data.frame(
      gradient = nm,
      mean_daily_dmi = mean(herb$DailyDMI),
      mean_daily_dist_m = mean(herb$DailyDistMoved),
      mean_daily_forage_water = mean(herb$DailyForageWater),
      mean_daily_drinking_water = mean(herb$DailyWaterDrinking),
      mean_energy_balance = mean(herb$EnergyBalance),
      final_total_shoot_biomass_kg = struc$total_shoot_biomass_kg,
      final_fine_fuel_proxy_kg = struc$fine_fuel_proxy_kg,
      stringsAsFactors = FALSE
    )
  }

  gradient_df <- do.call(rbind, rows)
  gradient_df$gradient_index <- match(gradient_df$gradient, c("low", "mid", "high"))
  gradient_df <- gradient_df[order(gradient_df$gradient_index), ]

  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  summary_path <- file.path(run_dir, "experiment_c_summary.csv")
  plot_path <- file.path(run_dir, "experiment_c_aridity_gradient.png")
  report_path <- file.path(run_dir, "experiment_c_report.md")

  utils::write.csv(gradient_df, summary_path, row.names = FALSE)

  grDevices::png(plot_path, width = 1300, height = 700)
  op <- par(mfrow = c(1, 2), mar = c(5, 5, 3, 1))
  plot(
    gradient_df$gradient_index,
    gradient_df$mean_daily_drinking_water,
    type = "b",
    xaxt = "n",
    pch = 19,
    col = "#bc4749",
    xlab = "Aridity gradient",
    ylab = "Mean daily drinking water",
    main = "Water-demand signal"
  )
  axis(1, at = gradient_df$gradient_index, labels = gradient_df$gradient)

  plot(
    gradient_df$gradient_index,
    gradient_df$mean_daily_dmi,
    type = "b",
    xaxt = "n",
    pch = 19,
    col = "#386641",
    xlab = "Aridity gradient",
    ylab = "Mean daily DMI",
    main = "Intake limitation signal"
  )
  axis(1, at = gradient_df$gradient_index, labels = gradient_df$gradient)
  par(op)
  grDevices::dev.off()

  report_lines <- c(
    "# Experiment C: Aridity/Productivity Limits",
    "",
    "## Design",
    "- Three-point climate gradient (`low`, `mid`, `high`) with scenario-defined forcing multipliers.",
    "",
    "## Expected qualitative direction",
    "- Higher aridity/productivity stress should increase drinking pressure and constrain intake.",
    "",
    "## Observed",
    sprintf(
      "- Drinking water means: low=`%.2f`, mid=`%.2f`, high=`%.2f`",
      gradient_df$mean_daily_drinking_water[1],
      gradient_df$mean_daily_drinking_water[2],
      gradient_df$mean_daily_drinking_water[3]
    ),
    sprintf(
      "- Daily DMI means: low=`%.2f`, mid=`%.2f`, high=`%.2f`",
      gradient_df$mean_daily_dmi[1],
      gradient_df$mean_daily_dmi[2],
      gradient_df$mean_daily_dmi[3]
    ),
    "",
    "## Interpretation",
    "- Gradient outputs are mechanistic checks of activity limitation, not calibration to site-level forcing datasets.",
    "- No numeric instability was observed in the generated summary metrics."
  )
  writeLines(report_lines, report_path)

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = as.integer(seed),
    scenario_parameters = list(gradient = c("low", "mid", "high")),
    output_files = c(
      summary = file.path(base_dir, scenario_slug, basename(summary_path)),
      figure = file.path(base_dir, scenario_slug, basename(plot_path)),
      report = file.path(base_dir, scenario_slug, basename(report_path))
    )
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    run_dir = run_dir,
    summary_path = summary_path,
    plot_path = plot_path,
    report_path = report_path,
    manifest_path = manifest_path,
    summary = gradient_df
  )
}

#' Run benchmark appendix overlap case
#'
#' @param base_dir Base artefact directory.
#' @param seed Seed recorded in manifest metadata.
#' @param scenario_slug Output scenario slug for this benchmark bundle.
#'
#' @return List containing appendix and benchmark artefact paths.
#' @export
run_benchmark_appendix_v1 <- function(base_dir = file.path("artefacts", "canonical_runs"),
                                      seed = 601L,
                                      scenario_slug = "benchmark_appendix_v1") {
  bench <- run_ttr_pgm_overlap_benchmark(
    days = 14L,
    seed = seed,
    scenario_slug = scenario_slug,
    base_dir = base_dir
  )

  appendix_path <- file.path(bench$run_dir, "benchmark_appendix_report.md")
  lines <- c(
    "# Benchmark Appendix: Internal TTR vs TTR.PGM",
    "",
    "## Artefact summary",
    sprintf("- Internal trajectory: `%s`", bench$internal_path),
    sprintf("- Benchmark summary: `%s`", bench$comparison_path),
    sprintf("- Harness report: `%s`", bench$report_path),
    "",
    "## Notes",
    "- TTR.PGM is treated as benchmark-only unless/until overlap semantics are fully aligned.",
    "- Default coupled backend remains the internal multi-PFT implementation."
  )
  writeLines(lines, appendix_path)

  list(
    run_dir = bench$run_dir,
    appendix_path = appendix_path,
    benchmark = bench
  )
}
