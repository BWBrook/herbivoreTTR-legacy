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

resolve_hardware_tier_v1 <- function(hardware_tier = "auto",
                                     total_cores = detect_available_cores_v1()) {
  tier <- tolower(as.character(hardware_tier[[1]]))
  allowed <- c("auto", "laptop", "workstation", "server")
  if (!tier %in% allowed) {
    rlang::abort(
      "Argument `hardware_tier` must be one of `auto`, `laptop`, `workstation`, `server`.",
      class = "herbivoreTTR_parallel_hardware_tier_invalid",
      hardware_tier = hardware_tier
    )
  }

  if (!identical(tier, "auto")) {
    return(tier)
  }

  cores <- as.integer(total_cores[[1]])
  if (!is.finite(cores) || cores < 1L) {
    cores <- 1L
  }

  if (cores <= 8L) {
    return("laptop")
  }
  if (cores <= 32L) {
    return("workstation")
  }
  "server"
}

parallel_hardware_defaults_v1 <- function(hardware_tier = "auto",
                                          total_cores = detect_available_cores_v1(),
                                          running_on_ci = running_on_ci_v1()) {
  tier <- resolve_hardware_tier_v1(hardware_tier = hardware_tier, total_cores = total_cores)
  cores <- max(1L, as.integer(total_cores[[1]]))

  if (isTRUE(running_on_ci)) {
    return(list(
      hardware_tier_requested = tolower(as.character(hardware_tier[[1]])),
      hardware_tier_resolved = tier,
      reserve_cores = 0L,
      worker_cap = 1L,
      rationale = "CI defaults to serial execution to reduce variance."
    ))
  }

  reserve <- if (identical(tier, "laptop")) {
    1L
  } else if (identical(tier, "workstation")) {
    2L
  } else {
    4L
  }
  worker_cap <- if (identical(tier, "laptop")) {
    min(6L, max(1L, cores - reserve))
  } else if (identical(tier, "workstation")) {
    min(24L, max(1L, cores - reserve))
  } else {
    min(48L, max(1L, cores - reserve))
  }

  list(
    hardware_tier_requested = tolower(as.character(hardware_tier[[1]])),
    hardware_tier_resolved = tier,
    reserve_cores = as.integer(reserve),
    worker_cap = as.integer(worker_cap),
    rationale = "Tier defaults are conservative to preserve host responsiveness."
  )
}

resolve_parallel_execution_plan_v1 <- function(execution_mode = c("auto", "serial", "multicore"),
                                               workers = NULL,
                                               n_tasks = 1L,
                                               reserve_cores = NULL,
                                               hardware_tier = "auto") {
  mode <- match.arg(execution_mode)
  worker_request <- normalise_worker_request_v1(workers)

  tasks <- as.integer(n_tasks[[1]])
  if (!is.finite(tasks) || tasks < 1L) {
    tasks <- 1L
  }

  total_cores <- detect_available_cores_v1()
  on_ci <- running_on_ci_v1()
  defaults <- parallel_hardware_defaults_v1(
    hardware_tier = hardware_tier,
    total_cores = total_cores,
    running_on_ci = on_ci
  )

  reserve <- if (is.null(reserve_cores)) {
    as.integer(defaults$reserve_cores)
  } else {
    as.integer(reserve_cores[[1]])
  }
  if (!is.finite(reserve) || reserve < 0L) {
    reserve <- 0L
  }

  usable_cores <- max(1L, total_cores - reserve)
  default_worker_cap <- min(as.integer(defaults$worker_cap), usable_cores)

  target_workers <- if (mode == "serial") {
    1L
  } else if (!is.null(worker_request)) {
    worker_request
  } else if (mode == "multicore") {
    default_worker_cap
  } else if (on_ci) {
    1L
  } else {
    default_worker_cap
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
    hardware_tier_requested = as.character(defaults$hardware_tier_requested),
    hardware_tier_resolved = as.character(defaults$hardware_tier_resolved),
    default_worker_cap = as.integer(default_worker_cap),
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
