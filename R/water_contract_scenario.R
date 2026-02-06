# Focused scenario helper for WP-0.4.7 water-balance contract validation.

build_water_contract_plant <- function(qshoot_to_shoot_ratio = 8,
                                       total_shoot_kg = 25,
                                       defence_fraction = 0.05) {
  if (!is.numeric(qshoot_to_shoot_ratio) || length(qshoot_to_shoot_ratio) != 1L ||
      !is.finite(qshoot_to_shoot_ratio) || qshoot_to_shoot_ratio < 0) {
    rlang::abort(
      "Argument `qshoot_to_shoot_ratio` must be a non-negative finite scalar.",
      class = "herbivoreTTR_water_contract_qshoot_ratio_invalid",
      qshoot_to_shoot_ratio = qshoot_to_shoot_ratio
    )
  }
  if (!is.numeric(total_shoot_kg) || length(total_shoot_kg) != 1L ||
      !is.finite(total_shoot_kg) || total_shoot_kg <= 0) {
    rlang::abort(
      "Argument `total_shoot_kg` must be a positive finite scalar.",
      class = "herbivoreTTR_water_contract_total_shoot_invalid",
      total_shoot_kg = total_shoot_kg
    )
  }
  if (!is.numeric(defence_fraction) || length(defence_fraction) != 1L ||
      !is.finite(defence_fraction) || defence_fraction < 0 || defence_fraction > 1) {
    rlang::abort(
      "Argument `defence_fraction` must be in [0, 1].",
      class = "herbivoreTTR_water_contract_defence_fraction_invalid",
      defence_fraction = defence_fraction
    )
  }

  bdef <- total_shoot_kg * defence_fraction
  remaining <- max(total_shoot_kg - bdef, 0)
  bleaf <- remaining * 0.8
  bstem <- remaining * 0.2

  data.frame(
    plant_id = 1L,
    xcor = 0,
    ycor = 0,
    veg_type = 0L,
    height = 1,
    ms = total_shoot_kg,
    mr = total_shoot_kg,
    bdef = bdef,
    bleaf = bleaf,
    bstem = bstem,
    qshoot = total_shoot_kg * qshoot_to_shoot_ratio,
    qroot = total_shoot_kg * qshoot_to_shoot_ratio,
    cs = total_shoot_kg * CONSTANTS$FRACTION_C,
    cr = total_shoot_kg * CONSTANTS$FRACTION_C,
    ns = total_shoot_kg * CONSTANTS$FRACTION_N,
    nr = total_shoot_kg * CONSTANTS$FRACTION_N,
    stringsAsFactors = FALSE
  )
}

simulate_water_balance_probe <- function(probe_id,
                                         qshoot_to_shoot_ratio,
                                         minute_limit = 360L,
                                         seed = 1L) {
  with_optional_seed(seed, {
    plants <- build_water_contract_plant(
      qshoot_to_shoot_ratio = qshoot_to_shoot_ratio
    )
    herb <- init_herbivore(mass = 5e5, herb_type = 0L)
    herb$xcor <- 0
    herb$ycor <- 0
    herb$selected_plant_id <- 1L
    herb$behaviour <- "EATING"
    herb$gut_capacity <- max(herb$gut_capacity, 2e5)
    herb$handling_time <- min(herb$handling_time, 0.2)
    herb$bite_size <- max(herb$bite_size, 1e4)
    herb <- reset_daily_variables(herb)

    start_qshoot <- plants$qshoot
    start_distance <- herb$distance_moved
    start_energy <- herb$energy_balance

    for (minute in seq_len(as.integer(minute_limit))) {
      herb <- update_gut_content(herb)
      eat <- herbivore_eat(herbivore = herb, plants = plants)
      herb <- eat$herbivore
      plants <- eat$plants

      if (minute %% 60 == 0) {
        herb <- hourly_digestion_step(herb)
      }
    }

    herb$daily_water_requirement <- calc_water_requirement(herb$mass)
    herb <- check_daily_water_balance(herb)

    with_drink_state <- herb
    with_drink_state <- calc_daily_energy_balance(with_drink_state)
    energy_with_drink <- with_drink_state$energy_balance

    without_drink_state <- herb
    if (without_drink_state$intake_water_drinking > 0) {
      without_drink_state$distance_moved <- without_drink_state$distance_moved - CONSTANTS$DIST_TO_WATER
    }
    without_drink_state <- calc_daily_energy_balance(without_drink_state)
    energy_without_drink <- without_drink_state$energy_balance

    mass_kg <- herb$mass / 1000
    expected_drinking_energy_penalty <- if (herb$intake_water_drinking > 0) {
      (CONSTANTS$DIST_TO_WATER / 1000) * (CONSTANTS$ICL_A * (mass_kg ^ CONSTANTS$ICL_B)) / 100
    } else {
      0
    }

    data.frame(
      probe_id = probe_id,
      qshoot_to_shoot_ratio = qshoot_to_shoot_ratio,
      minute_limit = as.integer(minute_limit),
      water_requirement_g = herb$daily_water_requirement,
      water_forage_g = herb$intake_water_forage,
      water_metabolic_g = herb$metabolic_water_day,
      water_drinking_g = herb$intake_water_drinking,
      daily_net_water_balance_g = herb$daily_net_water_balance,
      cumulative_water_balance_g = herb$water_balance,
      distance_before_m = start_distance,
      distance_after_m = herb$distance_moved,
      distance_drinking_increment_m = herb$distance_moved - start_distance,
      start_qshoot_kg = start_qshoot,
      end_qshoot_kg = plants$qshoot,
      drinking_triggered = as.integer(herb$intake_water_drinking > 0),
      expected_drinking_energy_penalty_kj = expected_drinking_energy_penalty,
      observed_drinking_energy_penalty_kj = energy_without_drink - energy_with_drink,
      energy_balance_before_kj = start_energy,
      energy_balance_after_kj = energy_with_drink,
      stringsAsFactors = FALSE
    )
  })
}

