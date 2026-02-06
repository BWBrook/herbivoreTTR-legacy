#' Update total gut content
#'
#' Recomputes total gut content (g dry matter) as the sum of biomass in
#' leaf, stem, and defence digestion vectors, and stores it in the
#' `herbivore$gut_content` field.
#'
#' @param herbivore Herbivore state list with `digestion` vectors.
#' @return Updated `herbivore` list.
#' @examples
#' # herbivore <- update_gut_content(herbivore)
#' @export
update_gut_content <- function(herbivore) {
  k <- resolve_mrt_hours(herbivore$MRT)
  if (!is.list(herbivore$digestion)) {
    herbivore$digestion <- empty_digestion_state(k)
  }

  biomass_queues <- c("bleaf", "bstem", "bdef")
  for (nm in biomass_queues) {
    herbivore$digestion[[nm]] <- normalize_digestion_queue(herbivore$digestion[[nm]], k)
  }

  herbivore$gut_content <- sum(unlist(herbivore$digestion[biomass_queues], use.names = FALSE))
  return(herbivore)
}
