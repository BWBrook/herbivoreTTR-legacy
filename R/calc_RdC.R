#' Defence C resistance (skeleton)
#'
#' @inheritParams calc_RsC
#' @param Md Numeric: defence biomass mass (kg).
#' @note Write-target: plant$rdC
calc_RdC <- function(TR_C, Md, Q_SCP) {
  TR_C <- pmax(TR_C, 0)
  Q_SCP <- pmax(Q_SCP, 0)
  Md_safe <- ifelse(Md <= 0 | !is.finite(Md), NA_real_, Md)
  val <- TR_C / (Md_safe ^ Q_SCP)
  LARGE <- 1e12
  val[!is.finite(val)] <- LARGE
  val <- pmax(val, 0)
  pmin(val, LARGE)
}
