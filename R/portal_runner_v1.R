# Portal runner helpers for non-coder scenario and sensitivity workflows.

portal_slugify_id_v1 <- function(text) {
  slug <- tolower(gsub("[^a-zA-Z0-9]+", "_", text))
  slug <- gsub("_+", "_", slug)
  slug <- gsub("^_|_$", "", slug)
  if (!nzchar(slug)) {
    slug <- "portal_plan"
  }
  slug
}

portal_relativize_path_v1 <- function(path) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
    return(path)
  }

  abs_path <- tryCatch(
    normalizePath(path, winslash = "/", mustWork = TRUE),
    error = function(e) path
  )
  repo_root <- scenario_find_repo_root()
  if (is.null(repo_root)) {
    return(abs_path)
  }

  repo_root_abs <- normalizePath(repo_root, winslash = "/", mustWork = TRUE)
  prefix <- paste0(repo_root_abs, "/")
  if (startsWith(abs_path, prefix)) {
    return(sub(prefix, "", abs_path, fixed = TRUE))
  }

  abs_path
}

portal_prepare_output_dirs_v1 <- function(root_dir) {
  dirs <- list(
    root = root_dir,
    canonical_runs = file.path(root_dir, "canonical_runs"),
    tables = file.path(root_dir, "tables"),
    figures = file.path(root_dir, "figures"),
    reports = file.path(root_dir, "reports"),
    manifests = file.path(root_dir, "manifests")
  )

  for (d in unname(dirs)) {
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
  }

  dirs
}

portal_resolve_run_root_v1 <- function(plan) {
  run_root <- file.path(plan$execution$base_dir, portal_slugify_id_v1(plan$plan_id))
  dir.create(run_root, recursive = TRUE, showWarnings = FALSE)
  normalizePath(run_root, winslash = "/", mustWork = TRUE)
}

portal_resolve_base_scenario_v1 <- function(plan) {
  if (identical(plan$scenario$source, "reference")) {
    scenario_path <- scenario_contract_reference_path(plan$scenario$reference)
  } else {
    scenario_path <- resolve_scenario_yaml_path(plan$scenario$path)
  }

  scenario <- compile_scenario_yaml(scenario_path)
  scenario <- portal_apply_scenario_overrides_v1(scenario, plan$scenario$overrides)
  scenario
}

portal_apply_changes_v1 <- function(scenario,
                                    changes) {
  if (!is.list(changes) || length(changes) < 1L) {
    return(validate_scenario_v1(scenario))
  }

  out <- scenario
  for (path in names(changes)) {
    out <- portal_set_path_v1(out, path = path, value = changes[[path]])
  }

  validate_scenario_v1(out)
}

portal_template_report_path_v1 <- function() {
  repo_root <- scenario_find_repo_root()
  candidates <- c(
    if (!is.null(repo_root)) file.path(repo_root, "portal", "reports", "ecologist_report_v1.qmd") else character(),
    file.path("portal", "reports", "ecologist_report_v1.qmd")
  )
  existing <- candidates[file.exists(candidates)]

  if (length(existing) < 1L) {
    portal_abort_v1(
      "Portal report template `.qmd` could not be found.",
      class = "herbivoreTTR_portal_report_template_missing",
      candidates = candidates
    )
  }

  normalizePath(existing[[1]], winslash = "/", mustWork = TRUE)
}

