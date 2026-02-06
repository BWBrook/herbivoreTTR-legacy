# Focused scenario helper for WP-0.4.3 plant-selection contract validation.

build_selection_contract_treatments <- function() {
  list(
    defence_probe = list(
      herbivore = init_herbivore(mass = 5e5, herb_type = 0L),
      plants = data.frame(
        plant_id = 1:2,
        plant_label = c("low_defence", "high_defence"),
        veg_type = c(0L, 0L),
        height = c(0.8, 0.8),
        ms = c(6, 6),
        ns = c(0.12, 0.12),
        cs = c(2.5, 2.5),
        bdef = c(0.05, 1.25),
        distance = c(2, 2),
        stringsAsFactors = FALSE
      )
    ),
    distance_probe = list(
      herbivore = init_herbivore(mass = 5e5, herb_type = 0L),
      plants = data.frame(
        plant_id = 1:2,
        plant_label = c("near", "far"),
        veg_type = c(0L, 0L),
        height = c(0.8, 0.8),
        ms = c(6, 6),
        ns = c(0.12, 0.12),
        cs = c(2.5, 2.5),
        bdef = c(0.1, 0.1),
        distance = c(1, 9),
        stringsAsFactors = FALSE
      )
    ),
    constraint_probe = list(
      herbivore = init_herbivore(mass = 5e5, herb_type = 1L),
      plants = data.frame(
        plant_id = 1:4,
        plant_label = c("reachable", "too_far", "too_tall", "depleted"),
        veg_type = c(2L, 2L, 2L, 2L),
        height = c(
          1.0,
          1.0,
          CONSTANTS$BROWSE_HEIGHT / CONSTANTS$LEAF_HEIGHT + 0.5,
          1.0
        ),
        ms = c(6, 6, 6, CONSTANTS$MIN_SHOOT / 2),
        ns = c(0.12, 0.12, 0.12, 0.12),
        cs = c(2.5, 2.5, 2.5, 2.5),
        bdef = c(0.1, 0.1, 0.1, 0.1),
        distance = c(2, CONSTANTS$DETECTION_DISTANCE + 2, 2, 2),
        stringsAsFactors = FALSE
      )
    )
  )
}

run_selection_contract_treatment <- function(treatment_name,
                                             treatment,
                                             n_draws,
                                             seed) {
  if (!is.numeric(n_draws) || length(n_draws) != 1L || !is.finite(n_draws) || n_draws < 1) {
    rlang::abort(
      "Argument `n_draws` must be a positive scalar.",
      class = "herbivoreTTR_selection_contract_n_draws_invalid",
      n_draws = n_draws
    )
  }

  n_draws <- as.integer(n_draws)

  with_optional_seed(seed, {
    herbivore <- treatment$herbivore
    plants <- treatment$plants

    tastiness <- calc_plant_tastiness(
      plants_in_range = plants,
      herbivore = herbivore,
      desired_dp_dc_ratio = CONSTANTS$DP_TO_DC_TARGET
    )

    total_tastiness <- sum(tastiness)
    probabilities <- if (!is.finite(total_tastiness) || total_tastiness <= 0) {
      rep(0, length(tastiness))
    } else {
      tastiness / total_tastiness
    }

    picked <- vapply(
      seq_len(n_draws),
      function(i) pick_a_plant(plants, tastiness),
      integer(1)
    )

    picked_idx <- match(picked, plants$plant_id)
    selected_count <- tabulate(picked_idx, nbins = nrow(plants))

    data.frame(
      treatment = treatment_name,
      herb_type = normalize_herb_type(herbivore$herb_type),
      plant_id = plants$plant_id,
      plant_label = plants$plant_label,
      distance = plants$distance,
      bdef = plants$bdef,
      ms = plants$ms,
      height = plants$height,
      tastiness = tastiness,
      selection_probability = probabilities,
      selected_count = selected_count,
      selected_frequency = selected_count / n_draws,
      draws = n_draws,
      stringsAsFactors = FALSE
    )
  })
}

