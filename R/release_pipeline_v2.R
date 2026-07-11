# Release-candidate helpers for the v2.0 readiness track.

release_candidate_label_v2 <- function(version = resolve_package_version()) {
  if (grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", version)) {
    return(sprintf("v%s-rc1", version))
  }
  sprintf("v%s", version)
}

release_bundle_docs_v2 <- function() {
  c(
    "README.md",
    "CHANGELOG.md",
    file.path("docs", "roadmap_v2.md"),
    file.path("docs", "contracts", "scenario_contract_v2.md"),
    file.path("docs", "contracts", "scenario_run_output_contract_v2.md"),
    file.path("docs", "contracts", "observational_data_contract_v1.md"),
    file.path("docs", "contracts", "portal_plan_contract_v2.md"),
    file.path("docs", "release_checklist.md"),
    file.path("docs", "workflow.md"),
    file.path("docs", "guides", "scenario_v2_migration.md"),
    file.path("docs", "governance", "api_surface_v2.md"),
    file.path("reports", "paper_pipeline_v2.qmd")
  )
}

release_bundle_output_dirs_v2 <- function() {
  c(
    file.path("artefacts", "canonical_runs", "experiment_a_presence_removal_v2"),
    file.path("artefacts", "canonical_runs", "experiment_c_aridity_gradient_v2"),
    file.path("artefacts", "validation", "pilot_benchmark_v1"),
    file.path("artefacts", "stability", "long_horizon_v1"),
    file.path("artefacts", "benchmarks", "post_v1_scaling_v2"),
    file.path("artefacts", "reports_v2")
  )
}

release_expected_outputs_v2 <- function() {
  c(
    file.path("artefacts", "canonical_runs", "experiment_a_presence_removal_v2", "experiment_a_summary_v2.csv"),
    file.path("artefacts", "canonical_runs", "experiment_c_aridity_gradient_v2", "experiment_c_summary_v2.csv"),
    file.path("artefacts", "validation", "pilot_benchmark_v1", "pilot_metrics_summary_v1.csv"),
    file.path("artefacts", "stability", "long_horizon_v1", "stability_summary_v1.csv"),
    file.path("artefacts", "benchmarks", "post_v1_scaling_v2", "scaling_summary_v1.csv"),
    file.path("artefacts", "reports_v2", "paper_pipeline_v2.html"),
    file.path("artefacts", "reports_v2", "figure_table_manifest_v2.csv")
  )
}

validate_release_label_v2 <- function(release_label) {
  valid <- is.character(release_label) &&
    length(release_label) == 1L &&
    !is.na(release_label) &&
    nzchar(release_label) &&
    !release_label %in% c(".", "..") &&
    grepl("^[A-Za-z0-9][A-Za-z0-9._-]*$", release_label)
  if (!valid) {
    repro_abort(
      "`release_label` must be one safe path component.",
      "herbivoreTTR_release_label_invalid",
      release_label = release_label
    )
  }
  release_label
}

prepare_release_bundle_destination_v2 <- function(release_label,
                                                  bundle_root) {
  release_label <- validate_release_label_v2(release_label)
  canonical_root <- canonicalize_run_path(bundle_root)
  bundle_dir <- canonicalize_run_path(file.path(canonical_root, release_label))
  if (!identical(dirname(bundle_dir), canonical_root)) {
    repro_abort(
      "The release destination resolves outside the bundle root.",
      "herbivoreTTR_release_destination_outside_root",
      bundle_root = canonical_root,
      bundle_dir = bundle_dir
    )
  }
  assert_fresh_run_directory(bundle_dir, purpose = "v2 release bundle")
  bundle_dir
}

run_release_bundle_v2_cli <- function(args = character(),
                                      builder = build_release_bundle_v2) {
  release_label <- if (length(args) >= 1L && nzchar(args[[1]])) {
    args[[1]]
  } else {
    release_candidate_label_v2()
  }
  release_label <- validate_release_label_v2(release_label)
  result <- builder(release_label = release_label)
  checklist <- result$checklist
  all_pass <- is.data.frame(checklist) &&
    nrow(checklist) > 0L &&
    "pass" %in% names(checklist) &&
    is.logical(checklist$pass) &&
    !anyNA(checklist$pass) &&
    all(checklist$pass)

  message("Release bundle v2 generated")
  message(sprintf("- label: %s", result$release_label))
  message(sprintf("- bundle: %s", result$bundle_dir))
  message(sprintf("- checklist: %s", result$checklist_path))
  message(sprintf("- all checks pass: %s", ifelse(all_pass, "yes", "no")))

  if (all_pass) 0L else 1L
}

