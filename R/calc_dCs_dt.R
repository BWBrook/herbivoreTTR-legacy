#' dCs/dt (skeleton)
#'
#' Rate of change of shoot carbon.
#'
#' @param plant_row Single-row data.frame or named list for a plant.
#' @param FRACTION_C Numeric fraction parameter for allocation.
#' @return numeric scalar (stub returns NA_real_).
#' @note Output used by orchestrator to update `cs`.
calc_dCs_dt <- function(plant_row, FRACTION_C) {
  UC <- plant_row$uc; Gs <- plant_row$gs; tauC <- plant_row$tauC; tauCd <- plant_row$tauCd
  if (is.null(UC) || is.null(Gs) || is.null(tauC) || is.null(tauCd)) return(NA_real_)
  val <- UC - FRACTION_C * Gs - tauC - tauCd
  if (!is.finite(val)) 0 else val
}
