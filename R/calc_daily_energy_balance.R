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

  herbivore$energy_balance <- herbivore$energy_balance + total_energy_intake - total_energy_cost

  return(herbivore)
}
