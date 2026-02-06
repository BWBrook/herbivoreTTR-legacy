# Focused scenario helper for WP-0.4.6 digestion-model contract validation.

simulate_digestion_probe <- function(probe_id,
                                     mass_g,
                                     MRT_hours,
                                     hours = 24L) {
  herb <- init_herbivore(mass = mass_g, herb_type = 0L, MRT = MRT_hours)
  hours <- as.integer(hours)

  hourly_rows <- vector("list", hours)
  for (hour in seq_len(hours)) {
    gut_before <- herb$gut_content
    carbs_before <- herb$intake_digest_carbs_day
    protein_before <- herb$intake_digest_protein_day
    npe_before <- herb$intake_NPE_day
    pe_before <- herb$intake_PE_day
    water_before <- herb$metabolic_water_day

    herb <- hourly_digestion_step(herb)

    digested_carbs <- herb$intake_digest_carbs_day - carbs_before
    digested_protein <- herb$intake_digest_protein_day - protein_before
    npe_released <- herb$intake_NPE_day - npe_before
    pe_released <- herb$intake_PE_day - pe_before
    water_released <- herb$metabolic_water_day - water_before

    hourly_rows[[hour]] <- data.frame(
      probe_id = probe_id,
      mass_g = as.numeric(herb$mass),
      MRT_hours = as.integer(herb$MRT),
      hour = as.integer(hour),
      gut_content_start_g = gut_before,
      gut_content_end_g = herb$gut_content,
      digested_carbs_g = digested_carbs,
      digested_protein_g = digested_protein,
      npe_released_kj = npe_released,
      pe_released_kj = pe_released,
      energy_released_kj = npe_released + pe_released,
      metabolic_water_released_g = water_released,
      stringsAsFactors = FALSE
    )
  }

  hourly_df <- do.call(rbind, hourly_rows)
  maintenance_kj <- CONSTANTS$ENERGY_MAINTENANCE_A * ((mass_g / 1000) ^ CONSTANTS$ENERGY_MAINTENANCE_B)
  day_energy <- sum(hourly_df$energy_released_kj)

  summary_df <- data.frame(
    probe_id = probe_id,
    mass_g = as.numeric(herb$mass),
    MRT_hours = as.integer(herb$MRT),
    hours = as.integer(hours),
    gut_start_g = hourly_df$gut_content_start_g[1],
    gut_end_g = tail(hourly_df$gut_content_end_g, 1),
    day_digestible_carbs_g = sum(hourly_df$digested_carbs_g),
    day_digestible_protein_g = sum(hourly_df$digested_protein_g),
    day_energy_kj = day_energy,
    day_metabolic_water_g = sum(hourly_df$metabolic_water_released_g),
    maintenance_energy_kj = maintenance_kj,
    energy_to_maintenance_ratio = if (maintenance_kj > 0) day_energy / maintenance_kj else NA_real_,
    first_hour_energy_kj = hourly_df$energy_released_kj[1],
    min_hourly_energy_kj = min(hourly_df$energy_released_kj),
    stringsAsFactors = FALSE
  )

  list(
    hourly = hourly_df,
    summary = summary_df
  )
}

summarise_digestion_contract <- function(hourly_df, probe_summary_df) {
  tol <- max(CONSTANTS$TOLERANCE, 1e-8)
  default_probe <- probe_summary_df[probe_summary_df$probe_id == "default_large", , drop = FALSE]
  short_probe <- probe_summary_df[probe_summary_df$probe_id == "short_mrt", , drop = FALSE]
  long_probe <- probe_summary_df[probe_summary_df$probe_id == "long_mrt", , drop = FALSE]

  data.frame(
    metric = c(
      "default_first_hour_energy_positive",
      "default_day_energy_positive",
      "default_gut_declines_without_intake",
      "short_minus_long_day_energy_kj",
      "long_day_energy_positive",
      "hourly_energy_non_negative",
      "hourly_gut_non_negative"
    ),
    value = c(
      as.numeric(default_probe$first_hour_energy_kj > tol),
      as.numeric(default_probe$day_energy_kj > tol),
      as.numeric(default_probe$gut_end_g < default_probe$gut_start_g - tol),
      short_probe$day_energy_kj - long_probe$day_energy_kj,
      as.numeric(long_probe$day_energy_kj > tol),
      as.numeric(all(hourly_df$energy_released_kj >= -tol & is.finite(hourly_df$energy_released_kj))),
      as.numeric(all(hourly_df$gut_content_end_g >= -tol & is.finite(hourly_df$gut_content_end_g)))
    ),
    stringsAsFactors = FALSE
  )
}

