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

  out <- render_paper_pipeline_report_v2(input = tmp_qmd, output_dir = tmp_out)
  expect_true(file.exists(out$html))
  expect_true(file.exists(out$manifest_path))
})

test_that("report manifest comparison detects deterministic rebuilds", {
  tmp_dir <- tempfile(pattern = "manifest-v2-")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  html_path <- file.path(tmp_dir, "report.html")
  csv_path <- file.path(tmp_dir, "table.csv")
  writeLines("<html><body>test</body></html>", html_path)
  utils::write.csv(data.frame(x = 1:3), csv_path, row.names = FALSE)

  m1 <- file.path(tmp_dir, "manifest_1.csv")
  m2 <- file.path(tmp_dir, "manifest_2.csv")
  write_report_artifact_manifest_v2(output_dir = tmp_dir, manifest_path = m1)
  write_report_artifact_manifest_v2(output_dir = tmp_dir, manifest_path = m2)

  cmp <- check_report_manifest_determinism_v2(m1, m2)
  expect_true(all(cmp$matches))
})
