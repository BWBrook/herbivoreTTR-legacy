#' Consume biomass from the selected plant (robust)
#'
#' Internal helper that transfers intake from a selected plant to the
#' herbivore's gut and updates plant biomass. Handles constraints:
#' handling-rate, gut capacity, remaining plant biomass, and an optional
#' mechanical cap (CONSTANTS$MAX_BITE_FRACTION, g/min as a fraction of gut).
#' Intake is constrained to keep at least `CONSTANTS$MIN_SHOOT` kg of standing
#' shoot biomass on each plant.
#'
#' @param herbivore Herbivore state list; requires `selected_plant_id`,
#'   `handling_time` (min/g), `gut_capacity` (g), `gut_content` (g),
#'   and `digestion` vectors.
#' @param plants data.frame with at least `plant_id`, `ms`, `bleaf`, `bstem`, `bdef`.
#' @return list(herbivore=..., plants=...)
#' @keywords internal
herbivore_eat <- function(herbivore, plants) {

  ## 0) Resolve the target plant row (fail-safe no-ops)
  pid <- herbivore$selected_plant_id
  if (is.null(pid) || is.na(pid)) {
    return(list(herbivore = herbivore, plants = plants))
  }
  row_idx <- which(plants$plant_id == pid)
  if (length(row_idx) != 1L) {
    # target vanished or ambiguous
    return(list(herbivore = herbivore, plants = plants))
  }
  plant <- plants[row_idx, , drop = FALSE]

  ## 1) Pull pools and coalesce NAs
  bleaf <- ifelse(is.finite(plant$bleaf), plant$bleaf, 0)
  bstem <- ifelse(is.finite(plant$bstem), plant$bstem, 0)
  bdef  <- if ("bdef" %in% names(plant)) ifelse(is.finite(plant$bdef), plant$bdef, 0) else 0
  total_shoot <- bleaf + bstem + bdef
  if (!is.finite(total_shoot) || total_shoot <= 0) {
    return(list(herbivore = herbivore, plants = plants))
  }
  prop_defence <- max(min(bdef / total_shoot, 1), 0)
  min_shoot_residual <- if (is.finite(CONSTANTS$MIN_SHOOT)) {
    max(CONSTANTS$MIN_SHOOT, 0)
  } else {
    0
  }

  ## 2) Per-minute intake constraints (all NA-safe)
  # Handling: handling_time is min per g  -> g/min -> kg/min
  rate_g_per_min <- if (is.finite(herbivore$handling_time) && herbivore$handling_time > 0) {
    1 / herbivore$handling_time
  } else 0
  intake_rate_kg <- (rate_g_per_min / 1000) * (1 - prop_defence)
  if (!is.finite(intake_rate_kg) || intake_rate_kg < 0) intake_rate_kg <- 0

  # Capacity (kg)
  capacity_kg <- (herbivore$gut_capacity - herbivore$gut_content) / 1000
  if (!is.finite(capacity_kg) || capacity_kg < 0) capacity_kg <- 0

  # Available plant (kg) above a minimum standing shoot.
  # Use component pools directly so ms/component drift cannot violate floor.
  available_plant_kg <- total_shoot - min_shoot_residual
  if (!is.finite(available_plant_kg) || available_plant_kg < 0) available_plant_kg <- 0

  # Optional: mechanical cap per minute as a fraction of gut capacity
  mechanical_cap_kg <- if (!is.null(CONSTANTS$MAX_BITE_FRACTION)) {
    max(CONSTANTS$MAX_BITE_FRACTION, 0) * herbivore$gut_capacity / 1000
  } else Inf

  # Combine limits; ignore NAs; if all NA, fall back to 0
  limits <- c(intake_rate_kg, capacity_kg, available_plant_kg, mechanical_cap_kg)
  potential_intake_kg <- suppressWarnings(min(limits, na.rm = TRUE))
  if (!is.finite(potential_intake_kg)) potential_intake_kg <- 0

  # No feasible intake this minute
  if (potential_intake_kg <= 0) {
    return(list(herbivore = herbivore, plants = plants))
  }

  ## 3) Allocate intake across leaf/stem/defence by current proportions
  share_leaf <- if (bleaf > 0) bleaf / total_shoot else 0
  share_stem <- if (bstem > 0) bstem / total_shoot else 0
  share_def  <- 1 - share_leaf - share_stem
  if (share_def < 0) share_def <- 0  # guard rounding

  leaf_intake_kg <- potential_intake_kg * share_leaf
  stem_intake_kg <- potential_intake_kg * share_stem
  def_intake_kg  <- potential_intake_kg * share_def

  ## 4) Push grams into the first hour slot of digestion queues
  herbivore$MRT <- resolve_mrt_hours(herbivore$MRT)
  if (!is.list(herbivore$digestion)) {
    herbivore$digestion <- empty_digestion_state(herbivore$MRT)
  }
  for (nm in digestion_queue_names()) {
    herbivore$digestion[[nm]] <- normalize_digestion_queue(herbivore$digestion[[nm]], herbivore$MRT)
  }

  # DM -> grams into biomass queues
  herbivore$digestion$bleaf[1] <- herbivore$digestion$bleaf[1] + leaf_intake_kg * 1000
  herbivore$digestion$bstem[1] <- herbivore$digestion$bstem[1] + stem_intake_kg * 1000
  herbivore$digestion$bdef[1]  <- herbivore$digestion$bdef[1]  + def_intake_kg  * 1000

  # Schedule digestible grams (carb/protein) for later release
  herbivore$digestion$dc_leaf[1] <- herbivore$digestion$dc_leaf[1] + digestible_carbs_from_biomass_kg(leaf_intake_kg)
  herbivore$digestion$dc_stem[1] <- herbivore$digestion$dc_stem[1] + digestible_carbs_from_biomass_kg(stem_intake_kg)
  herbivore$digestion$dp_leaf[1] <- herbivore$digestion$dp_leaf[1] + digestible_protein_from_biomass_kg(leaf_intake_kg)
  herbivore$digestion$dp_stem[1] <- herbivore$digestion$dp_stem[1] + digestible_protein_from_biomass_kg(stem_intake_kg)
  herbivore$digestion$dp_def[1]  <- herbivore$digestion$dp_def[1]  + digestible_protein_from_biomass_kg(def_intake_kg)

  ## 5) Update plant state (in kg) for the target row only
  new_bleaf <- max(bleaf - leaf_intake_kg, 0)
  new_bstem <- max(bstem - stem_intake_kg, 0)
  new_bdef  <- max(bdef  - def_intake_kg,  0)
  new_ms <- max(new_bleaf + new_bstem + new_bdef, 0)

  plants$bleaf[row_idx] <- new_bleaf
  plants$bstem[row_idx] <- new_bstem
  plants$bdef[row_idx]  <- new_bdef
  plants$ms[row_idx]    <- new_ms

  ## 6) Update herbivore daily totals and gut content
  herbivore$intake_total_day <- herbivore$intake_total_day + potential_intake_kg * 1000
  herbivore$intake_defence_day <- herbivore$intake_defence_day + def_intake_kg * 1000
  herbivore <- update_gut_content(herbivore)

  list(herbivore = herbivore, plants = plants)
}
