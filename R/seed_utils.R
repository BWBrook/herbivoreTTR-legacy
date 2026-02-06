# Seed helpers for deterministic runs without leaking RNG side effects.

#' Validate optional seed input
#' @keywords internal
#' @noRd
validate_optional_seed <- function(seed) {
  if (is.null(seed)) {
    return(NULL)
  }
  if (!is.numeric(seed) || length(seed) != 1L || is.na(seed) || !is.finite(seed)) {
    rlang::abort(
      "Argument `seed` must be NULL or a finite scalar numeric value.",
      class = "herbivoreTTR_seed_invalid",
      seed = seed
    )
  }
  as.integer(seed)
}

#' Evaluate code with optional local seed and restore RNG state afterwards
#' @keywords internal
#' @noRd
with_optional_seed <- function(seed, code) {
  seed <- validate_optional_seed(seed)
  if (is.null(seed)) {
    return(eval.parent(substitute(code)))
  }

  rng_env <- .GlobalEnv
  had_seed <- exists(".Random.seed", envir = rng_env, inherits = FALSE)
  if (had_seed) {
    old_seed <- get(".Random.seed", envir = rng_env, inherits = FALSE)
  }

  on.exit(
    {
      if (had_seed) {
        assign(".Random.seed", old_seed, envir = rng_env)
      } else if (exists(".Random.seed", envir = rng_env, inherits = FALSE)) {
        rm(".Random.seed", envir = rng_env)
      }
    },
    add = TRUE
  )

  set.seed(seed)
  eval.parent(substitute(code))
}
