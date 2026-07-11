test_that("v2 paper renderer produces html and checksum manifest", {
  skip_on_cran()

  tmp_qmd <- tempfile(fileext = ".qmd")
  tmp_out <- tempfile(pattern = "paper-v2-out-")
  dir.create(tmp_out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(c(tmp_qmd, tmp_out), recursive = TRUE, force = TRUE), add = TRUE)

  writeLines(
    c(
      "---",
      "title: \"Smoke v2\"",
      "format: html",
      "---",
      "",
      "v2 report body."
    ),
    tmp_qmd
  )

  out <- render_paper_pipeline_report_v2(
    input = tmp_qmd,
    output_dir = tmp_out,
    input_files = tmp_qmd
  )
  expect_true(file.exists(out$html))
  expect_true(file.exists(out$manifest_path))
})

test_that("report rendering can execute from the repository root", {
  skip_on_cran()

  tmp_root <- tempfile(pattern = "paper-v2-root-")
  input_dir <- file.path(tmp_root, "reports")
  data_dir <- file.path(tmp_root, "artefacts")
  output_dir <- file.path(tmp_root, "output")
  dir.create(input_dir, recursive = TRUE)
  dir.create(data_dir, recursive = TRUE)
  on.exit(unlink(tmp_root, recursive = TRUE, force = TRUE), add = TRUE)

  utils::write.csv(
    data.frame(signal = "root-visible-signal"),
    file.path(data_dir, "input.csv"),
    row.names = FALSE
  )
  input <- file.path(input_dir, "root-report.qmd")
  writeLines(
    c(
      "---",
      "title: \"Root report\"",
      "format: html",
      "---",
      "",
      "```{r}",
      "x <- read.csv('artefacts/input.csv')",
      "cat(x$signal[[1]])",
      "```"
    ),
    input
  )

  html <- render_quarto_report_internal(
    input = input,
    output_dir = output_dir,
    execute_dir = tmp_root
  )
  expect_match(paste(readLines(html, warn = FALSE), collapse = "\n"),
               "root-visible-signal", fixed = TRUE)
})

test_that("v2 report content gate requires populated tables for every caption", {
  good_report <- tempfile(fileext = ".html")
  captions_only_report <- tempfile(fileext = ".html")
  missing_report <- tempfile(fileext = ".html")
  on.exit(
    unlink(c(good_report, captions_only_report, missing_report), force = TRUE),
    add = TRUE
  )

  tables <- vapply(
    report_required_content_markers_v2(),
    function(caption) {
      paste0(
        "<table><caption>", caption, "</caption>",
        "<thead><tr><th>metric</th></tr></thead>",
        "<tbody><tr><td>1</td></tr></tbody></table>"
      )
    },
    character(1)
  )
  writeLines(c("<html><body>", tables, "</body></html>"), good_report)
  writeLines(report_required_content_markers_v2(), captions_only_report)
  writeLines(
    c("<html><body>", tables, "Experiment A v2 summary is missing.", "</body></html>"),
    missing_report
  )

  expect_true(check_report_content_v2(good_report))
  expect_false(check_report_content_v2(captions_only_report))
  expect_false(check_report_content_v2(missing_report))
  expect_false(check_report_content_v2(tempfile(fileext = ".html")))
})

