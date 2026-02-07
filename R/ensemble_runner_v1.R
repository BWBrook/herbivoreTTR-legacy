# Deterministic multi-seed ensemble execution helpers.

normalise_ensemble_seeds <- function(seeds) {
  seed_vec <- as.integer(seeds)
  if (length(seed_vec) < 1L || any(!is.finite(seed_vec))) {
    rlang::abort(
      "Argument `seeds` must contain at least one finite integer seed.",
      class = "herbivoreTTR_ensemble_seeds_invalid",
      seeds = seeds
    )
  }
  sort(unique(seed_vec))
}

summarise_run_result_for_ensemble <- function(run_result, seed_value, seed_index) {
  herb <- run_result$herbivore_daily
  metrics <- run_result$structure_fuel_metrics
  final <- metrics[which.max(metrics$Day), , drop = FALSE]

  data.frame(
    seed_index = as.integer(seed_index),
    seed_value = as.integer(seed_value),
    run_id = as.character(run_result$run_id),
    scenario_slug = as.character(run_result$scenario$outputs$scenario_slug),
    mean_daily_dmi = mean(herb$DailyDMI),
    mean_daily_dist_m = mean(herb$DailyDistMoved),
    mean_daily_forage_water = mean(herb$DailyForageWater),
    mean_daily_drinking_water = mean(herb$DailyWaterDrinking),
    mean_energy_balance = mean(herb$EnergyBalance),
    final_total_shoot_biomass_kg = as.numeric(final$total_shoot_biomass_kg),
    final_fine_fuel_proxy_kg = as.numeric(final$fine_fuel_proxy_kg),
    stringsAsFactors = FALSE
  )
}

