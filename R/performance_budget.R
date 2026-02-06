# Performance budget profiling helpers.

run_performance_budget_profile <- function(base_dir = file.path("artefacts", "canonical_runs"),
                                           scenario_slug = "performance_budget_v1") {
  scenario <- compile_scenario_yaml(scenario_contract_reference_path("canonical_smoke_v1"))
  scenario$runtime$days <- 2L
  scenario$runtime$minute_limit <- 30L
  scenario$outputs$scenario_slug <- "performance_budget_smoke_v1"

  gc_before <- gc(reset = TRUE)
  elapsed <- as.numeric(system.time({
    run <- run_scenario_v1(scenario = scenario, base_dir = base_dir)
  })[["elapsed"]])
  gc_after <- gc()

  mem_mb <- max(gc_after[, 2] - gc_before[, 2])

  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  summary <- data.frame(
    metric = c("elapsed_seconds", "memory_cells_delta_mb", "runtime_budget_seconds", "budget_pass"),
    value = c(elapsed, mem_mb, 30, as.numeric(elapsed < 30)),
    stringsAsFactors = FALSE
  )

  summary_path <- file.path(run_dir, "performance_summary.csv")
  report_path <- file.path(run_dir, "performance_report.md")
  utils::write.csv(summary, summary_path, row.names = FALSE)

  writeLines(
    c(
      "# Performance Budget Profile",
      "",
      sprintf("- Elapsed seconds: `%.3f`", elapsed),
      sprintf("- Approx memory delta (MB): `%.3f`", mem_mb),
      "- Runtime budget: `< 30 s` for small CI-profile scenario.",
      sprintf("- Budget pass: `%s`", ifelse(elapsed < 30, "yes", "no")),
      "",
      "Hotspot note:",
      "- Most runtime cost is minute-level herbivore stepping and repeated plant-state updates."
    ),
    report_path
  )

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = scenario$runtime$seed,
    scenario_parameters = list(days = 2L, minute_limit = 30L, base_scenario = "canonical_smoke_v1"),
    output_files = c(
      performance_summary = file.path(base_dir, scenario_slug, basename(summary_path)),
      performance_report = file.path(base_dir, scenario_slug, basename(report_path))
    )
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    summary_path = summary_path,
    report_path = report_path,
    manifest_path = manifest_path,
    summary = summary
  )
}