test_that("v2 report content ignores caption attributes and whitespace entities", {
  attribute_report <- tempfile(fileext = ".html")
  entity_report <- tempfile(fileext = ".html")
  quoted_attribute_report <- tempfile(fileext = ".html")
  numeric_entity_report <- tempfile(fileext = ".html")
  on.exit(unlink(
    c(
      attribute_report,
      entity_report,
      quoted_attribute_report,
      numeric_entity_report
    ),
    force = TRUE
  ), add = TRUE)

  markers <- report_required_content_markers_v2()
  attribute_tables <- vapply(seq_along(markers), function(i) {
    caption <- if (i == 1L) {
      sprintf('<caption data-marker="%s">Different caption</caption>', markers[[i]])
    } else {
      paste0("<caption>", markers[[i]], "</caption>")
    }
    paste0(
      "<table>", caption,
      "<tbody><tr><td>1</td></tr></tbody></table>"
    )
  }, character(1))
  writeLines(c("<html><body>", attribute_tables, "</body></html>"), attribute_report)

  whitespace_entities <- c("&nbsp;", "&#160;", "&#xA0;")
  entity_tables <- vapply(seq_along(markers), function(i) {
    paste0(
      "<table><caption>", markers[[i]], "</caption>",
      "<tbody><tr><td>",
      whitespace_entities[[(i - 1L) %% length(whitespace_entities) + 1L]],
      "</td></tr></tbody></table>"
    )
  }, character(1))
  writeLines(c("<html><body>", entity_tables, "</body></html>"), entity_report)

  quoted_attribute_tables <- vapply(seq_along(markers), function(i) {
    caption <- if (i == 1L) {
      sprintf('<caption title=">%s">Different caption</caption>', markers[[i]])
    } else {
      paste0("<caption>", markers[[i]], "</caption>")
    }
    paste0(
      "<table>", caption,
      "<tbody><tr><td>1</td></tr></tbody></table>"
    )
  }, character(1))
  writeLines(
    c("<html><body>", quoted_attribute_tables, "</body></html>"),
    quoted_attribute_report
  )

  numeric_whitespace_entities <- c("&#32;", "&#x20;", "&#000032;", "&#X0020;")
  numeric_entity_tables <- vapply(seq_along(markers), function(i) {
    paste0(
      "<table><caption>", markers[[i]], "</caption>",
      "<tbody><tr><td>",
      numeric_whitespace_entities[
        (i - 1L) %% length(numeric_whitespace_entities) + 1L
      ],
      "</td></tr></tbody></table>"
    )
  }, character(1))
  writeLines(
    c("<html><body>", numeric_entity_tables, "</body></html>"),
    numeric_entity_report
  )

  expect_false(check_report_content_v2(attribute_report))
  expect_false(check_report_content_v2(entity_report))
  expect_false(check_report_content_v2(quoted_attribute_report))
  expect_false(check_report_content_v2(numeric_entity_report))
})

test_that("v2 report manifest declares every report source and data input", {
  source_input <- file.path("reports", "paper_pipeline_v2.qmd")
  expected_generated <- c(
    experiment_a_summary = file.path("artefacts", "canonical_runs", "experiment_a_presence_removal_v2", "experiment_a_summary_v2.csv"),
    experiment_a_delta = file.path("artefacts", "canonical_runs", "experiment_a_presence_removal_v2", "experiment_a_delta_ensemble_v2.csv"),
    experiment_a_claims = file.path("artefacts", "canonical_runs", "experiment_a_presence_removal_v2", "experiment_a_claims_v2.csv"),
    experiment_a_summary_units = file.path("artefacts", "canonical_runs", "experiment_a_presence_removal_v2", "experiment_a_summary_v2_units.csv"),
    experiment_c_summary = file.path("artefacts", "canonical_runs", "experiment_c_aridity_gradient_v2", "experiment_c_summary_v2.csv"),
    experiment_c_claims = file.path("artefacts", "canonical_runs", "experiment_c_aridity_gradient_v2", "experiment_c_claims_v2.csv"),
    experiment_c_summary_units = file.path("artefacts", "canonical_runs", "experiment_c_aridity_gradient_v2", "experiment_c_summary_v2_units.csv"),
    pilot = file.path("artefacts", "validation", "pilot_benchmark_v1", "pilot_metrics_summary_v1.csv"),
    stability = file.path("artefacts", "stability", "long_horizon_v1", "stability_summary_v1.csv"),
    experiment_a_figure = file.path("artefacts", "canonical_runs", "experiment_a_presence_removal_v2", "experiment_a_presence_removal_v2.png"),
    experiment_c_figure = file.path("artefacts", "canonical_runs", "experiment_c_aridity_gradient_v2", "experiment_c_aridity_gradient_v2.png")
  )

  expect_identical(
    paper_pipeline_generated_input_files_v2(),
    expected_generated
  )
  expect_identical(
    paper_pipeline_input_files_v2(),
    c(source_input, unname(expected_generated))
  )
  expect_false(anyDuplicated(paper_pipeline_input_files_v2()) > 0L)
})

