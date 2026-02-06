# Internal helpers for movement/retargeting policy.

resolve_movement_disruption_prob <- function(herbivore) {
  prob <- herbivore$movement_disruption_prob
  if (!is.numeric(prob) || length(prob) != 1L || !is.finite(prob)) {
    return(CONSTANTS$MOVEMENT_DISRUPTION_PROB)
  }
  max(0, min(1, as.numeric(prob)))
}
