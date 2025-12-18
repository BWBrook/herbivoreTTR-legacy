#' Check daily water balance
#'
#' Computes water balance from metabolic water and forage intake, and adds
#' drinking to close any deficit. Adds a distance penalty for traveling to
#' water when drinking occurs.
#'
#' @param herbivore Herbivore state list with `daily_water_requirement`,
#'   `metabolic_water_day`, `intake_water_forage`, and tracking fields.
#' @return Updated `herbivore` list.
#' @examples
#' # herbivore <- check_daily_water_balance(herbivore)
#' @export
check_daily_water_balance <- function(herbivore) {

  water_deficit <- herbivore$daily_water_requirement -
                   (herbivore$metabolic_water_day + herbivore$intake_water_forage)

  if (water_deficit > 0) {
    herbivore$intake_water_drinking <- water_deficit
    herbivore$distance_moved <- herbivore$distance_moved + CONSTANTS$DIST_TO_WATER
  } else {
    herbivore$intake_water_drinking <- 0
  }

  herbivore$water_balance <- herbivore$water_balance +
                             herbivore$metabolic_water_day +
                             herbivore$intake_water_forage +
                             herbivore$intake_water_drinking -
                             herbivore$daily_water_requirement

  return(herbivore)
}
