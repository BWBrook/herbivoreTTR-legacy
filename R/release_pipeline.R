# Release-candidate artefact pipeline helpers.

release_candidate_label_v1 <- function(version = resolve_package_version()) {
  if (grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", version)) {
    return(sprintf("v%s-rc1", version))
  }
  sprintf("v%s", version)
}

build_source_package_tarball <- function(package_name = "herbivoreTTR") {
  before <- Sys.glob(sprintf("%s_*.tar.gz", package_name))

  output <- system2(
    "R",
    c("CMD", "build", "."),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    rlang::abort(
      "Failed to build source package tarball.",
      class = "herbivoreTTR_release_build_failed",
      build_output = output
    )
  }

  after <- Sys.glob(sprintf("%s_*.tar.gz", package_name))
  new_files <- setdiff(after, before)

  if (length(new_files) > 0L) {
    newest <- new_files[which.max(file.info(new_files)$mtime)]
  } else if (length(after) > 0L) {
    newest <- after[which.max(file.info(after)$mtime)]
  } else {
    rlang::abort(
      "No source package tarball found after build.",
      class = "herbivoreTTR_release_tarball_missing"
    )
  }

  normalizePath(newest, winslash = "/", mustWork = TRUE)
}

release_expected_run_slugs_v1 <- function() {
  c(
    "smoke_v0",
    "cohort_smoke_v1",
    "implicit_stocking_v1",
    "reference_presence_present_v1",
    "reference_presence_removed_v1",
    "reference_grazer_v1",
    "reference_browser_v1",
    "reference_mixed_v1",
    "reference_aridity_low_v1",
    "reference_aridity_mid_v1",
    "reference_aridity_high_v1",
    "day_in_life_nutrient_targeting_v1",
    "day_in_life_energy_only_v1",
    "day_in_life_mode_comparison_v1",
    "experiment_a_presence_removal_v1",
    "experiment_b_functional_types_v1",
    "experiment_c_aridity_gradient_v1",
    "benchmark_appendix_v1",
    "performance_budget_v1"
  )
}

run_release_reference_suite_v1 <- function(base_dir = file.path("artefacts", "canonical_runs")) {
  canonical <- run_scenario_v2(scenario_contract_reference_path("canonical_smoke_v1"), base_dir = base_dir)
  cohort <- run_scenario_v2(scenario_contract_reference_path("cohort_smoke_v1"), base_dir = base_dir)
  implicit <- run_scenario_v2(scenario_contract_reference_path("implicit_stocking_v1"), base_dir = base_dir)

  reference <- run_reference_scenario_library(base_dir = base_dir)
  exp_a <- run_experiment_a_presence_removal(base_dir = base_dir)
  exp_b <- run_experiment_b_functional_types(base_dir = base_dir)
  exp_c <- run_experiment_c_aridity_gradient(base_dir = base_dir)
  bench <- run_benchmark_appendix_v1(base_dir = base_dir)
  perf <- run_performance_budget_profile(base_dir = base_dir)
  day_in_life <- run_day_in_life_comparison(base_dir = base_dir)
  paper_html <- render_paper_pipeline_report(
    input = file.path("reports", "paper_pipeline.qmd"),
    output_dir = file.path("artefacts", "reports")
  )

  run_dirs <- c(
    canonical$run_dir,
    cohort$run_dir,
    implicit$run_dir,
    file.path(base_dir, "reference_scenarios_v1"),
    vapply(reference$runs, `[[`, character(1), "run_dir"),
    exp_a$run_dir,
    exp_b$run_dir,
    exp_c$run_dir,
    bench$run_dir,
    dirname(perf$summary_path),
    day_in_life$nutrient_run$run_dir,
    day_in_life$energy_run$run_dir,
    dirname(day_in_life$comparison_path)
  )

  list(
    run_dirs = unique(normalizePath(run_dirs, winslash = "/", mustWork = TRUE)),
    paper_html = normalizePath(paper_html, winslash = "/", mustWork = TRUE)
  )
}

