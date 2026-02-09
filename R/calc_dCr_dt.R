#' dCr/dt (skeleton)
#'
#' @inheritParams calc_dCs_dt
#' @note Output used by orchestrator to update `cr`.
calc_dCr_dt <- function(plant_row, FRACTION_C) {
  tauC <- plant_row$tauC; Gr <- plant_row$gr
  if (is.null(tauC) || is.null(Gr)) return(NA_real_)
  val <- tauC - FRACTION_C * Gr
  if (!is.finite(val)) 0 else val
}
