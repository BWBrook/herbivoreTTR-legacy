test_that("stability scenario builder defines expected variants", {
  scenarios <- build_stability_scenarios_v1(days = 20L, minute_limit = 60L)
  expect_equal(length(scenarios), 4L)
  expect_true(all(c("baseline", "high_aridity", "high_pressure", "low_access") %in% names(scenarios)))
})

test_that("long-horizon stability suite writes summary artefacts", {
  skip_on_cran()

  out <- run_long_horizon_stability_suite_v1(
    base_dir = tempdir(),
    seeds = 801:802,
    days = 10L,
    minute_limit = 60L
  )

  expect_true(file.exists(out$replicate_path))
  expect_true(file.exists(out$summary_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))
  expect_true(all(out$replicates$nan_inf_count >= 0))
})

test_that("scaling profile benchmark writes throughput artefacts", {
  skip_on_cran()

  out <- run_post_v1_scaling_profile(
    base_dir = tempdir(),
    scenario_slug = "scaling_test_v1",
    ensemble_seeds = 1:3,
    stability_days = 8L,
    stability_seeds = 1:2,
    enforce_regression_gate = FALSE,
    parallel_benchmark_seed_sizes = c(1L, 2L, 3L),
    parallel_benchmark_workers = c(1L, 2L)
  )

  expect_true(file.exists(out$summary_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))
  expect_true(file.exists(out$kernel_profile_raw_path))
  expect_true(file.exists(out$kernel_profile_self_path))
  expect_true(file.exists(out$kernel_profile_total_path))
  expect_true(file.exists(out$parallel_benchmark_path))
  expect_true(file.exists(out$break_even_path))
  expect_true(file.exists(out$break_even_gate_path))
  expect_true(all(out$summary$elapsed_seconds > 0))
  expect_true(all(out$summary$throughput_herbivore_days_per_sec > 0))
  expect_true(all(out$parallel_benchmark$elapsed_seconds > 0))
})

test_that("scaling regression checker flags degraded workloads", {
  current <- data.frame(
    workload = c("a", "b"),
    elapsed_seconds = c(12, 10),
    stringsAsFactors = FALSE
  )
  baseline <- data.frame(
    workload = c("a", "b"),
    elapsed_seconds = c(10, 10),
    stringsAsFactors = FALSE
  )

  check <- check_scaling_regression_v1(current, baseline, threshold = 0.1)
  expect_equal(nrow(check), 2L)
  expect_false(all(check$passes))
})

test_that("parallel benchmark helpers compute break-even and gate", {
  design <- build_parallel_benchmark_design_v1(
    seed_sizes = c(2L, 4L, 8L),
    worker_grid = c(1L, 2L, 4L)
  )
  expect_true(all(c("seed_count", "workers_requested") %in% names(design)))
  expect_true(any(design$workers_requested == 1L))

  bench <- data.frame(
    seed_count = c(2L, 4L, 8L, 2L, 4L, 8L),
    workers_used = c(1L, 1L, 1L, 2L, 2L, 2L),
    speedup_vs_serial = c(1.0, 1.0, 1.0, 0.8, 1.01, 1.2),
    stringsAsFactors = FALSE
  )
  break_even <- summarise_parallel_break_even_v1(bench, min_speedup = 1.05)
  expect_equal(break_even$break_even_seed_count[break_even$workers_used == 2L], 8L)

  gate_pass <- check_parallel_break_even_gate_v1(
    break_even_summary = break_even,
    max_break_even_seed_count = 8L
  )
  gate_fail <- check_parallel_break_even_gate_v1(
    break_even_summary = break_even,
    max_break_even_seed_count = 4L
  )
  expect_true(all(gate_pass$pass))
  expect_false(all(gate_fail$pass))
})

test_that("compiled throughput appendix writes matrix and break-even artefacts", {
  skip_on_cran()

  profiles <- data.frame(
    profile_id = c("tiny", "small"),
    days = c(2L, 3L),
    minute_limit = c(30L, 40L),
    stringsAsFactors = FALSE
  )
  out <- run_compiled_throughput_appendix_v1(
    base_dir = tempdir(),
    scenario_slug = "compiled_throughput_test_v1",
    size_profiles = profiles,
    replicate_grid = c(1L, 2L),
    modes = c("pure_r", "compiled_resistance"),
    execution_mode = "serial",
    reserve_cores = 0L,
    min_speedup = 1.0,
    seed_base = 9100L
  )

  expect_true(file.exists(out$matrix_path))
  expect_true(file.exists(out$break_even_path))
  expect_true(file.exists(out$speedup_plot_path))
  expect_true(file.exists(out$report_path))
  expect_true(file.exists(out$manifest_path))
  expect_true(all(c("profile_id", "compiled_mode", "speedup_vs_pure") %in% names(out$throughput)))
  expect_true(all(out$throughput$elapsed_seconds > 0))
})