render_portal_report_v1 <- function(run_dir,
                                    report_formats = c("html")) {
  formats <- unique(tolower(report_formats))
  reports_dir <- file.path(run_dir, "reports")
  dir.create(reports_dir, recursive = TRUE, showWarnings = FALSE)

  note_path <- file.path(reports_dir, "report_render_notes.md")
  lines <- c("# Portal report render notes", "")

  if (!nzchar(Sys.which("quarto"))) {
    lines <- c(lines, "- Quarto is not available on PATH; report rendering skipped.")
    writeLines(lines, con = note_path)
    return(list(
      html_path = NA_character_,
      pdf_path = NA_character_,
      note_path = note_path
    ))
  }

  template <- portal_template_report_path_v1()
  old_env <- Sys.getenv("HERBIVORE_PORTAL_RUN_DIR", unset = "")
  Sys.setenv(HERBIVORE_PORTAL_RUN_DIR = normalizePath(run_dir, winslash = "/", mustWork = TRUE))
  on.exit(Sys.setenv(HERBIVORE_PORTAL_RUN_DIR = old_env), add = TRUE)
  cache_dir <- file.path(reports_dir, ".quarto_cache")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  old_cache_env <- Sys.getenv("QUARTO_CACHE_DIR", unset = "")
  Sys.setenv(QUARTO_CACHE_DIR = normalizePath(cache_dir, winslash = "/", mustWork = TRUE))
  on.exit(Sys.setenv(QUARTO_CACHE_DIR = old_cache_env), add = TRUE)

  html_path <- NA_character_
  pdf_path <- NA_character_

  if ("html" %in% formats) {
    args <- c("render", template, "--to", "html", "--output-dir", reports_dir)
    status <- system2("quarto", args = args, stdout = TRUE, stderr = TRUE)
    status_code <- attr(status, "status")

    expected_html <- file.path(
      normalizePath(reports_dir, winslash = "/", mustWork = TRUE),
      sub("\\.qmd$", ".html", basename(template))
    )

    if (is.null(status_code) || identical(status_code, 0L)) {
      if (file.exists(expected_html)) {
        html_path <- expected_html
        lines <- c(lines, sprintf("- HTML report rendered: `%s`", html_path))
      } else {
        lines <- c(lines, "- HTML render command succeeded but expected HTML not found.")
      }
    } else {
      lines <- c(lines, "- HTML report render failed; see command output below.", "", status)
    }
  }

  if ("pdf" %in% formats) {
    args <- c("render", template, "--to", "pdf", "--output-dir", reports_dir)
    status <- system2("quarto", args = args, stdout = TRUE, stderr = TRUE)
    status_code <- attr(status, "status")

    expected_pdf <- file.path(
      normalizePath(reports_dir, winslash = "/", mustWork = TRUE),
      sub("\\.qmd$", ".pdf", basename(template))
    )

    if (is.null(status_code) || identical(status_code, 0L)) {
      if (file.exists(expected_pdf)) {
        pdf_path <- expected_pdf
        lines <- c(lines, sprintf("- PDF report rendered: `%s`", pdf_path))
      } else {
        lines <- c(lines, "- PDF render command succeeded but expected PDF not found.")
      }
    } else {
      lines <- c(lines, "- PDF report render failed; see command output below.", "", status)
    }
  }

  writeLines(lines, con = note_path)

  list(
    html_path = html_path,
    pdf_path = pdf_path,
    note_path = note_path
  )
}

portal_run_single_case_v1 <- function(base_scenario,
                                      spec,
                                      dirs,
                                      write_outputs = TRUE) {
  scenario <- portal_apply_changes_v1(base_scenario, spec$changes)
  scenario$outputs$scenario_slug <- file.path("runs", spec$run_label)

  elapsed <- as.numeric(system.time({
    run <- run_scenario_v1(
      scenario = scenario,
      base_dir = dirs$canonical_runs,
      write_outputs = write_outputs
    )
  })[["elapsed"]])

  daily_summary <- portal_build_daily_summary_v1(
    herbivore_daily = run$herbivore_daily,
    structure_fuel_metrics = run$structure_fuel_metrics
  )
  endpoint_summary <- portal_build_endpoint_summary_v1(daily_summary, run_label = spec$run_label)
  sanity_summary <- portal_domain_sanity_summary_v1(run, daily_summary, run_label = spec$run_label)

  daily_path <- file.path(dirs$tables, sprintf("%s_daily_summary.csv", spec$run_label))
  endpoint_path <- file.path(dirs$tables, sprintf("%s_endpoint_summary.csv", spec$run_label))
  sanity_path <- file.path(dirs$tables, sprintf("%s_domain_sanity_summary.csv", spec$run_label))

  utils::write.csv(daily_summary, daily_path, row.names = FALSE)
  utils::write.csv(endpoint_summary, endpoint_path, row.names = FALSE)
  utils::write.csv(sanity_summary, sanity_path, row.names = FALSE)

  figure_paths <- portal_write_single_figures_v1(
    run_result = run,
    daily_summary = daily_summary,
    figure_dir = dirs$figures,
    run_label = spec$run_label
  )

  list(
    spec = spec,
    run = run,
    elapsed_seconds = elapsed,
    daily_summary = daily_summary,
    endpoint_summary = endpoint_summary,
    sanity_summary = sanity_summary,
    daily_path = daily_path,
    endpoint_path = endpoint_path,
    sanity_path = sanity_path,
    figure_paths = figure_paths,
    run_index_row = data.frame(
      run_index = as.integer(spec$run_index),
      run_label = as.character(spec$run_label),
      run_id = as.character(run$run_id),
      scenario_slug = as.character(run$scenario$outputs$scenario_slug),
      scenario_id = as.character(run$scenario$scenario_id),
      seed = as.integer(run$scenario$runtime$seed),
      elapsed_seconds = elapsed,
      change_summary = as.character(spec$change_summary),
      design = as.character(spec$design),
      stringsAsFactors = FALSE
    )
  )
}