run_digestion_contract_scenario <- function(seed = 81L,
                                            hours = 24L,
                                            scenario_slug = "digestion_contract_v1",
                                            base_dir = file.path("artefacts", "canonical_runs")) {
  if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed)) {
    rlang::abort(
      "Argument `seed` must be a finite scalar numeric value.",
      class = "herbivoreTTR_digestion_contract_seed_invalid",
      seed = seed
    )
  }
  if (!is.numeric(hours) || length(hours) != 1L || !is.finite(hours) || hours < 1) {
    rlang::abort(
      "Argument `hours` must be a positive scalar.",
      class = "herbivoreTTR_digestion_contract_hours_invalid",
      hours = hours
    )
  }

  hours <- as.integer(hours)
  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  probe_specs <- data.frame(
    probe_id = c("default_large", "short_mrt", "long_mrt"),
    mass_g = c(2.18e6, 2.18e6, 2.18e6),
    MRT_hours = c(CONSTANTS$HERBIVORE_MRT, 12L, 48L),
    stringsAsFactors = FALSE
  )

  probe_results <- with_optional_seed(seed, {
    lapply(seq_len(nrow(probe_specs)), function(i) {
      simulate_digestion_probe(
        probe_id = probe_specs$probe_id[[i]],
        mass_g = probe_specs$mass_g[[i]],
        MRT_hours = probe_specs$MRT_hours[[i]],
        hours = hours
      )
    })
  })

  hourly_df <- do.call(rbind, lapply(probe_results, `[[`, "hourly"))
  probe_summary_df <- do.call(rbind, lapply(probe_results, `[[`, "summary"))
  contract_summary_df <- summarise_digestion_contract(
    hourly_df = hourly_df,
    probe_summary_df = probe_summary_df
  )

  hourly_path <- file.path(run_dir, "digestion_hourly.csv")
  probe_summary_path <- file.path(run_dir, "digestion_probe_summary.csv")
  contract_summary_path <- file.path(run_dir, "digestion_contract_summary.csv")
  manifest_path <- file.path(run_dir, "run_manifest.json")

  utils::write.csv(hourly_df, hourly_path, row.names = FALSE)
  utils::write.csv(probe_summary_df, probe_summary_path, row.names = FALSE)
  utils::write.csv(contract_summary_df, contract_summary_path, row.names = FALSE)

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = as.integer(seed),
    scenario_parameters = list(
      hours = hours,
      probe_specs = probe_specs,
      default_MRT = CONSTANTS$HERBIVORE_MRT,
      mrt_min = CONSTANTS$MRT_MIN_HOURS,
      mrt_max = CONSTANTS$MRT_MAX_HOURS,
      digestion_init_fill_fraction = CONSTANTS$DIGESTION_INIT_FILL_FRACTION,
      digestion_init_leaf_fraction = CONSTANTS$DIGESTION_INIT_LEAF_FRACTION,
      digestion_init_stem_fraction = CONSTANTS$DIGESTION_INIT_STEM_FRACTION,
      digestion_init_defence_fraction = CONSTANTS$DIGESTION_INIT_DEFENCE_FRACTION
    ),
    output_files = c(
      digestion_hourly = file.path(base_dir, scenario_slug, basename(hourly_path)),
      digestion_probe_summary = file.path(base_dir, scenario_slug, basename(probe_summary_path)),
      digestion_contract_summary = file.path(base_dir, scenario_slug, basename(contract_summary_path))
    )
  )
  write_run_manifest(manifest = manifest, path = manifest_path)

  list(
    run_dir = run_dir,
    hourly_path = hourly_path,
    probe_summary_path = probe_summary_path,
    contract_summary_path = contract_summary_path,
    manifest_path = manifest_path,
    hourly = hourly_df,
    probe_summary = probe_summary_df,
    contract_summary = contract_summary_df
  )
}
