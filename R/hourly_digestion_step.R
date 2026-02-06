digestion_queue_names <- function() {
  c("bleaf", "bstem", "bdef", "dc_leaf", "dc_stem", "dp_leaf", "dp_stem", "dp_def")
}

resolve_mrt_hours <- function(MRT = NULL) {
  mrt <- if (is.null(MRT)) CONSTANTS$HERBIVORE_MRT else MRT
  if (!is.numeric(mrt) || length(mrt) != 1L || !is.finite(mrt)) {
    rlang::abort(
      "Argument `MRT` must be a finite scalar numeric value.",
      class = "herbivoreTTR_mrt_invalid",
      MRT = MRT
    )
  }

  mrt <- as.integer(round(mrt))
  min_mrt <- as.integer(CONSTANTS$MRT_MIN_HOURS)
  max_mrt <- as.integer(CONSTANTS$MRT_MAX_HOURS)
  if (!is.finite(min_mrt) || min_mrt < 1L) min_mrt <- 1L
  if (!is.finite(max_mrt) || max_mrt < min_mrt) max_mrt <- min_mrt

  if (mrt < min_mrt || mrt > max_mrt) {
    rlang::abort(
      sprintf("Argument `MRT` must be within [%d, %d] hours.", min_mrt, max_mrt),
      class = "herbivoreTTR_mrt_out_of_bounds",
      MRT = mrt,
      min_mrt = min_mrt,
      max_mrt = max_mrt
    )
  }
  mrt
}

normalize_digestion_queue <- function(values, MRT) {
  k <- resolve_mrt_hours(MRT)
  values <- as.numeric(values)
  if (length(values) < k) values <- c(values, rep(0, k - length(values)))
  if (length(values) > k) values <- values[seq_len(k)]
  values[!is.finite(values) | values < 0] <- 0
  values
}

empty_digestion_state <- function(MRT) {
  k <- resolve_mrt_hours(MRT)
  zeros <- numeric(k)
  stats::setNames(
    rep(list(zeros), length(digestion_queue_names())),
    digestion_queue_names()
  )
}

digestible_carbs_from_biomass_kg <- function(biomass_kg) {
  biomass_kg <- as.numeric(biomass_kg)
  biomass_kg[!is.finite(biomass_kg) | biomass_kg < 0] <- 0
  biomass_kg * CONSTANTS$FRACTION_C * CONSTANTS$PROP_DIGEST_SC * 1000
}

digestible_protein_from_biomass_kg <- function(biomass_kg) {
  biomass_kg <- as.numeric(biomass_kg)
  biomass_kg[!is.finite(biomass_kg) | biomass_kg < 0] <- 0
  biomass_kg * CONSTANTS$FRACTION_N * CONSTANTS$N_TO_PROTEIN * CONSTANTS$PROP_DIGEST_TP * 1000
}

seed_digestion_state <- function(gut_capacity_g,
                                 MRT,
                                 fill_fraction = CONSTANTS$DIGESTION_INIT_FILL_FRACTION) {
  k <- resolve_mrt_hours(MRT)
  digestion <- empty_digestion_state(k)

  if (!is.finite(gut_capacity_g) || gut_capacity_g <= 0) {
    return(digestion)
  }

  fill_fraction <- as.numeric(fill_fraction)
  if (!is.finite(fill_fraction)) fill_fraction <- 0
  fill_fraction <- min(max(fill_fraction, 0), 1)

  total_seed_mass_g <- gut_capacity_g * fill_fraction
  if (!is.finite(total_seed_mass_g) || total_seed_mass_g <= 0) {
    return(digestion)
  }

  composition <- c(
    leaf = as.numeric(CONSTANTS$DIGESTION_INIT_LEAF_FRACTION),
    stem = as.numeric(CONSTANTS$DIGESTION_INIT_STEM_FRACTION),
    defence = as.numeric(CONSTANTS$DIGESTION_INIT_DEFENCE_FRACTION)
  )
  composition[!is.finite(composition) | composition < 0] <- 0
  composition_total <- sum(composition)
  if (!is.finite(composition_total) || composition_total <= 0) {
    composition <- c(leaf = 1, stem = 0, defence = 0)
    composition_total <- 1
  }
  composition <- composition / composition_total

  slot_mass_g <- total_seed_mass_g / k
  digestion$bleaf <- rep(slot_mass_g * composition[["leaf"]], k)
  digestion$bstem <- rep(slot_mass_g * composition[["stem"]], k)
  digestion$bdef <- rep(slot_mass_g * composition[["defence"]], k)

  digestion$dc_leaf <- digestible_carbs_from_biomass_kg(digestion$bleaf / 1000)
  digestion$dc_stem <- digestible_carbs_from_biomass_kg(digestion$bstem / 1000)
  digestion$dp_leaf <- digestible_protein_from_biomass_kg(digestion$bleaf / 1000)
  digestion$dp_stem <- digestible_protein_from_biomass_kg(digestion$bstem / 1000)
  digestion$dp_def <- digestible_protein_from_biomass_kg(digestion$bdef / 1000)

  digestion
}