check_copied_report_manifest_v2 <- function(manifest_path) {
  manifest <- tryCatch(
    validate_report_artifact_manifest_v2(manifest_path),
    error = function(e) NULL
  )
  if (is.null(manifest)) {
    return(FALSE)
  }

  artifact_ids <- as.character(manifest$artifact_id)
  paths <- as.character(manifest$path)
  identical(paths, paste0("./", artifact_ids)) &&
    "paper_pipeline_v2.html" %in% artifact_ids
}

run_release_reference_suite_v2 <- function() {
  run_experiment_a_presence_removal_v2()
  run_experiment_c_aridity_gradient_v2()
  run_pilot_validation_benchmark_v1()
  run_long_horizon_stability_suite_v1(days = 120L, seeds = 801:804)
  run_post_v1_scaling_profile(
    scenario_slug = "post_v1_scaling_v2",
    ensemble_seeds = 1:12,
    stability_days = 40L,
    stability_seeds = 1:3,
    enforce_regression_gate = FALSE
  )
  render_paper_pipeline_report_v2()
}

run_release_checklist_v2 <- function(package_tarball,
                                     checklist_csv = NULL,
                                     copied_report_manifest_path = NULL) {
  version <- resolve_package_version()
  semver_ok <- grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", version)
  tarball_ok <- file.exists(package_tarball)
  renv_sync <- isTRUE(renv::status()$synchronized)
  expected <- release_expected_outputs_v2()
  outputs_ok <- all(file.exists(expected))
  report_path <- file.path("artefacts", "reports_v2", "paper_pipeline_v2.html")
  report_content_ok <- check_report_content_v2(report_path)
  copied_manifest_ok <- check_copied_report_manifest_v2(
    copied_report_manifest_path
  )
  changelog_ok <- check_changelog_for_version_v1(version = version)

  checks <- data.frame(
    item = c(
      "description_version_semver",
      "source_tarball_present",
      "renv_status_synchronized",
      "changelog_has_current_version_header",
      "expected_v2_outputs_present",
      "v2_report_content_present",
      "copied_v2_report_manifest_valid"
    ),
    status = c(
      semver_ok,
      tarball_ok,
      renv_sync,
      changelog_ok,
      outputs_ok,
      report_content_ok,
      copied_manifest_ok
    ),
    evidence = c(
      version,
      package_tarball,
      if (renv_sync) "renv synchronized" else "renv out of sync",
      if (changelog_ok) "header found" else "missing header",
      sprintf("%d/%d present", sum(file.exists(expected)), length(expected)),
      if (report_content_ok) {
        "all required report sections present"
      } else {
        "report missing required sections or contains placeholders"
      },
      if (copied_manifest_ok) {
        copied_report_manifest_path
      } else {
        "copied report manifest path, checksum, size, or file mismatch"
      }
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

  bundle_dir <- prepare_release_bundle_destination_v2(release_label, bundle_root)
  tarball <- build_source_package_tarball()
  run_release_reference_suite_v2()

  dir.create(bundle_dir, recursive = TRUE, showWarnings = FALSE)

  package_dir <- file.path(bundle_dir, "package")
  docs_dir <- file.path(bundle_dir, "docs")
  outputs_dir <- file.path(bundle_dir, "outputs")

  tarball_copy <- copy_release_file_v1(tarball, file.path(package_dir, basename(tarball)))

  docs_to_copy <- release_bundle_docs_v2()
  copied_docs <- character(length(docs_to_copy))
  for (i in seq_along(docs_to_copy)) {
    copied_docs[[i]] <- copy_release_file_v1(docs_to_copy[[i]], file.path(docs_dir, basename(docs_to_copy[[i]])))
  }

  output_dirs <- release_bundle_output_dirs_v2()
  copied_outputs <- vapply(
    normalizePath(output_dirs, winslash = "/", mustWork = TRUE),
    copy_release_dir_v1,
    character(1),
    dst_parent = outputs_dir
  )

  copied_report_dirs <- copied_outputs[
    basename(copied_outputs) == "reports_v2"
  ]
  if (length(copied_report_dirs) != 1L) {
    repro_abort(
      "The copied v2 report directory could not be identified.",
      "herbivoreTTR_release_report_copy_missing",
      copied_outputs = copied_outputs
    )
  }
  copied_report_manifest_path <- file.path(
    unname(copied_report_dirs[[1]]),
    "figure_table_manifest_v2.csv"
  )
  rebase_copied_report_manifest_v2(copied_report_manifest_path)

  checklist_path <- file.path(bundle_dir, "release_checklist_status.csv")
  checklist <- run_release_checklist_v2(
    package_tarball = tarball_copy,
    checklist_csv = checklist_path,
    copied_report_manifest_path = copied_report_manifest_path
  )

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
