#' Pick a plant by tastiness-weighted sampling
#'
#' Samples one plant_id from candidates using probabilities proportional to
#' provided `tastiness_scores`. Returns `NA_integer_` when all scores are zero.
#'
#' @param plants_in_range data.frame of candidate plants; must include
#'   `plant_id` and have the same number of rows as `tastiness_scores`.
#' @param tastiness_scores Numeric vector of non-negative scores.
#' @return Integer plant_id or `NA_integer_` when no suitable plant exists.
#' @examples
#' # pick_a_plant(plants_in_range, scores)
#' @export
pick_a_plant <- function(plants_in_range, tastiness_scores) {
  if (nrow(plants_in_range) != length(tastiness_scores)) {
    rlang::abort(
      "Argument mismatch: `plants_in_range` rows must match `tastiness_scores` length.",
      class = "herbivoreTTR_pick_a_plant_length_mismatch",
      n_plants = nrow(plants_in_range),
      n_scores = length(tastiness_scores)
    )
  }

  weights <- as.numeric(tastiness_scores)
  weights[!is.finite(weights)] <- 0
  weights <- pmax(weights, 0)
  total_weight <- sum(weights)

  if (!is.finite(total_weight) || total_weight <= 0) {
    return(NA_integer_)
  }

  prob <- weights / total_weight
  selected_row <- sample(seq_len(nrow(plants_in_range)), 1, prob = prob)
  plants_in_range$plant_id[selected_row]
}
