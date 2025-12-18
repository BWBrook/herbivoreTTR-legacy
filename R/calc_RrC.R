#' Root C resistance (skeleton)
#'
#' @inheritParams calc_RsC
#' @param Mr Numeric: root biomass mass (kg).
#' @note Write-target: plant$rrC
calc_RrC <- function(TR_C, Mr, Q_SCP) {
  TR_C <- pmax(TR_C, 0)
  Q_SCP <- pmax(Q_SCP, 0)
  Mr_safe <- ifelse(Mr <= 0 | !is.finite(Mr), NA_real_, Mr)
  val <- TR_C / (Mr_safe ^ Q_SCP)
  LARGE <- 1e12
  val[!is.finite(val)] <- LARGE
  val <- pmax(val, 0)
  pmin(val, LARGE)
}
