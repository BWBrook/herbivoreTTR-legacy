# Compiled-path throughput appendix helpers (compiled on/off and break-even).

compiled_throughput_modes_v1 <- function() {
  c("pure_r", "compiled_resistance", "compiled_all_available")
}

compiled_mode_backend_v1 <- function(mode) {
  if (identical(mode, "pure_r")) {
    return("internal_ttr")
  }
  "internal_ttr_compiled"
}

with_compiled_mode_context_v1 <- function(mode,
                                          expr) {
  selected <- match.arg(as.character(mode[[1]]), choices = compiled_throughput_modes_v1())

  old_ttr_opt <- getOption("herbivoreTTR.use_compiled_ttr", NULL)
  old_minute_opt <- getOption("herbivoreTTR.use_compiled_minute_loop", NULL)
  old_ttr_env <- Sys.getenv("HERBIVORETTR_USE_COMPILED_TTR", unset = NA_character_)
  old_minute_env <- Sys.getenv("HERBIVORETTR_USE_COMPILED_MINUTE_LOOP", unset = NA_character_)

  on.exit({
    if (is.null(old_ttr_opt)) {
      options(herbivoreTTR.use_compiled_ttr = NULL)
    } else {
      options(herbivoreTTR.use_compiled_ttr = old_ttr_opt)
    }
    if (is.null(old_minute_opt)) {
      options(herbivoreTTR.use_compiled_minute_loop = NULL)
    } else {
      options(herbivoreTTR.use_compiled_minute_loop = old_minute_opt)
    }

    if (is.na(old_ttr_env)) {
      Sys.unsetenv("HERBIVORETTR_USE_COMPILED_TTR")
    } else {
      Sys.setenv(HERBIVORETTR_USE_COMPILED_TTR = old_ttr_env)
    }
    if (is.na(old_minute_env)) {
      Sys.unsetenv("HERBIVORETTR_USE_COMPILED_MINUTE_LOOP")
    } else {
      Sys.setenv(HERBIVORETTR_USE_COMPILED_MINUTE_LOOP = old_minute_env)
    }
  }, add = TRUE)

  use_ttr <- !identical(selected, "pure_r")
  use_minute <- identical(selected, "compiled_all_available")
  options(herbivoreTTR.use_compiled_ttr = use_ttr)
  options(herbivoreTTR.use_compiled_minute_loop = use_minute)
  Sys.setenv(HERBIVORETTR_USE_COMPILED_TTR = if (use_ttr) "1" else "0")
  Sys.setenv(HERBIVORETTR_USE_COMPILED_MINUTE_LOOP = if (use_minute) "1" else "0")
  reset_compiled_ttr_kernel_v1()

  force(expr)
}

normalise_compiled_size_profiles_v1 <- function(size_profiles = NULL) {
  if (is.null(size_profiles)) {
    return(data.frame(
      profile_id = c("small", "medium", "large"),
      days = c(7L, 10L, 14L),
      minute_limit = c(60L, 120L, 180L),
      stringsAsFactors = FALSE
    ))
  }

  if (!is.data.frame(size_profiles)) {
    rlang::abort(
      "Argument `size_profiles` must be NULL or a data.frame.",
      class = "herbivoreTTR_compiled_profiles_invalid"
    )
  }
  required <- c("profile_id", "days", "minute_limit")
  if (!all(required %in% names(size_profiles))) {
    rlang::abort(
      "Argument `size_profiles` is missing required columns.",
      class = "herbivoreTTR_compiled_profiles_invalid",
      required = required
    )
  }

  out <- size_profiles[, required, drop = FALSE]
  out$profile_id <- as.character(out$profile_id)
  out$days <- as.integer(out$days)
  out$minute_limit <- as.integer(out$minute_limit)
  if (any(!nzchar(out$profile_id)) || any(!is.finite(out$days)) || any(!is.finite(out$minute_limit)) ||
      any(out$days < 1L) || any(out$minute_limit < 1L)) {
    rlang::abort(
      "Size profiles must contain non-empty IDs and positive integer day/minute values.",
      class = "herbivoreTTR_compiled_profiles_invalid"
    )
  }
  rownames(out) <- NULL
  out
}

