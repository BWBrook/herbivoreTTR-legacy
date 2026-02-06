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
  targets::tar_target(plants0, init_plants(veg_types = c(0, 1, 2))),
  targets::tar_target(herb0, init_herbivore(mass = 5e5)),
  targets::tar_target(day_after_spinup, CONSTANTS$SPIN_UP_LENGTH * nrow(conditions) + 1L),
  targets::tar_target(
    canonical_scenario_parameters,
    list(
      temp_mode = "flat",
      veg_types = c(0, 1, 2),
      herbivore_mass = 5e5,
      minute_limit = 60,
      start_day = day_after_spinup,
      days = 7L
    )
  ),

  # One-day simulation snapshot
  targets::tar_target(sim_day1, run_daily_herbivore_simulation(
    herbivore = herb0,
    plants = plants0,
    conditions = conditions,
    day_of_simulation = day_after_spinup,
    minute_limit = 60,
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
    run_herbivore_days(days = 3L, minute_limit = 60, seed = canonical_seed)
  ),

  # 7-day continuation
  targets::tar_target(
    sim_day7,
    run_herbivore_days(days = 7L, minute_limit = 60, seed = canonical_seed)
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
  )
)
