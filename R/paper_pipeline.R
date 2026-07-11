# Quarto paper-pipeline rendering helpers.

#' Internal Quarto render helper for paper pipeline reports
#' @param input Path to the `.qmd` report source.
#' @param output_dir Directory where rendered outputs are written.
#' @param execute_dir Working directory used by report code chunks.
#' @return Absolute path to the rendered HTML report.
#' @keywords internal
#' @noRd
render_quarto_report_internal <- function(input,
                                          output_dir,
                                          execute_dir = getwd()) {
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
  execute_dir_abs <- normalizePath(execute_dir, winslash = "/", mustWork = TRUE)

  cmd <- "quarto"
  args <- c(
    "render",
    input_abs,
    "--output-dir",
    output_dir_abs,
    "--execute-dir",
    execute_dir_abs
  )
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

#' Render the paper pipeline Quarto report from existing artefacts
#'
#' @param input Path to the `.qmd` report source.
#' @param output_dir Directory where rendered outputs are written.
#'
#' @return Absolute path to the rendered HTML report.
#' @export
render_paper_pipeline_report <- function(input = file.path("reports", "paper_pipeline.qmd"),
                                         output_dir = file.path("artefacts", "reports")) {
  render_quarto_report_internal(input = input, output_dir = output_dir)
}

paper_pipeline_input_files_v2 <- function(
    input = file.path("reports", "paper_pipeline_v2.qmd")) {
  c(input, unname(paper_pipeline_generated_input_files_v2()))
}

#' Render the post-1.0 paper pipeline report and write deterministic manifest
#'
#' @param input Path to the v2 `.qmd` report source.
#' @param output_dir Directory where rendered outputs are written.
#' @param create_manifest Logical; when `TRUE`, write checksum manifest.
#'
#' @return List with rendered html path and manifest path.
render_paper_pipeline_report_v2 <- function(input = file.path("reports", "paper_pipeline_v2.qmd"),
                                            output_dir = file.path("artefacts", "reports_v2"),
                                            create_manifest = TRUE) {
  html <- render_quarto_report_internal(input = input, output_dir = output_dir)
  manifest_path <- NULL
  if (isTRUE(create_manifest)) {
    manifest_path <- write_report_artifact_manifest_v2(
      output_dir = output_dir,
      input_files = paper_pipeline_input_files_v2(input)
    )
  }
  list(
    html = html,
    manifest_path = manifest_path
  )
}
