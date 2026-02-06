# Canonical parameter and units reference helpers.

canonical_smoke_parameters <- function(conditions = init_conditions(mode = "flat")) {
  start_day <- CONSTANTS$SPIN_UP_LENGTH * nrow(conditions) + 1L

  list(
    temp_mode = "flat",
    veg_types = c(0L, 1L, 2L),
    herbivore_mass = 5e5,
    minute_limit = 60L,
    start_day = as.integer(start_day),
    days = 7L
  )
}

parameter_reference_table <- function() {
  refs <- data.frame(
    parameter = c(
      "GUT_CAPACITY_A", "GUT_CAPACITY_B",
      "BITE_SIZE_A", "BITE_SIZE_B",
      "HANDLING_TIME_A", "HANDLING_TIME_B",
      "FORAGE_VEL_A", "FORAGE_VEL_B",
      "ENERGY_MAINTENANCE_A", "ENERGY_MAINTENANCE_B",
      "ICL_A", "ICL_B",
      "WATER_TURNOVER", "DIST_TO_WATER",
      "NPE_TO_PE_TARGET", "DP_TO_DC_TARGET",
      "MIN_SHOOT", "BROWSE_HEIGHT",
      "SANITY_MAX_DAILY_ENERGY_JUMP", "SANITY_MAX_DAILY_WATER_JUMP"
    ),
    description = c(
      "Gut capacity allometry coefficient",
      "Gut capacity allometry exponent",
      "Bite size allometry coefficient",
      "Bite size allometry exponent",
      "Handling time allometry coefficient",
      "Handling time allometry exponent",
      "Foraging velocity allometry coefficient",
      "Foraging velocity allometry exponent",
      "Maintenance cost allometry coefficient",
      "Maintenance cost allometry exponent",
      "Locomotion cost allometry coefficient",
      "Locomotion cost allometry exponent",
      "Daily water turnover coefficient",
      "Distance travelled to drink when deficit occurs",
      "Daily target ratio for non-protein:protein energy",
      "Daily target ratio for digestible protein:digestible carbohydrate",
      "Minimum shoot biomass left for plant persistence",
      "Maximum browse height for browser/mixed access",
      "Maximum tolerated day-to-day energy jump (sanity guard)",
      "Maximum tolerated day-to-day water jump (sanity guard)"
    ),
    units = c(
      "kg DM / kg body mass^B",
      "unitless",
      "g DM / bite / kg body mass^B",
      "unitless",
      "min / g DM / kg body mass^B",
      "unitless",
      "m / s / kg body mass^B",
      "unitless",
      "kJ / day / kg body mass^B",
      "unitless",
      "J / m / kg body mass^B",
      "unitless",
      "L / kg body mass / day",
      "m / day",
      "unitless ratio",
      "unitless ratio",
      "kg DM",
      "m",
      "kJ / day",
      "water units / day"
    ),
    citation = c(
      "Muller et al. (2013) Table 6",
      "Muller et al. (2013) Table 6",
      "Shipley et al. (1994)",
      "Shipley et al. (1994)",
      "Jeschke and Tollrian (2005)",
      "Jeschke and Tollrian (2005)",
      "Shipley et al. (1996)",
      "Shipley et al. (1996)",
      "Kleiber (1961)",
      "Kleiber (1961)",
      "Taylor et al. (1980)",
      "Taylor et al. (1980)",
      "McFarlane (1965)",
      "Model assumption (v0)",
      "Model target definition (v0)",
      "Model target proxy definition (v0)",
      "Model assumption (v0)",
      "Model assumption (v0)",
      "Domain sanity policy (v0)",
      "Domain sanity policy (v0)"
    ),
    stringsAsFactors = FALSE
  )

  refs$value <- vapply(refs$parameter, function(nm) CONSTANTS[[nm]], numeric(1))
  refs <- refs[, c("parameter", "value", "units", "description", "citation")]
  refs
}

units_conventions_table <- function() {
  data.frame(
    quantity = c(
      "Herbivore body mass",
      "Plant biomass pools",
      "Plant C/N pools",
      "Energy",
      "Water",
      "Distance",
      "Time (plant update)",
      "Time (herbivore loop)",
      "Time (digestion queues)"
    ),
    unit = c(
      "g",
      "kg dry mass",
      "kg C or kg N",
      "kJ",
      "g water equivalent",
      "m",
      "day",
      "minute",
      "hour"
    ),
    notes = c(
      "Stored in grams; allometric equations convert internally to kg where required.",
      "Includes ms/mr/bleaf/bstem/bdef/md.",
      "Includes cs/cr/ns/nr/cd/nd.",
      "Daily balances and maintenance/locomotion costs use kJ.",
      "Water requirement and balances are tracked in gram-equivalent units.",
      "Toroidal movement and water travel penalties are in meters.",
      "TTR growth and transport are updated once per day.",
      "Movement/foraging decisions occur each simulated minute.",
      "Digestion vectors shift once per simulated hour."
    ),
    stringsAsFactors = FALSE
  )
}