copy_release_file_v1 <- function(src, dst) {
  dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
  ok <- file.copy(src, dst, overwrite = TRUE, copy.date = TRUE)
  if (!isTRUE(ok)) {
    rlang::abort(
      "Failed to copy release file.",
      class = "herbivoreTTR_release_copy_file_failed",
      source = src,
      destination = dst
    )
  }
  normalizePath(dst, winslash = "/", mustWork = TRUE)
}

copy_release_dir_v1 <- function(src_dir, dst_parent) {
  dir.create(dst_parent, recursive = TRUE, showWarnings = FALSE)
  src_name <- basename(src_dir)
  dst_dir <- file.path(dst_parent, src_name)

  if (dir.exists(dst_dir)) {
    unlink(dst_dir, recursive = TRUE, force = TRUE)
  }

  ok <- file.copy(src_dir, dst_parent, recursive = TRUE, overwrite = TRUE, copy.date = TRUE)
  if (!isTRUE(ok)) {
    rlang::abort(
      "Failed to copy release directory.",
      class = "herbivoreTTR_release_copy_dir_failed",
      source = src_dir,
      destination_parent = dst_parent
    )
  }

  normalizePath(dst_dir, winslash = "/", mustWork = TRUE)
}

check_changelog_for_version_v1 <- function(version = resolve_package_version(), path = "CHANGELOG.md") {
  if (!file.exists(path)) {
    return(FALSE)
  }
  lines <- readLines(path, warn = FALSE)
  escaped_version <- gsub("\\.", "\\\\.", version)
  pattern <- sprintf("^##[[:space:]]+\\[?%s\\]?", escaped_version)
  any(grepl(pattern, lines))
}

read_manifest_schema_version_v1 <- function(path) {
  if (!file.exists(path)) {
    return(NA_character_)
  }
  json <- jsonlite::read_json(path, simplifyVector = TRUE)
  as.character(json$schema_version)
}

