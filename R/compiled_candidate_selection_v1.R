# Candidate-selection and parity harness helpers for optional compiled kernels.

clean_profile_call_name_v1 <- function(call_name) {
  out <- as.character(call_name)
  out <- gsub("\"", "", out, fixed = TRUE)
  trimws(out)
}

read_kernel_profile_by_self_v1 <- function(path) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path) || !file.exists(path)) {
    rlang::abort(
      "Kernel profile `by_self` CSV path is missing.",
      class = "herbivoreTTR_compiled_profile_missing",
      path = path
    )
  }

  profile <- utils::read.csv(path, stringsAsFactors = FALSE)
  required <- c("call", "self.time", "self.pct")
  if (!all(required %in% names(profile))) {
    rlang::abort(
      "Kernel profile `by_self` CSV is missing required columns.",
      class = "herbivoreTTR_compiled_profile_invalid",
      path = path,
      required = required
    )
  }

  profile$call_clean <- clean_profile_call_name_v1(profile$call)
  profile$self.time <- as.numeric(profile$self.time)
  profile$self.pct <- as.numeric(profile$self.pct)
  profile
}

profile_self_share_for_patterns_v1 <- function(profile, patterns) {
  if (!is.list(patterns) && !is.character(patterns)) {
    return(0)
  }
  patterns <- as.character(unlist(patterns, use.names = FALSE))
  patterns <- patterns[nzchar(patterns)]
  if (length(patterns) < 1L) {
    return(0)
  }

  matched <- rep(FALSE, nrow(profile))
  for (pattern in patterns) {
    matched <- matched | grepl(pattern, profile$call_clean, perl = TRUE)
  }

  sum(profile$self.pct[matched], na.rm = TRUE)
}

compiled_kernel_candidate_catalog_v1 <- function() {
  data.frame(
    candidate_id = c(
      "resistance_vector_kernel",
      "tau_flux_kernel",
      "guardrail_scan_kernel",
      "minute_loop_vector_kernel"
    ),
    candidate_scope = c(
      "calc_Rs*/calc_Rr* resistance terms in TTR daily loop",
      "calc_tau*/calc_d* transport and flux equations",
      "assert_domain_sanity* scan stack",
      "minute-loop aggregate helpers (vapply/ifelse-heavy paths)"
    ),
    hotspot_patterns = I(list(
      c("^calc_RsC$", "^calc_RrC$", "^calc_RsN$", "^calc_RrN$"),
      c(
        "^calc_tauC$", "^calc_tauN$", "^calc_tauCd$", "^calc_tauNd$",
        "^calc_UC$", "^calc_UN$",
        "^calc_Gs$", "^calc_Gr$", "^calc_Gd$",
        "^calc_dCs_dt$", "^calc_dCr_dt$", "^calc_dNs_dt$",
        "^calc_dNr_dt$", "^calc_dCd_dt$", "^calc_dNd_dt$"
      ),
      c("^assert_domain_sanity_vector$", "^assert_domain_sanity_state$"),
      c("^vapply$", "^ifelse$", "^all$")
    )),
    implementation_risk = c("low", "high", "medium", "medium"),
    parity_risk = c("low", "high", "medium", "medium"),
    integration_notes = c(
      "Pure numeric vector path with bounded side effects.",
      "Touches many coupled equations and conservation contracts.",
      "Safety-critical path; output parity includes failure payload semantics.",
      "Cross-cutting helper path with broad call-site surface."
    ),
    stringsAsFactors = FALSE
  )
}

compiled_risk_score_v1 <- function(level) {
  lvl <- tolower(as.character(level))
  if (identical(lvl, "low")) {
    return(1)
  }
  if (identical(lvl, "medium")) {
    return(2)
  }
  3
}

