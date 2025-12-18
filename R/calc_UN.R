#' Nitrogen uptake (skeleton)
#'
#' Computes nitrogen uptake into the root compartment.
#'
#' @param plant_row Single-row data.frame or named list for a plant.
#' @param N0 Numeric: available nitrogen in soil (kg N).
#' @param K_M Numeric: Michaelis-Menten/Monod constant (unit depends on formulation).
#' @param PI_N Numeric: driver for N uptake (unit depends on formulation).
#' @return numeric scalar (stub returns NA_real_).
#' @note Write-target: plant$un
calc_UN <- function(plant_row, N0, K_M, PI_N) {
  Mr <- plant_row$mr
  Nr <- plant_row$nr
  if (is.null(Mr) || is.null(Nr)) return(NA_real_)
  if (Mr == 0) return(0)
  # (N0 * Mr) / (1 + Mr / K_M) * sf(Nr/Mr, PI_N, 1000)
  num <- N0 * Mr
  denom <- 1 + Mr / K_M
  if (!is.finite(denom) || denom <= 0) return(0)
  frac <- Nr / Mr
  val <- (num / denom) * sf(frac, PI_N, 1000)
  if (!is.finite(val)) 0 else val
}
