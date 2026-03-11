## Minimal {targets} pipeline to run simulation contracts and canonical artefacts.

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
  targets::tar_target(
    canonical_scenario_yaml_path,
    scenario_contract_reference_path("canonical_smoke_v1"),
    format = "file"
  ),
  targets::tar_target(canonical_scenario, compile_scenario_yaml_v2(canonical_scenario_yaml_path)),
  targets::tar_target(canonical_seed, canonical_scenario$runtime$seed),
  targets::tar_target(canonical_scenario_slug, canonical_scenario$outputs$scenario_slug),
  targets::tar_target(canonical_run_id, build_run_id(canonical_scenario_slug, canonical_seed, canonical_scenario)),
  targets::tar_target(conditions, init_conditions(mode = canonical_scenario$climate$mode)),
  targets::tar_target(
    canonical_scenario_parameters,
    scenario_to_canonical_parameters(canonical_scenario, conditions = conditions)
  ),
  targets::tar_target(plants0, init_plants(veg_types = canonical_scenario_parameters$veg_types)),
  targets::tar_target(
    herb0,
    {
      herb <- init_herbivore(
        mass = canonical_scenario_parameters$herbivore_mass,
        herb_type = canonical_scenario_parameters$herb_type,
        MRT = canonical_scenario_parameters$herbivore_mrt,
        herbivore_id = "herbivore_1"
      )
      herb$foraging_mode <- canonical_scenario_parameters$herbivore_foraging_mode
      herb
    }
  ),
  targets::tar_target(day_after_spinup, canonical_scenario_parameters$start_day),
  targets::tar_target(canonical_minute_limit, canonical_scenario_parameters$minute_limit),

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
      day = day_after_spinup,
      run_id = canonical_run_id
    ),
    format = "file"
  ),

  targets::tar_target(
    herb_day1_csv,
    write_herbivore_snapshot_target(
      herbivore = sim_day1$herbivore,
      day = day_after_spinup,
      run_id = canonical_run_id,
      herbivore_id = sim_day1$herbivore$herbivore_id
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
      day = day_after_spinup + 6L,
      run_id = canonical_run_id
    ),
    format = "file"
  ),

  targets::tar_target(
    herb_day7_csv,
    write_herbivore_snapshot_target(
      herbivore = sim_day7$herbivore,
      day = day_after_spinup + 6L,
      run_id = canonical_run_id,
      herbivore_id = sim_day7$herbivore$herbivore_id
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
      scenario_parameters = canonical_scenario_parameters,
      run_id = canonical_run_id
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
  ),

  targets::tar_target(
    foraging_contract_bundle_files,
    {
      foraging_run <- run_foraging_contract_scenario(
        seed = canonical_seed,
        scenario_slug = "foraging_contract_v0"
      )
      c(
        foraging_run$probe_path,
        foraging_run$summary_path,
        foraging_run$manifest_path
      )
    },
    format = "file"
  ),

  targets::tar_target(
    digestion_contract_bundle_files,
    {
      digestion_run <- run_digestion_contract_scenario(
        seed = canonical_seed,
        hours = 24L,
        scenario_slug = "digestion_contract_v1"
      )
      c(
        digestion_run$hourly_path,
        digestion_run$probe_summary_path,
        digestion_run$contract_summary_path,
        digestion_run$manifest_path
      )
    },
    format = "file"
  ),

  targets::tar_target(
    water_contract_bundle_files,
    {
      water_run <- run_water_contract_scenario(
        seed = canonical_seed,
        minute_limit = 360L,
        scenario_slug = "water_contract_v1"
      )
      c(
        water_run$probe_path,
        water_run$summary_path,
        water_run$manifest_path
      )
    },
    format = "file"
  ),

  targets::tar_target(
    day_in_life_bundle_files,
    {
      day_run <- run_day_in_life_comparison(
        seed = canonical_seed,
        minute_limit = 360L,
        base_dir = file.path("artefacts", "canonical_runs")
      )
      day_run$bundle_files
    },
    format = "file"
  ),

  targets::tar_target(
    cohort_scenario_yaml_path,
    scenario_contract_reference_path("cohort_smoke_v1"),
    format = "file"
  ),
  targets::tar_target(cohort_scenario, compile_scenario_yaml_v2(cohort_scenario_yaml_path)),
  targets::tar_target(
    cohort_bundle_files,
    {
      out <- run_scenario_v2(cohort_scenario, base_dir = file.path("artefacts", "canonical_runs"))
      c(
        out$plants_first_path,
        out$plants_last_path,
        out$daily_output_path,
        out$structure_fuel_path,
        out$manifest_path
      )
    },
    format = "file"
  ),

  targets::tar_target(
    implicit_scenario_yaml_path,
    scenario_contract_reference_path("implicit_stocking_v1"),
    format = "file"
  ),
  targets::tar_target(implicit_scenario, compile_scenario_yaml_v2(implicit_scenario_yaml_path)),
  targets::tar_target(
    implicit_bundle_files,
    {
      out <- run_scenario_v2(implicit_scenario, base_dir = file.path("artefacts", "canonical_runs"))
      files <- c(
        out$plants_first_path,
        out$plants_last_path,
        out$daily_output_path,
        out$structure_fuel_path,
        out$manifest_path
      )
      if (!is.null(out$implicit_visit_path)) {
        files <- c(files, out$implicit_visit_path)
      }
      files
    },
    format = "file"
  ),

  targets::tar_target(
    reference_library_bundle_files,
    {
      out <- run_reference_scenario_library(base_dir = file.path("artefacts", "canonical_runs"))
      run_manifests <- vapply(
        out$runs,
        function(x) x$manifest_path,
        character(1)
      )
      c(out$index_path, out$index_md_path, run_manifests)
    },
    format = "file"
  ),

  targets::tar_target(
    experiment_a_bundle_files,
    {
      out <- run_experiment_a_presence_removal(base_dir = file.path("artefacts", "canonical_runs"))
      c(out$summary_path, out$direction_path, out$plot_path, out$report_path, out$manifest_path)
    },
    format = "file"
  ),

  targets::tar_target(
    experiment_b_bundle_files,
    {
      out <- run_experiment_b_functional_types(base_dir = file.path("artefacts", "canonical_runs"))
      c(out$summary_path, out$plot_path, out$report_path, out$manifest_path)
    },
    format = "file"
  ),

  targets::tar_target(
    experiment_c_bundle_files,
    {
      out <- run_experiment_c_aridity_gradient(base_dir = file.path("artefacts", "canonical_runs"))
      c(out$summary_path, out$plot_path, out$report_path, out$manifest_path)
    },
    format = "file"
  ),

  targets::tar_target(
    benchmark_appendix_bundle_files,
    {
      out <- run_benchmark_appendix_v1(base_dir = file.path("artefacts", "canonical_runs"))
      c(
        out$appendix_path,
        out$benchmark$internal_path,
        out$benchmark$comparison_path,
        out$benchmark$report_path,
        out$benchmark$manifest_path
      )
    },
    format = "file"
  ),

  targets::tar_target(
    performance_budget_bundle_files,
    {
      out <- run_performance_budget_profile(base_dir = file.path("artefacts", "canonical_runs"))
      c(out$summary_path, out$report_path, out$manifest_path)
    },
    format = "file"
  ),

  targets::tar_target(
    paper_pipeline_bundle_files,
    {
      deps <- c(
        day_in_life_bundle_files,
        experiment_a_bundle_files,
        experiment_b_bundle_files,
        experiment_c_bundle_files
      )
      output <- render_paper_pipeline_report(
        input = file.path("reports", "paper_pipeline.qmd"),
        output_dir = file.path("artefacts", "reports")
      )
      c(
        output,
        file.path("reports", "paper_pipeline.qmd"),
        deps
      )
    },
    format = "file"
  ),

  targets::tar_target(
    experiment_a_v2_bundle_files,
    {
      out <- run_experiment_a_presence_removal_v2(
        base_dir = file.path("artefacts", "canonical_runs"),
        seeds = 301:304
      )
      c(
        out$replicate_path,
        out$summary_path,
        out$delta_path,
        out$claims_path,
        out$summary_units_path,
        out$delta_units_path,
        out$figure_path,
        out$report_path,
        out$manifest_path
      )
    },
    format = "file"
  ),

  targets::tar_target(
    experiment_c_v2_bundle_files,
    {
      out <- run_experiment_c_aridity_gradient_v2(
        base_dir = file.path("artefacts", "canonical_runs"),
        seeds = 701:703
      )
      c(
        out$matrix_path,
        out$replicate_path,
        out$summary_path,
        out$expected_path,
        out$claims_path,
        out$summary_units_path,
        out$expected_units_path,
        out$figure_path,
        out$report_path,
        out$manifest_path
      )
    },
    format = "file"
  ),

  targets::tar_target(
    pilot_validation_bundle_files,
    {
      out <- run_pilot_validation_benchmark_v1(base_dir = file.path("artefacts", "validation"))
      c(
        out$observed_path,
        out$model_path,
        out$summary_path,
        out$report_path,
        out$manifest_path
      )
    },
    format = "file"
  ),

  targets::tar_target(
    long_horizon_stability_bundle_files,
    {
      out <- run_long_horizon_stability_suite_v1(
        base_dir = file.path("artefacts", "stability"),
        seeds = 801:802,
        days = 30L
      )
      c(
        out$replicate_path,
        out$summary_path,
        out$report_path,
        out$manifest_path
      )
    },
    format = "file"
  ),

  targets::tar_target(
    post_v1_scaling_bundle_files,
    {
      out <- run_post_v1_scaling_profile(
        base_dir = file.path("artefacts", "benchmarks"),
        ensemble_seeds = 1:6,
        stability_days = 20L,
        stability_seeds = 1:2,
        enforce_regression_gate = FALSE
      )
      c(
        out$summary_path,
        out$parallel_benchmark_path,
        out$break_even_path,
        out$break_even_gate_path,
        out$kernel_profile_raw_path,
        out$kernel_profile_self_path,
        out$kernel_profile_total_path,
        out$report_path,
        out$manifest_path
      )
    },
    format = "file"
  ),

  targets::tar_target(
    paper_pipeline_v2_bundle_files,
    {
      deps <- c(
        experiment_a_v2_bundle_files,
        experiment_c_v2_bundle_files,
        pilot_validation_bundle_files,
        long_horizon_stability_bundle_files
      )
      out <- render_paper_pipeline_report_v2(
        input = file.path("reports", "paper_pipeline_v2.qmd"),
        output_dir = file.path("artefacts", "reports_v2")
      )
      files <- c(out$html, out$manifest_path, file.path("reports", "paper_pipeline_v2.qmd"), deps)
      files[!is.na(files) & nzchar(files)]
    },
    format = "file"
  )
)
