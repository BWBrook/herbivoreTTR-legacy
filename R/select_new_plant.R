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

  world_dim <- sqrt(CONSTANTS$PLOT_SIZE)

  # Compute distances to all plants considering toroidal wrapping
  distances <- plants %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      dx = min(abs(xcor - herbivore$xcor), world_dim - abs(xcor - herbivore$xcor)),
      dy = min(abs(ycor - herbivore$ycor), world_dim - abs(ycor - herbivore$ycor)),
      distance = sqrt(dx^2 + dy^2)
    ) %>%
    dplyr::ungroup() %>%
    dplyr::filter(ms > CONSTANTS$MIN_SHOOT, distance <= CONSTANTS$DETECTION_DISTANCE)

  if (nrow(distances) == 0) {
    herbivore$selected_plant_id <- NA
    return(herbivore)
  }

  # Calculate tastiness scores
  distances <- distances %>%
    dplyr::mutate(
      ratio_diff = abs(CONSTANTS$DP_TO_DC_TARGET - (ns / CONSTANTS$N_TO_PROTEIN) / (cs * CONSTANTS$PROP_DIGEST_SC)),
      tastiness = 1 / (ratio_diff + bdef + distance)
    )

  # Normalize scores to probabilities
  probabilities <- distances$tastiness / sum(distances$tastiness)

  selected_index <- sample(1:nrow(distances), size = 1, prob = probabilities)
  herbivore$selected_plant_id <- distances$plant_id[selected_index]

  return(herbivore)
}
