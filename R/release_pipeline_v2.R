# Release-candidate helpers for post-1.0 hardening cycle (v1.1 track).

release_candidate_label_v2 <- function(version = resolve_package_version()) {
  if (grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", version)) {
    return(sprintf("v%s-rc1", version))
  }
  sprintf("v%s", version)
}

release_expected_outputs_v2 <- function() {
  c(
    file.path("artefacts", "canonical_runs", "experiment_a_presence_removal_v2", "experiment_a_summary_v2.csv"),
    file.path("artefacts", "canonical_runs", "experiment_c_aridity_gradient_v2", "experiment_c_summary_v2.csv"),
    file.path("artefacts", "validation", "pilot_benchmark_v1", "pilot_metrics_summary_v1.csv"),
    file.path("artefacts", "stability", "long_horizon_v1", "stability_summary_v1.csv"),
    file.path("artefacts", "benchmarks", "post_v1_scaling_v1", "scaling_summary_v1.csv"),
    file.path("artefacts", "reports_v2", "paper_pipeline_v2.html"),
    file.path("artefacts", "reports_v2", "figure_table_manifest_v2.csv")
  )
}

run_release_reference_suite_v2 <- function() {
  run_experiment_a_presence_removal_v2()
  run_experiment_c_aridity_gradient_v2()
  run_pilot_validation_benchmark_v1()
  run_long_horizon_stability_suite_v1(days = 120L, seeds = 801:804)
  run_post_v1_scaling_profile(
    ensemble_seeds = 1:12,
    stability_days = 40L,
    stability_seeds = 1:3,
    enforce_regression_gate = FALSE
  )
  render_paper_pipeline_report_v2()
}

run_release_checklist_v2 <- function(package_tarball, checklist_csv = NULL) {
  version <- resolve_package_version()
  semver_ok <- grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", version)
  tarball_ok <- file.exists(package_tarball)
  renv_sync <- isTRUE(renv::status()$synchronized)
  expected <- release_expected_outputs_v2()
  outputs_ok <- all(file.exists(expected))
  changelog_ok <- check_changelog_for_version_v1(version = version)

  checks <- data.frame(
    item = c(
      "description_version_semver",
      "source_tarball_present",
      "renv_status_synchronized",
      "changelog_has_current_version_header",
      "expected_v2_outputs_present"
    ),
    status = c(
      semver_ok,
      tarball_ok,
      renv_sync,
      changelog_ok,
      outputs_ok
    ),
    evidence = c(
      version,
      package_tarball,
      if (renv_sync) "renv synchronized" else "renv out of sync",
      if (changelog_ok) "header found" else "missing header",
      sprintf("%d/%d present", sum(file.exists(expected)), length(expected))
    ),
    stringsAsFactors = FALSE
  )
  checks$pass <- checks$status

  if (!is.null(checklist_csv)) {
    dir.create(dirname(checklist_csv), recursive = TRUE, showWarnings = FALSE)
    utils::write.csv(checks, checklist_csv, row.names = FALSE)
  }

  checks
}

build_release_bundle_v2 <- function(release_label = NULL,
                                    bundle_root = file.path("artefacts", "release_candidates")) {
  if (is.null(release_label)) {
    release_label <- release_candidate_label_v2()
  }

  tarball <- build_source_package_tarball()
  run_release_reference_suite_v2()

  bundle_dir <- file.path(bundle_root, release_label)
  dir.create(bundle_dir, recursive = TRUE, showWarnings = FALSE)

  package_dir <- file.path(bundle_dir, "package")
  docs_dir <- file.path(bundle_dir, "docs")
  outputs_dir <- file.path(bundle_dir, "outputs")

  tarball_copy <- copy_release_file_v1(tarball, file.path(package_dir, basename(tarball)))

  docs_to_copy <- c(
    "README.md",
    "CHANGELOG.md",
    file.path("docs", "roadmap_v2.md"),
    file.path("docs", "observational_data_contract_v1.md"),
    file.path("docs", "release_checklist.md"),
    file.path("docs", "workflow.md"),
    file.path("reports", "paper_pipeline_v2.qmd")
  )
  copied_docs <- character(length(docs_to_copy))
  for (i in seq_along(docs_to_copy)) {
    copied_docs[[i]] <- copy_release_file_v1(docs_to_copy[[i]], file.path(docs_dir, basename(docs_to_copy[[i]])))
  }

  output_dirs <- c(
    file.path("artefacts", "canonical_runs", "experiment_a_presence_removal_v2"),
    file.path("artefacts", "canonical_runs", "experiment_c_aridity_gradient_v2"),
    file.path("artefacts", "validation", "pilot_benchmark_v1"),
    file.path("artefacts", "stability", "long_horizon_v1"),
    file.path("artefacts", "benchmarks", "post_v1_scaling_v1"),
    file.path("artefacts", "reports_v2")
  )
  copied_outputs <- vapply(
    normalizePath(output_dirs, winslash = "/", mustWork = TRUE),
    copy_release_dir_v1,
    character(1),
    dst_parent = outputs_dir
  )

  checklist_path <- file.path(bundle_dir, "release_checklist_status.csv")
  checklist <- run_release_checklist_v2(package_tarball = tarball_copy, checklist_csv = checklist_path)

  manifest <- list(
    schema_version = output_schema_version(),
    created_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    release_label = release_label,
    package_tarball = tarball_copy,
    docs = copied_docs,
    outputs = copied_outputs,
    checklist_path = checklist_path,
    all_checks_pass = all(checklist$pass)
  )
  manifest_path <- file.path(bundle_dir, "release_manifest.json")
  writeLines(jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE), manifest_path)

  list(
    release_label = release_label,
    bundle_dir = bundle_dir,
    checklist = checklist,
    checklist_path = checklist_path,
    manifest_path = manifest_path
  )
}
