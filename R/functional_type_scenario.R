# Controlled functional-type scenario for grazer/browser validation artefacts.

build_functional_type_control_plants <- function() {
  veg_type <- c(0L, 1L, 0L, 1L, 2L, 2L, 2L, 2L)
  height <- c(0.6, 0.6, 0.7, 0.7, 1.5, 1.6, 3.1, 3.2)
  ms <- rep(6, length(veg_type))
  bdef <- rep(0.05, length(veg_type))
  bstem <- ifelse(veg_type == 2L, 2.95, 0)
  bleaf <- ms - bstem - bdef

  data.frame(
    plant_id = seq_along(veg_type),
    xcor = c(47, 49, 51, 53, 47, 49, 51, 53),
    ycor = c(47, 47, 47, 47, 53, 53, 53, 53),
    veg_type = veg_type,
    height = height,
    ms = ms,
    mr = ms,
    bdef = bdef,
    cs = ms * CONSTANTS$FRACTION_C,
    cr = ms * CONSTANTS$FRACTION_C,
    ns = ms * CONSTANTS$FRACTION_N,
    nr = ms * CONSTANTS$FRACTION_N,
    bleaf = bleaf,
    bstem = bstem,
    stringsAsFactors = FALSE
  )
}

run_functional_type_single <- function(initial_plants,
                                       herb_type,
                                       minute_limit,
                                       herbivore_mass,
                                       seed) {
  with_optional_seed(seed, {
    herbivore <- init_herbivore(mass = herbivore_mass, herb_type = herb_type)
    herbivore <- reset_daily_variables(herbivore)
    herbivore <- calc_foraging_traits(herbivore)
    herbivore$xcor <- 50
    herbivore$ycor <- 50
    herbivore$selected_plant_id <- NA_integer_
    herbivore$behaviour <- "MOVING"

    plants <- initial_plants

    for (minute in seq_len(minute_limit)) {
      herbivore <- update_gut_content(herbivore)
      step_result <- herbivore_step(herbivore, plants)
      herbivore <- step_result$herbivore
      plants <- step_result$plants

      if (minute %% 60 == 0) {
        herbivore <- hourly_digestion_step(herbivore)
      }
    }

    herbivore <- check_daily_water_balance(herbivore)
    herbivore <- calc_daily_energy_balance(herbivore)

    list(
      herbivore = herbivore,
      plants = plants
    )
  })
}

summarise_functional_type_diet <- function(initial_plants, final_plants, herb_type) {
  consumed <- pmax(initial_plants$ms - final_plants$ms, 0)
  grass_idx <- initial_plants$veg_type %in% c(0L, 1L)
  tree_idx <- initial_plants$veg_type == 2L
  unreachable_tree_idx <- tree_idx &
    (initial_plants$height * CONSTANTS$LEAF_HEIGHT > CONSTANTS$BROWSE_HEIGHT)

  total_intake <- sum(consumed)
  grass_intake <- sum(consumed[grass_idx])
  tree_intake <- sum(consumed[tree_idx])
  unreachable_tree_intake <- sum(consumed[unreachable_tree_idx])

  grass_share <- if (total_intake <= 0) 0 else grass_intake / total_intake
  tree_share <- if (total_intake <= 0) 0 else tree_intake / total_intake

  data.frame(
    herb_type = as.integer(herb_type),
    herb_type_label = functional_type_label(herb_type),
    total_intake_kg = total_intake,
    grass_intake_kg = grass_intake,
    tree_intake_kg = tree_intake,
    unreachable_tree_intake_kg = unreachable_tree_intake,
    grass_share = grass_share,
    tree_share = tree_share,
    stringsAsFactors = FALSE
  )
}

run_functional_type_scenario <- function(minute_limit = 240L,
                                         seed = 41L,
                                         scenario_slug = "functional_types_v0",
                                         herbivore_mass = 5e5,
                                         herb_types = c(0L, 1L),
                                         base_dir = file.path("artefacts", "canonical_runs")) {
  if (!is.numeric(minute_limit) || length(minute_limit) != 1L || !is.finite(minute_limit) || minute_limit < 1) {
    rlang::abort(
      "Argument `minute_limit` must be a positive scalar.",
      class = "herbivoreTTR_functional_type_minute_limit_invalid",
      minute_limit = minute_limit
    )
  }
  if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed)) {
    rlang::abort(
      "Argument `seed` must be a finite scalar numeric value.",
      class = "herbivoreTTR_functional_type_seed_invalid",
      seed = seed
    )
  }

  minute_limit <- as.integer(minute_limit)
  herb_types <- as.integer(herb_types)

  initial_plants <- build_functional_type_control_plants()
  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  initial_path <- file.path(run_dir, "plants_initial.csv")
  utils::write.csv(initial_plants, file = initial_path, row.names = FALSE)

  metrics <- vector("list", length(herb_types))
  final_paths <- character(length(herb_types))
  names(final_paths) <- paste0("plants_final_", vapply(herb_types, functional_type_label, character(1L)))

  for (i in seq_along(herb_types)) {
    herb_type <- herb_types[[i]]
    scenario_seed <- as.integer(seed + i * 1000L)
    result <- run_functional_type_single(
      initial_plants = initial_plants,
      herb_type = herb_type,
      minute_limit = minute_limit,
      herbivore_mass = herbivore_mass,
      seed = scenario_seed
    )

    metrics[[i]] <- summarise_functional_type_diet(
      initial_plants = initial_plants,
      final_plants = result$plants,
      herb_type = herb_type
    )

    final_path <- file.path(
      run_dir,
      sprintf("plants_final_%s.csv", functional_type_label(herb_type))
    )
    utils::write.csv(result$plants, file = final_path, row.names = FALSE)
    final_paths[[i]] <- final_path
  }

  metrics_df <- do.call(rbind, metrics)
  metrics_path <- file.path(run_dir, "diet_composition.csv")
  utils::write.csv(metrics_df, file = metrics_path, row.names = FALSE)

  relative_outputs <- c(
    plants_initial = file.path(base_dir, scenario_slug, basename(initial_path)),
    diet_composition = file.path(base_dir, scenario_slug, basename(metrics_path)),
    stats::setNames(
      file.path(base_dir, scenario_slug, basename(final_paths)),
      names(final_paths)
    )
  )

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = as.integer(seed),
    scenario_parameters = list(
      minute_limit = minute_limit,
      herbivore_mass = herbivore_mass,
      herb_types = herb_types,
      grazer_grass_pref = CONSTANTS$GRAZER_GRASS_PREF,
      grazer_woody_pref = CONSTANTS$GRAZER_WOODY_PREF,
      browser_grass_pref = CONSTANTS$BROWSER_GRASS_PREF,
      browser_woody_pref = CONSTANTS$BROWSER_WOODY_PREF
    ),
    output_files = relative_outputs
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest = manifest, path = manifest_path)

  list(
    run_dir = run_dir,
    metrics = metrics_df,
    metrics_path = metrics_path,
    plants_initial_path = initial_path,
    plants_final_paths = unname(final_paths),
    manifest_path = manifest_path
  )
}