build_ensemble_summary <- function(replicate_summary) {
  numeric_cols <- names(replicate_summary)[vapply(replicate_summary, is.numeric, logical(1L))]
  metric_cols <- setdiff(numeric_cols, c("seed_index", "seed_value"))

  rows <- lapply(metric_cols, function(metric) {
    vals <- as.numeric(replicate_summary[[metric]])
    data.frame(
      metric = metric,
      median = stats::median(vals),
      p05 = stats::quantile(vals, probs = 0.05, names = FALSE, type = 7),
      p95 = stats::quantile(vals, probs = 0.95, names = FALSE, type = 7),
      n = length(vals),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

run_single_ensemble_seed_v1 <- function(seed_index,
                                        seed_vec,
                                        validated_scenario,
                                        parent_slug,
                                        ensemble_label,
                                        base_dir,
                                        write_outputs) {
  seed_value <- as.integer(seed_vec[[seed_index]])
  replicate_slug <- file.path(parent_slug, ensemble_label, sprintf("seed_%03d", seed_value))

  replicate_scenario <- validated_scenario
  replicate_scenario$runtime$seed <- seed_value
  replicate_scenario$outputs$scenario_slug <- replicate_slug

  run_result <- run_scenario_v1(
    scenario = replicate_scenario,
    base_dir = base_dir,
    write_outputs = write_outputs
  )

  list(
    summary = summarise_run_result_for_ensemble(
      run_result = run_result,
      seed_value = seed_value,
      seed_index = seed_index
    ),
    manifest = data.frame(
      seed_index = as.integer(seed_index),
      seed_value = seed_value,
      replicate_slug = replicate_slug,
      run_id = as.character(run_result$run_id),
      stringsAsFactors = FALSE
    )
  )
}

#' Run a scenario as a deterministic multi-seed ensemble
#'
#' Executes repeated scenario runs across a supplied seed vector and writes
#' deterministic ensemble summaries.
#'
#' @param scenario Scenario object or scenario YAML path/slug.
#' @param seeds Integer vector of seeds.
#' @param base_dir Base artefact directory.
#' @param ensemble_label Label for ensemble output folder.
#' @param write_outputs Logical; when `FALSE`, summaries are returned in memory.
#' @param execution_mode Execution mode (`auto`, `serial`, or `multicore`).
#' @param workers Optional worker count override.
#' @param reserve_cores Number of CPU cores to keep free on the host.
#'
#' @return List with seed manifest, replicate summary, ensemble summary, and
#'   optional written file paths.
run_scenario_ensemble_v1 <- function(scenario,
                                     seeds = 1:10,
                                     base_dir = file.path("artefacts", "canonical_runs"),
                                     ensemble_label = "ensemble_v1",
                                     write_outputs = TRUE,
                                     execution_mode = c("auto", "serial", "multicore"),
                                     workers = NULL,
                                     reserve_cores = 1L) {
  validated <- if (is.character(scenario)) {
    compile_scenario_yaml(scenario)
  } else {
    validate_scenario_v1(scenario)
  }

  seed_vec <- normalise_ensemble_seeds(seeds)
  parent_slug <- validated$outputs$scenario_slug
  plan <- resolve_parallel_execution_plan_v1(
    execution_mode = execution_mode,
    workers = workers,
    n_tasks = length(seed_vec),
    reserve_cores = reserve_cores
  )

  run_results <- execute_indexed_jobs_v1(
    index = seq_along(seed_vec),
    job_fn = function(i) {
      run_single_ensemble_seed_v1(
        seed_index = i,
        seed_vec = seed_vec,
        validated_scenario = validated,
        parent_slug = parent_slug,
        ensemble_label = ensemble_label,
        base_dir = base_dir,
        write_outputs = write_outputs
      )
    },
    execution_plan = plan
  )

  run_rows <- lapply(run_results, `[[`, "summary")
  manifest_rows <- lapply(run_results, `[[`, "manifest")

  seed_manifest <- do.call(rbind, manifest_rows)
  replicate_summary <- do.call(rbind, run_rows)
  rownames(seed_manifest) <- NULL
  rownames(replicate_summary) <- NULL
  seed_manifest <- seed_manifest[order(seed_manifest$seed_index), , drop = FALSE]
  replicate_summary <- replicate_summary[order(replicate_summary$seed_index), , drop = FALSE]
  ensemble_summary <- build_ensemble_summary(replicate_summary)

  if (!isTRUE(write_outputs)) {
    return(list(
      execution_plan = plan,
      seed_manifest = seed_manifest,
      replicate_summary = replicate_summary,
      ensemble_summary = ensemble_summary
    ))
  }

  run_dir <- file.path(base_dir, parent_slug, ensemble_label)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  seed_manifest_path <- file.path(run_dir, "seed_manifest.csv")
  replicate_summary_path <- file.path(run_dir, "replicate_summary.csv")
  ensemble_summary_path <- file.path(run_dir, "ensemble_summary.csv")

  utils::write.csv(seed_manifest, seed_manifest_path, row.names = FALSE)
  utils::write.csv(replicate_summary, replicate_summary_path, row.names = FALSE)
  utils::write.csv(ensemble_summary, ensemble_summary_path, row.names = FALSE)

  manifest <- build_run_manifest(
    scenario_slug = file.path(parent_slug, ensemble_label),
    seed = as.integer(seed_vec[[1]]),
    scenario_parameters = list(
      parent_slug = parent_slug,
      ensemble_label = ensemble_label,
      seeds = seed_vec,
      execution_mode_requested = plan$execution_mode_requested,
      execution_mode_resolved = plan$execution_mode_resolved,
      workers_used = plan$workers_used
    ),
    output_files = c(
      seed_manifest = file.path(base_dir, parent_slug, ensemble_label, basename(seed_manifest_path)),
      replicate_summary = file.path(base_dir, parent_slug, ensemble_label, basename(replicate_summary_path)),
      ensemble_summary = file.path(base_dir, parent_slug, ensemble_label, basename(ensemble_summary_path))
    )
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    run_dir = run_dir,
    seed_manifest_path = seed_manifest_path,
    replicate_summary_path = replicate_summary_path,
    ensemble_summary_path = ensemble_summary_path,
    manifest_path = manifest_path,
    execution_plan = plan,
    seed_manifest = seed_manifest,
    replicate_summary = replicate_summary,
    ensemble_summary = ensemble_summary
  )
}
