#' Package constants
#'
#' Collection of simulation and model constants used throughout the package,
#' including herbivore allometries, energy and water conversions, simulation
#' geometry, and TTR model parameters.
#'
#' Units are indicated inline where applicable. Some parameters (e.g.
#' seasonal temperature envelopes) are used to construct forcing functions.
#'
#' @format A named list of numeric scalars.
#' @name CONSTANTS
NULL

# Simulation and model constants
CONSTANTS <- list(

  # Herbivore constants
  GUT_CAPACITY_A = 0.03,       # g : Muller et al. (2013) - all herbivores >10kg, see Table 6
  GUT_CAPACITY_B = 0.924,      # Muller et al. (2013) - all herbivores >10kg, see Table 6
  BITE_SIZE_A = 0.096,         # g : Shipley et al. (1994)
  BITE_SIZE_B = 0.72,          # Shipley et al. (1994)
  MAX_BITE_FRACTION = 0.05,    # e.g., 5% of gut capacity per minute
  HANDLING_TIME_A = 1.65,      # Jeschke & Tollrian (2005)
  HANDLING_TIME_B = -0.766,    # Jeschke & Tollrian (2005)
  CONTINUE_K = 8,              # controls sensitivity to dp:dc mismatch
  M_REF = 10,                  # sets the mass (kg) consumed on given   plant where size benefits saturate
  FORAGE_VEL_A = 0.73,         # Shipley et al. (1996)
  FORAGE_VEL_B = 0.04,         # Shipley et al. (1996)
  ENERGY_MAINTENANCE_A = 293,  # Kleiber (1961)
  ENERGY_MAINTENANCE_B = 0.75, # Kleiber (1961)
  ICL_A = 10678,               # Taylor (1980)
  ICL_B = 0.7,                 # Taylor (1980)
  WATER_TURNOVER = 0.088,      # water turnover [L/kg body mass/24 hrs] for camels, taken from McFarlane (1965). (cattle = 0.148, sheep = 0.110, camels = 0.061, red kangaroo = 0.088)
  DIST_TO_WATER = 1e2,         # average distance to a water point in m (assume 50m each way, so 100m total)

  # Conversion constants
  CARB_TO_ENERGY = 16.7,    # kJ/g :  Felton et al. (2017)
  PROTEIN_TO_ENERGY = 23.0, # kJ/g from Felton :  Felton et al. (2017)
  CARB_TO_MW = 0.62,        # g water/g carbohydrate : metabolic water produced from digesting [g] carbohydrate (from Giger-Reverdin & Gihad 1991)
  PROTEIN_TO_MW = 0.42,     # g water/g protein :  metabolic water produced from digesting [g] protein (from Giger-Reverdin & Gihad 1991)
  PROP_DIGEST_SC = 0.63,    # proportion of structural carbohydrates that are digested (Tilley et al. (1969) for ruminants and grasses (would be nice to get this for woody vegetation))
  PROP_DIGEST_TP = 0.5,     # proportion of total protein that is digested (Navas-Camacho et al. (1993))
  N_TO_PROTEIN = 6.25,      # Felton et al. (2017)

  # Simulation setup
  MIN_SHOOT = 1e-3,         # kg DM, minimum shoot biomass [kg] at which herbivore will cease to eat (1e3 = 1g)
  LEAF_HEIGHT = 1.0,        # height factor for browsing calculation
  BROWSE_HEIGHT = 2.0,      # [m] maximum height at which the herbivore can browse (not utilised for grazers)
  DETECTION_DISTANCE = 10,  # maximum distance at which a herbivore can detect plants [m]
  EAT_RADIUS = 1.0,         # distance at which a herbivore can commence eating a plant [m]
  NPE_TO_PE_TARGET = 4.55,  # ratio non-protein energy to protein energy
  PLANT_DENSITY = 0.25,     # local availability of plants in the area
  DP_TO_DC_TARGET = 0.2,    # digestible protein to digestible carbohydrate target
  TEMP_WATER_SCALING = 0.1, # scaling water requirements based on temperature
  SANITY_MAX_DAILY_ENERGY_JUMP = 1e5, # kJ/day: max tolerated day-to-day energy balance jump in canonical runs
  SANITY_MAX_DAILY_WATER_JUMP = 5e4,  # water units/day: max tolerated day-to-day water balance jump in canonical runs
  TTR_MAX_POOL_ABS = 1e4,             # absolute per-plant pool cap used by TTR stability guardrails
  TTR_MAX_DAILY_POOL_MULTIPLIER = 5,  # max tolerated one-day multiplicative jump in key TTR pools
  TTR_MAX_DEFENCE_FRACTION = 0.35,    # upper bound: defence biomass as fraction of shoot mass
  TTR_DEFENCE_ALLOCATION_PROP = 1e-4, # default share of shoot growth routed to structural defence pool

  # Plot settings
  PLANTS_IN_X = 20,
  PLANTS_IN_Y = 20,
  PLANTS_PER_PLOT = NA_integer_,               # set after list construction to avoid self-reference
  PLOT_SIZE = 10000,                           # m^2 = 1 ha
  PLANT_INITIAL_MASS_MIN = 1,                  # kg DM
  PLANT_INITIAL_MASS_MAX = 100,                # kg DM
  HERBIVORES_PER_PLOT = 1,                     # number of herbivores in a plot

  # Thornley Transport Resistance (TTR) constants (mirroring C++ reference)
  K_LITTER        = 0.01,   # per day: litter production rate (proportion/day)
  K_M_LITTER      = 5,      # kg XDM: litter mass scale parameter
  G_SHOOT         = 25,     # per day scaling: shoot growth [kg C/kg N/kg XDM^2]/day
  G_ROOT          = 25,     # per day scaling: root growth [kg C/kg N/kg XDM^2]/day
  G_DEFENCE       = 1,      # per day scaling: defence growth [kg C/kg N/kg XDM^2]/day
  K_C             = 0.1,    # per day: C input rate [kg C/kg shoot XDM/day]
  K_N             = 0.01,   # per day: N input rate [kg N/kg shoot XDM/day]
  K_M             = 10,     # kg XDM: mass scale for uptake saturation
  PI_C            = 0.1,    # kg C/kg XDM: product inhibition for C uptake
  PI_N            = 0.01,   # kg N/kg XDM: product inhibition for N uptake
  Q_SCP           = 2/3,    # unitless: transport resistance exponent
  TR_C            = 1.0,    # XDM^(Q_SCP-1)/day: C transport resistance scale
  TR_N            = 1.0,    # XDM^(Q_SCP-1)/day: N transport resistance scale
  FRACTION_C      = 0.45,   # kg C/kg XDM: carbon fraction of dry matter
  FRACTION_N      = 0.02,   # kg N/kg XDM: nitrogen fraction of dry matter
  PHENO_SWITCH    = 10,     # deg C: phenology temperature threshold
  ACCEL_LEAF_LOSS = 3 ,     # unitless multiplier: accelerated leaf loss factor
  TEMP_GROWTH_1   = 1,      # deg C: growth envelope parameter
  TEMP_GROWTH_2   = 24,     # deg C: growth envelope parameter
  TEMP_GROWTH_3   = 26,     # deg C: growth envelope parameter
  TEMP_GROWTH_4   = 40,     # deg C: growth envelope parameter
  TEMP_PHOTO_1    = 1,      # deg C: photosynthesis envelope parameter
  TEMP_PHOTO_2    = 15,     # deg C: photosynthesis envelope parameter
  TEMP_PHOTO_3    = 25,     # deg C: photosynthesis envelope parameter
  TEMP_PHOTO_4    = 35,     # deg C: photosynthesis envelope parameter
  INIT_SW         = 0.5,    # relative soil water (0–1)
  INIT_N          = 0.5,    # relative soil N (0–1)
  HERBIVORY       = 1,      # 0/1 switch: enable herbivory in daily loop
  DEFENCE_ENABLED = 0,      # 0/1 switch: enable defence transport/growth wiring

    # Time settings
  SPIN_UP_LENGTH = 5, # number of years to run vegetation model before herbivory switches on
  HERBIVORE_MRT = 24, # mean gut retention time in hours (16 to 48 hours, default to 28)

  # OTHER SETTINGS
  TOLERANCE = 0.0001 # calculation buffer
)

# set derived constants after list construction (avoid self-reference during list eval)
CONSTANTS$PLANTS_PER_PLOT = CONSTANTS$PLANTS_IN_X * CONSTANTS$PLANTS_IN_Y
