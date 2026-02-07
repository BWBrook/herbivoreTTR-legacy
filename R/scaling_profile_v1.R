# Throughput and scaling profile helpers for post-1.0 workloads.

measure_workload_v1 <- function(expr) {
  gc(verbose = FALSE, reset = TRUE)
  gc_before <- gc(verbose = FALSE)[, 2]
  timing <- system.time(result <- force(expr))
  gc_after <- gc(verbose = FALSE)[, 2]

  list(
    result = result,
    elapsed_seconds = as.numeric(timing[["elapsed"]]),
    cpu_seconds = as.numeric(timing[["user.self"]] + timing[["sys.self"]]),
    memory_delta_mb = max(sum(gc_after - gc_before), 0)
  )
}

check_scaling_regression_v1 <- function(current_summary,
                                        baseline_summary,
                                        threshold = 0.2) {
  merged <- merge(
    current_summary[, c("workload", "elapsed_seconds")],
    baseline_summary[, c("workload", "elapsed_seconds")],
    by = "workload",
    suffixes = c("_current", "_baseline")
  )
  if (nrow(merged) < 1L) {
    return(data.frame())
  }

  merged$degradation_fraction <- (merged$elapsed_seconds_current - merged$elapsed_seconds_baseline) /
    pmax(merged$elapsed_seconds_baseline, 1e-8)
  merged$passes <- merged$degradation_fraction <= threshold
  merged
}

#' Run post-v1 scaling profile benchmark
#'
#' @param base_dir Base directory for benchmark artefacts.
#' @param scenario_slug Benchmark output slug.
#' @param ensemble_seeds Seeds for ensemble workload.
#' @param stability_days Days for stability workload subset.
#' @param stability_seeds Seeds for stability workload subset.
#' @param baseline_path Optional prior summary CSV for regression checks.
#' @param regression_threshold Allowed elapsed-time degradation fraction.
#' @param enforce_regression_gate Logical; if `TRUE`, fail on regression.
#'
#' @return List with benchmark artefact paths and summary data.
run_post_v1_scaling_profile <- function(base_dir = file.path("artefacts", "benchmarks"),
                                        scenario_slug = "post_v1_scaling_v1",
                                        ensemble_seeds = 1:30,
                                        stability_days = 120L,
                                        stability_seeds = 1:3,
                                        baseline_path = NULL,
                                        regression_threshold = 0.2,
                                        enforce_regression_gate = TRUE) {
  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  canonical_path <- scenario_contract_reference_path("canonical_smoke_v1")
  canonical <- compile_scenario_yaml(canonical_path)

  single <- measure_workload_v1(
    run_scenario_v1(
      scenario = canonical,
      base_dir = file.path(run_dir, "workloads")
    )
  )

  ensemble <- measure_workload_v1(
    run_scenario_ensemble_v1(
      scenario = canonical,
      seeds = ensemble_seeds,
      base_dir = file.path(run_dir, "workloads"),
      ensemble_label = "ensemble_scaling_v1"
    )
  )

  stability <- measure_workload_v1(
    run_long_horizon_stability_suite_v1(
      base_dir = file.path(run_dir, "workloads"),
      seeds = stability_seeds,
      days = stability_days,
      minute_limit = canonical$runtime$minute_limit
    )
  )

  single_days <- canonical$runtime$days
  ensemble_days <- canonical$runtime$days * length(normalise_ensemble_seeds(ensemble_seeds))
  stability_days_total <- as.integer(stability_days) * length(normalise_ensemble_seeds(stability_seeds)) * 4L

  summary_df <- data.frame(
    workload = c("single_seed_smoke", "ensemble_multi_seed", "stability_subset"),
    elapsed_seconds = c(single$elapsed_seconds, ensemble$elapsed_seconds, stability$elapsed_seconds),
    cpu_seconds = c(single$cpu_seconds, ensemble$cpu_seconds, stability$cpu_seconds),
    memory_delta_mb = c(single$memory_delta_mb, ensemble$memory_delta_mb, stability$memory_delta_mb),
    herbivore_days = c(single_days, ensemble_days, stability_days_total),
    stringsAsFactors = FALSE
  )
  summary_df$throughput_herbivore_days_per_sec <- summary_df$herbivore_days / pmax(summary_df$elapsed_seconds, 1e-8)

  summary_path <- file.path(run_dir, "scaling_summary_v1.csv")
  utils::write.csv(summary_df, summary_path, row.names = FALSE)

  regression_df <- data.frame()
  regression_path <- file.path(run_dir, "scaling_regression_check_v1.csv")
  if (!is.null(baseline_path) && file.exists(baseline_path)) {
    baseline <- utils::read.csv(baseline_path, stringsAsFactors = FALSE)
    regression_df <- check_scaling_regression_v1(
      current_summary = summary_df,
      baseline_summary = baseline,
      threshold = regression_threshold
    )
    utils::write.csv(regression_df, regression_path, row.names = FALSE)

    if (isTRUE(enforce_regression_gate) && nrow(regression_df) > 0L && any(!regression_df$passes)) {
      failing <- regression_df$workload[!regression_df$passes]
      rlang::abort(
        sprintf("Scaling regression threshold exceeded for workloads: %s", paste(failing, collapse = ", ")),
        class = "herbivoreTTR_scaling_regression_failed",
        failing_workloads = failing
      )
    }
  }

  report_path <- file.path(run_dir, "scaling_report_v1.md")
  report_lines <- c(
    "# Post-v1 Scaling Profile",
    "",
    "## Workloads",
    paste0(
      "- `", summary_df$workload, "`: elapsed=", format(round(summary_df$elapsed_seconds, 3), trim = TRUE),
      "s, throughput=", format(round(summary_df$throughput_herbivore_days_per_sec, 3), trim = TRUE), " herbivore-days/s."
    ),
    "",
    "## Regression gate",
    if (nrow(regression_df) == 0L) {
      "- No baseline provided; regression gate not evaluated."
    } else {
      paste0(
        "- `", regression_df$workload, "`: degradation=",
        format(round(regression_df$degradation_fraction, 4), trim = TRUE),
        ", pass=", regression_df$passes
      )
    }
  )
  writeLines(report_lines, report_path)

  manifest <- build_run_manifest(
    scenario_slug = file.path("benchmarks", scenario_slug),
    seed = canonical$runtime$seed,
    scenario_parameters = list(
      ensemble_seeds = normalise_ensemble_seeds(ensemble_seeds),
      stability_days = as.integer(stability_days),
      stability_seeds = normalise_ensemble_seeds(stability_seeds)
    ),
    output_files = c(
      summary = file.path(base_dir, scenario_slug, basename(summary_path)),
      regression = file.path(base_dir, scenario_slug, basename(regression_path)),
      report = file.path(base_dir, scenario_slug, basename(report_path))
    )
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    run_dir = run_dir,
    summary_path = summary_path,
    regression_path = regression_path,
    report_path = report_path,
    manifest_path = manifest_path,
    summary = summary_df,
    regression = regression_df
  )
}
