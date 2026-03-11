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

build_parallel_benchmark_design_v1 <- function(seed_sizes,
                                               worker_grid) {
  seeds <- sort(unique(as.integer(seed_sizes)))
  workers <- sort(unique(as.integer(worker_grid)))

  if (length(seeds) < 1L || any(!is.finite(seeds)) || any(seeds < 1L)) {
    rlang::abort(
      "Argument `seed_sizes` must contain positive integers.",
      class = "herbivoreTTR_parallel_seed_sizes_invalid",
      seed_sizes = seed_sizes
    )
  }

  if (length(workers) < 1L || any(!is.finite(workers)) || any(workers < 1L)) {
    rlang::abort(
      "Argument `worker_grid` must contain positive integers.",
      class = "herbivoreTTR_parallel_worker_grid_invalid",
      worker_grid = worker_grid
    )
  }

  grid <- expand.grid(
    seed_count = seeds,
    workers_requested = workers,
    stringsAsFactors = FALSE
  )
  grid <- grid[grid$workers_requested <= grid$seed_count, , drop = FALSE]
  if (!any(grid$workers_requested == 1L)) {
    serial_rows <- data.frame(
      seed_count = seeds,
      workers_requested = rep(1L, length(seeds)),
      stringsAsFactors = FALSE
    )
    grid <- unique(rbind(grid, serial_rows))
  }
  grid <- grid[order(grid$seed_count, grid$workers_requested), , drop = FALSE]
  rownames(grid) <- NULL
  grid
}

