#' Root N resistance (skeleton)
#'
#' @inheritParams calc_RsN
#' @param Mr Numeric: root biomass mass (kg).
#' @note Write-target: plant$rrN
calc_RrN <- function(TR_N, Mr, Q_SNP) {
  TR_N <- pmax(TR_N, 0)
  Q_SNP <- pmax(Q_SNP, 0)
  Mr_safe <- ifelse(Mr <= 0 | !is.finite(Mr), NA_real_, Mr)
  val <- TR_N / (Mr_safe ^ Q_SNP)
  LARGE <- 1e12
  val[!is.finite(val)] <- LARGE
  val <- pmax(val, 0)
  pmin(val, LARGE)
}
