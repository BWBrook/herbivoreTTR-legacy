# Optional TTR.PGM benchmark harness (overlap case).

ttr_pgm_package_name <- function() {
  paste0("TTR", ".PGM")
}

run_internal_ttr_overlap <- function(days = 14L,
                                     seed = 1L,
                                     veg_type = 0L,
                                     climate_mode = "flat") {
  with_optional_seed(seed, {
    plants <- init_plants(veg_types = veg_type)
    plants <- plants[1, , drop = FALSE]
    conditions <- init_conditions(mode = climate_mode)

    rows <- vector("list", as.integer(days))
    for (i in seq_len(as.integer(days))) {
      plants <- transport_resistance(plants, conditions, i)
      rows[[i]] <- data.frame(
        day = as.integer(i),
        ms = as.numeric(plants$ms),
        mr = as.numeric(plants$mr),
        cs = as.numeric(plants$cs),
        cr = as.numeric(plants$cr),
        ns = as.numeric(plants$ns),
        nr = as.numeric(plants$nr),
        stringsAsFactors = FALSE
      )
    }

    do.call(rbind, rows)
  })
}

run_ttr_pgm_overlap_adapter <- function(days = 14L,
                                        seed = 1L,
                                        climate_mode = "flat") {
  if (!requireNamespace(ttr_pgm_package_name(), quietly = TRUE)) {
    return(list(
      available = FALSE,
      reason = "Package TTR.PGM not installed.",
      trajectory = NULL
    ))
  }

  # Adapter remains deliberately conservative until stable overlap mappings are
  # validated against package API and parameter semantics.
  # The harness still records package presence and explicit non-run status.
  list(
    available = FALSE,
    reason = "TTR.PGM detected but overlap adapter is not yet API-mapped for this install.",
    trajectory = NULL
  )
}

run_ttr_pgm_overlap_benchmark <- function(days = 14L,
                                          seed = 1L,
                                          scenario_slug = "ttr_overlap_benchmark_v1",
                                          base_dir = file.path("artefacts", "canonical_runs")) {
  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  internal <- run_internal_ttr_overlap(days = days, seed = seed)
  adapter <- run_ttr_pgm_overlap_adapter(days = days, seed = seed)

  internal_path <- file.path(run_dir, "internal_ttr_trajectory.csv")
  utils::write.csv(internal, internal_path, row.names = FALSE)

  comparison <- data.frame(
    metric = c(
      "ttr_pgm_available",
      "ttr_pgm_adapter_ran",
      "internal_ms_final",
      "internal_mr_final"
    ),
    value = c(
      as.numeric(requireNamespace(ttr_pgm_package_name(), quietly = TRUE)),
      as.numeric(adapter$available),
      internal$ms[nrow(internal)],
      internal$mr[nrow(internal)]
    ),
    stringsAsFactors = FALSE
  )

  if (isTRUE(adapter$available) && !is.null(adapter$trajectory)) {
    pgm_path <- file.path(run_dir, "ttr_pgm_trajectory.csv")
    utils::write.csv(adapter$trajectory, pgm_path, row.names = FALSE)

    merged <- merge(internal, adapter$trajectory, by = "day", suffixes = c("_internal", "_ttrpgm"))
    if (nrow(merged) > 0L) {
      comparison <- rbind(
        comparison,
        data.frame(
          metric = c("ms_rmse", "mr_rmse", "cs_rmse", "cr_rmse", "ns_rmse", "nr_rmse"),
          value = c(
            sqrt(mean((merged$ms_internal - merged$ms_ttrpgm)^2)),
            sqrt(mean((merged$mr_internal - merged$mr_ttrpgm)^2)),
            sqrt(mean((merged$cs_internal - merged$cs_ttrpgm)^2)),
            sqrt(mean((merged$cr_internal - merged$cr_ttrpgm)^2)),
            sqrt(mean((merged$ns_internal - merged$ns_ttrpgm)^2)),
            sqrt(mean((merged$nr_internal - merged$nr_ttrpgm)^2))
          ),
          stringsAsFactors = FALSE
        )
      )
    }
  }

  comparison_path <- file.path(run_dir, "benchmark_summary.csv")
  utils::write.csv(comparison, comparison_path, row.names = FALSE)

  report_path <- file.path(run_dir, "benchmark_report.md")
  report <- c(
    "# Internal TTR vs TTR.PGM Overlap Benchmark",
    "",
    "## Scope",
    "- Single-species overlap case (benchmark-only; not default backend).",
    sprintf("- Days simulated: `%d`.", as.integer(days)),
    sprintf("- TTR.PGM installed: `%s`.", ifelse(requireNamespace(ttr_pgm_package_name(), quietly = TRUE), "yes", "no")),
    sprintf("- Adapter run status: `%s`.", ifelse(adapter$available, "ran", "not-run")),
    sprintf("- Adapter note: `%s`", adapter$reason),
    "",
    "## Outputs",
    sprintf("- Internal trajectory: `%s`", internal_path),
    sprintf("- Benchmark summary: `%s`", comparison_path),
    "",
    "## Interpretation",
    "- This harness is conditional by design and does not block default package usage.",
    "- Where TTR.PGM overlap execution is unavailable, benchmark artefacts still capture internal baseline trajectories with explicit non-run rationale."
  )
  writeLines(report, report_path)

  output_files <- c(
    internal_trajectory = file.path(base_dir, scenario_slug, basename(internal_path)),
    benchmark_summary = file.path(base_dir, scenario_slug, basename(comparison_path)),
    benchmark_report = file.path(base_dir, scenario_slug, basename(report_path))
  )

  manifest <- build_run_manifest(
    scenario_slug = scenario_slug,
    seed = as.integer(seed),
    scenario_parameters = list(days = as.integer(days), climate_mode = "flat"),
    output_files = output_files
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    run_dir = run_dir,
    internal_path = internal_path,
    comparison_path = comparison_path,
    report_path = report_path,
    manifest_path = manifest_path,
    comparison = comparison
  )
}
