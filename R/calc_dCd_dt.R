#' dCd/dt (skeleton)
#'
#' @inheritParams calc_dCs_dt
#' @note Output used by orchestrator to update `cd` (defence C), if present.
calc_dCd_dt <- function(plant_row, FRACTION_C) {
  tauCd <- plant_row$tauCd; Gd <- plant_row$gd
  if (is.null(tauCd) || is.null(Gd)) return(NA_real_)
  val <- tauCd - FRACTION_C * Gd
  if (!is.finite(val)) 0 else val
}
