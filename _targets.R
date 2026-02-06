## Minimal {targets} pipeline to run a short simulation and emit parity CSVs

if (!requireNamespace("targets", quietly = TRUE)) {
  stop("Install the 'targets' package to run the pipeline.")
}

targets::tar_option_set(
  packages = character(), # functions defined under R/; avoid auto-attaching packages
  format = "rds",
  memory = "transient",
  garbage_collection = TRUE,
  seed = 1L
)

targets::tar_source("R")

list(
  targets::tar_target(canonical_seed, 1L),
  targets::tar_target(canonical_scenario_slug, "smoke_v0"),
  targets::tar_target(conditions, init_conditions(mode = "flat")),
  targets::tar_target(canonical_scenario_parameters, canonical_smoke_parameters(conditions = conditions)),
  targets::tar_target(plants0, init_plants(veg_types = canonical_scenario_parameters$veg_types)),
  targets::tar_target(herb0, init_herbivore(mass = canonical_scenario_parameters$herbivore_mass)),
  targets::tar_target(day_after_spinup, canonical_scenario_parameters$start_day),
  targets::tar_target(
    canonical_minute_limit,
    canonical_scenario_parameters$minute_limit
  ),

  # One-day simulation snapshot
  targets::tar_target(sim_day1, run_daily_herbivore_simulation(
    herbivore = herb0,
    plants = plants0,
    conditions = conditions,
    day_of_simulation = day_after_spinup,
    minute_limit = canonical_minute_limit,
    seed = canonical_seed
  )),

  # Write CSVs for parity checks
  targets::tar_target(
    plants_day1_csv,
    write_plants_snapshot_target(
      plants = sim_day1$plants,
      day = day_after_spinup
    ),
    format = "file"
  ),

  targets::tar_target(
    herb_day1_csv,
    write_herbivore_snapshot_target(
      herbivore = sim_day1$herbivore,
      day = day_after_spinup
    ),
    format = "file"
  ),

  # Three-day demo run after spin-up
  targets::tar_target(
    sim_day3_demo,
    run_herbivore_days(days = 3L, minute_limit = canonical_minute_limit, seed = canonical_seed)
  ),

  # 7-day continuation
  targets::tar_target(
    sim_day7,
    run_herbivore_days(
      days = canonical_scenario_parameters$days,
      minute_limit = canonical_minute_limit,
      seed = canonical_seed
    )
  ),

  targets::tar_target(
    plants_day7_csv,
    write_plants_snapshot_target(
      plants = sim_day7$plants,
      day = day_after_spinup + 6L
    ),
    format = "file"
  ),

  targets::tar_target(
    herb_day7_csv,
    write_herbivore_snapshot_target(
      herbivore = sim_day7$herbivore,
      day = day_after_spinup + 6L
    ),
    format = "file"
  ),

  targets::tar_target(
    canonical_bundle_files,
    write_canonical_run_bundle(
      output_files = c(
        plants_day1 = plants_day1_csv,
        herb_day1 = herb_day1_csv,
        plants_day7 = plants_day7_csv,
        herb_day7 = herb_day7_csv
      ),
      scenario_slug = canonical_scenario_slug,
      seed = canonical_seed,
      scenario_parameters = canonical_scenario_parameters
    ),
    format = "file"
  ),

  targets::tar_target(
    functional_type_bundle_files,
    {
      functional_type_run <- run_functional_type_scenario(
        minute_limit = 120L,
        seed = canonical_seed,
        scenario_slug = "functional_types_v0"
      )
      c(
        functional_type_run$metrics_path,
        functional_type_run$plants_initial_path,
        functional_type_run$plants_final_paths,
        functional_type_run$manifest_path
      )
    },
    format = "file"
  ),

  targets::tar_target(
    mixed_feeder_bundle_files,
    {
      mixed_policy_run <- run_functional_type_scenario(
        minute_limit = 120L,
        seed = canonical_seed,
        scenario_slug = "mixed_policy_v0",
        herb_types = c(0L, 1L, 2L)
      )
      c(
        mixed_policy_run$metrics_path,
        mixed_policy_run$plants_initial_path,
        mixed_policy_run$plants_final_paths,
        mixed_policy_run$manifest_path
      )
    },
    format = "file"
  ),

  targets::tar_target(
    selection_contract_bundle_files,
    {
      selection_run <- run_selection_contract_scenario(
        seed = canonical_seed,
        n_draws = 5000L,
        scenario_slug = "selection_contract_v0"
      )
      c(
        selection_run$candidates_path,
        selection_run$frequency_path,
        selection_run$summary_path,
        selection_run$manifest_path
      )
    },
    format = "file"
  ),

  targets::tar_target(
    movement_contract_bundle_files,
    {
      movement_run <- run_movement_contract_scenario(
        seed = canonical_seed,
        steps = 400L,
        scenario_slug = "movement_contract_v0"
      )
      c(
        movement_run$movement_probe_path,
        movement_run$disruption_probe_path,
        movement_run$summary_path,
        movement_run$manifest_path
      )
    },
    format = "file"
  )
)
