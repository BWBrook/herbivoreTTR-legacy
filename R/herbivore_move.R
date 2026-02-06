#' Move the herbivore one step
#'
#' Moves toward the selected plant if any, otherwise performs a random step.
#' Movement respects toroidal (wrap-around) boundaries and caps step length
#' by `fv_max * 60 * time_step_minutes`.
#'
#' @param herbivore List representing the herbivore state; uses fields
#'   `xcor`, `ycor`, `selected_plant_id`, `fv_max`, and `distance_moved`.
#' @param plants data.frame of plants with `plant_id`, `xcor`, `ycor`.
#' @param time_step_minutes Numeric timestep in minutes (default 1).
#' @return Updated `herbivore` list with new position and `distance_moved`.
#' @examples
#' # herbivore <- herbivore_move(herbivore, plants)
#' @export
herbivore_move <- function(herbivore, plants, time_step_minutes = 1) {
  world_dim <- sqrt(CONSTANTS$PLOT_SIZE)
  max_distance <- herbivore$fv_max * 60 * time_step_minutes
  if (!is.finite(max_distance) || max_distance < 0) {
    max_distance <- 0
  }

  random_step <- function(herbivore, max_distance, world_dim) {
    angle <- runif(1, 0, 2 * pi)
    herbivore$xcor <- (herbivore$xcor + cos(angle) * max_distance) %% world_dim
    herbivore$ycor <- (herbivore$ycor + sin(angle) * max_distance) %% world_dim
    herbivore$distance_moved <- herbivore$distance_moved + max_distance
    herbivore
  }

  if (!is.na(herbivore$selected_plant_id)) {
    idx <- which(plants$plant_id == herbivore$selected_plant_id)
    if (length(idx) == 1L) {
      target_x <- plants$xcor[[idx]]
      target_y <- plants$ycor[[idx]]

      dx <- target_x - herbivore$xcor
      dy <- target_y - herbivore$ycor
      if (abs(dx) > world_dim / 2) dx <- dx - sign(dx) * world_dim
      if (abs(dy) > world_dim / 2) dy <- dy - sign(dy) * world_dim

      distance <- sqrt(dx^2 + dy^2)

      if (!is.finite(distance) || distance <= 0) {
        moved_distance <- 0
      } else if (distance <= max_distance) {
        herbivore$xcor <- target_x %% world_dim
        herbivore$ycor <- target_y %% world_dim
        moved_distance <- distance
      } else {
        ratio <- max_distance / distance
        herbivore$xcor <- (herbivore$xcor + dx * ratio) %% world_dim
        herbivore$ycor <- (herbivore$ycor + dy * ratio) %% world_dim
        moved_distance <- max_distance
      }
      herbivore$distance_moved <- herbivore$distance_moved + moved_distance
      return(herbivore)
    }
    herbivore$selected_plant_id <- NA_integer_
  }

  random_step(herbivore = herbivore, max_distance = max_distance, world_dim = world_dim)
}
