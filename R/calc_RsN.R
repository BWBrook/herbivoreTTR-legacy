#' Shoot N resistance (skeleton)
#'
#' Resistance to nitrogen transport in shoot compartment.
#'
#' @param TR_N Numeric: temperature-related factor for N transport (unitless scalar).
#' @param Ms Numeric: shoot biomass mass (kg).
#' @param Q_SNP Numeric: phenomenological parameter (unitless or 1/kg) for N pathway.
#' @return numeric scalar (stub returns NA_real_).
#' @note Write-target: plant$rsN
calc_RsN <- function(TR_N, Ms, Q_SNP) {
  TR_N <- pmax(TR_N, 0)
  Q_SNP <- pmax(Q_SNP, 0)
  Ms_safe <- ifelse(Ms <= 0 | !is.finite(Ms), NA_real_, Ms)
  val <- TR_N / (Ms_safe ^ Q_SNP)
  LARGE <- 1e12
  val[!is.finite(val)] <- LARGE
  val <- pmax(val, 0)
  pmin(val, LARGE)
}
