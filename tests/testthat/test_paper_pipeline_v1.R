test_that("paper pipeline renderer executes quarto for qmd input", {
  skip_on_cran()

  tmp_qmd <- tempfile(fileext = ".qmd")
  tmp_out <- tempfile(pattern = "paper-out-")
  dir.create(tmp_out, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(c(tmp_qmd, tmp_out), recursive = TRUE, force = TRUE), add = TRUE)

  writeLines(
    c(
      "---",
      "title: \"Smoke Paper\"",
      "format: html",
      "---",
      "",
      "Smoke report body."
    ),
    tmp_qmd
  )

  out <- render_paper_pipeline_report(input = tmp_qmd, output_dir = tmp_out)
  expect_true(file.exists(out))
})