summarise_selection_contract_frequency <- function(frequency_table) {
  defence <- frequency_table[frequency_table$treatment == "defence_probe", , drop = FALSE]
  distance <- frequency_table[frequency_table$treatment == "distance_probe", , drop = FALSE]
  constraints <- frequency_table[frequency_table$treatment == "constraint_probe", , drop = FALSE]

  data.frame(
    metric = c(
      "defence_low_minus_high_frequency",
      "distance_near_minus_far_frequency",
      "constraint_invalid_total_frequency"
    ),
    value = c(
      defence$selected_frequency[defence$plant_label == "low_defence"] -
        defence$selected_frequency[defence$plant_label == "high_defence"],
      distance$selected_frequency[distance$plant_label == "near"] -
        distance$selected_frequency[distance$plant_label == "far"],
      sum(constraints$selected_frequency[constraints$plant_label != "reachable"])
    ),
    stringsAsFactors = FALSE
  )
}

run_selection_contract_scenario <- function(seed = 51L,
                                            n_draws = 5000L,
                                            scenario_slug = "selection_contract_v0",
                                            base_dir = file.path("artefacts", "canonical_runs")) {
  if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed)) {
    rlang::abort(
      "Argument `seed` must be a finite scalar numeric value.",
      class = "herbivoreTTR_selection_contract_seed_invalid",
      seed = seed
    )
  }

  treatments <- build_selection_contract_treatments()

  frequency_tables <- vector("list", length(treatments))
  for (i in seq_along(treatments)) {
    treatment_name <- names(treatments)[[i]]
    treatment_seed <- as.integer(seed + i * 1000L)
    frequency_tables[[i]] <- run_selection_contract_treatment(
      treatment_name = treatment_name,
      treatment = treatments[[i]],
      n_draws = n_draws,
      seed = treatment_seed
    )
  }

  frequency_df <- do.call(rbind, frequency_tables)
  summary_df <- summarise_selection_contract_frequency(frequency_df)

  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  candidates_df <- do.call(
    rbind,
    lapply(names(treatments), function(name) {
      plants <- treatments[[name]]$plants
      plants$treatment <- name
      plants$herb_type <- normalize_herb_type(treatments[[name]]$herbivore$herb_type)
      plants
    })
  )

  candidates_path <- file.path(run_dir, "selection_candidates.csv")
  frequency_path <- file.path(run_dir, "selection_frequency.csv")
  summary_path <- file.path(run_dir, "selection_summary.csv")
  manifest_path <- file.path(run_dir, "run_manifest.json")

  utils::write.csv(candidates_df, file = candidates_path, row.names = FALSE)
  utils::write.csv(frequency_df, file = frequency_path, row.names = FALSE)
  utils::write.csv(summary_df, file = summary_path, row.names = FALSE)

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = as.integer(seed),
    scenario_parameters = list(
      n_draws = as.integer(n_draws),
      dp_to_dc_target = CONSTANTS$DP_TO_DC_TARGET,
      detection_distance = CONSTANTS$DETECTION_DISTANCE,
      browse_height = CONSTANTS$BROWSE_HEIGHT,
      min_shoot = CONSTANTS$MIN_SHOOT,
      tastiness_ratio_weight = CONSTANTS$TASTINESS_RATIO_WEIGHT,
      tastiness_distance_weight = CONSTANTS$TASTINESS_DISTANCE_WEIGHT,
      tastiness_defence_weight = CONSTANTS$TASTINESS_DEFENCE_WEIGHT,
      tastiness_epsilon = CONSTANTS$TASTINESS_EPSILON
    ),
    output_files = c(
      selection_candidates = file.path(base_dir, scenario_slug, basename(candidates_path)),
      selection_frequency = file.path(base_dir, scenario_slug, basename(frequency_path)),
      selection_summary = file.path(base_dir, scenario_slug, basename(summary_path))
    )
  )
  write_run_manifest(manifest = manifest, path = manifest_path)

  list(
    run_dir = run_dir,
    candidates_path = candidates_path,
    frequency_path = frequency_path,
    summary_path = summary_path,
    manifest_path = manifest_path,
    frequency = frequency_df,
    summary = summary_df
  )
}
