test_that("runtime metadata identifies the active R installation", {
  expect_true(exists("resolve_current_r_runtime", mode = "function"))
  if (!exists("resolve_current_r_runtime", mode = "function")) {
    return(invisible())
  }

  runtime <- resolve_current_r_runtime()

  expect_identical(
    runtime$r_home,
    normalizePath(R.home(), winslash = "/", mustWork = TRUE)
  )
  expect_identical(runtime$r_version, R.version.string)
  expect_true(file.exists(runtime$executable))
  expect_true(startsWith(runtime$executable, paste0(runtime$r_home, "/")))
})

test_that("source package builder uses the selected R executable", {
  skip_on_os("windows")
  expect_true("r_executable" %in% names(formals(build_source_package_tarball)))
  if (!"r_executable" %in% names(formals(build_source_package_tarball))) {
    return(invisible())
  }

  tmp_dir <- tempfile(pattern = "release-r-runtime-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  fake_r <- file.path(tmp_dir, "fake-r")
  writeLines(
    c(
      "#!/bin/sh",
      "printf '%s\\n' \"$@\" > fake-r-args.txt",
      ": > herbivoreTTR_9.9.9.tar.gz"
    ),
    fake_r
  )
  Sys.chmod(fake_r, mode = "0755")

  old_wd <- setwd(tmp_dir)
  on.exit(setwd(old_wd), add = TRUE)
  tarball <- build_source_package_tarball(
    package_name = "herbivoreTTR",
    r_executable = fake_r
  )

  expect_identical(basename(tarball), "herbivoreTTR_9.9.9.tar.gz")
  expect_identical(readLines("fake-r-args.txt", warn = FALSE), c("CMD", "build", "."))
})

test_that("fresh-run directory preflight rejects inherited contents", {
  expect_true(exists("assert_fresh_run_directory", mode = "function"))
  if (!exists("assert_fresh_run_directory", mode = "function")) {
    return(invisible())
  }

  tmp_dir <- tempfile(pattern = "fresh-run-dir-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  expect_no_error(assert_fresh_run_directory(tmp_dir, purpose = "test run"))
  writeLines("stale", file.path(tmp_dir, ".stale"))
  expect_error(
    assert_fresh_run_directory(tmp_dir, purpose = "test run"),
    class = "herbivoreTTR_fresh_run_directory_not_empty"
  )
})

test_that("fresh-output gate requires changed metadata after a run marker", {
  helpers <- c("snapshot_file_metadata", "assert_files_regenerated_since")
  available <- vapply(
    helpers,
    function(name) exists(name, mode = "function", inherits = TRUE),
    logical(1)
  )
  expect_true(all(available))
  signature_ok <- exists("assert_files_regenerated_since", mode = "function") &&
    all(c("before", "marker_path") %in% names(formals(assert_files_regenerated_since)))
  expect_true(signature_ok)
  if (!all(available) || !signature_ok) {
    return(invisible())
  }

  tmp_dir <- tempfile(pattern = "fresh-run-files-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  output_path <- file.path(tmp_dir, "output.csv")
  marker_path <- file.path(tmp_dir, "run.marker")
  writeLines("marker", marker_path)
  marker_time <- Sys.time()
  Sys.setFileTime(marker_path, marker_time)

  before_missing <- snapshot_file_metadata(output_path)
  expect_error(
    assert_files_regenerated_since(
      output_path,
      before = before_missing,
      marker_path = marker_path,
      purpose = "test output"
    ),
    class = "herbivoreTTR_repro_output_missing"
  )

  writeLines("same", output_path)
  Sys.setFileTime(output_path, marker_time + 3600)
  before_future <- snapshot_file_metadata(output_path)
  expect_error(
    assert_files_regenerated_since(
      output_path,
      before = before_future,
      marker_path = marker_path,
      purpose = "test output"
    ),
    class = "herbivoreTTR_repro_output_unchanged"
  )

  writeLines("changed", output_path)
  Sys.setFileTime(output_path, marker_time)
  expect_error(
    assert_files_regenerated_since(
      output_path,
      before = before_future,
      marker_path = marker_path,
      purpose = "test output"
    ),
    class = "herbivoreTTR_repro_output_stale"
  )

  Sys.setFileTime(output_path, marker_time + 1)
  expect_no_error(
    assert_files_regenerated_since(
      output_path,
      before = before_future,
      marker_path = marker_path,
      purpose = "test output"
    )
  )
})

test_that("v2 suite freshness rejects outputs rewritten only by targets", {
  expect_true(exists("assert_v2_replay_phase_freshness", mode = "function"))
  if (!exists("assert_v2_replay_phase_freshness", mode = "function")) {
    return(invisible())
  }

  tmp_dir <- tempfile(pattern = "v2-phase-freshness-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  target_output <- file.path(tmp_dir, "plant_snapshot.csv")
  suite_output <- file.path(tmp_dir, "experiment_a_summary_v2.csv")
  overall_marker <- file.path(tmp_dir, "overall.marker")
  suite_marker <- file.path(tmp_dir, "suite.marker")
  boundary_time <- as.POSIXct("2026-07-11 00:00:00", tz = "UTC")

  writeLines("before", target_output)
  writeLines("before", suite_output)
  overall_before <- snapshot_file_metadata(c(target_output, suite_output))
  writeLines("overall boundary", overall_marker)
  Sys.setFileTime(overall_marker, boundary_time)

  writeLines("target-generated plant", target_output)
  writeLines("target-generated suite output", suite_output)
  Sys.setFileTime(target_output, boundary_time + 10)
  Sys.setFileTime(suite_output, boundary_time + 10)
  suite_before <- snapshot_file_metadata(suite_output)
  writeLines("suite boundary", suite_marker)
  Sys.setFileTime(suite_marker, boundary_time + 20)

  expect_error(
    assert_v2_replay_phase_freshness(
      target_owned_paths = target_output,
      suite_owned_paths = suite_output,
      overall_before = overall_before,
      overall_marker_path = overall_marker,
      suite_before = suite_before,
      suite_marker_path = suite_marker
    ),
    class = "herbivoreTTR_repro_output_unchanged"
  )

  writeLines("suite-generated output", suite_output)
  Sys.setFileTime(suite_output, boundary_time + 30)
  expect_no_error(assert_v2_replay_phase_freshness(
    target_owned_paths = target_output,
    suite_owned_paths = suite_output,
    overall_before = overall_before,
    overall_marker_path = overall_marker,
    suite_before = suite_before,
    suite_marker_path = suite_marker
  ))
})

test_that("v2 replay script persists overall and post-target boundaries", {
  repo_root <- repo_root_for_tests()
  script_path <- file.path(repo_root, "scripts", "run_external_repro_check_v2.R")
  skip_if_not(file.exists(script_path), "v2 replay script is unavailable")
  script <- paste(readLines(script_path, warn = FALSE), collapse = "\n")

  target_step <- regexpr("02_targets_smoke", script, fixed = TRUE)[[1]]
  boundary_step <- regexpr("03_capture_v2_suite_boundary", script, fixed = TRUE)[[1]]
  suite_step <- regexpr("04_run_v2_suites", script, fixed = TRUE)[[1]]
  verify_step <- regexpr("05_verify_outputs", script, fixed = TRUE)[[1]]
  expect_true(all(c(target_step, boundary_step, suite_step, verify_step) > 0L))
  expect_lt(target_step, boundary_step)
  expect_lt(boundary_step, suite_step)
  expect_lt(suite_step, verify_step)
  expect_match(script, "post_targets_snapshot", fixed = TRUE)
  expect_match(script, "post_targets_marker", fixed = TRUE)
  expect_match(script, "assert_v2_replay_phase_freshness", fixed = TRUE)
})

test_that("v2 suite freshness owns every generated report input without drift", {
  generated_report_inputs <- paper_pipeline_generated_input_files_v2()
  suite_owned <- v2_replay_suite_owned_paths()
  expected_suite_only <- c(
    scaling = file.path(
      "artefacts", "benchmarks", "post_v1_scaling_v2",
      "scaling_summary_v1.csv"
    ),
    report = file.path("artefacts", "reports_v2", "paper_pipeline_v2.html"),
    manifest = file.path("artefacts", "reports_v2", "figure_table_manifest_v2.csv")
  )

  expect_identical(
    paper_pipeline_input_files_v2(),
    c(file.path("reports", "paper_pipeline_v2.qmd"), unname(generated_report_inputs))
  )
  expect_setequal(intersect(suite_owned, generated_report_inputs), generated_report_inputs)
  expect_setequal(setdiff(suite_owned, generated_report_inputs), expected_suite_only)
  expect_false(file.path("reports", "paper_pipeline_v2.qmd") %in% suite_owned)
  expect_false(anyDuplicated(suite_owned) > 0L)
  expect_false(anyDuplicated(names(suite_owned)) > 0L)
  expect_true(all(nzchar(names(suite_owned))))

  verifier_roles <- c(
    "experiment_a_summary",
    "experiment_a_claims",
    "experiment_c_summary",
    "experiment_c_claims",
    "stability",
    "pilot",
    "scaling",
    "report",
    "manifest"
  )
  expect_identical(
    unname(suite_owned[verifier_roles]),
    unname(c(
      generated_report_inputs[c(
        "experiment_a_summary",
        "experiment_a_claims",
        "experiment_c_summary",
        "experiment_c_claims",
        "stability",
        "pilot"
      )],
      expected_suite_only
    ))
  )

  repo_root <- repo_root_for_tests()
  script <- paste(readLines(
    file.path(repo_root, "scripts", "run_external_repro_check_v2.R"),
    warn = FALSE
  ), collapse = "\n")
  expect_false(grepl("required\\[\\[[0-9]+\\]\\]", script, perl = TRUE))
  for (role in verifier_roles) {
    expect_match(
      script,
      sprintf("required[['%s']]", role),
      fixed = TRUE,
      info = role
    )
  }
})

test_that("replay paths are canonical, distinct siblings", {
  expect_true(exists("validate_repro_run_paths", mode = "function"))
  if (!exists("validate_repro_run_paths", mode = "function")) {
    return(invisible())
  }

  tmp_dir <- tempfile(pattern = "repro-topology-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  paths <- file.path(tmp_dir, c("output", "library", "targets"))
  canonical <- validate_repro_run_paths(paths[[1]], paths[[2]], paths[[3]])
  expect_named(canonical, c("out_dir", "lib_dir", "targets_store"))
  expect_length(unique(unname(canonical)), 3L)
  expect_identical(length(unique(dirname(unname(canonical)))), 1L)

  expect_error(
    validate_repro_run_paths(paths[[1]], paths[[1]], paths[[3]]),
    class = "herbivoreTTR_repro_path_overlap"
  )
  expect_error(
    validate_repro_run_paths(paths[[1]], file.path(paths[[1]], "library"), paths[[3]]),
    class = "herbivoreTTR_repro_path_overlap"
  )
  expect_error(
    validate_repro_run_paths(file.path(tmp_dir, "a", "..", "output"), paths[[2]], paths[[3]]),
    class = "herbivoreTTR_repro_path_parent_component"
  )

  skip_on_os("windows")
  expect_error(
    validate_repro_run_paths("/", paths[[2]], paths[[3]]),
    class = "herbivoreTTR_repro_path_overlap"
  )

  dir.create(paths[[1]])
  alias <- file.path(tmp_dir, "output-alias")
  expect_true(file.symlink(paths[[1]], alias))
  expect_error(
    validate_repro_run_paths(paths[[1]], alias, paths[[3]]),
    class = "herbivoreTTR_repro_path_overlap"
  )
})

test_that("replay wrappers reject case-only aliases after directory creation", {
  repo_root <- repo_root_for_tests()
  tmp_dir <- tempfile(pattern = "repro-case-alias-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  probe_upper <- file.path(tmp_dir, "CaseProbe")
  probe_lower <- file.path(tmp_dir, "caseprobe")
  dir.create(probe_upper)
  if (!dir.exists(probe_lower)) {
    skip("Temporary filesystem is case-sensitive")
  }

  scripts <- c(
    v1 = "scripts/run_external_repro_check.R",
    v2 = "scripts/run_external_repro_check_v2.R"
  )
  for (version in names(scripts)) {
    run_root <- file.path(tmp_dir, version)
    dir.create(run_root)
    paths <- file.path(run_root, c("Replay", "replay", "targets"))
    result <- withr::with_dir(
      repo_root,
      suppressWarnings(system2(
        file.path(
          R.home("bin"),
          if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript"
        ),
        c("--vanilla", shQuote(scripts[[version]]), shQuote(paths)),
        stdout = TRUE,
        stderr = TRUE,
        env = "HERBIVORETTR_R_EXECUTABLE=herbivoreTTR-missing-r-command"
      ))
    )
    status <- attr(result, "status")
    if (is.null(status)) status <- 0L

    expect_true(as.integer(status) > 0L, info = version)
    expect_match(
      paste(result, collapse = "\n"),
      "must not overlap",
      fixed = TRUE,
      info = version
    )
  }
})

test_that("replay numeric guards reject non-finite and negative contract values", {
  helpers <- c("assert_finite_numeric_columns", "assert_nonnegative_columns")
  available <- vapply(
    helpers,
    function(name) exists(name, mode = "function", inherits = TRUE),
    logical(1)
  )
  expect_true(all(available))
  if (!all(available)) {
    return(invisible())
  }

  values <- data.frame(Ms = c(1, 2), Mr = c(3, 4), label = c("a", "b"))
  expect_no_error(
    assert_finite_numeric_columns(values, c("Ms", "Mr"), purpose = "plant output")
  )
  expect_no_error(
    assert_nonnegative_columns(values, c("Ms", "Mr"), purpose = "plant biomass")
  )
  expect_error(
    assert_finite_numeric_columns(values, character(), purpose = "plant output"),
    class = "herbivoreTTR_repro_columns_invalid"
  )

  non_finite <- values
  non_finite$Ms[[2]] <- Inf
  expect_error(
    assert_finite_numeric_columns(non_finite, c("Ms", "Mr"), purpose = "plant output"),
    class = "herbivoreTTR_repro_non_finite_values"
  )

  negative <- values
  negative$Mr[[1]] <- -1
  expect_error(
    assert_nonnegative_columns(negative, c("Ms", "Mr"), purpose = "plant biomass"),
    class = "herbivoreTTR_repro_negative_values"
  )
})

test_that("replay row and claim guards reject missing required evidence", {
  expect_identical(
    names(formals(assert_required_claims_supported)),
    "claim_status"
  )

  helpers <- c(
    "assert_required_rows_present",
    "assert_repro_required_claims_supported"
  )
  available <- vapply(
    helpers,
    function(name) exists(name, mode = "function", inherits = TRUE),
    logical(1)
  )
  expect_true(all(available))
  if (!all(available)) {
    return(invisible())
  }
  expect_identical(
    names(formals(assert_repro_required_claims_supported)),
    c("data", "purpose")
  )

  observed <- data.frame(scenario = c("present", "removal"), value = c(1, 2))
  required <- data.frame(scenario = c("present", "removal"))
  expect_no_error(
    assert_required_rows_present(observed, required, "scenario", purpose = "experiment A")
  )
  expect_error(
    assert_required_rows_present(observed[1, ], required, "scenario", purpose = "experiment A"),
    class = "herbivoreTTR_repro_required_rows_missing"
  )

  supported <- data.frame(required = c(TRUE, FALSE), status = c("supported", "not_supported"))
  expect_no_error(assert_repro_required_claims_supported(supported, purpose = "claims"))

  failed <- data.frame(required = TRUE, status = "not_supported")
  expect_error(
    assert_repro_required_claims_supported(failed, purpose = "claims"),
    class = "herbivoreTTR_repro_required_claim_failed"
  )

  absent <- data.frame(required = FALSE, status = "supported")
  expect_error(
    assert_repro_required_claims_supported(absent, purpose = "claims"),
    class = "herbivoreTTR_repro_required_rows_missing"
  )

  malformed <- data.frame(required = c("TRUE", "unknown"), status = "supported")
  expect_error(
    assert_repro_required_claims_supported(malformed, purpose = "claims"),
    class = "herbivoreTTR_repro_required_flag_invalid"
  )

  missing_flag <- data.frame(required = c(TRUE, NA), status = "supported")
  expect_error(
    assert_repro_required_claims_supported(missing_flag, purpose = "claims"),
    class = "herbivoreTTR_repro_required_flag_invalid"
  )
})

test_that("every generated plant snapshot is validated", {
  expect_true(exists("assert_plant_snapshot_contract", mode = "function"))
  if (!exists("assert_plant_snapshot_contract", mode = "function")) {
    return(invisible())
  }

  tmp_dir <- tempfile(pattern = "plant-snapshots-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  valid <- data.frame(BLeaf = 1, BStem = 1, BDef = 0, Ms = 2, Mr = 2)
  invalid <- valid
  invalid$Mr <- Inf
  paths <- file.path(tmp_dir, c("plants_day1.csv", "plants_day2.csv"))
  utils::write.table(valid, paths[[1]], sep = ";", row.names = FALSE)
  utils::write.table(invalid, paths[[2]], sep = ";", row.names = FALSE)

  expect_error(
    assert_plant_snapshot_contract(paths, purpose = "plant snapshots"),
    class = "herbivoreTTR_repro_non_finite_values"
  )
  utils::write.table(valid, paths[[2]], sep = ";", row.names = FALSE)
  expect_no_error(assert_plant_snapshot_contract(paths, purpose = "plant snapshots"))
})

test_that("canonical replay discovery selects exact herb and plant snapshots", {
  expect_true(exists("canonical_replay_snapshot_paths", mode = "function"))
  if (!exists("canonical_replay_snapshot_paths", mode = "function")) {
    return(invisible())
  }

  canonical_dir <- tempfile(pattern = "canonical-snapshots-")
  dir.create(canonical_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(canonical_dir, recursive = TRUE, force = TRUE), add = TRUE)
  paths <- file.path(
    canonical_dir,
    c(
      "herb_day1826.csv",
      "herb_day1832.csv",
      "herbivore_daily.csv",
      "plants_day1826.csv",
      "plants_day1832.csv"
    )
  )
  expect_true(all(file.create(paths)))

  discovered <- canonical_replay_snapshot_paths(canonical_dir)

  expect_identical(
    discovered$herbivore_paths,
    sort(paths[grepl("/herb_day", paths, fixed = TRUE)])
  )
  expect_identical(
    discovered$plant_paths,
    sort(paths[grepl("/plants_day", paths, fixed = TRUE)])
  )
  expect_false(any(grepl("herbivore_daily", discovered$herbivore_paths, fixed = TRUE)))
})

test_that("every generated herbivore snapshot satisfies the replay contract", {
  expect_true(exists("assert_herbivore_snapshot_contract", mode = "function"))
  if (!exists("assert_herbivore_snapshot_contract", mode = "function")) {
    return(invisible())
  }

  tmp_dir <- tempfile(pattern = "herbivore-snapshots-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)
  paths <- file.path(tmp_dir, c("herb_day1.csv", "herb_day2.csv"))
  valid <- data.frame(
    Mass = c(100, 99),
    EnergyBalance = c(2, -1),
    WaterBalance = c(1, -0.5)
  )
  for (path in paths) {
    utils::write.table(valid, path, sep = ";", row.names = FALSE)
  }
  expect_no_error(assert_herbivore_snapshot_contract(paths, "herbivore snapshots"))

  non_finite <- valid
  non_finite$EnergyBalance[[2]] <- Inf
  utils::write.table(non_finite, paths[[2]], sep = ";", row.names = FALSE)
  expect_error(
    assert_herbivore_snapshot_contract(paths, "herbivore snapshots"),
    class = "herbivoreTTR_repro_non_finite_values"
  )

  negative <- valid
  negative$Mass[[1]] <- -1
  utils::write.table(negative, paths[[2]], sep = ";", row.names = FALSE)
  expect_error(
    assert_herbivore_snapshot_contract(paths, "herbivore snapshots"),
    class = "herbivoreTTR_repro_negative_values"
  )

  utils::write.csv(valid, paths[[2]], row.names = FALSE)
  expect_error(
    assert_herbivore_snapshot_contract(paths, "herbivore snapshots"),
    class = "herbivoreTTR_repro_columns_invalid"
  )

  empty <- valid[0, , drop = FALSE]
  utils::write.table(empty, paths[[2]], sep = ";", row.names = FALSE)
  expect_error(
    assert_herbivore_snapshot_contract(paths, "herbivore snapshots"),
    class = "herbivoreTTR_repro_required_rows_missing"
  )
  expect_error(
    assert_herbivore_snapshot_contract(character(), "herbivore snapshots"),
    class = "herbivoreTTR_repro_output_missing"
  )
})

test_that("replay stability guard rejects existing violation counts", {
  expect_true(exists("assert_zero_stability_violations", mode = "function"))
  if (!exists("assert_zero_stability_violations", mode = "function")) {
    return(invisible())
  }

  stability <- data.frame(
    nan_inf_count_total = 0,
    negative_biomass_violations_total = 0,
    gut_capacity_violations_total = 0,
    any_violation_runs = 0
  )
  expect_no_error(assert_zero_stability_violations(stability))

  stability$gut_capacity_violations_total <- 1
  expect_error(
    assert_zero_stability_violations(stability),
    class = "herbivoreTTR_repro_stability_violation"
  )
})

test_that("v2 release destination rejects inherited contents", {
  helpers <- c("prepare_release_bundle_destination_v2", "validate_release_label_v2")
  available <- vapply(
    helpers,
    function(name) exists(name, mode = "function", inherits = TRUE),
    logical(1)
  )
  expect_true(all(available))
  if (!all(available)) {
    return(invisible())
  }

  bundle_root <- tempfile(pattern = "release-v2-root-")
  bundle_dir <- file.path(bundle_root, "occupied")
  dir.create(bundle_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(bundle_root, recursive = TRUE, force = TRUE), add = TRUE)
  writeLines("stale", file.path(bundle_dir, "release_manifest.json"))

  expect_error(
    prepare_release_bundle_destination_v2("occupied", bundle_root),
    class = "herbivoreTTR_fresh_run_directory_not_empty"
  )

  invalid_labels <- c("", ".", "..", "../escape", "nested/label", "nested\\label")
  for (label in invalid_labels) {
    expect_error(
      prepare_release_bundle_destination_v2(label, bundle_root),
      class = "herbivoreTTR_release_label_invalid",
      info = label
    )
  }

  if (.Platform$OS.type != "windows") {
    outside <- tempfile(pattern = "release-v2-outside-")
    dir.create(outside)
    on.exit(unlink(outside, recursive = TRUE, force = TRUE), add = TRUE)
    expect_true(file.symlink(outside, file.path(bundle_root, "escaped")))
    expect_error(
      prepare_release_bundle_destination_v2("escaped", bundle_root),
      class = "herbivoreTTR_release_destination_outside_root"
    )
  }

  safe_path <- prepare_release_bundle_destination_v2("v2.0.0-rc1-test", bundle_root)
  expect_identical(dirname(safe_path), normalizePath(bundle_root, winslash = "/"))
  expect_identical(basename(safe_path), "v2.0.0-rc1-test")
})

test_that("v2 release CLI requires a strict non-empty logical checklist", {
  expect_true(exists("run_release_bundle_v2_cli", mode = "function"))
  if (!exists("run_release_bundle_v2_cli", mode = "function")) {
    return(invisible())
  }

  builder_for <- function(checklist) {
    function(release_label) list(
      release_label = release_label,
      bundle_dir = "bundle",
      checklist_path = "checklist.csv",
      checklist = checklist
    )
  }

  cases <- list(
    passing = list(checklist = data.frame(pass = c(TRUE, TRUE)), status = 0L),
    false_row = list(checklist = data.frame(pass = c(TRUE, FALSE)), status = 1L),
    empty = list(checklist = data.frame(pass = logical()), status = 1L),
    missing = list(checklist = data.frame(status = TRUE), status = 1L),
    missing_value = list(checklist = data.frame(pass = c(TRUE, NA)), status = 1L),
    character = list(checklist = data.frame(pass = c("TRUE", "TRUE")), status = 1L),
    numeric = list(checklist = data.frame(pass = c(1, 1)), status = 1L)
  )

  for (case_name in names(cases)) {
    case <- cases[[case_name]]
    status <- suppressWarnings(suppressMessages(run_release_bundle_v2_cli(
      "test-label",
      builder = builder_for(case$checklist)
    )))
    expect_identical(status, case$status, info = case_name)
  }
})

test_that("shared runtime probe rejects mismatches and preserves spaced commands", {
  expect_true(exists("assert_shared_r_runtime", mode = "function"))
  if (!exists("assert_shared_r_runtime", mode = "function")) {
    return(invisible())
  }

  calls <- list()
  matching_runner <- function(command, args, env = character()) {
    calls[[length(calls) + 1L]] <<- list(command = command, args = args, env = env)
    list(status = 0L, output = "/active/R/home")
  }
  selected_r <- "/tmp/runtime with spaces/R"
  expected_selected_r <- canonicalize_run_path(selected_r)
  expect_no_error(assert_shared_r_runtime(
    selected_r,
    expected_r_home = "/active/R/home",
    command_runner = matching_runner
  ))
  expect_identical(calls[[1]]$command, expected_selected_r)

  mismatch_runner <- function(command, args, env = character()) {
    list(status = 0L, output = "/different/R/home")
  }
  expect_error(
    assert_shared_r_runtime(
      selected_r,
      expected_r_home = "/active/R/home",
      command_runner = mismatch_runner
    ),
    class = "herbivoreTTR_r_runtime_mismatch"
  )
})

test_that("shared runtime probe resolves a bare R command through PATH", {
  calls <- list()
  runner <- function(command, args, env = character()) {
    calls[[length(calls) + 1L]] <<- list(command = command, args = args, env = env)
    list(status = 0L, output = normalizePath(R.home(), winslash = "/"))
  }
  expected_r <- normalizePath(unname(Sys.which("R")), winslash = "/", mustWork = TRUE)

  runtime <- assert_shared_r_runtime(
    "R",
    expected_r_home = R.home(),
    command_runner = runner
  )

  expect_identical(calls[[1]]$command, expected_r)
  expect_identical(runtime$r_executable, expected_r)
})

test_that("replay step runner selects R, propagates store, and stops on failure", {
  expect_true(exists("run_repro_steps", mode = "function"))
  if (!exists("run_repro_steps", mode = "function")) {
    return(invisible())
  }

  tmp_dir <- tempfile(pattern = "repro-step-runner-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  calls <- list()
  statuses <- c(0L, 1L, 0L)
  runner <- function(command, args, env = character()) {
    index <- length(calls) + 1L
    calls[[index]] <<- list(command = command, args = args, env = env)
    list(status = statuses[[index]], output = paste("step", index))
  }
  steps <- list(
    list(step = "restore", expr = "restore()"),
    list(step = "targets", expr = "tar_make()"),
    list(step = "verify", expr = "verify()")
  )
  env <- c("HERBIVORETTR_TARGETS_STORE=/tmp/store with spaces", "TARGETS_PROFILE=ci")
  selected_r <- "/tmp/runtime with spaces/R"

  results <- run_repro_steps(
    steps,
    r_executable = selected_r,
    env = env,
    out_dir = tmp_dir,
    command_runner = runner
  )

  expect_length(results, 2L)
  expect_identical(vapply(calls, `[[`, character(1), "command"), rep(selected_r, 2L))
  expect_true(all(vapply(calls, function(call) identical(call$env, env), logical(1))))
  expect_identical(tail(calls[[1]]$args, 1L), shQuote(steps[[1]]$expr))
  expect_identical(vapply(results, `[[`, integer(1), "status"), c(0L, 1L))
  expect_true(all(file.exists(vapply(results, `[[`, character(1), "log_path"))))
})

test_that("system command runner preserves environment values containing spaces", {
  expect_true(exists("run_command_capture", mode = "function"))
  if (!exists("run_command_capture", mode = "function")) {
    return(invisible())
  }

  expected <- "/tmp/targets store with spaces"
  expr <- "cat(Sys.getenv('HERBIVORETTR_TEST_PATH'))"
  result <- run_command_capture(
    file.path(R.home("bin"), "R"),
    c("--vanilla", "--slave", "-e", shQuote(expr)),
    sprintf("HERBIVORETTR_TEST_PATH=%s", expected)
  )

  expect_identical(result$status, 0L)
  expect_identical(paste(result$output, collapse = "\n"), expected)
})

test_that("targets store requires readable non-empty metadata", {
  expect_true(exists("assert_targets_store_metadata", mode = "function"))
  if (!exists("assert_targets_store_metadata", mode = "function")) {
    return(invisible())
  }

  store <- tempfile(pattern = "targets-store-")
  dir.create(store, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(store, recursive = TRUE, force = TRUE), add = TRUE)

  expect_no_error(assert_targets_store_metadata(
    store,
    metadata_reader = function(path) data.frame(name = "target", path = path)
  ))
  expect_error(
    assert_targets_store_metadata(store, metadata_reader = function(path) data.frame()),
    class = "herbivoreTTR_targets_store_metadata_missing"
  )
})

test_that("source Makefile locator finds the R CMD check source tree", {
  expect_true(exists("find_source_makefile_for_tests", mode = "function"))
  if (!exists("find_source_makefile_for_tests", mode = "function")) {
    return(invisible())
  }

  tmp_dir <- tempfile(pattern = "check-source-makefile-")
  installed_root <- file.path(tmp_dir, "library", "herbivoreTTR")
  check_root <- file.path(tmp_dir, "herbivoreTTR.Rcheck")
  source_root <- file.path(check_root, "00_pkg_src", "herbivoreTTR")
  dir.create(installed_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(source_root, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)
  writeLines("Package: herbivoreTTR", file.path(installed_root, "DESCRIPTION"))
  writeLines("all:", file.path(source_root, "Makefile"))

  located <- find_source_makefile_for_tests(
    repo_root = installed_root,
    check_root = check_root
  )
  expect_identical(
    located,
    normalizePath(file.path(source_root, "Makefile"), winslash = "/")
  )
})

test_that("test harness prefers R CMD check source assets and functions", {
  tmp_dir <- tempfile(pattern = "check-source-root-")
  check_root <- file.path(tmp_dir, "herbivoreTTR.Rcheck")
  source_root <- file.path(check_root, "00_pkg_src", "herbivoreTTR")
  dir.create(file.path(source_root, "R"), recursive = TRUE, showWarnings = FALSE)
  dir.create(
    file.path(source_root, "config", "claims"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  writeLines("Package: herbivoreTTR", file.path(source_root, "DESCRIPTION"))
  writeLines(
    "standalone_source_marker <- function() 'source-tree'",
    file.path(source_root, "R", "standalone-marker.R")
  )
  asset_path <- file.path(source_root, "config", "claims", "source-only.csv")
  writeLines("claim_id", asset_path)

  selected <- repo_root_for_tests(start = check_root)
  expected <- normalizePath(source_root, winslash = "/", mustWork = TRUE)
  expect_identical(selected, expected)
  if (!identical(selected, expected)) {
    return(invisible())
  }

  source_signature <- c("base", "envir") %in% names(formals(source_all_R))
  expect_true(all(source_signature))
  if (!all(source_signature)) {
    return(invisible())
  }

  source_env <- new.env(parent = baseenv())
  source_all_R(base = selected, envir = source_env)
  expect_identical(source_env$standalone_source_marker(), "source-tree")
  expect_true(file.exists(asset_path))
})

test_that("source Makefile and build exclusions are package-check portable", {
  makefile <- find_source_makefile_for_tests()
  skip_if(is.na(makefile), "No source Makefile available")
  repo_root <- dirname(makefile)

  make_text <- paste(readLines(makefile, warn = FALSE), collapse = "\n")
  forbidden <- c("ifeq", ":=", "$(shell", "?=")
  for (token in forbidden) {
    expect_false(grepl(token, make_text, fixed = TRUE), info = token)
  }

  checkout_buildignore <- file.path(repo_root_for_tests(), ".Rbuildignore")
  if (file.exists(checkout_buildignore)) {
    buildignore <- readLines(checkout_buildignore, warn = FALSE)
    expect_true("^\\.superpowers$" %in% buildignore)
  }
})

test_that("Makefile forwards fresh release and replay destinations", {
  makefile <- find_source_makefile_for_tests()
  skip_if(is.na(makefile), "No source Makefile available")
  repo_root <- dirname(makefile)
  dry_run <- function(target, variables) {
    withr::with_dir(
      repo_root,
      system2("make", c("-n", target, variables), stdout = TRUE, stderr = TRUE)
    )
  }

  release_output <- dry_run(
    "release-bundle-v2",
    c("RSCRIPT=/selected/Rscript", "RELEASE_V2_LABEL=test-label")
  )
  expect_match(
    paste(release_output, collapse = "\n"),
    '"/selected/Rscript" scripts/build_release_bundle_v2.R "test-label"',
    fixed = TRUE
  )

  replay_output <- dry_run(
    "repro-check",
    c(
      "RSCRIPT=/selected/Rscript",
      "REPRO_V1_OUT_DIR=/tmp/repro-v1",
      "REPRO_V1_LIB_DIR=/tmp/repro-v1-lib",
      "REPRO_V1_TARGETS_STORE=/tmp/repro-v1-store"
    )
  )
  replay_command <- paste(replay_output, collapse = "\n")
  expect_match(replay_command, '"/selected/Rscript"', fixed = TRUE)
  expect_match(replay_command, '"/tmp/repro-v1"', fixed = TRUE)
  expect_match(replay_command, '"/tmp/repro-v1-lib"', fixed = TRUE)
  expect_match(replay_command, '"/tmp/repro-v1-store"', fixed = TRUE)
})

test_that("bare CLI defaults are stable and explicit overrides remain exact", {
  helpers <- c(
    "default_repro_run_paths",
    "resolve_repro_cli_paths",
    "release_candidate_label_v2",
    "run_release_bundle_v2_cli"
  )
  available <- vapply(
    helpers,
    function(name) exists(name, mode = "function", inherits = TRUE),
    logical(1)
  )
  expect_true(all(available))
  if (!all(available)) {
    return(invisible())
  }

  labels <- character()
  builder <- function(release_label) {
    labels <<- c(labels, release_label)
    list(
      release_label = release_label,
      bundle_dir = "bundle",
      checklist_path = "checklist.csv",
      checklist = data.frame(pass = TRUE)
    )
  }
  for (i in seq_len(2L)) {
    status <- suppressMessages(run_release_bundle_v2_cli(character(), builder = builder))
    expect_identical(status, 0L)
  }
  expect_identical(labels, rep(release_candidate_label_v2(), 2L))

  explicit_label <- "v2.0.0-rc1-explicit"
  expect_identical(
    suppressMessages(run_release_bundle_v2_cli(explicit_label, builder = builder)),
    0L
  )
  expect_identical(tail(labels, 1L), explicit_label)

  expected_v1 <- c(
    out_dir = file.path("artefacts", "reproducibility", "external_run_v1"),
    lib_dir = file.path("artefacts", "reproducibility", "external_run_v1_library"),
    targets_store = file.path("artefacts", "reproducibility", "external_run_v1_targets")
  )
  expected_v2 <- c(
    out_dir = file.path("artefacts", "reproducibility", "external_run_v2"),
    lib_dir = file.path("artefacts", "reproducibility", "external_run_v2_library"),
    targets_store = file.path("artefacts", "reproducibility", "external_run_v2_targets")
  )
  expect_identical(resolve_repro_cli_paths(character(), version = "v1"), expected_v1)
  expect_identical(resolve_repro_cli_paths(character(), version = "v1"), expected_v1)
  expect_identical(resolve_repro_cli_paths(character(), version = "v2"), expected_v2)

  explicit <- c(
    out_dir = "/tmp/explicit-output",
    lib_dir = "/tmp/explicit-library",
    targets_store = "/tmp/explicit-targets"
  )
  expect_identical(
    resolve_repro_cli_paths(unname(explicit), version = "v1"),
    explicit
  )
})

test_that("Makefile exposes an isolated non-CRAN retained-heap gate", {
  makefile <- find_source_makefile_for_tests()
  skip_if(is.na(makefile), "No source Makefile available")
  repo_root <- dirname(makefile)

  output <- withr::with_dir(
    repo_root,
    suppressWarnings(system2(
      "make",
      c("-n", "test-memory", "R=/selected/R"),
      stdout = TRUE,
      stderr = TRUE
    ))
  )
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  command <- paste(output, collapse = "\n")

  expect_identical(as.integer(status), 0L)
  expect_match(command, "NOT_CRAN=true", fixed = TRUE)
  expect_match(command, "tests/testthat/test_memory_usage.R", fixed = TRUE)
  expect_match(command, "stop_on_failure = TRUE", fixed = TRUE)
  expect_false(grepl("test_dir", command, fixed = TRUE))
})

test_that("Make shared-runtime gate handles spaces and rejects mismatches", {
  skip_on_os("windows")
  makefile <- find_source_makefile_for_tests()
  skip_if(is.na(makefile), "No source Makefile available")
  repo_root <- dirname(makefile)
  tmp_dir <- tempfile(pattern = "runtime path with spaces ")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  r_path <- file.path(tmp_dir, "R")
  rscript_path <- file.path(tmp_dir, "Rscript")
  expect_true(file.symlink(file.path(R.home("bin"), "R"), r_path))
  expect_true(file.symlink(file.path(R.home("bin"), "Rscript"), rscript_path))

  matching <- withr::with_dir(
    repo_root,
    suppressWarnings(system2(
      "make",
      c(
        "assert-r-runtime",
        shQuote(paste0("R=", r_path)),
        shQuote(paste0("RSCRIPT=", rscript_path))
      ),
      stdout = TRUE,
      stderr = TRUE
    ))
  )
  matching_status <- attr(matching, "status")
  if (is.null(matching_status)) matching_status <- 0L
  expect_identical(as.integer(matching_status), 0L)

  fake_r <- file.path(tmp_dir, "mismatched-r")
  writeLines(c("#!/bin/sh", "printf '%s\\n' '/different/R/home'"), fake_r)
  Sys.chmod(fake_r, mode = "0755")
  mismatch <- withr::with_dir(
    repo_root,
    suppressWarnings(system2(
      "make",
      c(
        "assert-r-runtime",
        shQuote(paste0("R=", fake_r)),
        shQuote(paste0("RSCRIPT=", rscript_path))
      ),
      stdout = TRUE,
      stderr = TRUE
    ))
  )
  mismatch_status <- attr(mismatch, "status")
  if (is.null(mismatch_status)) mismatch_status <- 0L
  expect_gt(as.integer(mismatch_status), 0L)
  expect_match(paste(mismatch, collapse = "\n"), "does not match", fixed = TRUE)
})

test_that("default Make runtime reaches the replay wrapper as an absolute path", {
  skip_on_os("windows")
  skip_if(
    !is.na(find_check_root_for_tests()),
    "R CMD check wraps the child R command"
  )

  makefile <- find_source_makefile_for_tests()
  skip_if(is.na(makefile), "No source Makefile available")
  repo_root <- dirname(makefile)
  tmp_dir <- tempfile(pattern = "make-default-runtime-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  capture_path <- file.path(tmp_dir, "captured-r.txt")
  proxy_rscript <- file.path(tmp_dir, "Rscript-proxy")
  writeLines(
    c(
      "#!/bin/sh",
      "if [ \"$1\" = \"--vanilla\" ]; then",
      sprintf("  exec %s \"$@\"", shQuote(file.path(R.home("bin"), "Rscript"))),
      "fi",
      sprintf(
        "printf '%%s\\n' \"$HERBIVORETTR_R_EXECUTABLE\" > %s",
        shQuote(capture_path)
      )
    ),
    proxy_rscript
  )
  Sys.chmod(proxy_rscript, mode = "0755")

  hostile_r_tests <- file.path(tmp_dir, "hostile-r-tests.R")
  writeLines("quit(save = 'no', status = 7L)", hostile_r_tests)
  result <- withr::with_envvar(
    c(R_TESTS = hostile_r_tests),
    withr::with_envvar(
      c(R = NA_character_, R_TESTS = NA_character_),
      withr::with_dir(
        repo_root,
        suppressWarnings(system2(
          "make",
          c("repro-check", shQuote(paste0("RSCRIPT=", proxy_rscript))),
          stdout = TRUE,
          stderr = TRUE
        ))
      )
    )
  )
  status <- attr(result, "status")
  if (is.null(status)) status <- 0L
  expected_r <- normalizePath(unname(Sys.which("R")), winslash = "/", mustWork = TRUE)

  expect_identical(
    as.integer(status),
    0L,
    info = paste(result, collapse = "\n")
  )
  capture_exists <- file.exists(capture_path)
  expect_true(capture_exists)
  if (identical(as.integer(status), 0L) && capture_exists) {
    expect_identical(readLines(capture_path, warn = FALSE), expected_r)
  }
})

test_that("automation disables pak without changing the R compatibility pin", {
  repo_root <- repo_root_for_tests()
  workflow_paths <- file.path(
    repo_root,
    ".github",
    "workflows",
    c("ci.yml", "nightly.yml", "weekly_repro.yml")
  )
  skip_if(
    all(!file.exists(workflow_paths)),
    "GitHub workflows are excluded from built source packages."
  )

  for (workflow_path in workflow_paths) {
    workflow <- yaml::read_yaml(workflow_path)
    expect_identical(
      workflow$env$RENV_CONFIG_PAK_ENABLED,
      "FALSE",
      info = basename(workflow_path)
    )

    script <- paste(readLines(workflow_path, warn = FALSE), collapse = "\n")
    pins <- regmatches(
      script,
      gregexpr('r-version: "[^"]+"', script, perl = TRUE)
    )[[1]]
    expect_gt(length(pins), 0L)
    expect_true(
      all(pins == 'r-version: "4.5.3"'),
      info = basename(workflow_path)
    )
  }
})

test_that("weekly replay uploads its named fresh output directory", {
  workflow_path <- file.path(
    repo_root_for_tests(),
    ".github",
    "workflows",
    "weekly_repro.yml"
  )
  skip_if(
    !file.exists(workflow_path),
    "GitHub workflows are excluded from built source packages."
  )

  workflow <- paste(readLines(workflow_path, warn = FALSE), collapse = "\n")
  expect_match(
    workflow,
    "REPRO_V2_OUT_DIR: artefacts/reproducibility/weekly_repro_v2",
    fixed = TRUE
  )
  expect_match(
    workflow,
    'Rscript scripts/run_external_repro_check_v2.R "$REPRO_V2_OUT_DIR" "$REPRO_V2_LIB_DIR" "$REPRO_V2_TARGETS_STORE"',
    fixed = TRUE
  )
  expect_match(
    workflow,
    "artefacts/reproducibility/weekly_repro_v2/**",
    fixed = TRUE
  )
  expect_false(grepl("external_run_v2/**", workflow, fixed = TRUE))
})
