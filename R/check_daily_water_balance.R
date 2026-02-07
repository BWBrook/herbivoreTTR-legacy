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
  requirement <- as.numeric(herbivore$daily_water_requirement)
  metabolic <- as.numeric(herbivore$metabolic_water_day)
  forage <- as.numeric(herbivore$intake_water_forage)

  if (!is.finite(requirement) || requirement < 0) requirement <- 0
  if (!is.finite(metabolic) || metabolic < 0) metabolic <- 0
  if (!is.finite(forage) || forage < 0) forage <- 0

  herbivore$daily_water_requirement <- requirement
  herbivore$metabolic_water_day <- metabolic
  herbivore$intake_water_forage <- forage

  available_without_drinking <- metabolic + forage
  water_deficit <- requirement - available_without_drinking

  if (water_deficit > 0) {
    herbivore$intake_water_drinking <- water_deficit
    herbivore$distance_moved <- herbivore$distance_moved + CONSTANTS$DIST_TO_WATER
  } else {
    herbivore$intake_water_drinking <- 0
  }

  herbivore$daily_net_water_balance <- herbivore$metabolic_water_day +
    herbivore$intake_water_forage +
    herbivore$intake_water_drinking -
    herbivore$daily_water_requirement
  herbivore$daily_water_intake_total <- herbivore$metabolic_water_day +
    herbivore$intake_water_forage +
    herbivore$intake_water_drinking
  herbivore$water_requirement_day <- herbivore$daily_water_requirement
  herbivore$water_balance_ratio <- if (herbivore$daily_water_requirement > 0) {
    herbivore$daily_net_water_balance / herbivore$daily_water_requirement
  } else {
    0
  }
  herbivore$water_balance <- herbivore$water_balance + herbivore$daily_net_water_balance

  return(herbivore)
}
