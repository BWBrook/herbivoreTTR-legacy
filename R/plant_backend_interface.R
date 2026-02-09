# Plant backend interface boundary.

plant_backend_internal_ttr <- function(use_compiled_kernel = FALSE,
                                       backend_name = "internal_ttr") {
  list(
    name = backend_name,
    init = function(veg_types) init_plants(veg_types = veg_types),
    step_day = function(plants, conditions, day_index) {
      transport_resistance(
        plants = plants,
        conditions = conditions,
        day_index = day_index,
        use_compiled_kernel = use_compiled_kernel
      )
    },
    apply_herbivory = function(plants) plants,
    observe = function(plants) {
      list(
        n_plants = nrow(plants),
        total_ms = sum(plants$ms),
        total_bleaf = sum(plants$bleaf),
        total_bstem = sum(plants$bstem)
      )
    }
  )
}

plant_backend_internal_ttr_compiled <- function() {
  plant_backend_internal_ttr(
    use_compiled_kernel = TRUE,
    backend_name = "internal_ttr_compiled"
  )
}

resolve_plant_backend <- function(backend = "internal_ttr") {
  if (is.list(backend)) {
    required <- c("name", "init", "step_day", "apply_herbivory", "observe")
    missing <- setdiff(required, names(backend))
    if (length(missing) > 0L) {
      rlang::abort(
        paste("Plant backend is missing required interface members:", paste(missing, collapse = ", ")),
        class = "herbivoreTTR_backend_missing_members",
        missing_members = missing
      )
    }
    return(backend)
  }

  if (!is.character(backend) || length(backend) != 1L || !nzchar(backend)) {
    rlang::abort(
      "Argument `backend` must be a backend name or backend interface list.",
      class = "herbivoreTTR_backend_invalid",
      backend = backend
    )
  }

  if (identical(backend, "internal_ttr")) {
    return(plant_backend_internal_ttr())
  }
  if (identical(backend, "internal_ttr_compiled")) {
    return(plant_backend_internal_ttr_compiled())
  }

  rlang::abort(
    "Unknown plant backend.",
    class = "herbivoreTTR_backend_unknown",
    backend = backend
  )
}
