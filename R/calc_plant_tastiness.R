#' Plant 'tastiness' score
#'
#' Heuristic plant-selection score used as stochastic sampling weight.
#'
#' Score direction of effect (all else equal):
#' - Higher nutrient mismatch (`DP:DC` vs target) reduces score.
#' - Greater distance reduces score.
#' - Higher structural defence biomass (`bdef`) reduces score.
#' - Larger shoot biomass (`ms`) increases score up to a saturation scale.
#' - Functional-type multipliers (`herb_type`) up/down-weight vegetation types.
#'
#' Constraint gating:
#' - Plants beyond `CONSTANTS$DETECTION_DISTANCE` are assigned score `0`.
#' - Plants at or below `CONSTANTS$MIN_SHOOT` are assigned score `0`.
#' - Browser/mixed feeders (`herb_type %in% c(1, 2)`) assign score `0` to
#'   plants above browse reach (`LEAF_HEIGHT * height > BROWSE_HEIGHT`) when
#'   a `height` column is present.
#'
#' @param plants_in_range data.frame of nearby plants; expects `ns`, `cs`,
#'   `distance`, optional `bdef`, and optional `ms` (shoot biomass).
#' @param herbivore Herbivore state list used for functional-type weighting and
#'   browse-height gating.
#' @param desired_dp_dc_ratio Numeric target ratio of digestible protein to
#'   digestible carbohydrate.
#' @return Numeric vector of tastiness scores aligned to `plants_in_range`.
#' @examples
#' # scores <- calc_plant_tastiness(plants_in_range, herb, 0.2)
#' @export
calc_plant_tastiness <- function(plants_in_range, herbivore, desired_dp_dc_ratio) {
  n <- nrow(plants_in_range)
  if (n == 0L) {
    return(numeric(0))
  }

  safe_column <- function(name, default = 0) {
    if (!name %in% names(plants_in_range)) {
      return(rep(default, n))
    }
    values <- as.numeric(plants_in_range[[name]])
    values[!is.finite(values)] <- default
    values
  }

  ns <- safe_column("ns", default = NA_real_)
  cs <- safe_column("cs", default = NA_real_)
  distance <- pmax(safe_column("distance", default = 0), 0)
  defence <- pmax(safe_column("bdef", default = 0), 0)
  shoot_mass <- pmax(safe_column("ms", default = CONSTANTS$MIN_SHOOT + 1), 0)

  digestible_protein <- ns / CONSTANTS$N_TO_PROTEIN
  digestible_carb <- cs * CONSTANTS$PROP_DIGEST_SC
  plant_dp_dc <- ifelse(
    is.finite(digestible_carb) & digestible_carb > CONSTANTS$TOLERANCE,
    digestible_protein / digestible_carb,
    NA_real_
  )
  ratio_diff <- abs(desired_dp_dc_ratio - plant_dp_dc)
  ratio_diff[!is.finite(ratio_diff)] <- Inf
  foraging_mode <- resolve_foraging_mode(herbivore)
  ratio_weight <- if (identical(foraging_mode, "energy_only")) {
    0
  } else {
    CONSTANTS$TASTINESS_RATIO_WEIGHT
  }

  size_bonus <- {
    denom <- log1p(CONSTANTS$M_REF)
    if (!is.finite(denom) || denom <= 0) {
      rep(1, n)
    } else {
      pmax(log1p(shoot_mass) / denom, 0)
    }
  }

  if ("veg_type" %in% names(plants_in_range)) {
    functional_multiplier <- functional_type_preference_multiplier(
      herbivore = herbivore,
      veg_type = plants_in_range$veg_type
    )
  } else {
    functional_multiplier <- rep(1, n)
  }

  eligible <- distance <= CONSTANTS$DETECTION_DISTANCE &
    shoot_mass > CONSTANTS$MIN_SHOOT

  herb_type <- normalize_herb_type(herbivore$herb_type)
  if (herb_type %in% c(1L, 2L) && "height" %in% names(plants_in_range)) {
    height <- safe_column("height", default = Inf)
    reachable <- CONSTANTS$LEAF_HEIGHT * height <= CONSTANTS$BROWSE_HEIGHT
    eligible <- eligible & reachable
  }

  denom <- CONSTANTS$TASTINESS_EPSILON +
    ratio_weight * ratio_diff +
    CONSTANTS$TASTINESS_DISTANCE_WEIGHT * distance +
    CONSTANTS$TASTINESS_DEFENCE_WEIGHT * defence

  tastiness <- functional_multiplier * size_bonus / denom
  tastiness[!is.finite(tastiness)] <- 0
  tastiness[!eligible] <- 0
  pmax(tastiness, 0)
}
