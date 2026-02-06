#' Reset daily herbivore variables
#'
#' Clears daily intake and balance trackers, resets movement counters, and
#' sets behaviour to "MOVING" at the start of each simulated day.
#'
#' @param herbivore Herbivore state list.
#' @return Updated `herbivore` list with daily fields zeroed and behaviour reset.
#' @examples
#' # herbivore <- reset_daily_variables(herbivore)
#' @export
reset_daily_variables <- function(herbivore) {
  herbivore$intake_defence_day <- 0
  herbivore$intake_digest_carbs_day <- 0
  herbivore$intake_digest_protein_day <- 0
  herbivore$intake_NPE_day <- 0
  herbivore$intake_PE_day <- 0
  herbivore$intake_total_day <- 0
  herbivore$intake_water_drinking <- 0
  herbivore$intake_water_forage <- 0
  herbivore$metabolic_water_day <- 0
  herbivore$daily_net_water_balance <- 0
  herbivore$distance_moved <- 0
  herbivore$gut_content <-  max(0,
                                sum(c(herbivore$digestion$bleaf,
                                  herbivore$digestion$bstem,
                                  herbivore$digestion$bdef))
                                )

  # Reset behaviour to MOVING at day's start
  herbivore$behaviour <- "MOVING"

  return(herbivore)
}
