#' Defence growth (skeleton)
#'
#' @inheritParams calc_Gs
#' @param G_DEF_forced Numeric growth forcing scalar for defence allocation.
#' @note Write-target: plant$gd
calc_Gd <- function(plant_row, G_DEF_forced) {
  Md <- plant_row$md; Cd <- plant_row$cd; Nd <- plant_row$nd
  if (is.null(Md) || is.null(Cd) || is.null(Nd)) return(NA_real_)
  if (Md == 0) return(0)
  val <- G_DEF_forced * (Cd * Nd) / Md
  if (!is.finite(val)) 0 else val
}