run_release_checklist_v1 <- function(package_tarball,
                                     base_dir = file.path("artefacts", "canonical_runs"),
                                     paper_html = file.path("artefacts", "reports", "paper_pipeline.html"),
                                     checklist_csv = NULL) {
  version <- resolve_package_version()

  semver_ok <- grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", version)
  changelog_ok <- check_changelog_for_version_v1(version = version)
  api_doc_ok <- file.exists(file.path("docs", "governance", "api_surface_v1.md"))
  dep_doc_ok <- file.exists(file.path("docs", "governance", "deprecation_policy.md"))
  repro_doc_ok <- file.exists(file.path("docs", "governance", "reproducibility_runbook_v1.md"))
  tarball_ok <- file.exists(package_tarball)
  renv_sync <- isTRUE(renv::status()$synchronized)

  expected_manifest_paths <- file.path(base_dir, release_expected_run_slugs_v1(), "run_manifest.json")
  manifests_ok <- all(file.exists(expected_manifest_paths))

  schema_versions <- vapply(expected_manifest_paths, read_manifest_schema_version_v1, character(1))
  schema_ok <- all(!is.na(schema_versions) & schema_versions == output_schema_version())
  paper_ok <- file.exists(paper_html)

  checks <- data.frame(
    item = c(
      "description_version_semver",
      "changelog_has_current_version_header",
      "api_surface_doc_present",
      "deprecation_policy_doc_present",
      "reproducibility_runbook_present",
      "source_tarball_present",
      "renv_status_synchronized",
      "expected_reference_manifests_present",
      "manifest_schema_versions_match_current",
      "paper_pipeline_report_present"
    ),
    status = c(
      semver_ok,
      changelog_ok,
      api_doc_ok,
      dep_doc_ok,
      repro_doc_ok,
      tarball_ok,
      renv_sync,
      manifests_ok,
      schema_ok,
      paper_ok
    ),
    evidence = c(
      version,
      if (changelog_ok) "header found" else "missing header",
      file.path("docs", "governance", "api_surface_v1.md"),
      file.path("docs", "governance", "deprecation_policy.md"),
      file.path("docs", "governance", "reproducibility_runbook_v1.md"),
      package_tarball,
      if (renv_sync) "renv synchronized" else "renv out of sync",
      sprintf("%d/%d manifests present", sum(file.exists(expected_manifest_paths)), length(expected_manifest_paths)),
      sprintf("schema=%s", paste(unique(schema_versions), collapse = ",")),
      paper_html
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

build_release_bundle_v1 <- function(release_label = NULL,
                                    bundle_root = file.path("artefacts", "release_candidates"),
                                    base_dir = file.path("artefacts", "canonical_runs")) {
  if (is.null(release_label)) {
    release_label <- release_candidate_label_v1()
  }

  if (!is.character(release_label) || length(release_label) != 1L || !nzchar(release_label)) {
    rlang::abort(
      "`release_label` must be a non-empty scalar character.",
      class = "herbivoreTTR_release_label_invalid",
      release_label = release_label
    )
  }

  tarball <- build_source_package_tarball()
  suite <- run_release_reference_suite_v1(base_dir = base_dir)

  bundle_dir <- file.path(bundle_root, release_label)
  dir.create(bundle_dir, recursive = TRUE, showWarnings = FALSE)

  package_dir <- file.path(bundle_dir, "package")
  docs_dir <- file.path(bundle_dir, "docs")
  outputs_dir <- file.path(bundle_dir, "reference_outputs")
  reports_dir <- file.path(bundle_dir, "reports")

  tarball_copy <- copy_release_file_v1(tarball, file.path(package_dir, basename(tarball)))

  docs_to_copy <- c(
    "README.md",
    "CHANGELOG.md",
    file.path("docs", "release_checklist.md"),
    file.path("docs", "governance", "api_surface_v1.md"),
    file.path("docs", "governance", "deprecation_policy.md"),
    file.path("docs", "governance", "reproducibility_runbook_v1.md"),
    file.path("reports", "paper_pipeline.qmd")
  )

  copied_docs <- character(length(docs_to_copy))
  for (i in seq_along(docs_to_copy)) {
    src <- docs_to_copy[[i]]
    if (!file.exists(src)) {
      rlang::abort(
        "Required release document missing.",
        class = "herbivoreTTR_release_doc_missing",
        path = src
      )
    }
    copied_docs[[i]] <- copy_release_file_v1(src, file.path(docs_dir, basename(src)))
  }

  copied_output_dirs <- vapply(
    suite$run_dirs,
    copy_release_dir_v1,
    character(1),
    dst_parent = outputs_dir
  )

  paper_copy <- copy_release_file_v1(
    suite$paper_html,
    file.path(reports_dir, basename(suite$paper_html))
  )

  checklist_path <- file.path(bundle_dir, "release_checklist_status.csv")
  checklist <- run_release_checklist_v1(
    package_tarball = tarball_copy,
    base_dir = base_dir,
    paper_html = suite$paper_html,
    checklist_csv = checklist_path
  )

  manifest <- list(
    schema_version = output_schema_version(),
    release_label = release_label,
    package_version = resolve_package_version(),
    git_sha = resolve_git_sha(),
    created_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    bundle_dir = normalize_manifest_path(bundle_dir),
    package_tarball = normalize_manifest_path(tarball_copy),
    copied_docs = as.list(vapply(copied_docs, normalize_manifest_path, character(1))),
    copied_output_dirs = as.list(vapply(copied_output_dirs, normalize_manifest_path, character(1))),
    paper_report = normalize_manifest_path(paper_copy),
    checklist = list(
      path = normalize_manifest_path(checklist_path),
      all_pass = all(checklist$pass)
    )
  )

  manifest_path <- file.path(bundle_dir, "release_manifest.json")
  write_run_manifest(manifest = manifest, path = manifest_path)

  list(
    release_label = release_label,
    bundle_dir = normalizePath(bundle_dir, winslash = "/", mustWork = TRUE),
    package_tarball = tarball_copy,
    docs = copied_docs,
    output_dirs = copied_output_dirs,
    paper_report = paper_copy,
    checklist_path = normalizePath(checklist_path, winslash = "/", mustWork = TRUE),
    checklist = checklist,
    manifest_path = normalizePath(manifest_path, winslash = "/", mustWork = TRUE)
  )
}
