# Focused scenario helper for WP-0.4.5 foraging-rate and defence contract.

build_foraging_contract_plant <- function(total_shoot_kg,
                                          defence_fraction,
                                          plant_id = 1L,
                                          ms_override = NULL) {
  if (!is.numeric(total_shoot_kg) || length(total_shoot_kg) != 1L ||
      !is.finite(total_shoot_kg) || total_shoot_kg <= 0) {
    rlang::abort(
      "Argument `total_shoot_kg` must be a positive finite scalar.",
      class = "herbivoreTTR_foraging_contract_total_shoot_invalid",
      total_shoot_kg = total_shoot_kg
    )
  }

  if (!is.numeric(defence_fraction) || length(defence_fraction) != 1L ||
      !is.finite(defence_fraction) || defence_fraction < 0 || defence_fraction > 1) {
    rlang::abort(
      "Argument `defence_fraction` must be a finite scalar in [0, 1].",
      class = "herbivoreTTR_foraging_contract_defence_fraction_invalid",
      defence_fraction = defence_fraction
    )
  }

  bdef <- total_shoot_kg * defence_fraction
  non_defence <- max(total_shoot_kg - bdef, 0)
  bleaf <- non_defence * 0.8
  bstem <- non_defence * 0.2

  ms <- if (is.null(ms_override)) {
    total_shoot_kg
  } else {
    as.numeric(ms_override)
  }

  data.frame(
    plant_id = as.integer(plant_id),
    xcor = 0,
    ycor = 0,
    ms = ms,
    mr = 1,
    bdef = bdef,
    height = 1,
    cs = 1,
    cr = 1,
    ns = 0.1,
    nr = 0.1,
    bleaf = bleaf,
    bstem = bstem,
    stringsAsFactors = FALSE
  )
}

simulate_foraging_probe <- function(probe_id,
                                    defence_fraction,
                                    handling_time_min_per_g,
                                    gut_capacity_g,
                                    gut_content_g,
                                    total_shoot_kg,
                                    ms_override = NULL) {
  if (!is.character(probe_id) || length(probe_id) != 1L || !nzchar(probe_id)) {
    rlang::abort(
      "Argument `probe_id` must be a non-empty scalar character.",
      class = "herbivoreTTR_foraging_contract_probe_id_invalid",
      probe_id = probe_id
    )
  }

  plants <- build_foraging_contract_plant(
    total_shoot_kg = total_shoot_kg,
    defence_fraction = defence_fraction,
    ms_override = ms_override
  )

  herb <- init_herbivore(mass = 5e5, herb_type = 0L)
  herb$selected_plant_id <- 1L
  herb$behaviour <- "EATING"
  herb$gut_capacity <- as.numeric(gut_capacity_g)
  herb$gut_content <- as.numeric(gut_content_g)
  herb$handling_time <- as.numeric(handling_time_min_per_g)
  herb$bite_size <- 1e6 # keep bite size out of the limiting pathway

  initial_total_shoot <- plants$bleaf + plants$bstem + plants$bdef
  defence_prop <- if (initial_total_shoot > 0) {
    plants$bdef / initial_total_shoot
  } else {
    0
  }

  rate_g_per_min <- if (is.finite(herb$handling_time) && herb$handling_time > 0) {
    1 / herb$handling_time
  } else {
    0
  }
  expected_handling_limit_kg <- (rate_g_per_min / 1000) * (1 - defence_prop)

  capacity_limit_kg <- max((herb$gut_capacity - herb$gut_content) / 1000, 0)
  available_above_min_kg <- max(initial_total_shoot - CONSTANTS$MIN_SHOOT, 0)
  mechanical_cap_kg <- max(CONSTANTS$MAX_BITE_FRACTION, 0) * herb$gut_capacity / 1000

  expected_limit_kg <- min(
    expected_handling_limit_kg,
    capacity_limit_kg,
    available_above_min_kg,
    mechanical_cap_kg
  )
  if (!is.finite(expected_limit_kg) || expected_limit_kg < 0) {
    expected_limit_kg <- 0
  }

  out <- herbivore_eat(herbivore = herb, plants = plants)

  final_total_shoot <- out$plants$bleaf + out$plants$bstem + out$plants$bdef
  intake_kg <- (out$herbivore$intake_total_day - herb$intake_total_day) / 1000

  data.frame(
    probe_id = probe_id,
    defence_fraction = defence_fraction,
    handling_time_min_per_g = herb$handling_time,
    gut_capacity_g = herb$gut_capacity,
    gut_content_g = herb$gut_content,
    ms_reported_start_kg = plants$ms,
    shoot_components_start_kg = initial_total_shoot,
    expected_handling_limit_kg = expected_handling_limit_kg,
    capacity_limit_kg = capacity_limit_kg,
    available_above_min_kg = available_above_min_kg,
    expected_limit_kg = expected_limit_kg,
    observed_intake_kg = intake_kg,
    residual_shoot_kg = final_total_shoot,
    min_shoot_kg = CONSTANTS$MIN_SHOOT,
    stringsAsFactors = FALSE
  )
}

