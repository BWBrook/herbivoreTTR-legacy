# Quarto paper-pipeline rendering helpers.

render_paper_pipeline_report <- function(input = file.path("reports", "paper_pipeline.qmd"),
                                         output_dir = file.path("artefacts", "reports")) {
  if (!file.exists(input)) {
    rlang::abort(
      "Paper pipeline input `.qmd` does not exist.",
      class = "herbivoreTTR_paper_qmd_missing",
      input = input
    )
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  input_abs <- normalizePath(input, winslash = "/", mustWork = TRUE)
  output_dir_abs <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)

  cmd <- "quarto"
  args <- c("render", input_abs, "--output-dir", output_dir_abs)
  status <- tryCatch(
    system2(cmd, args = args, stdout = TRUE, stderr = TRUE),
    error = function(e) {
      rlang::abort(
        "Failed to execute `quarto render`.",
        class = "herbivoreTTR_paper_quarto_exec_failed",
        parent = e
      )
    }
  )

  status_code <- attr(status, "status")
  if (!is.null(status_code) && status_code != 0) {
    rlang::abort(
      "`quarto render` returned a non-zero exit status.",
      class = "herbivoreTTR_paper_quarto_nonzero",
      output = status
    )
  }

  output_file <- file.path(
    output_dir_abs,
    sub("\\.qmd$", ".html", basename(input))
  )

  if (!file.exists(output_file)) {
    rlang::abort(
      "Paper pipeline HTML output was not produced.",
      class = "herbivoreTTR_paper_output_missing",
      output_file = output_file
    )
  }

  output_file
}
