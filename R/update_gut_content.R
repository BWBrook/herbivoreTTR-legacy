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
  gut_content <- sum(herbivore$digestion$bleaf) +
                 sum(herbivore$digestion$bstem) +
                 sum(herbivore$digestion$bdef)

  herbivore$gut_content <- gut_content
  return(herbivore)
}
