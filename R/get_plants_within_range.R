#' Get plants within detection range
#'
#' Computes toroidal distances from the herbivore to all plants and returns
#' those within `CONSTANTS$DETECTION_DISTANCE`, optionally filtering by browse
#' height for browser and mixed feeders (`herb_type %in% c(1, 2)`). Adds a
#' `distance` column to the
#' returned data frame.
#'
#' @param herbivore List representing the herbivore state; must include
#'   `xcor`, `ycor`, and optionally `herb_type`.
#' @param plants data.frame of plant state with at least columns `plant_id`,
#'   `xcor`, `ycor`, `ms`, and optionally `height`.
#' @return data.frame subset of `plants` within range, with an added
#'   numeric `distance` column (meters).
#' @examples
#'
#' # Assuming `herb` and `plants` created via init_* helpers:
#' # near <- get_plants_within_range(herb, plants)
#' @export
get_plants_within_range <- function(herbivore, plants) {
  plot_width <- sqrt(CONSTANTS$PLOT_SIZE)
  plot_height <- sqrt(CONSTANTS$PLOT_SIZE)

  distances <- calc_toroidal_distance(
    herbivore$xcor, herbivore$ycor,
    plants$xcor, plants$ycor,
    plot_width, plot_height
  )

  keep <- distances <= CONSTANTS$DETECTION_DISTANCE & plants$ms > 0

  # For browser/mixed feeders, enforce browse height limit
  if (!is.null(herbivore$herb_type) && herbivore$herb_type %in% c(1, 2)) {
    reachable <- CONSTANTS$LEAF_HEIGHT * plants$height <= CONSTANTS$BROWSE_HEIGHT
    keep <- keep & reachable
  }
  within_range <- plants[keep, ]
  within_range$distance <- distances[keep]

  return(within_range)
}