run_portal_sensitivity_v1 <- function(plan,
                                      root_dir = NULL,
                                      base_scenario = NULL) {
  validated <- if (is.character(plan)) compile_portal_plan_yaml(plan) else validate_portal_plan_v1(plan)
  if (!isTRUE(validated$sensitivity$enabled) && !identical(validated$execution$mode, "sensitivity")) {
    portal_abort_v1(
      "Sensitivity runner called for a non-sensitivity plan.",
      class = "herbivoreTTR_portal_plan_sensitivity_invalid"
    )
  }

  if (is.null(base_scenario)) {
    base_scenario <- portal_resolve_base_scenario_v1(validated)
  }

  if (is.null(root_dir)) {
    root_dir <- portal_resolve_run_root_v1(validated)
  }

  dirs <- portal_prepare_output_dirs_v1(root_dir)
  design <- portal_expand_sensitivity_design_v1(validated, base_scenario)
  specs <- design$specs

  parallel_plan <- resolve_parallel_execution_plan_v1(
    execution_mode = validated$execution$parallel$execution_mode,
    workers = validated$execution$parallel$workers,
    n_tasks = length(specs),
    reserve_cores = validated$execution$parallel$reserve_cores,
    hardware_tier = validated$execution$parallel$hardware_tier
  )

  results <- execute_indexed_jobs_v1(
    index = seq_along(specs),
    job_fn = function(i) {
      portal_run_single_case_v1(
        base_scenario = base_scenario,
        spec = specs[[i]],
        dirs = dirs,
        write_outputs = validated$execution$write_outputs
      )
    },
    execution_plan = parallel_plan
  )

  run_index <- do.call(rbind, lapply(results, `[[`, "run_index_row"))
  run_index <- run_index[order(run_index$run_index), , drop = FALSE]
  rownames(run_index) <- NULL

  endpoint_all <- do.call(rbind, lapply(results, `[[`, "endpoint_summary"))
  endpoint_all <- endpoint_all[order(match(endpoint_all$run_label, run_index$run_label)), , drop = FALSE]
  rownames(endpoint_all) <- NULL
  endpoint_all <- portal_join_endpoint_design_v1(
    endpoint_summary = endpoint_all,
    design_table = design$design_table
  )
  endpoint_all <- portal_add_sensitivity_deltas_v1(endpoint_all)

  sanity_all <- do.call(rbind, lapply(results, `[[`, "sanity_summary"))
  sanity_all <- sanity_all[order(match(sanity_all$run_label, run_index$run_label)), , drop = FALSE]
  rownames(sanity_all) <- NULL

  design_path <- file.path(dirs$tables, "sensitivity_design.csv")
  endpoint_path <- file.path(dirs$tables, "sensitivity_endpoint_summary.csv")
  sanity_path <- file.path(dirs$tables, "sensitivity_domain_sanity_summary.csv")
  run_index_path <- file.path(dirs$root, "run_index.csv")

  utils::write.csv(design$design_table, design_path, row.names = FALSE)
  utils::write.csv(endpoint_all, endpoint_path, row.names = FALSE)
  utils::write.csv(sanity_all, sanity_path, row.names = FALSE)
  utils::write.csv(run_index, run_index_path, row.names = FALSE)

  figure_paths <- portal_write_sensitivity_figures_v1(
    endpoint_summary = endpoint_all,
    design_table = design$design_table,
    figure_dir = dirs$figures,
    prefix = "sensitivity"
  )

  list(
    mode = "sensitivity",
    run_dir = dirs$root,
    dirs = dirs,
    parallel_plan = parallel_plan,
    design_table = design$design_table,
    run_index = run_index,
    endpoint_summary = endpoint_all,
    sanity_summary = sanity_all,
    run_index_path = run_index_path,
    design_path = design_path,
    endpoint_path = endpoint_path,
    sanity_path = sanity_path,
    figure_paths = figure_paths,
    run_results = results
  )
}

