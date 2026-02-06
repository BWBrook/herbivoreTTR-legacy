# Internal helpers for herbivore functional-type preference weights.

functional_type_preference_multiplier <- function(herbivore, veg_type) {
  if (length(veg_type) == 0L) {
    return(numeric())
  }

  herb_type <- normalize_herb_type(herbivore$herb_type)
  is_grass <- veg_type %in% c(0L, 1L)
  is_woody <- veg_type %in% 2L

  if (herb_type == 0L) {
    multipliers <- rep(1, length(veg_type))
    multipliers[is_grass] <- CONSTANTS$GRAZER_GRASS_PREF
    multipliers[is_woody] <- CONSTANTS$GRAZER_WOODY_PREF
    return(multipliers)
  }

  if (herb_type == 1L) {
    multipliers <- rep(1, length(veg_type))
    multipliers[is_grass] <- CONSTANTS$BROWSER_GRASS_PREF
    multipliers[is_woody] <- CONSTANTS$BROWSER_WOODY_PREF
    return(multipliers)
  }

  rep(1, length(veg_type))
}

functional_type_label <- function(herb_type) {
  herb_type <- normalize_herb_type(herb_type)
  if (herb_type == 0L) return("grazer")
  if (herb_type == 1L) return("browser")
  if (herb_type == 2L) return("mixed")
  "unknown"
}

normalize_herb_type <- function(herb_type) {
  if (!is.numeric(herb_type) || length(herb_type) != 1L || !is.finite(herb_type)) {
    return(2L)
  }
  as.integer(herb_type)
}
