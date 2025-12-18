#' Plant 'tastiness' score
#'
#' Heuristic combining distance, nutrient ratio mismatch, and defence to
#' prioritise plants for feeding. Larger values are more attractive.
#'
#' @param plants_in_range data.frame of nearby plants; expects `ns`, `cs`,
#'   `distance`, optional `bdef`, and optional `ms` (shoot biomass).
#' @param herbivore Herbivore state list (unused placeholder for future use).
#' @param desired_dp_dc_ratio Numeric target ratio of digestible protein to
#'   digestible carbohydrate.
#' @return Numeric vector of tastiness scores aligned to `plants_in_range`.
#' @examples
#' # scores <- calc_plant_tastiness(plants_in_range, herb, 0.2)
#' @export
calc_plant_tastiness <- function(plants_in_range, herbivore, desired_dp_dc_ratio) {
  # Use defence column name consistent with init_plants: `bdef`
  with(plants_in_range, {
    diff_ratio <- abs(desired_dp_dc_ratio - (ns / cs))
    defence <- if (!"bdef" %in% names(plants_in_range)) 0 else bdef
    size_bonus <- if (!"ms" %in% names(plants_in_range)) {
      1
    } else {
      denom <- log1p(CONSTANTS$M_REF)
      if (!is.finite(denom) || denom <= 0) 1 else log1p(ms) / denom
    }
    tastiness <- size_bonus / (diff_ratio + distance + defence)
    tastiness[!is.finite(tastiness)] <- 0
    tastiness
  })
}