summarise_foraging_contract <- function(probe_df) {
  tol <- max(CONSTANTS$TOLERANCE, 1e-8)

  low <- probe_df[probe_df$probe_id == "defence_low", , drop = FALSE]
  high <- probe_df[probe_df$probe_id == "defence_high", , drop = FALSE]
  capacity <- probe_df[probe_df$probe_id == "capacity_cap", , drop = FALSE]
  residual <- probe_df[probe_df$probe_id == "residual_floor_with_ms_drift", , drop = FALSE]

  data.frame(
    metric = c(
      "defence_low_minus_high_intake_kg",
      "handling_probe_matches_expected_limit",
      "capacity_probe_matches_expected_limit",
      "residual_probe_respects_min_shoot",
      "residual_probe_not_limited_by_ms_drift"
    ),
    value = c(
      low$observed_intake_kg - high$observed_intake_kg,
      as.numeric(abs(low$observed_intake_kg - low$expected_limit_kg) <= tol),
      as.numeric(abs(capacity$observed_intake_kg - capacity$expected_limit_kg) <= tol),
      as.numeric(residual$residual_shoot_kg >= residual$min_shoot_kg - tol),
      as.numeric(abs(residual$observed_intake_kg - residual$available_above_min_kg) <= tol)
    ),
    stringsAsFactors = FALSE
  )
}

run_foraging_contract_scenario <- function(seed = 71L,
                                           scenario_slug = "foraging_contract_v0",
                                           base_dir = file.path("artefacts", "canonical_runs")) {
  if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed)) {
    rlang::abort(
      "Argument `seed` must be a finite scalar numeric value.",
      class = "herbivoreTTR_foraging_contract_seed_invalid",
      seed = seed
    )
  }

  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  probe_df <- with_optional_seed(seed, {
    do.call(
      rbind,
      list(
        simulate_foraging_probe(
          probe_id = "defence_low",
          defence_fraction = 0.05,
          handling_time_min_per_g = 1,
          gut_capacity_g = 1e6,
          gut_content_g = 0,
          total_shoot_kg = 2.0
        ),
        simulate_foraging_probe(
          probe_id = "defence_high",
          defence_fraction = 0.60,
          handling_time_min_per_g = 1,
          gut_capacity_g = 1e6,
          gut_content_g = 0,
          total_shoot_kg = 2.0
        ),
        simulate_foraging_probe(
          probe_id = "capacity_cap",
          defence_fraction = 0.05,
          handling_time_min_per_g = 0.2,
          gut_capacity_g = 1000,
          gut_content_g = 999.7,
          total_shoot_kg = 2.0
        ),
        simulate_foraging_probe(
          probe_id = "residual_floor_with_ms_drift",
          defence_fraction = 0.10,
          handling_time_min_per_g = 0.1,
          gut_capacity_g = 1e6,
          gut_content_g = 0,
          total_shoot_kg = CONSTANTS$MIN_SHOOT + 4e-4,
          ms_override = CONSTANTS$MIN_SHOOT + 0.25
        )
      )
    )
  })

  summary_df <- summarise_foraging_contract(probe_df)

  probe_path <- file.path(run_dir, "foraging_probe.csv")
  summary_path <- file.path(run_dir, "foraging_summary.csv")
  manifest_path <- file.path(run_dir, "run_manifest.json")

  utils::write.csv(probe_df, probe_path, row.names = FALSE)
  utils::write.csv(summary_df, summary_path, row.names = FALSE)

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = as.integer(seed),
    scenario_parameters = list(
      min_shoot = CONSTANTS$MIN_SHOOT,
      max_bite_fraction = CONSTANTS$MAX_BITE_FRACTION,
      tolerance = CONSTANTS$TOLERANCE,
      probes = as.list(probe_df$probe_id)
    ),
    output_files = c(
      foraging_probe = file.path(base_dir, scenario_slug, basename(probe_path)),
      foraging_summary = file.path(base_dir, scenario_slug, basename(summary_path))
    )
  )
  write_run_manifest(manifest = manifest, path = manifest_path)

  list(
    run_dir = run_dir,
    probe_path = probe_path,
    summary_path = summary_path,
    manifest_path = manifest_path,
    probe = probe_df,
    summary = summary_df
  )
}
