#' Decide whether to continue eating or move (robust & NA-safe)
#'
#' Re-evaluates persistence on the current plant using dp:dc mismatch and a
#' mild size stickiness term. All TRUE/FALSE checks are NA-safe.
#'
#' @keywords internal
make_foraging_decision <- function(herbivore, plants) {

  # Resolve current target row
  pid <- herbivore$selected_plant_id
  if (is.null(pid) || is.na(pid)) {
    herbivore$behaviour <- "MOVING"
    return(herbivore)
  }
  idx <- which(plants$plant_id == pid)
  if (length(idx) != 1L) {
    herbivore$behaviour <- "MOVING"
    return(herbivore)
  }
  p <- plants[idx, , drop = FALSE]

  # Pull numbers with NA guards
  ms  <- ifelse(is.finite(p$ms),  p$ms,  0)
  cs  <- ifelse(is.finite(p$cs),  p$cs,  NA_real_)
  ns  <- ifelse(is.finite(p$ns),  p$ns,  NA_real_)
  cap <- ifelse(is.finite(herbivore$gut_capacity), herbivore$gut_capacity, 0)
  gut <- ifelse(is.finite(herbivore$gut_content),  herbivore$gut_content,  0)
  tol <- ifelse(is.finite(CONSTANTS$TOLERANCE),     CONSTANTS$TOLERANCE,    0)

  # Edibility guard (above minimal shoot biomass)
  can_continue_eating <- isTRUE(ms > CONSTANTS$MIN_SHOOT)

  # Fullness guard (NA-safe)
  has_capacity <- isTRUE((gut + tol) <= cap)

  if (!(has_capacity && can_continue_eating)) {
    herbivore$behaviour <- "MOVING"
    return(herbivore)
  }

  # ---- Persistence probability ----
  # dp:dc on plant (NA-safe; if undefined, treat as poor match)
  denom <- cs * CONSTANTS$PROP_DIGEST_SC
  dpdc  <- if (is.finite(ns) && is.finite(denom) && denom > 0) {
    (ns / CONSTANTS$N_TO_PROTEIN) / denom
  } else NA_real_

  if (identical(resolve_foraging_mode(herbivore), "energy_only")) {
    ratio_diff <- 0
  } else {
    ratio_diff <- abs(CONSTANTS$DP_TO_DC_TARGET - dpdc)
    if (!is.finite(ratio_diff)) ratio_diff <- 1  # penalise undefined composition
  }

  # Size stickiness (0..1), saturates at M_REF kg
  M_REF <- if (!is.null(CONSTANTS$M_REF) && is.finite(CONSTANTS$M_REF) && CONSTANTS$M_REF > 0)
    CONSTANTS$M_REF else 10
  size_term <- pmin(1, ms / M_REF)

  # Sensitivity to mismatch
  CONTINUE_K <- if (!is.null(CONSTANTS$CONTINUE_K) && is.finite(CONSTANTS$CONTINUE_K))
    CONSTANTS$CONTINUE_K else 8

  probability_continue <- exp(-CONTINUE_K * ratio_diff) * size_term
  if (!is.finite(probability_continue)) probability_continue <- 0
  probability_continue <- max(min(probability_continue, 1), 0)

  # Draw
  if (runif(1) < probability_continue) {
    herbivore$behaviour <- "EATING"
  } else {
    herbivore$behaviour <- "MOVING"
  }

  herbivore
}