summarise_parallel_break_even_v1 <- function(benchmark_df,
                                             min_speedup = 1.05) {
  if (nrow(benchmark_df) < 1L) {
    return(data.frame())
  }

  worker_levels <- sort(unique(benchmark_df$workers_used[benchmark_df$workers_used > 1L]))
  if (length(worker_levels) < 1L) {
    return(data.frame())
  }

  rows <- lapply(worker_levels, function(worker_count) {
    df <- benchmark_df[benchmark_df$workers_used == worker_count, , drop = FALSE]
    df <- df[order(df$seed_count), , drop = FALSE]
    qualifying <- df[df$speedup_vs_serial >= min_speedup, , drop = FALSE]
    break_even <- if (nrow(qualifying) < 1L) NA_integer_ else as.integer(qualifying$seed_count[[1]])
    max_idx <- which.max(df$speedup_vs_serial)

    data.frame(
      workers_used = as.integer(worker_count),
      break_even_seed_count = break_even,
      min_speedup_target = as.numeric(min_speedup),
      max_speedup = as.numeric(df$speedup_vs_serial[[max_idx]]),
      seed_count_at_max_speedup = as.integer(df$seed_count[[max_idx]]),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL

  if (nrow(out) > 0L) {
    ordered <- out[order(is.na(out$break_even_seed_count), out$break_even_seed_count, -out$max_speedup), , drop = FALSE]
    best_workers <- ordered$workers_used[[1]]
    out$recommended_workers <- as.integer(out$workers_used == best_workers)
  } else {
    out$recommended_workers <- integer(0)
  }

  out
}

check_parallel_break_even_gate_v1 <- function(break_even_summary,
                                              max_break_even_seed_count = 16L) {
  if (nrow(break_even_summary) < 1L) {
    return(data.frame(
      check = "parallel_break_even_available",
      pass = FALSE,
      detail = "No parallel worker rows available in break-even summary.",
      stringsAsFactors = FALSE
    ))
  }

  max_seed <- as.integer(max_break_even_seed_count[[1]])
  if (!is.finite(max_seed) || max_seed < 1L) {
    max_seed <- 16L
  }

  pass <- any(!is.na(break_even_summary$break_even_seed_count) &
    break_even_summary$break_even_seed_count <= max_seed)

  data.frame(
    check = "parallel_break_even_within_budget",
    pass = as.logical(pass),
    detail = if (isTRUE(pass)) {
      sprintf("At least one worker tier breaks even at <= %d replicates.", max_seed)
    } else {
      sprintf("No worker tier breaks even at <= %d replicates.", max_seed)
    },
    stringsAsFactors = FALSE
  )
}

profile_simulation_kernel_v1 <- function(scenario,
                                         run_dir,
                                         profile_slug = "kernel_profile_v1",
                                         interval = 0.002) {
  scenario_profile <- validate_scenario_v2(scenario)
  scenario_profile$scenario_id <- paste0(scenario_profile$scenario_id, "_kernel_profile")
  scenario_profile$outputs$scenario_slug <- paste0(profile_slug, "_run")
  scenario_profile$runtime$days <- max(7L, as.integer(scenario_profile$runtime$days))
  scenario_profile$runtime$minute_limit <- max(60L, as.integer(scenario_profile$runtime$minute_limit))

  raw_path <- file.path(run_dir, paste0(profile_slug, ".out"))
  self_path <- file.path(run_dir, paste0(profile_slug, "_by_self.csv"))
  total_path <- file.path(run_dir, paste0(profile_slug, "_by_total.csv"))

  chosen_interval <- max(0.01, as.numeric(interval))
  utils::Rprof(raw_path, interval = chosen_interval)
  on.exit(utils::Rprof(NULL), add = TRUE)
  run_scenario_v2(
    scenario = scenario_profile,
    base_dir = file.path(run_dir, "kernel_profile_runs"),
    write_outputs = FALSE
  )
  utils::Rprof(NULL)

  profile <- utils::summaryRprof(raw_path)
  by_self <- as.data.frame(profile$by.self, stringsAsFactors = FALSE)
  by_total <- as.data.frame(profile$by.total, stringsAsFactors = FALSE)

  by_self$call <- rownames(by_self)
  by_total$call <- rownames(by_total)
  rownames(by_self) <- NULL
  rownames(by_total) <- NULL

  by_self <- by_self[, c("call", setdiff(names(by_self), "call")), drop = FALSE]
  by_total <- by_total[, c("call", setdiff(names(by_total), "call")), drop = FALSE]

  utils::write.csv(by_self, self_path, row.names = FALSE)
  utils::write.csv(by_total, total_path, row.names = FALSE)

  list(
    raw_path = raw_path,
    self_path = self_path,
    total_path = total_path,
    by_self = by_self,
    by_total = by_total
  )
}

run_parallel_overhead_benchmark_v1 <- function(canonical_scenario,
                                               run_dir,
                                               seed_sizes,
                                               worker_grid,
                                               reserve_cores = 1L,
                                               min_speedup = 1.05) {
  benchmark_slug <- "parallel_benchmark_workloads_v1"
  design <- build_parallel_benchmark_design_v1(
    seed_sizes = seed_sizes,
    worker_grid = worker_grid
  )

  rows <- vector("list", nrow(design))
  base_seed <- as.integer(canonical_scenario$runtime$seed) + 1000L

  for (i in seq_len(nrow(design))) {
    seed_count <- as.integer(design$seed_count[[i]])
    workers_requested <- as.integer(design$workers_requested[[i]])
    seeds <- base_seed + seq_len(seed_count) - 1L

    benchmark <- measure_workload_v1(
      run_scenario_ensemble_v1(
        scenario = canonical_scenario,
        seeds = seeds,
        base_dir = file.path(run_dir, benchmark_slug),
        ensemble_label = sprintf("parallel_s%03d_w%02d", seed_count, workers_requested),
        write_outputs = FALSE,
        execution_mode = if (workers_requested > 1L) "multicore" else "serial",
        workers = workers_requested,
        reserve_cores = reserve_cores
      )
    )

    plan <- benchmark$result$execution_plan
    herbivore_days <- as.numeric(canonical_scenario$runtime$days) * seed_count
    rows[[i]] <- data.frame(
      seed_count = seed_count,
      workers_requested = workers_requested,
      workers_used = as.integer(plan$workers_used),
      execution_mode_resolved = as.character(plan$execution_mode_resolved),
      elapsed_seconds = as.numeric(benchmark$elapsed_seconds),
      cpu_seconds = as.numeric(benchmark$cpu_seconds),
      memory_delta_mb = as.numeric(benchmark$memory_delta_mb),
      herbivore_days = herbivore_days,
      throughput_herbivore_days_per_sec = herbivore_days / pmax(benchmark$elapsed_seconds, 1e-8),
      stringsAsFactors = FALSE
    )
  }

  benchmark_df <- do.call(rbind, rows)
  rownames(benchmark_df) <- NULL
  benchmark_df <- benchmark_df[order(benchmark_df$seed_count, benchmark_df$workers_requested), , drop = FALSE]

  serial_rows <- benchmark_df[benchmark_df$workers_used == 1L, c("seed_count", "elapsed_seconds"), drop = FALSE]
  serial_lookup <- tapply(serial_rows$elapsed_seconds, serial_rows$seed_count, min)
  benchmark_df$serial_elapsed_seconds <- as.numeric(serial_lookup[as.character(benchmark_df$seed_count)])
  benchmark_df$speedup_vs_serial <- benchmark_df$serial_elapsed_seconds / pmax(benchmark_df$elapsed_seconds, 1e-8)
  benchmark_df$efficiency_vs_serial <- benchmark_df$speedup_vs_serial / pmax(benchmark_df$workers_used, 1L)

  break_even_df <- summarise_parallel_break_even_v1(
    benchmark_df = benchmark_df,
    min_speedup = min_speedup
  )

  list(
    design = design,
    benchmark = benchmark_df,
    break_even = break_even_df
  )
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
#' @param execution_mode Execution mode (`auto`, `serial`, or `multicore`).
#' @param workers Optional worker count override for primary workloads.
#' @param reserve_cores Number of CPU cores to keep free on host.
#' @param parallel_benchmark_seed_sizes Replicate counts for break-even benchmark.
#' @param parallel_benchmark_workers Worker counts to benchmark.
#' @param parallel_min_speedup Speedup threshold used to define break-even.
#' @param enforce_break_even_gate Logical; if `TRUE`, fail if break-even target is missed.
#' @param break_even_max_seed_count Maximum acceptable break-even replicate count.
#'
#' @return List with benchmark artefact paths and summary data.
run_post_v1_scaling_profile <- function(base_dir = file.path("artefacts", "benchmarks"),
                                        scenario_slug = "post_v1_scaling_v1",
                                        ensemble_seeds = 1:30,
                                        stability_days = 120L,
                                        stability_seeds = 1:3,
                                        baseline_path = NULL,
                                        regression_threshold = 0.2,
                                        enforce_regression_gate = TRUE,
                                        execution_mode = c("auto", "serial", "multicore"),
                                        workers = NULL,
                                        reserve_cores = 1L,
                                        parallel_benchmark_seed_sizes = NULL,
                                        parallel_benchmark_workers = c(1L, 2L, 4L, 8L),
                                        parallel_min_speedup = 1.05,
                                        enforce_break_even_gate = FALSE,
                                        break_even_max_seed_count = 16L) {
  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  canonical_path <- scenario_contract_reference_path("canonical_smoke_v1")
  canonical <- compile_scenario_yaml_v2(canonical_path)

  single <- measure_workload_v1(
    run_scenario_v2(
      scenario = canonical,
      base_dir = file.path(run_dir, "workloads")
    )
  )

  ensemble <- measure_workload_v1(
    run_scenario_ensemble_v1(
      scenario = canonical,
      seeds = ensemble_seeds,
      base_dir = file.path(run_dir, "workloads"),
      ensemble_label = "ensemble_scaling_v1",
      execution_mode = execution_mode,
      workers = workers,
      reserve_cores = reserve_cores
    )
  )

  stability <- measure_workload_v1(
    run_long_horizon_stability_suite_v1(
      base_dir = file.path(run_dir, "workloads"),
      seeds = stability_seeds,
      days = stability_days,
      minute_limit = canonical$runtime$minute_limit,
      execution_mode = execution_mode,
      workers = workers,
      reserve_cores = reserve_cores
    )
  )

  if (is.null(parallel_benchmark_seed_sizes)) {
    ensemble_count <- length(normalise_ensemble_seeds(ensemble_seeds))
    default_sizes <- c(2L, 4L, 8L, as.integer(ensemble_count))
    parallel_benchmark_seed_sizes <- sort(unique(default_sizes[default_sizes >= 1L]))
  }

  max_workers_host <- max(1L, detect_available_cores_v1() - as.integer(reserve_cores))
  parallel_benchmark_workers <- sort(unique(as.integer(parallel_benchmark_workers)))
  parallel_benchmark_workers <- parallel_benchmark_workers[is.finite(parallel_benchmark_workers) & parallel_benchmark_workers >= 1L]
  parallel_benchmark_workers <- parallel_benchmark_workers[parallel_benchmark_workers <= max_workers_host]
  if (!any(parallel_benchmark_workers == 1L)) {
    parallel_benchmark_workers <- sort(unique(c(1L, parallel_benchmark_workers)))
  }

  parallel_benchmark <- run_parallel_overhead_benchmark_v1(
    canonical_scenario = canonical,
    run_dir = run_dir,
    seed_sizes = parallel_benchmark_seed_sizes,
    worker_grid = parallel_benchmark_workers,
    reserve_cores = reserve_cores,
    min_speedup = parallel_min_speedup
  )

  kernel_profile <- profile_simulation_kernel_v1(
    scenario = canonical,
    run_dir = run_dir,
    profile_slug = "kernel_profile_v1"
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

  parallel_benchmark_path <- file.path(run_dir, "parallel_overhead_benchmark_v1.csv")
  break_even_path <- file.path(run_dir, "parallel_break_even_summary_v1.csv")
  break_even_gate_path <- file.path(run_dir, "parallel_break_even_gate_v1.csv")
  utils::write.csv(parallel_benchmark$benchmark, parallel_benchmark_path, row.names = FALSE)
  utils::write.csv(parallel_benchmark$break_even, break_even_path, row.names = FALSE)

  break_even_gate <- check_parallel_break_even_gate_v1(
    break_even_summary = parallel_benchmark$break_even,
    max_break_even_seed_count = break_even_max_seed_count
  )
  utils::write.csv(break_even_gate, break_even_gate_path, row.names = FALSE)

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

  if (isTRUE(enforce_break_even_gate) && any(!break_even_gate$pass)) {
    rlang::abort(
      paste0("Parallel break-even gate failed: ", break_even_gate$detail[[1]]),
      class = "herbivoreTTR_parallel_break_even_gate_failed",
      gate = break_even_gate
    )
  }

  report_path <- file.path(run_dir, "scaling_report_v1.md")
  hotspot_calls <- if (nrow(kernel_profile$by_self) > 0L) {
    top <- utils::head(kernel_profile$by_self, 5L)
    paste0("- `", top$call, "` self.time=", format(round(top$self.time, 3), trim = TRUE))
  } else {
    "- No kernel profile samples recorded."
  }

  break_even_lines <- if (nrow(parallel_benchmark$break_even) < 1L) {
    "- No parallel worker tiers were available for break-even estimation."
  } else {
    paste0(
      "- workers=", parallel_benchmark$break_even$workers_used,
      ", break_even_seed_count=", ifelse(is.na(parallel_benchmark$break_even$break_even_seed_count), "NA", parallel_benchmark$break_even$break_even_seed_count),
      ", max_speedup=", format(round(parallel_benchmark$break_even$max_speedup, 3), trim = TRUE),
      ", recommended=", as.logical(parallel_benchmark$break_even$recommended_workers)
    )
  }

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
    },
    "",
    "## Parallel break-even benchmark",
    break_even_lines,
    paste0(
      "- Gate status: ",
      ifelse(all(break_even_gate$pass), "pass", "fail"),
      " (", break_even_gate$detail[[1]], ")"
    ),
    "",
    "## Kernel hotspot profile (top self-time calls)",
    hotspot_calls
  )
  writeLines(report_lines, report_path)

  manifest <- build_run_manifest(
    scenario_slug = file.path("benchmarks", scenario_slug),
    seed = canonical$runtime$seed,
    scenario_parameters = list(
      ensemble_seeds = normalise_ensemble_seeds(ensemble_seeds),
      stability_days = as.integer(stability_days),
      stability_seeds = normalise_ensemble_seeds(stability_seeds),
      execution_mode = match.arg(execution_mode),
      workers = workers,
      reserve_cores = as.integer(reserve_cores)
    ),
    output_files = c(
      summary = file.path(base_dir, scenario_slug, basename(summary_path)),
      regression = file.path(base_dir, scenario_slug, basename(regression_path)),
      report = file.path(base_dir, scenario_slug, basename(report_path)),
      kernel_profile_raw = file.path(base_dir, scenario_slug, basename(kernel_profile$raw_path)),
      kernel_profile_self = file.path(base_dir, scenario_slug, basename(kernel_profile$self_path)),
      kernel_profile_total = file.path(base_dir, scenario_slug, basename(kernel_profile$total_path)),
      parallel_benchmark = file.path(base_dir, scenario_slug, basename(parallel_benchmark_path)),
      parallel_break_even = file.path(base_dir, scenario_slug, basename(break_even_path)),
      parallel_break_even_gate = file.path(base_dir, scenario_slug, basename(break_even_gate_path))
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
    kernel_profile_raw_path = kernel_profile$raw_path,
    kernel_profile_self_path = kernel_profile$self_path,
    kernel_profile_total_path = kernel_profile$total_path,
    parallel_benchmark_path = parallel_benchmark_path,
    break_even_path = break_even_path,
    break_even_gate_path = break_even_gate_path,
    summary = summary_df,
    regression = regression_df,
    parallel_benchmark = parallel_benchmark$benchmark,
    break_even = parallel_benchmark$break_even,
    break_even_gate = break_even_gate
  )
}
