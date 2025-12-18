## Declare non-standard evaluation (NSE) symbols for R CMD check
utils::globalVariables(c(
  # plant columns
  "plant_id", "xcor", "ycor", "ms", "mr", "cs", "cr", "ns", "nr",
  "bleaf", "bstem", "bdef", "height", "uc", "un", "gs", "gr", "gd",
  "rsC", "rrC", "rdC", "rsN", "rrN", "rdN", "tauC", "tauN", "tauCd", "tauNd",
  # temporary mutate fields
  ".data", "delta_ms", "dx", "dy", "distance", "ratio_diff", "tastiness",
  # herbivore list fields used in dplyr contexts
  "selected_plant_id"
))