summarise_water_contract <- function(probe_df) {
  tol <- max(CONSTANTS$TOLERANCE, 1e-8)
  deficit <- probe_df[probe_df$probe_id == "water_deficit", , drop = FALSE]
  hydrated <- probe_df[probe_df$probe_id == "water_sufficient", , drop = FALSE]
  numeric_cols <- vapply(probe_df, is.numeric, logical(1))
  numeric_values <- unlist(probe_df[, numeric_cols, drop = FALSE], use.names = FALSE)

  data.frame(
    metric = c(
      "deficit_probe_drinking_triggered",
      "sufficient_probe_no_drinking",
      "deficit_probe_distance_includes_water_trip",
      "deficit_probe_energy_penalty_matches_expected",
      "forage_water_positive_for_both_probes",
      "daily_water_balance_components_finite"
    ),
    value = c(
      as.numeric(deficit$drinking_triggered == 1),
      as.numeric(hydrated$drinking_triggered == 0),
      as.numeric(deficit$distance_drinking_increment_m >= CONSTANTS$DIST_TO_WATER - tol),
      as.numeric(abs(
        deficit$observed_drinking_energy_penalty_kj -
          deficit$expected_drinking_energy_penalty_kj
      ) <= 1e-6),
      as.numeric(all(probe_df$water_forage_g > 0)),
      as.numeric(all(is.finite(numeric_values)))
    ),
    stringsAsFactors = FALSE
  )
}

run_water_contract_scenario <- function(seed = 91L,
                                        minute_limit = 360L,
                                        scenario_slug = "water_contract_v1",
                                        base_dir = file.path("artefacts", "canonical_runs")) {
  if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed)) {
    rlang::abort(
      "Argument `seed` must be a finite scalar numeric value.",
      class = "herbivoreTTR_water_contract_seed_invalid",
      seed = seed
    )
  }
  if (!is.numeric(minute_limit) || length(minute_limit) != 1L ||
      !is.finite(minute_limit) || minute_limit < 1) {
    rlang::abort(
      "Argument `minute_limit` must be a positive scalar.",
      class = "herbivoreTTR_water_contract_minute_limit_invalid",
      minute_limit = minute_limit
    )
  }

  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  probe <- with_optional_seed(seed, {
    do.call(
      rbind,
      list(
        simulate_water_balance_probe(
          probe_id = "water_deficit",
          qshoot_to_shoot_ratio = 0.5,
          minute_limit = as.integer(minute_limit),
          seed = as.integer(seed + 100L)
        ),
        simulate_water_balance_probe(
          probe_id = "water_sufficient",
          qshoot_to_shoot_ratio = 12,
          minute_limit = as.integer(minute_limit),
          seed = as.integer(seed + 200L)
        )
      )
    )
  })

  summary <- summarise_water_contract(probe_df = probe)

  probe_path <- file.path(run_dir, "water_probe.csv")
  summary_path <- file.path(run_dir, "water_summary.csv")
  manifest_path <- file.path(run_dir, "run_manifest.json")

  utils::write.csv(probe, probe_path, row.names = FALSE)
  utils::write.csv(summary, summary_path, row.names = FALSE)

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = as.integer(seed),
    scenario_parameters = list(
      minute_limit = as.integer(minute_limit),
      deficit_qshoot_ratio = 0.5,
      sufficient_qshoot_ratio = 12,
      dist_to_water = CONSTANTS$DIST_TO_WATER,
      carb_to_mw = CONSTANTS$CARB_TO_MW,
      protein_to_mw = CONSTANTS$PROTEIN_TO_MW
    ),
    output_files = c(
      water_probe = file.path(base_dir, scenario_slug, basename(probe_path)),
      water_summary = file.path(base_dir, scenario_slug, basename(summary_path))
    )
  )
  write_run_manifest(manifest = manifest, path = manifest_path)

  list(
    run_dir = run_dir,
    probe_path = probe_path,
    summary_path = summary_path,
    manifest_path = manifest_path,
    probe = probe,
    summary = summary
  )
}
