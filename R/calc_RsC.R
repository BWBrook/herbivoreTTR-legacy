#' Shoot C resistance (skeleton)
#'
#' Resistance to carbon transport in shoot compartment.
#'
#' @param TR_C Numeric: temperature-related factor for C transport (unitless scalar).
#' @param Ms Numeric: shoot biomass mass (kg).
#' @param Q_SCP Numeric: phenomenological parameter (unitless or 1/kg) for C pathway.
#' @return numeric scalar (stub returns NA_real_).
#' @note Write-target: plant$rsC
calc_RsC <- function(TR_C, Ms, Q_SCP) {
  TR_C <- pmax(TR_C, 0)
  Q_SCP <- pmax(Q_SCP, 0)
  Ms_safe <- ifelse(Ms <= 0 | !is.finite(Ms), NA_real_, Ms)
  val <- TR_C / (Ms_safe ^ Q_SCP)
  # Large cap to avoid Inf/NaN while preserving limiting behavior
  LARGE <- 1e12
  val[!is.finite(val)] <- LARGE
  val <- pmax(val, 0)
  pmin(val, LARGE)
}