build_compiled_throughput_design_v1 <- function(size_profiles = NULL,
                                                replicate_grid = c(1L, 4L, 8L, 16L, 32L),
                                                modes = compiled_throughput_modes_v1()) {
  profiles <- normalise_compiled_size_profiles_v1(size_profiles)
  reps <- sort(unique(as.integer(replicate_grid)))
  reps <- reps[is.finite(reps) & reps >= 1L]
  if (length(reps) < 1L) {
    rlang::abort(
      "Argument `replicate_grid` must contain at least one positive integer.",
      class = "herbivoreTTR_compiled_replicate_grid_invalid"
    )
  }

  mode_vec <- unique(as.character(modes))
  if (!all(mode_vec %in% compiled_throughput_modes_v1())) {
    rlang::abort(
      "Argument `modes` contains unsupported values.",
      class = "herbivoreTTR_compiled_modes_invalid",
      modes = mode_vec
    )
  }

  design <- expand.grid(
    profile_id = profiles$profile_id,
    replicate_count = reps,
    compiled_mode = mode_vec,
    stringsAsFactors = FALSE
  )
  design <- merge(design, profiles, by = "profile_id", all.x = TRUE, sort = FALSE)
  design <- design[order(design$profile_id, design$replicate_count, design$compiled_mode), , drop = FALSE]
  rownames(design) <- NULL
  design
}