test_that("report input hash attests file content and fails closed on missing inputs", {
  tmp_dir <- tempfile(pattern = "manifest-v2-input-hash-")
  artifact_dir <- file.path(tmp_dir, "artifacts")
  input_dir <- file.path(tmp_dir, "inputs")
  dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(input_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  writeLines("<html><body>report</body></html>", file.path(artifact_dir, "report.html"))
  qmd_path <- file.path(input_dir, "report.qmd")
  csv_path <- file.path(input_dir, "table.csv")
  image_path <- file.path(input_dir, "figure.png")
  writeLines("report source", qmd_path)
  writeLines(c("value", "1"), csv_path)
  writeBin(charToRaw("image-v1"), image_path)
  inputs <- c(qmd_path, csv_path, image_path)

  first_manifest <- file.path(tmp_dir, "first.csv")
  second_manifest <- file.path(tmp_dir, "second.csv")
  write_report_artifact_manifest_v2(
    output_dir = artifact_dir,
    input_files = inputs,
    manifest_path = first_manifest
  )
  first <- utils::read.csv(first_manifest, stringsAsFactors = FALSE)

  writeLines(c("value", "2"), csv_path)
  write_report_artifact_manifest_v2(
    output_dir = artifact_dir,
    input_files = inputs,
    manifest_path = second_manifest
  )
  second <- utils::read.csv(second_manifest, stringsAsFactors = FALSE)

  expect_length(unique(first$input_files_hash), 1L)
  expect_match(first$input_files_hash[[1]], "^[0-9a-f]{32}$")
  expect_false(identical(first$input_files_hash, second$input_files_hash))
  expect_error(
    write_report_artifact_manifest_v2(
      output_dir = artifact_dir,
      input_files = c(inputs, file.path(input_dir, "missing.csv")),
      manifest_path = file.path(tmp_dir, "missing.csv")
    ),
    class = "herbivoreTTR_report_manifest_input_missing"
  )
})

test_that("report input hash binds normalized file identity and content", {
  tmp_dir <- tempfile(pattern = "manifest-v2-input-identity-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  first_path <- file.path(tmp_dir, "first.csv")
  second_path <- file.path(tmp_dir, "second.csv")
  writeLines(c("value", "identical"), first_path)
  writeLines(c("value", "identical"), second_path)

  expect_identical(hash_file_md5(first_path), hash_file_md5(second_path))
  expect_false(identical(
    hash_report_input_files_v2(first_path),
    hash_report_input_files_v2(second_path)
  ))
})

report_manifest_fixture_v2 <- function(artifact_ids,
                                       checksums = rep(strrep("a", 32L), length(artifact_ids))) {
  data.frame(
    artifact_id = artifact_ids,
    path = file.path("unavailable", artifact_ids),
    checksum_md5 = checksums,
    bytes = rep(1, length(artifact_ids)),
    modified_utc = rep("2026-07-11T00:00:00Z", length(artifact_ids)),
    input_files_hash = rep(strrep("b", 32L), length(artifact_ids)),
    stringsAsFactors = FALSE
  )
}

test_that("report manifest comparison detects deterministic rebuilds", {
  tmp_dir <- tempfile(pattern = "manifest-v2-")
  artifact_dir <- file.path(tmp_dir, "artifacts")
  dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  html_path <- file.path(artifact_dir, "report.html")
  csv_path <- file.path(artifact_dir, "table.csv")
  writeLines("<html><body>test</body></html>", html_path)
  utils::write.csv(data.frame(x = 1:3), csv_path, row.names = FALSE)

  m1 <- file.path(tmp_dir, "manifest_1.csv")
  m2 <- file.path(tmp_dir, "manifest_2.csv")
  write_report_artifact_manifest_v2(output_dir = artifact_dir, manifest_path = m1)
  write_report_artifact_manifest_v2(output_dir = artifact_dir, manifest_path = m2)

  cmp <- check_report_manifest_determinism_v2(m1, m2)
  expect_true(all(cmp$matches))
})

test_that("report manifest excludes its own output from artefact rows", {
  tmp_dir <- tempfile(pattern = "manifest-v2-self-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  writeLines("<html><body>test</body></html>", file.path(tmp_dir, "report.html"))
  manifest_path <- file.path(tmp_dir, "figure_table_manifest_v2.csv")
  writeLines("stale manifest", manifest_path)

  write_report_artifact_manifest_v2(
    output_dir = tmp_dir,
    manifest_path = manifest_path
  )

  manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE)
  expect_false(basename(manifest_path) %in% manifest$artifact_id)
})

test_that("report manifest comparison rejects unequal artefact ID sets", {
  tmp_dir <- tempfile(pattern = "manifest-v2-sets-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  current_path <- file.path(tmp_dir, "current.csv")
  previous_path <- file.path(tmp_dir, "previous.csv")
  utils::write.csv(
    report_manifest_fixture_v2(
      c("report.html", "table.csv"),
      c(strrep("a", 32L), strrep("c", 32L))
    ),
    current_path,
    row.names = FALSE
  )
  utils::write.csv(
    report_manifest_fixture_v2("report.html"),
    previous_path,
    row.names = FALSE
  )

  expect_error(
    check_report_manifest_determinism_v2(current_path, previous_path),
    class = "herbivoreTTR_report_manifest_artifact_set_mismatch"
  )
})

test_that("report manifest comparison rejects duplicate artefact IDs", {
  tmp_dir <- tempfile(pattern = "manifest-v2-duplicates-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  current_path <- file.path(tmp_dir, "current.csv")
  previous_path <- file.path(tmp_dir, "previous.csv")
  utils::write.csv(
    report_manifest_fixture_v2(c("report.html", "report.html")),
    current_path,
    row.names = FALSE
  )
  utils::write.csv(
    report_manifest_fixture_v2("report.html"),
    previous_path,
    row.names = FALSE
  )

  expect_error(
    check_report_manifest_determinism_v2(current_path, previous_path),
    class = "herbivoreTTR_report_manifest_duplicate_id"
  )
})

test_that("report manifest validation fails closed on malformed input", {
  malformed_path <- tempfile(fileext = ".csv")
  on.exit(unlink(malformed_path, force = TRUE), add = TRUE)
  utils::write.csv(data.frame(unrelated = "value"), malformed_path, row.names = FALSE)

  expect_error(
    validate_report_artifact_manifest_v2(malformed_path),
    class = "herbivoreTTR_report_manifest_malformed"
  )
})

test_that("manifest comparator validates full schema without requiring artefact files", {
  tmp_dir <- tempfile(pattern = "manifest-v2-comparator-schema-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  valid <- report_manifest_fixture_v2("report.html")
  valid_path <- file.path(tmp_dir, "valid.csv")
  utils::write.csv(valid, valid_path, row.names = FALSE)
  expect_true(all(check_report_manifest_determinism_v2(valid_path, valid_path)$matches))

  malformed <- list(
    missing_schema_field = valid[, setdiff(names(valid), "bytes"), drop = FALSE],
    empty_path = transform(valid, path = ""),
    invalid_checksum = transform(valid, checksum_md5 = "not-md5"),
    invalid_bytes = transform(valid, bytes = -1),
    invalid_modified = transform(valid, modified_utc = "yesterday"),
    invalid_input_hash = transform(valid, input_files_hash = "not-md5")
  )
  for (case in names(malformed)) {
    malformed_path <- file.path(tmp_dir, paste0(case, ".csv"))
    utils::write.csv(malformed[[case]], malformed_path, row.names = FALSE)
    expect_error(
      check_report_manifest_determinism_v2(malformed_path, valid_path),
      class = "herbivoreTTR_report_manifest_malformed",
      info = case
    )
  }
})

test_that("report manifest writer rejects duplicate basenames", {
  tmp_dir <- tempfile(pattern = "manifest-v2-duplicate-files-")
  dir.create(file.path(tmp_dir, "a"), recursive = TRUE)
  dir.create(file.path(tmp_dir, "b"), recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)
  writeLines("first", file.path(tmp_dir, "a", "report.html"))
  writeLines("second", file.path(tmp_dir, "b", "report.html"))

  expect_error(
    write_report_artifact_manifest_v2(output_dir = tmp_dir),
    class = "herbivoreTTR_report_manifest_duplicate_id"
  )
})