rank_compiled_kernel_candidates_v1 <- function(profile) {
  catalog <- compiled_kernel_candidate_catalog_v1()

  hotspot_self_pct <- vapply(
    catalog$hotspot_patterns,
    function(patterns) profile_self_share_for_patterns_v1(profile, patterns),
    numeric(1L)
  )
  risk_score <- vapply(
    seq_len(nrow(catalog)),
    function(i) {
      compiled_risk_score_v1(catalog$implementation_risk[[i]]) +
        compiled_risk_score_v1(catalog$parity_risk[[i]])
    },
    numeric(1L)
  )

  # Reward hotspot share but penalize coupled/high-risk kernels.
  priority_score <- hotspot_self_pct / pmax(risk_score, 1)
  ranking <- catalog
  ranking$hotspot_self_pct <- as.numeric(hotspot_self_pct)
  ranking$risk_score <- as.numeric(risk_score)
  ranking$priority_score <- as.numeric(priority_score)
  ranking$selected_for_wp_3_4_2 <- ranking$candidate_id == "resistance_vector_kernel"
  ranking <- ranking[order(-ranking$priority_score, -ranking$hotspot_self_pct), , drop = FALSE]
  ranking$priority_rank <- seq_len(nrow(ranking))
  rownames(ranking) <- NULL
  ranking
}

run_compiled_resistance_parity_harness_v1 <- function(sample_size = 2000L,
                                                      seed = 20260209L,
                                                      tolerance = 1e-12) {
  sample_n <- max(16L, as.integer(sample_size[[1]]))
  tol <- max(0, as.numeric(tolerance[[1]]))

  with_optional_seed(seed, {
    ms <- stats::runif(sample_n, min = 0, max = 120)
    mr <- stats::runif(sample_n, min = 0, max = 120)
    ms[[1]] <- 0
    mr[[1]] <- 0
    ms[[2]] <- 1e-12
    mr[[2]] <- 1e-12

    old_env_flag <- Sys.getenv("HERBIVORETTR_USE_COMPILED_TTR", unset = "0")
    on.exit(Sys.setenv(HERBIVORETTR_USE_COMPILED_TTR = old_env_flag), add = TRUE)
    Sys.setenv(HERBIVORETTR_USE_COMPILED_TTR = "0")

    pure <- compute_ttr_resistances_kernel_v1(
      ms = ms,
      mr = mr,
      tr_c = CONSTANTS$TR_C,
      tr_n = CONSTANTS$TR_N,
      q_scp = CONSTANTS$Q_SCP,
      q_snp = CONSTANTS$Q_SCP,
      use_compiled = FALSE
    )
    compiled <- compute_ttr_resistances_kernel_v1(
      ms = ms,
      mr = mr,
      tr_c = CONSTANTS$TR_C,
      tr_n = CONSTANTS$TR_N,
      q_scp = CONSTANTS$Q_SCP,
      q_snp = CONSTANTS$Q_SCP,
      use_compiled = TRUE
    )

    metrics <- do.call(
      rbind,
      lapply(c("rsC", "rrC", "rsN", "rrN"), function(metric) {
        delta <- abs(as.numeric(compiled[[metric]]) - as.numeric(pure[[metric]]))
        data.frame(
          metric = metric,
          max_abs_diff = max(delta),
          mean_abs_diff = mean(delta),
          stringsAsFactors = FALSE
        )
      })
    )
    rownames(metrics) <- NULL

    summary <- data.frame(
      candidate_id = "resistance_vector_kernel",
      engine = as.character(compiled$engine),
      fallback_used = as.logical(compiled$fallback_used),
      compiled_available = as.logical(identical(compiled$engine, "compiled_cpp")),
      sample_size = as.integer(sample_n),
      tolerance = as.numeric(tol),
      max_abs_diff = max(metrics$max_abs_diff),
      mean_abs_diff = mean(metrics$mean_abs_diff),
      parity_pass = isTRUE(all(metrics$max_abs_diff <= tol)),
      stringsAsFactors = FALSE
    )

    list(
      summary = summary,
      metrics = metrics
    )
  })
}

