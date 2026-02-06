#' Select a new target plant (internal)
#'
#' Weighted sampling of a new plant target using distance, size, nutrition,
#' and defence. Returns the herbivore with `selected_plant_id` set.
#'
#' @param herbivore Herbivore state list.
#' @param plants data.frame of plant state.
#' @return Updated `herbivore` list.
#' @keywords internal
select_new_plant <- function(herbivore, plants) {
  plants_in_range <- get_plants_within_range(herbivore, plants)

  if (nrow(plants_in_range) == 0L) {
    herbivore$selected_plant_id <- NA_integer_
    return(herbivore)
  }

  tastiness <- calc_plant_tastiness(
    plants_in_range = plants_in_range,
    herbivore = herbivore,
    desired_dp_dc_ratio = CONSTANTS$DP_TO_DC_TARGET
  )
  herbivore$selected_plant_id <- pick_a_plant(
    plants_in_range = plants_in_range,
    tastiness_scores = tastiness
  )
  herbivore
}
