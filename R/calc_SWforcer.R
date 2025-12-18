#' Soil-water forcer envelope (skeleton)
#'
#' Computes a forcing scalar for soil water availability based on water content.
#' Units: inputs in kg (or m^3) consistent with model; output is a unitless scalar.
#'
#' @param sw Numeric: current soil water.
#' @param sw_w Numeric: wilting soil water threshold.
#' @param sw_star Numeric: optimal soil water threshold.
#' @return numeric scalar (stub returns NA_real_).
#' @note Write-target: used upstream by uptake/growth; does not write plant columns directly.
calc_SWforcer <- function(sw, sw_w, sw_star) {
  # Vectorized via trap1; clamps to [0, 1]
  trap1(sw, sw_w, sw_star)
}
