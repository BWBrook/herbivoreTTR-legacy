#' Initialise a herbivore agent
#'
#' Constructs a herbivore list with spatial state, gut compartments, and
#' daily trackers. Derived foraging traits are computed from mass.
#'
#' @param mass Herbivore mass (g).
#' @param herb_type Integer behaviour type (0=grazer, 1=browser, 2=mixed).
#' @param MRT Mean retention time (hours) for gut compartments.
#' @return Herbivore state list ready for simulation.
#' @examples
#' h <- init_herbivore()
#' @export
init_herbivore <- function(mass = 5e5, herb_type = 0, MRT = 24) {
  MRT <- resolve_mrt_hours(MRT)

  herbivore <- list(
    mass = mass,                                   # [g] average white rhino is 2.18e6 (Steuer et al. 2010)
    herb_type = herb_type,                         # GRAZER, BROWSER, MIXED
    mixed_browser_weight = CONSTANTS$MIXED_BROWSER_WEIGHT, # interpolation weight used when herb_type == 2
    movement_disruption_prob = CONSTANTS$MOVEMENT_DISRUPTION_PROB, # chance of dropping target while moving
    foraging_mode = "nutrient_targeting",         # nutrient_targeting or energy_only selection objective
    xcor = runif(1, 0, sqrt(CONSTANTS$PLOT_SIZE)), # x-coordinate
    ycor = runif(1, 0, sqrt(CONSTANTS$PLOT_SIZE)), # y-coordinate
    current_hour = 0,                              # hour the herbivore is currently foraging in (continuous across days)
    last_hour = 0,                                 # hour the herbivore was foraging in last time step (continuous across days)
    MRT = MRT,                                     # mean time to digest food in gut [hrs]
    behaviour = "MOVING",                          # MOVING, EATING, REST
    selected_plant_id = NA_integer_,               # ID of selected plant
    selected_plant_dist = NA_real_,                # distance from herbivore to selected plant [m]
    gut_content = 0,                               # current mass of gut content [g]
    distance_moved = 0,                            # distance moved in a day [m]
    time_spent_foraging = 12,                      # time spent foraging in a day [hrs]
    intake_total_day = 0,                          # total daily intake [g DM]
    intake_digest_carbs_day = 0,                   # total daily digestible carbohydrate intake [g DM]
    intake_digest_protein_day = 0,                 # total daily digestible protein intake [g DM]
    intake_PE_day = 0,                             # total daily protein energy intake [kJ]
    intake_NPE_day = 0,                            # total daily non-protein energy intake [kJ]
    intake_defence_day = 0,                        # total daily plant defence intake [g DM]
    intake_total = 0,                              # total intake over simulation [g DM]
    metabolic_water_day = 0,                       # total daily metabolic water produced [g]
    intake_water_forage = 0,                       # total daily water intake from forage [g]
    intake_water_drinking = 0,                     # total daily water intake from drinking [g]
    daily_net_water_balance = 0,                   # net daily water balance increment [g]
    energy_balance = 0,                            # energy balance [kJ]
    water_balance = 0,                             # water balance [g]
    digestion = empty_digestion_state(MRT)
  )

  # Calculated parameters
  herbivore <- calc_foraging_traits(herbivore)
  herbivore <- initialise_herbivore_digestion(herbivore)
  herbivore$daily_water_requirement <- calc_water_requirement(mass)

  return(herbivore)
}
