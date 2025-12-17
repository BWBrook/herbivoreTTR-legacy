#' Initialise a simple simulation setup
#'
#' Creates environmental conditions, plant grid, and a single herbivore with
#' default traits. Useful for tests and quick start examples.
#'
#' @param temp_mode One of "flat", "stochastic", or "seasonal" for
#'   `init_conditions()`.
#' @param veg_types Integer vector of vegetation types to include (0, 1, 2).
#' @param herbivore_mass Herbivore mass in grams.
#' @return List with `conditions`, `plants`, and `herbivore` objects.
#' @examples
#' sim <- init_simulation()
#' str(sim)
#' @export
init_simulation <- function(
  temp_mode = "flat",
  veg_types = c(0, 1, 2),
  herbivore_mass = 5e5,
  herb_type = 0,
  MRT = 24
) {
  conditions <- init_conditions(mode = temp_mode)
  plants     <- init_plants(veg_types = veg_types)
  herbivore  <- init_herbivore(mass = herbivore_mass, herb_type = herb_type, MRT = MRT)
  
  return(list(
    conditions = conditions,
    plants = plants,
    herbivore = herbivore
  ))
}
