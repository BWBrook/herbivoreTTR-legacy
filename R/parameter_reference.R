# Canonical parameter and units reference helpers.

canonical_smoke_parameters <- function(conditions = init_conditions(mode = "flat")) {
  scenario_path <- scenario_contract_reference_path("canonical_smoke_v1")
  if (file.exists(scenario_path)) {
    scenario <- compile_scenario_yaml(scenario_path)
    return(scenario_to_canonical_parameters(scenario, conditions = conditions))
  }

  start_day <- CONSTANTS$SPIN_UP_LENGTH * nrow(conditions) + 1L

  list(
    temp_mode = "flat",
    veg_types = c(0L, 1L, 2L),
    herbivore_mass = 5e5,
    herb_type = 0L,
    herbivore_mrt = 24L,
    herbivore_foraging_mode = "nutrient_targeting",
    minute_limit = 60L,
    start_day = as.integer(start_day),
    days = 7L,
    seed = 1L,
    scenario_slug = "smoke_v0"
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
      "HERBIVORE_MRT", "MRT_MIN_HOURS", "MRT_MAX_HOURS",
      "DIGESTION_INIT_FILL_FRACTION",
      "DIGESTION_INIT_LEAF_FRACTION", "DIGESTION_INIT_STEM_FRACTION",
      "DIGESTION_INIT_DEFENCE_FRACTION",
      "NPE_TO_PE_TARGET", "DP_TO_DC_TARGET",
      "MIN_SHOOT", "BROWSE_HEIGHT",
      "GRAZER_GRASS_PREF", "GRAZER_WOODY_PREF",
      "BROWSER_GRASS_PREF", "BROWSER_WOODY_PREF",
      "MIXED_BROWSER_WEIGHT",
      "TASTINESS_RATIO_WEIGHT", "TASTINESS_DISTANCE_WEIGHT",
      "TASTINESS_DEFENCE_WEIGHT", "TASTINESS_EPSILON",
      "MOVEMENT_DISRUPTION_PROB",
      "SANITY_MAX_DAILY_ENERGY_JUMP", "SANITY_MAX_DAILY_WATER_JUMP",
      "TTR_MAX_POOL_ABS", "TTR_MAX_DAILY_POOL_MULTIPLIER",
      "TTR_MAX_DEFENCE_FRACTION", "TTR_DEFENCE_ALLOCATION_PROP"
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
      "Default mean retention time used for herbivore queue initialisation",
      "Minimum allowed explicit MRT parameter",
      "Maximum allowed explicit MRT parameter",
      "Initial gut-fill fraction used to seed digestion queues",
      "Seeded gut biomass share allocated to leaf pool",
      "Seeded gut biomass share allocated to stem pool",
      "Seeded gut biomass share allocated to defence pool",
      "Daily target ratio for non-protein:protein energy",
      "Daily target ratio for digestible protein:digestible carbohydrate",
      "Minimum shoot biomass left for plant persistence",
      "Maximum browse height for browser/mixed access",
      "Grazer tastiness multiplier applied to grass veg types (0/1)",
      "Grazer tastiness multiplier applied to woody veg type (2)",
      "Browser tastiness multiplier applied to grass veg types (0/1)",
      "Browser tastiness multiplier applied to woody veg type (2)",
      "Mixed-feeder interpolation weight between grazer and browser policy",
      "Selection denominator weight for nutrient-ratio mismatch penalty",
      "Selection denominator weight for distance penalty",
      "Selection denominator weight for defence penalty",
      "Numeric floor in tastiness denominator",
      "Probability of dropping and reselecting target while moving",
      "Maximum tolerated day-to-day energy jump (sanity guard)",
      "Maximum tolerated day-to-day water jump (sanity guard)",
      "Maximum absolute per-plant pool value for TTR stability",
      "Maximum tolerated one-day multiplicative jump in key TTR pools",
      "Maximum defence biomass fraction of shoot mass",
      "Default fraction of shoot growth allocated to defence biomass"
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
      "hour",
      "hour",
      "hour",
      "unitless fraction",
      "unitless fraction",
      "unitless fraction",
      "unitless fraction",
      "unitless ratio",
      "unitless ratio",
      "kg DM",
      "m",
      "unitless",
      "unitless",
      "unitless",
      "unitless",
      "unitless",
      "unitless",
      "unitless",
      "unitless",
      "unitless",
      "unitless probability",
      "kJ / day",
      "water units / day",
      "pool units",
      "unitless",
      "unitless",
      "unitless"
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
      "Digestion policy (v0.4.6)",
      "Digestion policy guardrail (v0.4.6)",
      "Digestion policy guardrail (v0.4.6)",
      "Digestion initialisation policy (v0.4.6)",
      "Digestion initialisation policy (v0.4.6)",
      "Digestion initialisation policy (v0.4.6)",
      "Digestion initialisation policy (v0.4.6)",
      "Model target definition (v0)",
      "Model target proxy definition (v0)",
      "Model assumption (v0)",
      "Model assumption (v0)",
      "Functional-type policy (v0.4.1)",
      "Functional-type policy (v0.4.1)",
      "Functional-type policy (v0.4.1)",
      "Functional-type policy (v0.4.1)",
      "Mixed-feeder policy (v0.4.2)",
      "Plant-selection contract (v0.4.3)",
      "Plant-selection contract (v0.4.3)",
      "Plant-selection contract (v0.4.3)",
      "Plant-selection contract (v0.4.3)",
      "Movement contract (v0.4.4)",
      "Domain sanity policy (v0)",
      "Domain sanity policy (v0)",
      "TTR stability policy (v0)",
      "TTR stability policy (v0)",
      "TTR stability policy (v0)",
      "TTR stability policy (v0)"
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
