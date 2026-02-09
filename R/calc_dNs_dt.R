#' dNs/dt (skeleton)
#'
#' @param plant_row Single-row data.frame or named list for a plant.
#' @param FRACTION_N Numeric fraction parameter for allocation.
#' @return numeric scalar (stub returns NA_real_).
#' @note Output used by orchestrator to update `ns`.
calc_dNs_dt <- function(plant_row, FRACTION_N) {
  tauN <- plant_row$tauN; Gs <- plant_row$gs
  if (is.null(tauN) || is.null(Gs)) return(NA_real_)
  val <- tauN - FRACTION_N * Gs
  if (!is.finite(val)) 0 else val
}
