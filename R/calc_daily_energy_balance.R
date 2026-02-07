#' Compute daily energy balance
#'
#' Calculates energy intake (protein + non-protein) and subtracts
#' maintenance and locomotion costs to update `herbivore$energy_balance`.
#'
#' @param herbivore Herbivore state list with energy intake and distance.
#' @return Updated `herbivore` list.
#' @examples
#' # herbivore <- calc_daily_energy_balance(herbivore)
#' @export
calc_daily_energy_balance <- function(herbivore) {
  mass_kg <- herbivore$mass / 1000

  maintenance_cost <- CONSTANTS$ENERGY_MAINTENANCE_A * (mass_kg ^ CONSTANTS$ENERGY_MAINTENANCE_B)
  locomotion_cost  <- (herbivore$distance_moved / 1000) * (CONSTANTS$ICL_A * (mass_kg ^ CONSTANTS$ICL_B)) / 100

  total_energy_cost <- maintenance_cost + locomotion_cost
  total_energy_intake <- herbivore$intake_PE_day + herbivore$intake_NPE_day
  daily_delta <- total_energy_intake - total_energy_cost

  herbivore$maintenance_energy_requirement_day <- maintenance_cost
  herbivore$total_energy_requirement_day <- total_energy_cost
  herbivore$daily_energy_intake <- total_energy_intake
  herbivore$daily_energy_delta <- daily_delta
  herbivore$energy_balance_ratio <- if (total_energy_cost > 0) {
    daily_delta / total_energy_cost
  } else {
    0
  }

  herbivore$energy_balance <- herbivore$energy_balance + daily_delta

  return(herbivore)
}
