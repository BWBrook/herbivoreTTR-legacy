#' One behavioural step (move/eat) — robust & NA-safe
#'
#' Re-evaluates target selection while eating, accrues distance on moves,
#' and guards all TRUE/FALSE checks against NA.
#'
#' @param herbivore list
#' @param plants    data.frame
#' @return list(herbivore=..., plants=...)
#' @export
herbivore_step <- function(herbivore, plants) {

  plot_width  <- sqrt(CONSTANTS$PLOT_SIZE)
  plot_height <- sqrt(CONSTANTS$PLOT_SIZE)
  desired_dp_dc_ratio <- CONSTANTS$DP_TO_DC_TARGET

  # ---------- MOVING state or no target ----------
  if (is.na(herbivore$selected_plant_id) || identical(herbivore$behaviour, "MOVING")) {

    # ~10% chance to drop target while moving
    if (identical(herbivore$behaviour, "MOVING") &&
        !is.na(herbivore$selected_plant_id) && runif(1) < 0.1) {
      herbivore$selected_plant_id <- NA_integer_
    }

    plants_in_range <- get_plants_within_range(herbivore, plants)

    if (nrow(plants_in_range) == 0) {
      # Random step (not teleport) + accrue distance
      max_distance <- herbivore$fv_max * 60  # m per minute
      angle <- runif(1, 0, 2 * pi)
      new_x <- (herbivore$xcor + max_distance * cos(angle)) %% plot_width
      new_y <- (herbivore$ycor + max_distance * sin(angle)) %% plot_height
      herbivore$distance_moved <- herbivore$distance_moved + max_distance
      herbivore$xcor <- new_x; herbivore$ycor <- new_y
      herbivore$selected_plant_id <- NA_integer_
      herbivore$behaviour <- "MOVING"

    } else {
      # Taste + choose
      scores <- calc_plant_tastiness(plants_in_range, herbivore, desired_dp_dc_ratio)
      selected_id <- pick_a_plant(plants_in_range, scores)

      if (!is.na(selected_id)) {
        herbivore$selected_plant_id <- selected_id
        sp <- plants[plants$plant_id == selected_id, , drop = FALSE]
        if (nrow(sp) == 1L && is.finite(sp$ms)) {
          dist <- calc_toroidal_distance(
            herbivore$xcor, herbivore$ycor, sp$xcor, sp$ycor, plot_width, plot_height
          )
          if (is.finite(dist) && dist <= CONSTANTS$EAT_RADIUS) {
            herbivore$behaviour <- "EATING"
          } else {
            max_distance  <- herbivore$fv_max * 60
            step_distance <- min(max_distance, ifelse(is.finite(dist), dist, 0))
            dx <- sp$xcor - herbivore$xcor; dy <- sp$ycor - herbivore$ycor
            angle <- atan2(dy, dx)
            new_x <- (herbivore$xcor + step_distance * cos(angle)) %% plot_width
            new_y <- (herbivore$ycor + step_distance * sin(angle)) %% plot_height
            herbivore$distance_moved <- herbivore$distance_moved + step_distance
            herbivore$xcor <- new_x; herbivore$ycor <- new_y
            herbivore$behaviour <- "MOVING"
          }
        } else {
          herbivore$selected_plant_id <- NA_integer_
          herbivore$behaviour <- "MOVING"
        }
      } else {
        herbivore$selected_plant_id <- NA_integer_
        herbivore$behaviour <- "MOVING"
      }
    }
  }

  # ---------- EATING state ----------
  if (identical(herbivore$behaviour, "EATING") && !is.na(herbivore$selected_plant_id)) {
    sp <- plants[plants$plant_id == herbivore$selected_plant_id, , drop = FALSE]
    if (nrow(sp) != 1L || !is.finite(sp$ms)) {
      herbivore$behaviour <- "MOVING"
      return(list(herbivore = herbivore, plants = plants))
    }

    dist <- calc_toroidal_distance(
      herbivore$xcor, herbivore$ycor, sp$xcor, sp$ycor, plot_width, plot_height
    )

    if (is.finite(dist) && dist <= CONSTANTS$EAT_RADIUS && is.finite(sp$ms) && sp$ms > 0) {
      eat_res <- herbivore_eat(herbivore, plants)
      herbivore <- eat_res$herbivore
      plants    <- eat_res$plants

      # NA-safe fullness check
      cap <- if (is.finite(herbivore$gut_capacity)) herbivore$gut_capacity else 0
      gc  <- if (is.finite(herbivore$gut_content))  herbivore$gut_content  else 0
      tol <- if (is.finite(CONSTANTS$TOLERANCE))     CONSTANTS$TOLERANCE    else 0

      if (cap > 0 && (gc + tol) >= cap) {
        herbivore$behaviour <- "REST"
      } else {
        # Re-evaluate whether to keep eating or move
        herbivore <- make_foraging_decision(herbivore, plants)
      }
    } else {
      herbivore$behaviour <- "MOVING"
    }
  }

  list(herbivore = herbivore, plants = plants)
}