summarise_compiled_break_even_v1 <- function(throughput_df,
                                             min_speedup = 1.05) {
  if (!is.data.frame(throughput_df) || nrow(throughput_df) < 1L) {
    return(data.frame())
  }

  non_pure <- throughput_df[
    throughput_df$compiled_mode != "pure_r" &
      throughput_df$run_status == "ok" &
      is.finite(throughput_df$speedup_vs_pure),
    ,
    drop = FALSE
  ]
  if (nrow(non_pure) < 1L) {
    return(data.frame())
  }

  keys <- unique(non_pure[, c("profile_id", "compiled_mode"), drop = FALSE])
  rows <- vector("list", nrow(keys))
  for (i in seq_len(nrow(keys))) {
    profile <- keys$profile_id[[i]]
    mode <- keys$compiled_mode[[i]]
    df <- non_pure[non_pure$profile_id == profile & non_pure$compiled_mode == mode, , drop = FALSE]
    df <- df[order(df$replicate_count), , drop = FALSE]

    qualifying <- df[df$speedup_vs_pure >= min_speedup, , drop = FALSE]
    break_even <- if (nrow(qualifying) < 1L) NA_integer_ else as.integer(qualifying$replicate_count[[1]])
    max_idx <- which.max(df$speedup_vs_pure)

    rows[[i]] <- data.frame(
      profile_id = profile,
      compiled_mode = mode,
      break_even_replicates = break_even,
      min_speedup_target = as.numeric(min_speedup),
      max_speedup = as.numeric(df$speedup_vs_pure[[max_idx]]),
      replicate_at_max_speedup = as.integer(df$replicate_count[[max_idx]]),
      stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

write_compiled_speedup_plot_v1 <- function(throughput_df,
                                           path) {
  if (!is.data.frame(throughput_df) || nrow(throughput_df) < 1L) {
    return(invisible(FALSE))
  }
  throughput_df <- throughput_df[
    throughput_df$run_status == "ok" &
      is.finite(throughput_df$speedup_vs_pure),
    ,
    drop = FALSE
  ]
  if (nrow(throughput_df) < 1L) {
    return(invisible(FALSE))
  }

  profiles <- unique(throughput_df$profile_id)
  n_panels <- length(profiles)
  grDevices::png(path, width = 1200, height = max(900, 340 * n_panels))
  on.exit(grDevices::dev.off(), add = TRUE)
  old_par <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(old_par), add = TRUE)

  graphics::par(mfrow = c(n_panels, 1), mar = c(4.2, 4.2, 2.5, 1.2))
  mode_colors <- c(
    pure_r = "#4C78A8",
    compiled_resistance = "#59A14F",
    compiled_all_available = "#F28E2B"
  )

  for (profile in profiles) {
    df <- throughput_df[throughput_df$profile_id == profile, , drop = FALSE]
    reps <- sort(unique(df$replicate_count))
    y_max <- max(df$speedup_vs_pure, 1, na.rm = TRUE)
    graphics::plot(
      x = reps,
      y = rep(1, length(reps)),
      type = "n",
      ylim = c(0.8, y_max * 1.05),
      xlab = "Replicate count",
      ylab = "Speedup vs pure R",
      main = sprintf("Compiled speedup profile: %s", profile)
    )
    graphics::abline(h = 1, lty = 2, col = "gray60")

    modes <- unique(df$compiled_mode)
    for (mode in modes) {
      mdf <- df[df$compiled_mode == mode, , drop = FALSE]
      mdf <- mdf[order(mdf$replicate_count), , drop = FALSE]
      graphics::lines(
        x = mdf$replicate_count,
        y = mdf$speedup_vs_pure,
        type = "b",
        lwd = 2,
        pch = 16,
        col = mode_colors[[mode]]
      )
    }
    graphics::legend(
      "topleft",
      legend = modes,
      col = unname(mode_colors[modes]),
      lty = 1,
      pch = 16,
      bty = "n"
    )
  }

  invisible(TRUE)
}

render_compiled_appendix_qmd_v1 <- function(run_dir,
                                            matrix_path,
                                            break_even_path) {
  matrix_file <- basename(matrix_path)
  break_even_file <- basename(break_even_path)
  qmd_path <- file.path(run_dir, "compiled_throughput_appendix_v1.qmd")
  html_path <- file.path(run_dir, "compiled_throughput_appendix_v1.html")
  pdf_path <- file.path(run_dir, "compiled_throughput_appendix_v1.pdf")
  notes_path <- file.path(run_dir, "compiled_throughput_appendix_render_notes.md")

  lines <- c(
    "---",
    "title: \"Compiled Throughput Appendix v1\"",
    "format:",
    "  html: default",
    "  pdf: default",
    "---",
    "",
    "```{r}",
    sprintf("matrix <- read.csv(\"%s\", stringsAsFactors = FALSE)", matrix_file),
    sprintf("break_even <- read.csv(\"%s\", stringsAsFactors = FALSE)", break_even_file),
    "```",
    "",
    "## Throughput Matrix",
    "",
    "```{r}",
    "knitr::kable(matrix)",
    "```",
    "",
    "## Break-even Summary",
    "",
    "```{r}",
    "knitr::kable(break_even)",
    "```"
  )
  writeLines(lines, con = qmd_path)

  note_lines <- c("# Compiled throughput appendix render notes", "")
  if (!nzchar(Sys.which("quarto"))) {
    note_lines <- c(note_lines, "- Quarto not found on PATH; appendix render skipped.")
    writeLines(note_lines, con = notes_path)
    return(list(
      qmd_path = qmd_path,
      html_path = NA_character_,
      pdf_path = NA_character_,
      notes_path = notes_path
    ))
  }

  html_status <- system2(
    "quarto",
    args = c("render", qmd_path, "--to", "html", "--output-dir", run_dir),
    stdout = TRUE,
    stderr = TRUE
  )
  html_code <- attr(html_status, "status")
  if (is.null(html_code) || identical(html_code, 0L)) {
    note_lines <- c(note_lines, sprintf("- HTML rendered: `%s`", html_path))
  } else {
    note_lines <- c(note_lines, "- HTML render failed.", "", html_status)
  }

  pdf_status <- system2(
    "quarto",
    args = c("render", qmd_path, "--to", "pdf", "--output-dir", run_dir),
    stdout = TRUE,
    stderr = TRUE
  )
  pdf_code <- attr(pdf_status, "status")
  if (is.null(pdf_code) || identical(pdf_code, 0L)) {
    note_lines <- c(note_lines, sprintf("- PDF rendered: `%s`", pdf_path))
  } else {
    note_lines <- c(note_lines, "- PDF render failed (optional).", "", pdf_status)
  }

  writeLines(note_lines, con = notes_path)

  list(
    qmd_path = qmd_path,
    html_path = if (file.exists(html_path)) html_path else NA_character_,
    pdf_path = if (file.exists(pdf_path)) pdf_path else NA_character_,
    notes_path = notes_path
  )
}

#' Run compiled throughput appendix benchmark v1
#'
#' Executes a matrix of pure-R and compiled runtime modes across scenario sizes
#' and replicate counts, then writes break-even tables and an appendix report.
#'
#' @param base_dir Base directory for benchmark artefacts.
#' @param scenario_slug Output directory slug under `base_dir`.
#' @param size_profiles Optional data.frame with columns
#'   `profile_id`, `days`, `minute_limit`.
#' @param replicate_grid Integer replicate counts to benchmark.
#' @param modes Runtime mode labels from `compiled_throughput_modes_v1()`.
#' @param execution_mode Parallel execution mode for replicate counts > 1.
#' @param workers Optional worker override for ensemble execution.
#' @param reserve_cores Number of CPU cores to keep free.
#' @param min_speedup Break-even threshold versus pure-R baseline.
#' @param seed_base Base integer seed used for replicate vectors.
#'
#' @return List containing output paths and in-memory benchmark tables.
run_compiled_throughput_appendix_v1 <- function(base_dir = file.path("artefacts", "benchmarks"),
                                                scenario_slug = "compiled_throughput_appendix_v1",
                                                size_profiles = NULL,
                                                replicate_grid = c(1L, 4L, 8L, 16L, 32L),
                                                modes = compiled_throughput_modes_v1(),
                                                execution_mode = c("auto", "serial", "multicore"),
                                                workers = NULL,
                                                reserve_cores = 1L,
                                                min_speedup = 1.05,
                                                seed_base = 8100L) {
  mode_exec <- match.arg(execution_mode)
  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  design <- build_compiled_throughput_design_v1(
    size_profiles = size_profiles,
    replicate_grid = replicate_grid,
    modes = modes
  )
  canonical <- compile_scenario_yaml(scenario_contract_reference_path("canonical_smoke_v1"))

  rows <- vector("list", nrow(design))
  for (i in seq_len(nrow(design))) {
    row <- design[i, , drop = FALSE]
    profile_id <- as.character(row$profile_id[[1]])
    replicate_count <- as.integer(row$replicate_count[[1]])
    compiled_mode <- as.character(row$compiled_mode[[1]])

    scenario <- canonical
    scenario$runtime$days <- as.integer(row$days[[1]])
    scenario$runtime$minute_limit <- as.integer(row$minute_limit[[1]])
    scenario$outputs$scenario_slug <- sprintf(
      "compiled_appendix_%s_%s_rep%03d",
      profile_id,
      compiled_mode,
      replicate_count
    )

    seed_start <- as.integer(seed_base + i * 1000L)
    seeds <- seed_start + seq_len(replicate_count) - 1L

    bench <- tryCatch(
      with_compiled_mode_context_v1(compiled_mode, {
        measure_workload_v1(
          run_scenario_ensemble_v1(
            scenario = scenario,
            seeds = seeds,
            base_dir = file.path(run_dir, "workloads"),
            ensemble_label = sprintf("%s_%s_rep%03d", profile_id, compiled_mode, replicate_count),
            write_outputs = FALSE,
            execution_mode = if (replicate_count <= 1L) "serial" else mode_exec,
            workers = workers,
            reserve_cores = reserve_cores,
            plant_backend = compiled_mode_backend_v1(compiled_mode)
          )
        )
      }),
      error = function(e) {
        structure(
          list(error = conditionMessage(e)),
          class = "herbivoreTTR_compiled_benchmark_error"
        )
      }
    )

    herbivore_days <- as.numeric(scenario$runtime$days) * replicate_count
    if (inherits(bench, "herbivoreTTR_compiled_benchmark_error")) {
      rows[[i]] <- data.frame(
        profile_id = profile_id,
        days = as.integer(scenario$runtime$days),
        minute_limit = as.integer(scenario$runtime$minute_limit),
        replicate_count = replicate_count,
        compiled_mode = compiled_mode,
        plant_backend = as.character(compiled_mode_backend_v1(compiled_mode)),
        execution_mode_resolved = "error",
        workers_used = NA_integer_,
        elapsed_seconds = NA_real_,
        cpu_seconds = NA_real_,
        memory_delta_mb = NA_real_,
        herbivore_days = as.numeric(herbivore_days),
        throughput_herbivore_days_per_sec = NA_real_,
        compiled_ttr_requested = identical(compiled_mode, "compiled_resistance") || identical(compiled_mode, "compiled_all_available"),
        compiled_minute_loop_requested = identical(compiled_mode, "compiled_all_available"),
        run_status = "error",
        error_message = as.character(bench$error),
        stringsAsFactors = FALSE
      )
    } else {
      plan <- bench$result$execution_plan
      rows[[i]] <- data.frame(
        profile_id = profile_id,
        days = as.integer(scenario$runtime$days),
        minute_limit = as.integer(scenario$runtime$minute_limit),
        replicate_count = replicate_count,
        compiled_mode = compiled_mode,
        plant_backend = as.character(compiled_mode_backend_v1(compiled_mode)),
        execution_mode_resolved = as.character(plan$execution_mode_resolved),
        workers_used = as.integer(plan$workers_used),
        elapsed_seconds = as.numeric(bench$elapsed_seconds),
        cpu_seconds = as.numeric(bench$cpu_seconds),
        memory_delta_mb = as.numeric(bench$memory_delta_mb),
        herbivore_days = as.numeric(herbivore_days),
        throughput_herbivore_days_per_sec = herbivore_days / pmax(bench$elapsed_seconds, 1e-8),
        compiled_ttr_requested = identical(compiled_mode, "compiled_resistance") || identical(compiled_mode, "compiled_all_available"),
        compiled_minute_loop_requested = identical(compiled_mode, "compiled_all_available"),
        run_status = "ok",
        error_message = "",
        stringsAsFactors = FALSE
      )
    }
  }

  throughput <- do.call(rbind, rows)
  rownames(throughput) <- NULL
  throughput <- throughput[order(throughput$profile_id, throughput$replicate_count, throughput$compiled_mode), , drop = FALSE]

  baseline <- throughput[
    throughput$compiled_mode == "pure_r" &
      throughput$run_status == "ok" &
      is.finite(throughput$elapsed_seconds),
    c("profile_id", "replicate_count", "elapsed_seconds"),
    drop = FALSE
  ]
  names(baseline)[[3]] <- "pure_elapsed_seconds"
  throughput <- merge(
    throughput,
    baseline,
    by = c("profile_id", "replicate_count"),
    all.x = TRUE,
    sort = FALSE
  )
  throughput$speedup_vs_pure <- ifelse(
    is.finite(throughput$pure_elapsed_seconds) & is.finite(throughput$elapsed_seconds),
    throughput$pure_elapsed_seconds / pmax(throughput$elapsed_seconds, 1e-8),
    NA_real_
  )
  throughput$overhead_seconds_vs_pure <- ifelse(
    is.finite(throughput$pure_elapsed_seconds) & is.finite(throughput$elapsed_seconds),
    throughput$elapsed_seconds - throughput$pure_elapsed_seconds,
    NA_real_
  )
  throughput <- throughput[order(throughput$profile_id, throughput$replicate_count, throughput$compiled_mode), , drop = FALSE]

  break_even <- summarise_compiled_break_even_v1(
    throughput_df = throughput,
    min_speedup = min_speedup
  )

  matrix_path <- file.path(run_dir, "compiled_throughput_matrix_v1.csv")
  break_even_path <- file.path(run_dir, "compiled_break_even_summary_v1.csv")
  speedup_plot_path <- file.path(run_dir, "compiled_speedup_break_even_v1.png")
  report_path <- file.path(run_dir, "compiled_throughput_report_v1.md")
  utils::write.csv(throughput, matrix_path, row.names = FALSE)
  utils::write.csv(break_even, break_even_path, row.names = FALSE)
  write_compiled_speedup_plot_v1(throughput_df = throughput, path = speedup_plot_path)

  failed <- throughput[throughput$run_status != "ok", c("profile_id", "compiled_mode", "replicate_count", "error_message"), drop = FALSE]
  break_even_lines <- if (nrow(break_even) < 1L) {
    "- No non-pure runtime modes were available for break-even estimation."
  } else {
    paste0(
      "- Profile `", break_even$profile_id,
      "`, mode `", break_even$compiled_mode,
      "`: break-even=", ifelse(is.na(break_even$break_even_replicates), "NA", break_even$break_even_replicates),
      ", max speedup=", format(round(break_even$max_speedup, 3), trim = TRUE)
    )
  }
  report_lines <- c(
    "# Compiled Throughput Appendix v1",
    "",
    "## Benchmark matrix",
    paste0(
      "- profile=", throughput$profile_id,
      ", mode=", throughput$compiled_mode,
      ", replicates=", throughput$replicate_count,
      ", status=", throughput$run_status,
      ", elapsed=", ifelse(is.finite(throughput$elapsed_seconds), paste0(format(round(throughput$elapsed_seconds, 3), trim = TRUE), "s"), "NA"),
      ", speedup_vs_pure=", ifelse(is.finite(throughput$speedup_vs_pure), format(round(throughput$speedup_vs_pure, 3), trim = TRUE), "NA")
    ),
    "",
    "## Break-even summary",
    break_even_lines,
    "",
    "## Failed matrix rows",
    if (nrow(failed) < 1L) {
      "- None"
    } else {
      paste0(
        "- profile=", failed$profile_id,
        ", mode=", failed$compiled_mode,
        ", replicates=", failed$replicate_count,
        ", error=", failed$error_message
      )
    },
    "",
    "## Outputs",
    sprintf("- Throughput matrix: `%s`", matrix_path),
    sprintf("- Break-even summary: `%s`", break_even_path),
    sprintf("- Speedup plot: `%s`", speedup_plot_path)
  )
  writeLines(report_lines, con = report_path)

  appendix_render <- render_compiled_appendix_qmd_v1(
    run_dir = run_dir,
    matrix_path = matrix_path,
    break_even_path = break_even_path
  )

  manifest <- build_run_manifest(
    scenario_slug = file.path("benchmarks", scenario_slug),
    seed = as.integer(seed_base),
    scenario_parameters = list(
      design = design,
      execution_mode = mode_exec,
      workers = workers,
      reserve_cores = as.integer(reserve_cores),
      min_speedup = as.numeric(min_speedup)
    ),
    output_files = c(
      throughput_matrix = file.path(base_dir, scenario_slug, basename(matrix_path)),
      break_even_summary = file.path(base_dir, scenario_slug, basename(break_even_path)),
      speedup_plot = file.path(base_dir, scenario_slug, basename(speedup_plot_path)),
      report = file.path(base_dir, scenario_slug, basename(report_path)),
      appendix_qmd = file.path(base_dir, scenario_slug, basename(appendix_render$qmd_path)),
      appendix_render_notes = file.path(base_dir, scenario_slug, basename(appendix_render$notes_path))
    )
  )
  if (!is.na(appendix_render$html_path) && file.exists(appendix_render$html_path)) {
    manifest$outputs$appendix_html <- file.path(base_dir, scenario_slug, basename(appendix_render$html_path))
  }
  if (!is.na(appendix_render$pdf_path) && file.exists(appendix_render$pdf_path)) {
    manifest$outputs$appendix_pdf <- file.path(base_dir, scenario_slug, basename(appendix_render$pdf_path))
  }
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    run_dir = run_dir,
    matrix_path = matrix_path,
    break_even_path = break_even_path,
    speedup_plot_path = speedup_plot_path,
    report_path = report_path,
    appendix_qmd_path = appendix_render$qmd_path,
    appendix_html_path = appendix_render$html_path,
    appendix_pdf_path = appendix_render$pdf_path,
    appendix_notes_path = appendix_render$notes_path,
    manifest_path = manifest_path,
    design = design,
    throughput = throughput,
    break_even = break_even
  )
}
