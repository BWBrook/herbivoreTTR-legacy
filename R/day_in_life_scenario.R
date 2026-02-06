# Controlled nutrient-targeting vs energy-only day-in-life artefact scenario.

build_day_in_life_control_plants <- function() {
  group <- c(rep("balanced", 4), rep("high_ratio", 4))
  ms <- c(rep(4, 4), rep(8, 4))
  bdef <- rep(0.05, length(group))
  bstem <- rep(0, length(group))
  bleaf <- pmax(ms - bdef - bstem, 0)

  cs <- ifelse(group == "balanced", 0.4, 0.6)
  ns <- ifelse(
    group == "balanced",
    CONSTANTS$DP_TO_DC_TARGET * CONSTANTS$N_TO_PROTEIN * cs * CONSTANTS$PROP_DIGEST_SC,
    2 * CONSTANTS$N_TO_PROTEIN * cs * CONSTANTS$PROP_DIGEST_SC
  )

  data.frame(
    plant_id = seq_along(group),
    xcor = c(47, 49, 51, 53, 47, 49, 51, 53),
    ycor = c(47, 47, 47, 47, 53, 53, 53, 53),
    veg_type = 0L,
    nutrient_group = group,
    height = 1,
    ms = ms,
    mr = ms,
    bdef = bdef,
    bleaf = bleaf,
    bstem = bstem,
    qshoot = ms * 3,
    qroot = ms * 3,
    cs = cs,
    cr = cs,
    ns = ns,
    nr = ns,
    stringsAsFactors = FALSE
  )
}

selected_group_label <- function(selected_plant_id, plants) {
  if (!is.numeric(selected_plant_id) || length(selected_plant_id) != 1L || is.na(selected_plant_id)) {
    return("none")
  }
  idx <- which(plants$plant_id == as.integer(selected_plant_id))
  if (length(idx) != 1L) {
    return("none")
  }
  as.character(plants$nutrient_group[[idx]])
}

summarise_day_in_life_mode <- function(initial_plants, final_plants, herbivore, foraging_mode, seed, minute_limit) {
  consumed <- pmax(initial_plants$ms - final_plants$ms, 0)
  balanced_idx <- initial_plants$nutrient_group == "balanced"
  high_ratio_idx <- initial_plants$nutrient_group == "high_ratio"

  balanced_intake <- sum(consumed[balanced_idx])
  high_ratio_intake <- sum(consumed[high_ratio_idx])
  total_intake <- balanced_intake + high_ratio_intake

  balanced_share <- if (total_intake <= 0) 0 else balanced_intake / total_intake
  high_ratio_share <- if (total_intake <= 0) 0 else high_ratio_intake / total_intake

  data.frame(
    foraging_mode = as.character(foraging_mode),
    seed = as.integer(seed),
    minute_limit = as.integer(minute_limit),
    total_intake_kg = total_intake,
    balanced_intake_kg = balanced_intake,
    high_ratio_intake_kg = high_ratio_intake,
    balanced_intake_share = balanced_share,
    high_ratio_intake_share = high_ratio_share,
    distance_moved_m = as.numeric(herbivore$distance_moved),
    energy_balance_kj = as.numeric(herbivore$energy_balance),
    water_balance_g = as.numeric(herbivore$water_balance),
    stringsAsFactors = FALSE
  )
}