# Initialise gut queues with a steady-state fill assumption rather than zeros.
initialise_herbivore_digestion <- function(herbivore,
                                           fill_fraction = CONSTANTS$DIGESTION_INIT_FILL_FRACTION) {
  k <- resolve_mrt_hours(herbivore$MRT)
  herbivore$MRT <- k
  herbivore$digestion <- seed_digestion_state(
    gut_capacity_g = herbivore$gut_capacity,
    MRT = k,
    fill_fraction = fill_fraction
  )
  update_gut_content(herbivore)
}

#' Advance digestion by one hour
#'
#' Shifts gut content through hourly compartments, accumulates digestible
#' carbohydrate and protein energy, and accounts for metabolic water
#' production.
#'
#' @param herbivore Herbivore state list containing `MRT` and `digestion`
#'   vectors (`bleaf`, `bstem`, `bdef`, `dc_leaf`, `dc_stem`, `dp_leaf`,
#'   `dp_stem`, `dp_def`).
#' @return Updated `herbivore` list with intake and water fields increased.
#' @examples
#' # herbivore <- hourly_digestion_step(herbivore)
#' @export
hourly_digestion_step <- function(herbivore) {
  k <- resolve_mrt_hours(herbivore$MRT)
  herbivore$MRT <- k
  if (!is.list(herbivore$digestion)) {
    herbivore$digestion <- empty_digestion_state(k)
  }

  for (nm in digestion_queue_names()) {
    herbivore$digestion[[nm]] <- normalize_digestion_queue(herbivore$digestion[[nm]], k)
  }

  digested_carbs <- herbivore$digestion$dc_leaf[k] + herbivore$digestion$dc_stem[k]
  digested_prot <- herbivore$digestion$dp_leaf[k] + herbivore$digestion$dp_stem[k] + herbivore$digestion$dp_def[k]

  herbivore$intake_digest_carbs_day <- herbivore$intake_digest_carbs_day + digested_carbs
  herbivore$intake_digest_protein_day <- herbivore$intake_digest_protein_day + digested_prot
  herbivore$intake_NPE_day <- herbivore$intake_NPE_day + digested_carbs * CONSTANTS$CARB_TO_ENERGY
  herbivore$intake_PE_day <- herbivore$intake_PE_day + digested_prot * CONSTANTS$PROTEIN_TO_ENERGY
  herbivore$metabolic_water_day <- herbivore$metabolic_water_day +
    CONSTANTS$CARB_TO_MW * digested_carbs + CONSTANTS$PROTEIN_TO_MW * digested_prot

  for (nm in digestion_queue_names()) {
    queue <- herbivore$digestion[[nm]]
    herbivore$digestion[[nm]] <- c(0, queue[seq_len(k - 1L)])
  }

  update_gut_content(herbivore)
}

set_herbivore_MRT <- function(h, MRT, preserve_content = TRUE) {
  k <- resolve_mrt_hours(MRT)
  h$MRT <- k

  if (isTRUE(preserve_content) && is.list(h$digestion)) {
    redistributed <- empty_digestion_state(k)
    for (nm in digestion_queue_names()) {
      old_queue <- as.numeric(h$digestion[[nm]])
      old_queue[!is.finite(old_queue) | old_queue < 0] <- 0
      total <- sum(old_queue)
      if (is.finite(total) && total > 0) {
        redistributed[[nm]] <- rep(total / k, k)
      }
    }
    h$digestion <- redistributed
    return(update_gut_content(h))
  }

  h$digestion <- empty_digestion_state(k)
  h$gut_content <- 0
  h
}
