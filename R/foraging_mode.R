# Internal helpers for nutrient-targeting vs energy-only foraging objective.

foraging_mode_levels <- function() {
  c("nutrient_targeting", "energy_only")
}

resolve_foraging_mode <- function(herbivore) {
  if (is.null(herbivore$foraging_mode) || length(herbivore$foraging_mode) != 1L) {
    return("nutrient_targeting")
  }

  mode <- as.character(herbivore$foraging_mode)
  if (!nzchar(mode) || !mode %in% foraging_mode_levels()) {
    return("nutrient_targeting")
  }

  mode
}