run_day_in_life_mode_scenario <- function(foraging_mode = c("nutrient_targeting", "energy_only"),
                                          seed = 81L,
                                          minute_limit = 360L,
                                          herbivore_mass = 5e5,
                                          scenario_slug = NULL,
                                          base_dir = file.path("artefacts", "canonical_runs")) {
  foraging_mode <- match.arg(foraging_mode)
  if (is.null(scenario_slug)) {
    scenario_slug <- sprintf("day_in_life_%s_v1", foraging_mode)
  }
  if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed)) {
    rlang::abort(
      "Argument `seed` must be a finite scalar numeric value.",
      class = "herbivoreTTR_day_in_life_seed_invalid",
      seed = seed
    )
  }
  if (!is.numeric(minute_limit) || length(minute_limit) != 1L || !is.finite(minute_limit) || minute_limit < 1) {
    rlang::abort(
      "Argument `minute_limit` must be a positive scalar.",
      class = "herbivoreTTR_day_in_life_minute_limit_invalid",
      minute_limit = minute_limit
    )
  }

  minute_limit <- as.integer(minute_limit)
  seed <- as.integer(seed)

  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  initial_plants <- build_day_in_life_control_plants()
  plants <- initial_plants

  herbivore <- init_herbivore(mass = herbivore_mass, herb_type = 2L)
  herbivore$foraging_mode <- foraging_mode
  herbivore$movement_disruption_prob <- 1
  herbivore$xcor <- 50
  herbivore$ycor <- 50
  herbivore$selected_plant_id <- NA_integer_
  herbivore$behaviour <- "MOVING"
  herbivore <- reset_daily_variables(herbivore)
  herbivore <- calc_foraging_traits(herbivore)

  hourly_rows <- vector("list", floor(minute_limit / 60L))
  hourly_idx <- 0L

  with_optional_seed(seed, {
    for (minute in seq_len(minute_limit)) {
      herbivore <- update_gut_content(herbivore)
      step <- herbivore_step(herbivore = herbivore, plants = plants)
      herbivore <- step$herbivore
      plants <- step$plants

      if (minute %% 60 == 0) {
        herbivore <- hourly_digestion_step(herbivore)
        hourly_idx <- hourly_idx + 1L
        consumed <- pmax(initial_plants$ms - plants$ms, 0)
        balanced_idx <- initial_plants$nutrient_group == "balanced"
        high_ratio_idx <- initial_plants$nutrient_group == "high_ratio"

        hourly_rows[[hourly_idx]] <- data.frame(
          foraging_mode = foraging_mode,
          hour = as.integer(minute / 60),
          selected_group = selected_group_label(herbivore$selected_plant_id, initial_plants),
          distance_moved_m = as.numeric(herbivore$distance_moved),
          intake_total_g = as.numeric(herbivore$intake_total_day),
          intake_pe_kj = as.numeric(herbivore$intake_PE_day),
          intake_npe_kj = as.numeric(herbivore$intake_NPE_day),
          balanced_consumed_kg = sum(consumed[balanced_idx]),
          high_ratio_consumed_kg = sum(consumed[high_ratio_idx]),
          stringsAsFactors = FALSE
        )
      }
    }
  })

  herbivore <- check_daily_water_balance(herbivore)
  herbivore <- calc_daily_energy_balance(herbivore)

  hourly_df <- if (length(hourly_rows) == 0L) {
    data.frame(
      foraging_mode = character(),
      hour = integer(),
      selected_group = character(),
      distance_moved_m = numeric(),
      intake_total_g = numeric(),
      intake_pe_kj = numeric(),
      intake_npe_kj = numeric(),
      balanced_consumed_kg = numeric(),
      high_ratio_consumed_kg = numeric(),
      stringsAsFactors = FALSE
    )
  } else {
    do.call(rbind, hourly_rows)
  }

  summary_df <- summarise_day_in_life_mode(
    initial_plants = initial_plants,
    final_plants = plants,
    herbivore = herbivore,
    foraging_mode = foraging_mode,
    seed = seed,
    minute_limit = minute_limit
  )

  summary_df$selected_balanced_hours <- sum(hourly_df$selected_group == "balanced")
  summary_df$selected_high_ratio_hours <- sum(hourly_df$selected_group == "high_ratio")

  initial_path <- file.path(run_dir, "plants_initial.csv")
  final_path <- file.path(run_dir, "plants_final.csv")
  hourly_path <- file.path(run_dir, "hourly_timeline.csv")
  summary_path <- file.path(run_dir, "daily_summary.csv")

  utils::write.csv(initial_plants, initial_path, row.names = FALSE)
  utils::write.csv(plants, final_path, row.names = FALSE)
  utils::write.csv(hourly_df, hourly_path, row.names = FALSE)
  utils::write.csv(summary_df, summary_path, row.names = FALSE)

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = seed,
    scenario_parameters = list(
      minute_limit = minute_limit,
      foraging_mode = foraging_mode,
      herbivore_mass = herbivore_mass,
      movement_disruption_prob = herbivore$movement_disruption_prob,
      dp_to_dc_target = CONSTANTS$DP_TO_DC_TARGET
    ),
    output_files = c(
      plants_initial = file.path(base_dir, scenario_slug, basename(initial_path)),
      plants_final = file.path(base_dir, scenario_slug, basename(final_path)),
      hourly_timeline = file.path(base_dir, scenario_slug, basename(hourly_path)),
      daily_summary = file.path(base_dir, scenario_slug, basename(summary_path))
    )
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest = manifest, path = manifest_path)

  list(
    run_dir = run_dir,
    initial_path = initial_path,
    final_path = final_path,
    hourly_path = hourly_path,
    summary_path = summary_path,
    manifest_path = manifest_path,
    summary = summary_df,
    hourly = hourly_df,
    herbivore = herbivore
  )
}

