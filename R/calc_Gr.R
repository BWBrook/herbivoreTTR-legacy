#' Root growth (skeleton)
#'
#' @inheritParams calc_Gs
#' @param G_ROOT_forced Numeric growth forcing scalar for root allocation.
#' @note Write-target: plant$gr
calc_Gr <- function(plant_row, G_ROOT_forced) {
  Mr <- plant_row$mr; Cr <- plant_row$cr; Nr <- plant_row$nr
  if (is.null(Mr) || is.null(Cr) || is.null(Nr)) return(NA_real_)
  if (Mr == 0) return(0)
  val <- G_ROOT_forced * (Cr * Nr) / Mr
  if (!is.finite(val)) 0 else val
}
