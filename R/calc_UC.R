#' Carbon uptake (skeleton)
#'
#' Computes carbon uptake into the plant shoot compartment.
#'
#' @param plant_row Single-row data.frame or named list for a plant.
#' @param CLeaf Numeric: available carbon in leaves (kg C).
#' @param K_C_forced Numeric: environmental forcing scalar for C uptake (unitless).
#' @param K_M Numeric: Michaelis-Menten/Monod constant (unit depends on formulation).
#' @param PI_C Numeric: photosynthetic input or driver (unit depends on formulation).
#' @return numeric scalar (stub returns NA_real_).
#' @note Write-target: plant$uc
calc_UC <- function(plant_row, CLeaf, K_C_forced, K_M, PI_C) {
  Ms <- plant_row$ms
  Cs <- plant_row$cs
  if (is.null(Ms) || is.null(Cs)) return(NA_real_)
  if (Ms == 0) return(0)
  # (K_C * Ms) / (1 + Ms / K_M) * sf(Cs/Ms, PI_C, 100)
  num <- K_C_forced * Ms
  denom <- 1 + Ms / K_M
  if (!is.finite(denom) || denom <= 0) return(0)
  frac <- Cs / Ms
  val <- (num / denom) * sf(frac, PI_C, 100)
  if (!is.finite(val)) 0 else val
}
