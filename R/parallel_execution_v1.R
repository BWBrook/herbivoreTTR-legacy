# Deterministic across-run parallel execution helpers.

running_on_ci_v1 <- function() {
  ci <- Sys.getenv("CI", unset = "")
  identical(tolower(ci), "true") || identical(ci, "1")
}

normalise_worker_request_v1 <- function(workers) {
  if (is.null(workers)) {
    return(NULL)
  }

  worker_value <- as.integer(workers[[1]])
  if (!is.finite(worker_value) || worker_value < 1L) {
    rlang::abort(
      "Argument `workers` must be a positive integer when supplied.",
      class = "herbivoreTTR_parallel_workers_invalid",
      workers = workers
    )
  }

  worker_value
}

detect_available_cores_v1 <- function() {
  detected <- suppressWarnings(parallel::detectCores(logical = TRUE))
  if (!is.finite(detected) || detected < 1L) {
    return(1L)
  }
  as.integer(detected)
}

resolve_parallel_execution_plan_v1 <- function(execution_mode = c("auto", "serial", "multicore"),
                                               workers = NULL,
                                               n_tasks = 1L,
                                               reserve_cores = 1L) {
  mode <- match.arg(execution_mode)
  worker_request <- normalise_worker_request_v1(workers)

  tasks <- as.integer(n_tasks[[1]])
  if (!is.finite(tasks) || tasks < 1L) {
    tasks <- 1L
  }

  reserve <- as.integer(reserve_cores[[1]])
  if (!is.finite(reserve) || reserve < 0L) {
    reserve <- 0L
  }

  total_cores <- detect_available_cores_v1()
  usable_cores <- max(1L, total_cores - reserve)
  on_ci <- running_on_ci_v1()

  target_workers <- if (mode == "serial") {
    1L
  } else if (!is.null(worker_request)) {
    worker_request
  } else if (mode == "multicore") {
    usable_cores
  } else if (on_ci) {
    1L
  } else {
    usable_cores
  }

  workers_used <- min(max(1L, target_workers), usable_cores, tasks)

  fallback_reason <- ""
  if (!identical(.Platform$OS.type, "unix") && workers_used > 1L) {
    workers_used <- 1L
    fallback_reason <- "non-unix platform fallback to serial execution"
  }

  resolved_mode <- if (workers_used > 1L) "multicore" else "serial"
  list(
    execution_mode_requested = mode,
    execution_mode_resolved = resolved_mode,
    workers_requested = if (is.null(worker_request)) NA_integer_ else as.integer(worker_request),
    workers_used = as.integer(workers_used),
    n_tasks = as.integer(tasks),
    reserve_cores = as.integer(reserve),
    total_cores = as.integer(total_cores),
    usable_cores = as.integer(usable_cores),
    running_on_ci = isTRUE(on_ci),
    fallback_reason = fallback_reason
  )
}

execute_indexed_jobs_v1 <- function(index, job_fn, execution_plan) {
  if (!is.function(job_fn)) {
    rlang::abort(
      "Argument `job_fn` must be a function.",
      class = "herbivoreTTR_parallel_job_fn_invalid"
    )
  }

  idx <- as.integer(index)
  if (length(idx) < 1L) {
    return(list())
  }

  if (is.null(execution_plan) || execution_plan$workers_used <= 1L || length(idx) <= 1L) {
    return(lapply(idx, job_fn))
  }

  parallel::mclapply(
    X = idx,
    FUN = job_fn,
    mc.cores = execution_plan$workers_used,
    mc.preschedule = TRUE,
    mc.set.seed = FALSE
  )
}