write_day_in_life_report <- function(nutrient_run,
                                     energy_run,
                                     comparison_df,
                                     report_path) {
  dir.create(dirname(report_path), recursive = TRUE, showWarnings = FALSE)

  nutrient <- nutrient_run$summary
  energy <- energy_run$summary
  delta_share <- comparison_df$value[comparison_df$metric == "delta_balanced_intake_share"]
  delta_high_ratio <- comparison_df$value[comparison_df$metric == "delta_high_ratio_intake_kg"]

  report_lines <- c(
    "# Day-in-Life: Nutrient Targeting vs Energy-Only",
    "",
    "## Scenario",
    "- Same initial plants, herbivore mass, and RNG seed in both runs.",
    "- Only `foraging_mode` changes between runs (`nutrient_targeting` vs `energy_only`).",
    "",
    "## Artefact locations",
    sprintf("- Nutrient-targeting run: `%s`", nutrient_run$run_dir),
    sprintf("- Energy-only run: `%s`", energy_run$run_dir),
    "",
    "## Observed differences",
    sprintf("- Nutrient-targeting balanced-intake share: `%.4f`", nutrient$balanced_intake_share),
    sprintf("- Energy-only balanced-intake share: `%.4f`", energy$balanced_intake_share),
    sprintf("- Delta balanced-intake share (nutrient - energy): `%.4f`", delta_share),
    sprintf("- Delta high-ratio intake kg (energy - nutrient): `%.4f`", delta_high_ratio),
    "",
    "## Interpretation",
    "- Nutrient-targeting mode shifts selection toward plants closer to the configured DP:DC target.",
    "- Energy-only mode emphasizes non-nutrient terms (size, distance, defence), producing a different intake partition.",
    "- Hourly timelines (`hourly_timeline.csv`) provide the day-in-life sequence used for this interpretation."
  )

  writeLines(report_lines, con = report_path)
  report_path
}

run_day_in_life_comparison <- function(seed = 81L,
                                       minute_limit = 360L,
                                       base_dir = file.path("artefacts", "canonical_runs"),
                                       comparison_slug = "day_in_life_mode_comparison_v1") {
  nutrient_run <- run_day_in_life_mode_scenario(
    foraging_mode = "nutrient_targeting",
    seed = seed,
    minute_limit = minute_limit,
    scenario_slug = "day_in_life_nutrient_targeting_v1",
    base_dir = base_dir
  )

  energy_run <- run_day_in_life_mode_scenario(
    foraging_mode = "energy_only",
    seed = seed,
    minute_limit = minute_limit,
    scenario_slug = "day_in_life_energy_only_v1",
    base_dir = base_dir
  )

  nutrient <- nutrient_run$summary
  energy <- energy_run$summary

  delta_balanced_share <- nutrient$balanced_intake_share - energy$balanced_intake_share
  delta_high_ratio_intake <- energy$high_ratio_intake_kg - nutrient$high_ratio_intake_kg

  comparison <- data.frame(
    metric = c(
      "nutrient_balanced_intake_share",
      "energy_balanced_intake_share",
      "delta_balanced_intake_share",
      "nutrient_high_ratio_intake_kg",
      "energy_high_ratio_intake_kg",
      "delta_high_ratio_intake_kg",
      "modes_measurably_different"
    ),
    value = c(
      nutrient$balanced_intake_share,
      energy$balanced_intake_share,
      delta_balanced_share,
      nutrient$high_ratio_intake_kg,
      energy$high_ratio_intake_kg,
      delta_high_ratio_intake,
      as.numeric(delta_balanced_share > 0.05 || abs(delta_high_ratio_intake) > 0.1)
    ),
    stringsAsFactors = FALSE
  )

  comparison_dir <- file.path(base_dir, comparison_slug)
  dir.create(comparison_dir, recursive = TRUE, showWarnings = FALSE)

  comparison_path <- file.path(comparison_dir, "comparison_summary.csv")
  utils::write.csv(comparison, comparison_path, row.names = FALSE)

  report_path <- file.path(comparison_dir, "day_in_life_report.md")
  write_day_in_life_report(
    nutrient_run = nutrient_run,
    energy_run = energy_run,
    comparison_df = comparison,
    report_path = report_path
  )

  comparison_manifest <- build_run_manifest(
    scenario_slug = comparison_slug,
    seed = as.integer(seed),
    scenario_parameters = list(
      minute_limit = as.integer(minute_limit),
      energy_only_slug = "day_in_life_energy_only_v1",
      nutrient_targeting_slug = "day_in_life_nutrient_targeting_v1"
    ),
    output_files = c(
      nutrient_daily = file.path(base_dir, "day_in_life_nutrient_targeting_v1", "daily_summary.csv"),
      energy_daily = file.path(base_dir, "day_in_life_energy_only_v1", "daily_summary.csv"),
      comparison_summary = file.path(base_dir, comparison_slug, basename(comparison_path)),
      day_in_life_report = file.path(base_dir, comparison_slug, basename(report_path))
    )
  )
  manifest_path <- file.path(comparison_dir, "run_manifest.json")
  write_run_manifest(manifest = comparison_manifest, path = manifest_path)

  list(
    nutrient_run = nutrient_run,
    energy_run = energy_run,
    comparison = comparison,
    comparison_path = comparison_path,
    report_path = report_path,
    manifest_path = manifest_path,
    bundle_files = c(
      nutrient_run$initial_path,
      nutrient_run$final_path,
      nutrient_run$hourly_path,
      nutrient_run$summary_path,
      nutrient_run$manifest_path,
      energy_run$initial_path,
      energy_run$final_path,
      energy_run$hourly_path,
      energy_run$summary_path,
      energy_run$manifest_path,
      comparison_path,
      report_path,
      manifest_path
    )
  )
}
