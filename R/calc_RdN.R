#' Defence N resistance (skeleton)
#'
#' @inheritParams calc_RsN
#' @param Md Numeric: defence biomass mass (kg).
#' @note Write-target: plant$rdN
calc_RdN <- function(TR_N, Md, Q_SNP) {
  TR_N <- pmax(TR_N, 0)
  Q_SNP <- pmax(Q_SNP, 0)
  Md_safe <- ifelse(Md <= 0 | !is.finite(Md), NA_real_, Md)
  val <- TR_N / (Md_safe ^ Q_SNP)
  LARGE <- 1e12
  val[!is.finite(val)] <- LARGE
  val <- pmax(val, 0)
  pmin(val, LARGE)
}
