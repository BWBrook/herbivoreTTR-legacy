#' dNr/dt (skeleton)
#'
#' @inheritParams calc_dNs_dt
#' @note Output used by orchestrator to update `nr`.
calc_dNr_dt <- function(plant_row, FRACTION_N) {
  UN <- plant_row$un; Gr <- plant_row$gr; tauN <- plant_row$tauN; tauNd <- plant_row$tauNd
  if (is.null(UN) || is.null(Gr) || is.null(tauN) || is.null(tauNd)) return(NA_real_)
  val <- UN - FRACTION_N * Gr - tauN - tauNd
  if (!is.finite(val)) 0 else val
}