compiled_numeric_delta_table_v1 <- function(df_a,
                                            df_b,
                                            table_id) {
  if (!is.data.frame(df_a) || !is.data.frame(df_b) || nrow(df_a) != nrow(df_b)) {
    rlang::abort(
      "Parity comparison tables must be data.frames with matching row counts.",
      class = "herbivoreTTR_compiled_parity_table_invalid",
      table_id = table_id
    )
  }

  numeric_cols <- intersect(
    names(df_a)[vapply(df_a, is.numeric, logical(1L))],
    names(df_b)[vapply(df_b, is.numeric, logical(1L))]
  )
  if (length(numeric_cols) < 1L) {
    return(data.frame(
      table_id = table_id,
      metric = "no_numeric_columns",
      max_abs_diff = 0,
      mean_abs_diff = 0,
      stringsAsFactors = FALSE
    ))
  }

  rows <- lapply(numeric_cols, function(metric) {
    delta <- abs(as.numeric(df_a[[metric]]) - as.numeric(df_b[[metric]]))
    data.frame(
      table_id = table_id,
      metric = metric,
      max_abs_diff = max(delta),
      mean_abs_diff = mean(delta),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Run fixed-seed scenario parity check for compiled resistance path
#'
#' @param base_dir Base benchmark directory.
#' @param scenario_slug Output slug under `base_dir`.
#' @param days Number of simulation days.
#' @param minute_limit Minutes per day.
#' @param seed Deterministic seed for both runs.
#' @param tolerance Maximum allowed absolute numeric delta.
#'
#' @return List with parity summary and artefact paths.
run_compiled_scenario_parity_check_v1 <- function(base_dir = file.path("artefacts", "benchmarks"),
                                                  scenario_slug = "compiled_scenario_parity_v1",
                                                  days = 7L,
                                                  minute_limit = 120L,
                                                  seed = 4242L,
                                                  tolerance = 1e-12) {
  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  scenario <- compile_scenario_yaml(scenario_contract_reference_path("canonical_smoke_v1"))
  scenario$runtime$days <- as.integer(days)
  scenario$runtime$minute_limit <- as.integer(minute_limit)
  scenario$runtime$seed <- as.integer(seed)
  scenario$outputs$scenario_slug <- "compiled_scenario_parity_check_v1"

  old_flag <- Sys.getenv("HERBIVORETTR_USE_COMPILED_TTR", unset = "0")
  old_force <- Sys.getenv("HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE", unset = "0")
  on.exit({
    Sys.setenv(HERBIVORETTR_USE_COMPILED_TTR = old_flag)
    Sys.setenv(HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE = old_force)
  }, add = TRUE)
  Sys.setenv(HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE = "0")

  Sys.setenv(HERBIVORETTR_USE_COMPILED_TTR = "0")
  reset_compiled_ttr_kernel_v1()
  pure <- run_scenario_v1(scenario = scenario, base_dir = base_dir, write_outputs = FALSE)

  Sys.setenv(HERBIVORETTR_USE_COMPILED_TTR = "1")
  reset_compiled_ttr_kernel_v1()
  compiled <- run_scenario_v1(scenario = scenario, base_dir = base_dir, write_outputs = FALSE)

  order_by_keys <- function(df, keys) {
    key_vec <- keys[keys %in% names(df)]
    if (length(key_vec) < 1L) {
      return(df)
    }
    ord <- do.call(order, unname(df[key_vec]))
    df[ord, , drop = FALSE]
  }

  herb_a <- order_by_keys(pure$herbivore_daily, c("Day", "HerbivoreID", "HerbType"))
  herb_b <- order_by_keys(compiled$herbivore_daily, c("Day", "HerbivoreID", "HerbType"))
  struct_a <- order_by_keys(pure$structure_fuel_metrics, c("Day"))
  struct_b <- order_by_keys(compiled$structure_fuel_metrics, c("Day"))
  plants_a <- order_by_keys(pure$final_plants, c("plant_id", "xcor", "ycor"))
  plants_b <- order_by_keys(compiled$final_plants, c("plant_id", "xcor", "ycor"))

  metrics <- do.call(
    rbind,
    list(
      compiled_numeric_delta_table_v1(herb_a, herb_b, "herbivore_daily"),
      compiled_numeric_delta_table_v1(struct_a, struct_b, "structure_fuel_metrics"),
      compiled_numeric_delta_table_v1(plants_a, plants_b, "final_plants")
    )
  )
  rownames(metrics) <- NULL

  tol <- max(0, as.numeric(tolerance[[1]]))
  summary <- data.frame(
    scenario_id = as.character(scenario$scenario_id),
    days = as.integer(scenario$runtime$days),
    minute_limit = as.integer(scenario$runtime$minute_limit),
    seed = as.integer(scenario$runtime$seed),
    max_abs_diff = max(metrics$max_abs_diff),
    mean_abs_diff = mean(metrics$mean_abs_diff),
    tolerance = tol,
    parity_pass = isTRUE(all(metrics$max_abs_diff <= tol)),
    compiled_engine_available = isTRUE(compiled_ttr_kernel_available_v1()),
    stringsAsFactors = FALSE
  )

  metrics_path <- file.path(run_dir, "compiled_scenario_parity_metrics_v1.csv")
  summary_path <- file.path(run_dir, "compiled_scenario_parity_summary_v1.csv")
  report_path <- file.path(run_dir, "compiled_scenario_parity_report_v1.md")
  utils::write.csv(metrics, metrics_path, row.names = FALSE)
  utils::write.csv(summary, summary_path, row.names = FALSE)

  report_lines <- c(
    "# Compiled Scenario Parity Check v1",
    "",
    "## Configuration",
    sprintf("- Scenario: `%s`", scenario$scenario_id),
    sprintf("- Days: `%d`", summary$days[[1]]),
    sprintf("- Minute limit: `%d`", summary$minute_limit[[1]]),
    sprintf("- Seed: `%d`", summary$seed[[1]]),
    "",
    "## Result",
    sprintf("- Max absolute diff: `%.3e`", summary$max_abs_diff[[1]]),
    sprintf("- Mean absolute diff: `%.3e`", summary$mean_abs_diff[[1]]),
    sprintf("- Tolerance: `%.3e`", summary$tolerance[[1]]),
    sprintf("- Parity pass: `%s`", ifelse(summary$parity_pass[[1]], "yes", "no")),
    "",
    "## Outputs",
    sprintf("- Metrics: `%s`", metrics_path),
    sprintf("- Summary: `%s`", summary_path)
  )
  writeLines(report_lines, report_path)

  manifest <- build_run_manifest(
    scenario_slug = file.path("benchmarks", scenario_slug),
    seed = as.integer(seed),
    scenario_parameters = list(
      scenario_id = scenario$scenario_id,
      days = as.integer(days),
      minute_limit = as.integer(minute_limit),
      tolerance = tol
    ),
    output_files = c(
      metrics = file.path(base_dir, scenario_slug, basename(metrics_path)),
      summary = file.path(base_dir, scenario_slug, basename(summary_path)),
      report = file.path(base_dir, scenario_slug, basename(report_path))
    )
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    run_dir = run_dir,
    metrics_path = metrics_path,
    summary_path = summary_path,
    report_path = report_path,
    manifest_path = manifest_path,
    metrics = metrics,
    summary = summary
  )
}

#' Run compiled-candidate selection and parity harness v1
#'
#' @param base_dir Base benchmark directory.
#' @param scenario_slug Output slug under `base_dir`.
#' @param profile_self_path Optional existing kernel profile `by_self` CSV path.
#'
#' @return List with candidate ranking, parity summary, and output paths.
run_compiled_candidate_selection_v1 <- function(base_dir = file.path("artefacts", "benchmarks"),
                                                scenario_slug = "compiled_candidate_selection_v1",
                                                profile_self_path = NULL) {
  run_dir <- file.path(base_dir, scenario_slug)
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  profile_path <- profile_self_path
  if (is.null(profile_path)) {
    canonical_path <- file.path(
      base_dir,
      "post_v1_scaling_v2",
      "kernel_profile_v1_by_self.csv"
    )
    if (file.exists(canonical_path)) {
      profile_path <- canonical_path
    }
  }
  if (is.null(profile_path)) {
    canonical <- compile_scenario_yaml(scenario_contract_reference_path("canonical_smoke_v1"))
    prof <- profile_simulation_kernel_v1(
      scenario = canonical,
      run_dir = run_dir,
      profile_slug = "compiled_candidate_profile_v1",
      interval = 0.01
    )
    profile_path <- prof$self_path
  }

  profile <- read_kernel_profile_by_self_v1(profile_path)
  ranking <- rank_compiled_kernel_candidates_v1(profile)
  parity <- run_compiled_resistance_parity_harness_v1()

  ranking_path <- file.path(run_dir, "compiled_candidate_ranking_v1.csv")
  parity_summary_path <- file.path(run_dir, "compiled_parity_summary_v1.csv")
  parity_metrics_path <- file.path(run_dir, "compiled_parity_metrics_v1.csv")
  report_path <- file.path(run_dir, "compiled_candidate_report_v1.md")

  utils::write.csv(ranking, ranking_path, row.names = FALSE)
  utils::write.csv(parity$summary, parity_summary_path, row.names = FALSE)
  utils::write.csv(parity$metrics, parity_metrics_path, row.names = FALSE)

  top <- ranking[1, , drop = FALSE]
  report_lines <- c(
    "# Compiled Candidate Selection v1",
    "",
    "## Candidate ranking method",
    "- Ranked by hotspot self-time share (`self.pct`) divided by combined risk score.",
    "- Risk score combines implementation risk and parity risk (`low=1`, `medium=2`, `high=3`).",
    "",
    "## Top-ranked candidate",
    sprintf("- Candidate: `%s`", top$candidate_id[[1]]),
    sprintf("- Scope: `%s`", top$candidate_scope[[1]]),
    sprintf("- Hotspot self share: `%.3f%%`", top$hotspot_self_pct[[1]]),
    sprintf("- Priority score: `%.6f`", top$priority_score[[1]]),
    "",
    "## WP-3.4.2 prototype selection",
    "- Selected candidate: `resistance_vector_kernel`",
    "- Selection rationale: lowest ecological coupling risk while still targeting a measurable hotspot slice.",
    "",
    "## Parity harness (selected candidate)",
    sprintf("- Engine used: `%s`", parity$summary$engine[[1]]),
    sprintf("- Fallback used: `%s`", tolower(as.character(parity$summary$fallback_used[[1]]))),
    sprintf("- Max absolute diff: `%.3e`", parity$summary$max_abs_diff[[1]]),
    sprintf("- Parity pass: `%s`", ifelse(parity$summary$parity_pass[[1]], "yes", "no")),
    "",
    "## Outputs",
    sprintf("- Candidate ranking: `%s`", ranking_path),
    sprintf("- Parity summary: `%s`", parity_summary_path),
    sprintf("- Parity metrics: `%s`", parity_metrics_path)
  )
  writeLines(report_lines, report_path)

  manifest <- build_run_manifest(
    scenario_slug = file.path("benchmarks", scenario_slug),
    seed = as.integer(20260209L),
    scenario_parameters = list(
      profile_self_path = profile_path,
      selected_candidate = "resistance_vector_kernel"
    ),
    output_files = c(
      ranking = file.path(base_dir, scenario_slug, basename(ranking_path)),
      parity_summary = file.path(base_dir, scenario_slug, basename(parity_summary_path)),
      parity_metrics = file.path(base_dir, scenario_slug, basename(parity_metrics_path)),
      report = file.path(base_dir, scenario_slug, basename(report_path))
    )
  )
  manifest_path <- file.path(run_dir, "run_manifest.json")
  write_run_manifest(manifest, manifest_path)

  list(
    run_dir = run_dir,
    ranking_path = ranking_path,
    parity_summary_path = parity_summary_path,
    parity_metrics_path = parity_metrics_path,
    report_path = report_path,
    manifest_path = manifest_path,
    ranking = ranking,
    parity_summary = parity$summary,
    parity_metrics = parity$metrics
  )
}