run_portal_plan_v1 <- function(plan,
                               dry_run = NULL,
                               force_mode = NULL) {
  validated <- if (is.character(plan)) compile_portal_plan_yaml(plan) else validate_portal_plan_v1(plan)

  if (!is.null(force_mode)) {
    validated$execution$mode <- match.arg(force_mode, choices = c("single", "sensitivity"))
    if (identical(validated$execution$mode, "sensitivity")) {
      validated$sensitivity$enabled <- TRUE
    }
  }

  dry_run_final <- if (is.null(dry_run)) {
    validated$execution$dry_run
  } else {
    as.logical(dry_run[[1]])
  }

  base_scenario <- portal_resolve_base_scenario_v1(validated)

  if (isTRUE(dry_run_final)) {
    return(list(
      dry_run = TRUE,
      mode = validated$execution$mode,
      plan = validated,
      scenario_id = base_scenario$scenario_id,
      scenario_slug = base_scenario$outputs$scenario_slug,
      seed = base_scenario$runtime$seed,
      days = base_scenario$runtime$days,
      minute_limit = base_scenario$runtime$minute_limit
    ))
  }

  root_dir <- portal_resolve_run_root_v1(validated)
  dirs <- portal_prepare_output_dirs_v1(root_dir)

  if (!is.null(validated$plan_path) && file.exists(validated$plan_path)) {
    file.copy(validated$plan_path, file.path(dirs$manifests, "plan_input.yaml"), overwrite = TRUE)
  }
  yaml::write_yaml(validated, file.path(dirs$manifests, "plan_resolved.yaml"))

  result <- if (identical(validated$execution$mode, "sensitivity") || isTRUE(validated$sensitivity$enabled)) {
    run_portal_sensitivity_v1(
      plan = validated,
      root_dir = root_dir,
      base_scenario = base_scenario
    )
  } else {
    spec <- list(
      run_index = 1L,
      run_label = "single_main",
      changes = list(),
      change_summary = "single_run",
      design = "single"
    )

    single <- portal_run_single_case_v1(
      base_scenario = base_scenario,
      spec = spec,
      dirs = dirs,
      write_outputs = validated$execution$write_outputs
    )

    run_index <- single$run_index_row
    run_index_path <- file.path(dirs$root, "run_index.csv")
    utils::write.csv(run_index, run_index_path, row.names = FALSE)

    daily_path <- file.path(dirs$tables, "daily_summary.csv")
    endpoint_path <- file.path(dirs$tables, "endpoint_summary.csv")
    sanity_path <- file.path(dirs$tables, "domain_sanity_summary.csv")

    utils::write.csv(single$daily_summary, daily_path, row.names = FALSE)
    utils::write.csv(single$endpoint_summary, endpoint_path, row.names = FALSE)
    utils::write.csv(single$sanity_summary, sanity_path, row.names = FALSE)

    list(
      mode = "single",
      run_dir = dirs$root,
      dirs = dirs,
      run_index = run_index,
      run_index_path = run_index_path,
      daily_summary = single$daily_summary,
      endpoint_summary = single$endpoint_summary,
      sanity_summary = single$sanity_summary,
      daily_path = daily_path,
      endpoint_path = endpoint_path,
      sanity_path = sanity_path,
      figure_paths = single$figure_paths,
      run_results = list(single)
    )
  }

  acceptance_summary <- portal_build_acceptance_summary_v1(
    run_results = result$run_results,
    acceptance_profile = validated$outputs$acceptance_profile
  )
  acceptance_file <- if (identical(result$mode, "sensitivity")) {
    "sensitivity_ecological_acceptance_summary.csv"
  } else {
    "ecological_acceptance_summary.csv"
  }
  acceptance_path <- file.path(result$dirs$tables, acceptance_file)
  utils::write.csv(acceptance_summary, acceptance_path, row.names = FALSE)

  report <- list(html_path = NA_character_, pdf_path = NA_character_, note_path = NA_character_)
  if (isTRUE(validated$outputs$render_report)) {
    report <- render_portal_report_v1(
      run_dir = result$run_dir,
      report_formats = validated$outputs$report_formats
    )
  }

  interactive_note <- portal_write_interactive_note_v1(
    run_dir = result$run_dir,
    include_interactive = validated$outputs$include_interactive
  )

  output_files <- c(
    run_index = portal_relativize_path_v1(result$run_index_path),
    interactive_note = portal_relativize_path_v1(interactive_note)
  )

  if (!is.null(result$daily_path) && file.exists(result$daily_path)) {
    output_files <- c(output_files, daily_summary = portal_relativize_path_v1(result$daily_path))
  }
  if (!is.null(result$design_path) && file.exists(result$design_path)) {
    output_files <- c(output_files, sensitivity_design = portal_relativize_path_v1(result$design_path))
  }
  if (!is.null(result$endpoint_path) && file.exists(result$endpoint_path)) {
    output_files <- c(output_files, endpoint_summary = portal_relativize_path_v1(result$endpoint_path))
  }
  if (!is.null(result$sanity_path) && file.exists(result$sanity_path)) {
    output_files <- c(output_files, domain_sanity = portal_relativize_path_v1(result$sanity_path))
  }
  if (file.exists(acceptance_path)) {
    output_files <- c(output_files, ecological_acceptance = portal_relativize_path_v1(acceptance_path))
  }

  if (!is.null(result$figure_paths) && length(result$figure_paths) > 0L) {
    output_files <- c(output_files, vapply(result$figure_paths, portal_relativize_path_v1, character(1L)))
  }

  if (!is.na(report$html_path) && file.exists(report$html_path)) {
    output_files <- c(output_files, report_html = portal_relativize_path_v1(report$html_path))
  }
  if (!is.na(report$pdf_path) && file.exists(report$pdf_path)) {
    output_files <- c(output_files, report_pdf = portal_relativize_path_v1(report$pdf_path))
  }
  if (!is.na(report$note_path) && file.exists(report$note_path)) {
    output_files <- c(output_files, report_notes = portal_relativize_path_v1(report$note_path))
  }

  manifest <- build_run_manifest(
    scenario_slug = file.path("portal_runs", portal_slugify_id_v1(validated$plan_id)),
    seed = as.integer(base_scenario$runtime$seed),
    scenario_parameters = list(
      plan_id = validated$plan_id,
      mode = result$mode,
      render_report = validated$outputs$render_report,
      report_formats = validated$outputs$report_formats,
      acceptance_profile = validated$outputs$acceptance_profile,
      parallel_mode = validated$execution$parallel$execution_mode,
      parallel_hardware_tier = validated$execution$parallel$hardware_tier,
      parallel_workers_requested = validated$execution$parallel$workers
    ),
    output_files = output_files
  )
  manifest_path <- file.path(result$dirs$manifests, "portal_run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  result$plan <- validated
  result$report <- report
  result$interactive_note_path <- interactive_note
  result$manifest_path <- manifest_path
  result$acceptance_summary <- acceptance_summary
  result$acceptance_path <- acceptance_path
  result
}
