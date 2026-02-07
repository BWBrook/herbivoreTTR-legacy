#' Initialise a herbivore agent
#'
#' Constructs a herbivore list with spatial state, gut compartments, and
#' daily trackers. Derived foraging traits are computed from mass.
#'
#' @param mass Herbivore mass (g).
#' @param herb_type Integer behaviour type (0=grazer, 1=browser, 2=mixed).
#' @param MRT Mean retention time (hours) for gut compartments.
#' @param herbivore_id Stable herbivore identifier.
#' @return Herbivore state list ready for simulation.
#' @examples
#' h <- init_herbivore()
#' @export
init_herbivore <- function(mass = 5e5, herb_type = 0, MRT = 24, herbivore_id = "herbivore_1") {
  MRT <- resolve_mrt_hours(MRT)

  if (!is.character(herbivore_id) || length(herbivore_id) != 1L || !nzchar(herbivore_id)) {
    rlang::abort(
      "Argument `herbivore_id` must be a non-empty scalar character.",
      class = "herbivoreTTR_init_herbivore_id_invalid",
      herbivore_id = herbivore_id
    )
  }

  herbivore <- list(
    herbivore_id = herbivore_id,
    mass = mass,                                   # [g] average white rhino is 2.18e6 (Steuer et al. 2010)
    herb_type = herb_type,                         # GRAZER, BROWSER, MIXED
    mixed_browser_weight = CONSTANTS$MIXED_BROWSER_WEIGHT, # interpolation weight used when herb_type == 2
    movement_disruption_prob = CONSTANTS$MOVEMENT_DISRUPTION_PROB, # chance of dropping target while moving
    foraging_mode = "nutrient_targeting",         # nutrient_targeting or energy_only selection objective
    forage_access_scale = 1,                      # daily forage-access scaling factor in (0,1]
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
    daily_water_intake_total = 0,                  # total daily water intake including drinking [g]
    water_requirement_day = 0,                     # daily water requirement used for diagnostics [g]
    water_balance_ratio = 0,                       # daily net water / requirement ratio [unitless]
    maintenance_energy_requirement_day = 0,        # daily maintenance requirement [kJ]
    total_energy_requirement_day = 0,              # daily total energy requirement [kJ]
    daily_energy_intake = 0,                       # daily energy intake [kJ]
    daily_energy_delta = 0,                        # daily energy intake minus requirement [kJ]
    energy_balance_ratio = 0,                      # daily energy delta / requirement ratio [unitless]
    energy_deficit_streak_days = 0L,               # consecutive days with negative daily energy delta
    water_deficit_streak_days = 0L,                # consecutive days with negative daily water balance
    physiological_stress_flag = 0L,                # stress indicator derived from deficits and body condition
    body_condition_index = CONSTANTS$BODY_CONDITION_INITIAL, # body condition index [0,1]
    baseline_time_spent_foraging = 12,             # baseline daily foraging hours
    body_condition_feedback_enabled = TRUE,        # body-condition feedback switch
    body_condition_gain_coeff = CONSTANTS$BODY_CONDITION_GAIN_COEFF,
    body_condition_loss_coeff = CONSTANTS$BODY_CONDITION_LOSS_COEFF,
    body_condition_effort_threshold = CONSTANTS$BODY_CONDITION_EFFORT_THRESHOLD,
    body_condition_stress_threshold = CONSTANTS$BODY_CONDITION_STRESS_THRESHOLD,
    body_condition_max_foraging_boost = CONSTANTS$BODY_CONDITION_MAX_FORAGING_BOOST,
    energy_balance = 0,                            # energy balance [kJ]
    water_balance = 0,                             # water balance [g]
    digestion = empty_digestion_state(MRT)
  )

  # Calculated parameters
  herbivore <- calc_foraging_traits(herbivore)
  herbivore <- initialise_herbivore_digestion(herbivore)
  herbivore$daily_water_requirement <- calc_water_requirement(mass)
  herbivore$water_requirement_day <- herbivore$daily_water_requirement

  herbivore
}
