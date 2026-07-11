test_that("release v2 expected outputs point at the current v2 artefact set", {
  outputs <- release_expected_outputs_v2()

  expect_true(is.character(outputs))
  expect_false(anyDuplicated(outputs) > 0)
  expect_true(any(grepl("experiment_a_presence_removal_v2", outputs, fixed = TRUE)))
  expect_true(any(grepl("experiment_c_aridity_gradient_v2", outputs, fixed = TRUE)))
  expect_true(any(grepl("post_v1_scaling_v2/scaling_summary_v1.csv", outputs, fixed = TRUE)))
  expect_true(any(grepl("reports_v2/paper_pipeline_v2.html", outputs, fixed = TRUE)))
})

test_that("release v2 bundle doc references exist in a source checkout", {
  repo_root <- scenario_find_repo_root(getwd())
  skip_if(is.null(repo_root), "Repo root not detectable in this test context.")
  skip_if(
    !dir.exists(file.path(repo_root, "docs")),
    "Release documentation is excluded from built source packages."
  )

  docs_to_copy <- release_bundle_docs_v2()
  expect_true(all(file.exists(file.path(repo_root, docs_to_copy))))
  expect_true(any(grepl("docs/contracts/observational_data_contract_v1.md", docs_to_copy, fixed = TRUE)))
})

test_that("release v2 bundle output dirs reference the v2 scaling artefacts", {
  output_dirs <- release_bundle_output_dirs_v2()

  expect_true(is.character(output_dirs))
  expect_false(anyDuplicated(output_dirs) > 0)
  expect_true(any(grepl("artefacts/benchmarks/post_v1_scaling_v2", output_dirs, fixed = TRUE)))
  expect_true(any(grepl("artefacts/reports_v2", output_dirs, fixed = TRUE)))
})

test_that("external repro v2 script pins the no-pak restore path and v2 scaling artefacts", {
  repo_root <- scenario_find_repo_root(getwd())
  skip_if(is.null(repo_root), "Repo root not detectable in this test context.")

  script_path <- file.path(repo_root, "scripts", "run_external_repro_check_v2.R")
  skip_if_not(file.exists(script_path), "v2 repro script not available in this test context.")

  script <- paste(readLines(script_path, warn = FALSE), collapse = "\n")
  expect_match(script, "RENV_CONFIG_PAK_ENABLED=FALSE", fixed = TRUE)
  expect_match(script, "scenario_slug = 'post_v1_scaling_v2'", fixed = TRUE)
  expect_match(script, "v2_replay_suite_owned_paths", fixed = TRUE)
  expect_true(any(grepl(
    "artefacts/benchmarks/post_v1_scaling_v2/scaling_summary_v1.csv",
    v2_replay_suite_owned_paths(),
    fixed = TRUE
  )))
})

make_copied_report_manifest_fixture_v2 <- function(root) {
  live_dir <- file.path(root, "live", "reports_v2")
  bundle_outputs <- file.path(root, "bundle", "outputs")
  dir.create(live_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(bundle_outputs, recursive = TRUE, showWarnings = FALSE)

  writeLines(
    "<html><body><table><tbody><tr><td>1</td></tr></tbody></table></body></html>",
    file.path(live_dir, "paper_pipeline_v2.html")
  )
  write_report_artifact_manifest_v2(output_dir = live_dir)

  copied_dir <- copy_release_dir_v1(live_dir, bundle_outputs)
  copied_manifest <- file.path(copied_dir, "figure_table_manifest_v2.csv")
  rebase_copied_report_manifest_v2(copied_manifest)
  unlink(file.path(root, "live"), recursive = TRUE, force = TRUE)
  copied_manifest
}

test_that("copied release report manifest remains valid after bundle relocation", {
  tmp_dir <- tempfile(pattern = "release-v2-report-relocation-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  copied_manifest <- make_copied_report_manifest_fixture_v2(tmp_dir)
  relocated_bundle <- file.path(tmp_dir, "relocated-bundle")
  expect_true(file.rename(file.path(tmp_dir, "bundle"), relocated_bundle))
  relocated_manifest <- file.path(
    relocated_bundle,
    "outputs",
    "reports_v2",
    basename(copied_manifest)
  )

  manifest <- utils::read.csv(relocated_manifest, stringsAsFactors = FALSE)
  expect_true(all(startsWith(manifest$path, "./")))
  expect_true(check_copied_report_manifest_v2(relocated_manifest))
})

test_that("release checklist rejects every copied report manifest tamper", {
  tamper_cases <- c("path", "checksum", "size", "file")

  for (tamper in tamper_cases) {
    tmp_dir <- tempfile(pattern = paste0("release-v2-report-", tamper, "-"))
    dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
    copied_manifest <- make_copied_report_manifest_fixture_v2(tmp_dir)
    manifest <- utils::read.csv(copied_manifest, stringsAsFactors = FALSE)

    if (identical(tamper, "path")) {
      manifest$path[[1]] <- "./wrong-report.html"
      utils::write.csv(manifest, copied_manifest, row.names = FALSE)
    } else if (identical(tamper, "checksum")) {
      manifest$checksum_md5[[1]] <- strrep("0", 32L)
      utils::write.csv(manifest, copied_manifest, row.names = FALSE)
    } else if (identical(tamper, "size")) {
      manifest$bytes[[1]] <- manifest$bytes[[1]] + 1
      utils::write.csv(manifest, copied_manifest, row.names = FALSE)
    } else {
      artifact_path <- file.path(
        dirname(copied_manifest),
        sub("^[.]/", "", manifest$path[[1]])
      )
      unlink(artifact_path, force = TRUE)
    }

    tarball <- file.path(tmp_dir, "herbivoreTTR_2.0.0.tar.gz")
    writeLines("fixture", tarball)
    checklist <- suppressMessages(run_release_checklist_v2(
      package_tarball = tarball,
      copied_report_manifest_path = copied_manifest
    ))
    copied_check <- checklist[
      checklist$item == "copied_v2_report_manifest_valid",
      ,
      drop = FALSE
    ]
    expect_equal(nrow(copied_check), 1L, info = tamper)
    expect_false(copied_check$pass[[1]], info = tamper)

    unlink(tmp_dir, recursive = TRUE, force = TRUE)
  }
})
