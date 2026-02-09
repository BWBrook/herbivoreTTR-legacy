# Performance regression guard helpers (baseline threshold checks).

resolve_perf_guard_baseline_path_v1 <- function(path = NULL) {
  if (!is.null(path)) {
    if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
      rlang::abort(
        "Argument `path` must be a non-empty character scalar when supplied.",
        class = "herbivoreTTR_perf_guard_path_invalid",
        path = path
      )
    }
    if (!file.exists(path)) {
      rlang::abort(
        "Performance guard baseline file does not exist.",
        class = "herbivoreTTR_perf_guard_path_missing",
        path = path
      )
    }
    return(normalizePath(path, winslash = "/", mustWork = TRUE))
  }

  installed <- system.file("benchmarks", "perf_guard_baseline_v1.csv", package = "herbivoreTTR")
  if (nzchar(installed) && file.exists(installed)) {
    return(normalizePath(installed, winslash = "/", mustWork = TRUE))
  }

  # During `R CMD check`, tests may run outside repo root and before namespace
  # path assumptions hold. Walk upwards and probe known package-relative paths.
  search_dirs <- character()
  cursor <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  repeat {
    search_dirs <- c(search_dirs, cursor)
    parent <- dirname(cursor)
    if (identical(parent, cursor)) {
      break
    }
    cursor <- parent
  }

  relative_candidates <- c(
    file.path("inst", "benchmarks", "perf_guard_baseline_v1.csv"),
    file.path("benchmarks", "perf_guard_baseline_v1.csv"),
    file.path("herbivoreTTR", "benchmarks", "perf_guard_baseline_v1.csv"),
    file.path("00_pkg_src", "herbivoreTTR", "inst", "benchmarks", "perf_guard_baseline_v1.csv")
  )
  for (base_dir in search_dirs) {
    for (rel_path in relative_candidates) {
      candidate <- file.path(base_dir, rel_path)
      if (file.exists(candidate)) {
        return(normalizePath(candidate, winslash = "/", mustWork = TRUE))
      }
    }
  }

  rlang::abort(
    "Could not resolve performance guard baseline file.",
    class = "herbivoreTTR_perf_guard_path_missing"
  )
}

read_perf_guard_baseline_v1 <- function(path = NULL) {
  resolved <- resolve_perf_guard_baseline_path_v1(path)
  baseline <- utils::read.csv(resolved, stringsAsFactors = FALSE)
  required <- c("metric", "max_elapsed_seconds")
  if (!all(required %in% names(baseline))) {
    rlang::abort(
      "Performance guard baseline CSV is missing required columns.",
      class = "herbivoreTTR_perf_guard_baseline_invalid",
      required = required,
      path = resolved
    )
  }
  baseline$metric <- as.character(baseline$metric)
  baseline$max_elapsed_seconds <- as.numeric(baseline$max_elapsed_seconds)
  baseline
}

evaluate_perf_guard_v1 <- function(current_metrics,
                                   baseline) {
  if (!is.data.frame(current_metrics) || !is.data.frame(baseline)) {
    rlang::abort(
      "`current_metrics` and `baseline` must be data.frames.",
      class = "herbivoreTTR_perf_guard_inputs_invalid"
    )
  }

  required_current <- c("metric", "elapsed_seconds")
  required_baseline <- c("metric", "max_elapsed_seconds")
  if (!all(required_current %in% names(current_metrics)) ||
      !all(required_baseline %in% names(baseline))) {
    rlang::abort(
      "Performance guard inputs are missing required columns.",
      class = "herbivoreTTR_perf_guard_inputs_invalid"
    )
  }

  merged <- merge(
    current_metrics[, required_current, drop = FALSE],
    baseline[, required_baseline, drop = FALSE],
    by = "metric",
    all.x = TRUE,
    sort = FALSE
  )

  merged$within_baseline <- is.finite(merged$max_elapsed_seconds) &
    merged$elapsed_seconds <= merged$max_elapsed_seconds
  merged$degradation_fraction <- (merged$elapsed_seconds - merged$max_elapsed_seconds) /
    pmax(merged$max_elapsed_seconds, 1e-8)
  merged
}

#' Run lightweight performance guard checks against baseline thresholds
#'
#' @param baseline_path Optional baseline CSV path. Defaults to
#'   `inst/benchmarks/perf_guard_baseline_v1.csv`.
#' @param transport_iterations Number of iterations used for transport kernel
#'   timing.
#' @param tastiness_iterations Number of iterations used for tastiness timing.
#' @param enforce_guard Logical; when `TRUE`, abort if any metric exceeds
#'   baseline threshold.
#'
#' @return List containing current metrics, baseline table, and guard report.
run_performance_guard_v1 <- function(baseline_path = NULL,
                                     transport_iterations = 5L,
                                     tastiness_iterations = 100L,
                                     enforce_guard = TRUE) {
  transport_n <- max(1L, as.integer(transport_iterations[[1]]))
  tastiness_n <- max(1L, as.integer(tastiness_iterations[[1]]))
  baseline <- read_perf_guard_baseline_v1(path = baseline_path)

  set.seed(911)
  plants <- init_plants(veg_types = rep(c(0L, 1L, 2L), length.out = 300L))
  conditions <- init_conditions(
    days_in_year = 60L,
    mode = "seasonal",
    mean_temp = 19,
    amplitude = 6
  )
  transport_elapsed <- as.numeric(system.time({
    for (i in seq_len(transport_n)) {
      transport_resistance(plants, conditions, day_index = 7L)
    }
  })[["elapsed"]]) / transport_n

  plants_in_range <- data.frame(
    plant_id = seq_len(400L),
    ns = stats::runif(400L, 0.02, 0.2),
    cs = stats::runif(400L, 0.2, 2.5),
    distance = stats::runif(400L, 0, CONSTANTS$DETECTION_DISTANCE),
    bdef = stats::runif(400L, 0, 20),
    ms = stats::runif(400L, CONSTANTS$MIN_SHOOT + 0.1, 30),
    veg_type = sample(c(0L, 1L, 2L), 400L, replace = TRUE),
    height = stats::runif(400L, 0.2, 2.5),
    stringsAsFactors = FALSE
  )
  herb <- init_herbivore(mass = 5e5, herb_type = 2L, MRT = 24L, herbivore_id = "perf_guard")
  tastiness_elapsed <- as.numeric(system.time({
    for (i in seq_len(tastiness_n)) {
      calc_plant_tastiness(plants_in_range, herb, CONSTANTS$DP_TO_DC_TARGET)
    }
  })[["elapsed"]]) / tastiness_n

  current <- data.frame(
    metric = c("transport_resistance_kernel", "plant_tastiness_vector"),
    elapsed_seconds = c(transport_elapsed, tastiness_elapsed),
    iterations = c(transport_n, tastiness_n),
    stringsAsFactors = FALSE
  )

  report <- evaluate_perf_guard_v1(current_metrics = current, baseline = baseline)
  if (isTRUE(enforce_guard) && any(!report$within_baseline)) {
    failing <- report$metric[!report$within_baseline]
    rlang::abort(
      sprintf("Performance guard baseline exceeded for metrics: %s", paste(failing, collapse = ", ")),
      class = "herbivoreTTR_performance_guard_failed",
      failing_metrics = failing,
      report = report
    )
  }

  list(
    current = current,
    baseline = baseline,
    report = report
  )
}
