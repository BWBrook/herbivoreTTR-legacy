# Focused scenario helper for WP-0.4.4 movement contract validation.

build_movement_contract_plants <- function() {
  data.frame(
    plant_id = 1:2,
    xcor = c(52, 48),
    ycor = c(50, 50),
    ms = c(6, 6),
    mr = c(6, 6),
    bdef = c(0.1, 0.1),
    height = c(1, 1),
    veg_type = c(0L, 0L),
    cs = c(2.5, 2.5),
    cr = c(2.5, 2.5),
    ns = c(0.12, 0.12),
    nr = c(0.12, 0.12),
    bleaf = c(5, 5),
    bstem = c(0.9, 0.9),
    stringsAsFactors = FALSE
  )
}

simulate_retarget_rate <- function(disruption_prob, steps, seed) {
  with_optional_seed(seed, {
    plants <- build_movement_contract_plants()
    herb <- init_herbivore(mass = 5e5, herb_type = 0L)
    herb$xcor <- 50
    herb$ycor <- 50
    herb$fv_max <- 0
    herb$behaviour <- "MOVING"
    herb$selected_plant_id <- 1L
    herb$movement_disruption_prob <- disruption_prob

    retarget_count <- 0L

    for (step in seq_len(steps)) {
      prev_target <- herb$selected_plant_id
      out <- herbivore_step(herbivore = herb, plants = plants)
      herb <- out$herbivore

      if (!is.na(prev_target) && !is.na(herb$selected_plant_id) && herb$selected_plant_id != prev_target) {
        retarget_count <- retarget_count + 1L
      }

      # Keep probing moving-state retarget behavior each step.
      herb$behaviour <- "MOVING"
    }

    data.frame(
      disruption_prob = disruption_prob,
      steps = as.integer(steps),
      retarget_count = retarget_count,
      retarget_rate = retarget_count / as.integer(steps),
      stringsAsFactors = FALSE
    )
  })
}

run_movement_probe <- function() {
  world_dim <- sqrt(CONSTANTS$PLOT_SIZE)

  wrap_plants <- data.frame(
    plant_id = 1L,
    xcor = 1,
    ycor = 50,
    ms = 6,
    stringsAsFactors = FALSE
  )
  wrap_herb <- init_herbivore(mass = 5e5)
  wrap_herb$xcor <- 99
  wrap_herb$ycor <- 50
  wrap_herb$selected_plant_id <- 1L
  wrap_herb$fv_max <- 0.05 # max_distance = 3 m/min
  wrap_herb$distance_moved <- 0

  wrap_dist_before <- calc_toroidal_distance(99, 50, 1, 50, world_dim, world_dim)
  wrap_after <- herbivore_move(wrap_herb, wrap_plants, time_step_minutes = 1)

  limit_plants <- data.frame(
    plant_id = 1L,
    xcor = 40,
    ycor = 10,
    ms = 6,
    stringsAsFactors = FALSE
  )
  limit_herb <- init_herbivore(mass = 5e5)
  limit_herb$xcor <- 10
  limit_herb$ycor <- 10
  limit_herb$selected_plant_id <- 1L
  limit_herb$fv_max <- 0.05 # max_distance = 3 m/min
  limit_herb$distance_moved <- 0

  limit_dist_before <- calc_toroidal_distance(10, 10, 40, 10, world_dim, world_dim)
  limit_after <- herbivore_move(limit_herb, limit_plants, time_step_minutes = 1)

  data.frame(
    probe = c("wrap_probe", "step_limit_probe"),
    x_start = c(99, 10),
    y_start = c(50, 10),
    x_end = c(wrap_after$xcor, limit_after$xcor),
    y_end = c(wrap_after$ycor, limit_after$ycor),
    distance_before = c(wrap_dist_before, limit_dist_before),
    distance_moved = c(wrap_after$distance_moved, limit_after$distance_moved),
    max_distance = c(
      wrap_herb$fv_max * 60,
      limit_herb$fv_max * 60
    ),
    target_x = c(1, 40),
    target_y = c(50, 10),
    stringsAsFactors = FALSE
  )
}

run_movement_contract_scenario <- function(seed = 61L,
                                           steps = 400L,
                                           scenario_slug = "movement_contract_v0",
                                           base_dir = file.path("artefacts", "canonical_runs")) {
  if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed)) {
    rlang::abort(
      "Argument `seed` must be a finite scalar numeric value.",
      class = "herbivoreTTR_movement_contract_seed_invalid",
      seed = seed
    )
  }
  if (!is.numeric(steps) || length(steps) != 1L || !is.finite(steps) || steps < 1) {
    rlang::abort(
      "Argument `steps` must be a positive scalar.",
      class = "herbivoreTTR_movement_contract_steps_invalid",
      steps = steps
    )
  }

  steps <- as.integer(steps)
  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  movement_probe <- run_movement_probe()
  disruption_probe <- do.call(
    rbind,
    list(
      simulate_retarget_rate(disruption_prob = 0, steps = steps, seed = as.integer(seed + 1000L)),
      simulate_retarget_rate(disruption_prob = 1, steps = steps, seed = as.integer(seed + 2000L))
    )
  )

  summary_tbl <- data.frame(
    metric = c(
      "wrap_probe_lands_on_wrapped_target",
      "step_limit_respects_max_distance",
      "retarget_rate_prob1_minus_prob0"
    ),
    value = c(
      as.numeric(abs(movement_probe$x_end[movement_probe$probe == "wrap_probe"] - 1) <= 1e-8),
      as.numeric(
        movement_probe$distance_moved[movement_probe$probe == "step_limit_probe"] <=
          movement_probe$max_distance[movement_probe$probe == "step_limit_probe"] + 1e-8
      ),
      disruption_probe$retarget_rate[disruption_probe$disruption_prob == 1] -
        disruption_probe$retarget_rate[disruption_probe$disruption_prob == 0]
    ),
    stringsAsFactors = FALSE
  )

  movement_probe_path <- file.path(run_dir, "movement_probe.csv")
  disruption_probe_path <- file.path(run_dir, "disruption_probe.csv")
  summary_path <- file.path(run_dir, "movement_summary.csv")
  manifest_path <- file.path(run_dir, "run_manifest.json")

  utils::write.csv(movement_probe, movement_probe_path, row.names = FALSE)
  utils::write.csv(disruption_probe, disruption_probe_path, row.names = FALSE)
  utils::write.csv(summary_tbl, summary_path, row.names = FALSE)

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = as.integer(seed),
    scenario_parameters = list(
      steps = steps,
      movement_disruption_prob_default = CONSTANTS$MOVEMENT_DISRUPTION_PROB,
      eat_radius = CONSTANTS$EAT_RADIUS,
      detection_distance = CONSTANTS$DETECTION_DISTANCE,
      plot_size = CONSTANTS$PLOT_SIZE
    ),
    output_files = c(
      movement_probe = file.path(base_dir, scenario_slug, basename(movement_probe_path)),
      disruption_probe = file.path(base_dir, scenario_slug, basename(disruption_probe_path)),
      movement_summary = file.path(base_dir, scenario_slug, basename(summary_path))
    )
  )
  write_run_manifest(manifest = manifest, path = manifest_path)

  list(
    run_dir = run_dir,
    movement_probe_path = movement_probe_path,
    disruption_probe_path = disruption_probe_path,
    summary_path = summary_path,
    manifest_path = manifest_path,
    movement_probe = movement_probe,
    disruption_probe = disruption_probe,
    summary = summary_tbl
  )
}
