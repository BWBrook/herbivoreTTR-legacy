#' Run one simulated herbivore day
#'
#' Coordinates daily behaviour (decision, movement, feeding) and interactions
#' with plants. Also advances the plant state at the start of the day through
#' the configured plant backend and updates daily energy and water balances.
#'
#' @param herbivore Herbivore state list.
#' @param plants data.frame of plant state.
#' @param conditions data.frame of environmental drivers with columns
#'   `temp_mean`, `sw`, `N`.
#' @param day_of_simulation Positive integer day index.
#' @param minute_limit Number of minutes to simulate (default 1440).
#' @param capture_diagnostics Logical; when `TRUE`, the function captures
#'   start/end plant and herbivore states for downstream logging.
#' @param seed Optional integer seed for deterministic RNG behavior during this
#'   function call. The caller RNG state is restored afterwards.
#' @param apply_growth Logical; if `TRUE` daily plant growth is applied before
#'   herbivory. Set `FALSE` when growth was already applied by an outer runner.
#' @param plant_backend Plant backend name or backend interface list.
#' @return List with updated `herbivore`, `plants`, `daily_record` (optional
#'   minute-by-minute snapshots), and `daily_summary`.
#' @examples
#' sim <- init_simulation()
#' res <- run_daily_herbivore_simulation(sim$herbivore, sim$plants, sim$conditions)
#' names(res)
#' @export
run_daily_herbivore_simulation <- function(herbivore, plants, conditions,
                                           day_of_simulation = 1,
                                           minute_limit = 1440,
                                           capture_diagnostics = FALSE,
                                           seed = NULL,
                                           apply_growth = TRUE,
                                           plant_backend = "internal_ttr") {

  with_optional_seed(seed, {

  backend <- resolve_plant_backend(plant_backend)
  day_index <- ((day_of_simulation - 1) %% nrow(conditions)) + 1
  today_temp <- conditions$temp_mean[day_index]

  # Update plants via backend daily step before herbivory.
  diagnostics <- NULL
  if (capture_diagnostics) {
    diagnostics <- list(
      plants_start = plants,
      day_of_simulation = day_of_simulation,
      plant_backend = backend$name
    )
  }

  if (isTRUE(apply_growth)) {
    plants <- backend$step_day(plants, conditions, day_index)
    if (capture_diagnostics) {
      diagnostics$plants_after_growth <- plants
    }
  }

  assert_domain_sanity_state(
    plants = plants,
    herbivore = herbivore,
    day_of_simulation = day_of_simulation,
    minute_of_day = 0L,
    phase = if (isTRUE(apply_growth)) "post_growth" else "pre_foraging",
    check_plants = TRUE,
    check_herbivore = FALSE
  )

  # 1) Reset daily variables for herbivore
  herbivore <- reset_daily_variables(herbivore)

  # 2) Pre-compute foraging traits (bite size, gut capacity, etc.)
  herbivore <- calc_foraging_traits(herbivore)
  if (capture_diagnostics) {
    diagnostics$herbivore_start <- herbivore
  }

  assert_domain_sanity_state(
    plants = plants,
    herbivore = herbivore,
    day_of_simulation = day_of_simulation,
    minute_of_day = 0L,
    phase = "start_of_day"
  )

  # MRT allocation guard
  herbivore$MRT <- resolve_mrt_hours(herbivore$MRT)
  digestion_lengths <- if (is.list(herbivore$digestion)) {
    vapply(
      digestion_queue_names(),
      function(nm) {
        queue <- herbivore$digestion[[nm]]
        if (is.null(queue)) 0L else as.integer(length(queue))
      },
      integer(1L)
    )
  } else {
    integer()
  }
  if (length(digestion_lengths) != length(digestion_queue_names()) ||
      any(digestion_lengths != herbivore$MRT)) {
    herbivore <- set_herbivore_MRT(herbivore, herbivore$MRT, preserve_content = TRUE)
  }

  # 3) Optionally store daily water requirement if you want
  herbivore$daily_water_requirement <- calc_water_requirement(herbivore$mass)

  # 4) Prepare a container for minute-by-minute records (if desired)
  daily_record <- vector("list", minute_limit)

  # Determine if herbivory is active (post spin-up and not disabled)
  spin_up_days <- CONSTANTS$SPIN_UP_LENGTH * nrow(conditions)
  herbivory_active <- isTRUE(CONSTANTS$HERBIVORY != 0) && (day_of_simulation > spin_up_days)

  # 5) Loop through each minute (only if herbivory is active)
  if (herbivory_active) for (minute in seq_len(minute_limit)) {

    # (a) Update gut content
    herbivore <- update_gut_content(herbivore)

    # (b) Decide if the herbivore is still in its foraging window
    if (minute < herbivore$time_spent_foraging * 60) {
      # Use herbivore_step() to handle movement or eating:
      step_result <- herbivore_step(herbivore, plants)
      herbivore  <- step_result$herbivore
      plants     <- step_result$plants
    }

    # (c) Now tick digestion at the end of the hour
    if (minute %% 60 == 0) {
      herbivore <- hourly_digestion_step(herbivore)
    }

    assert_domain_sanity_state(
      plants = plants,
      herbivore = herbivore,
      day_of_simulation = day_of_simulation,
      minute_of_day = as.integer(minute),
      phase = "minute_loop"
    )

    # (d) Optionally record data for debugging
    daily_record[[minute]] <- list(
      minute              = minute,
      xcor                = herbivore$xcor,
      ycor                = herbivore$ycor,
      gut_content         = herbivore$gut_content,
      selected_plant_id   = herbivore$selected_plant_id,
      behaviour           = herbivore$behaviour,
      energy_balance      = herbivore$energy_balance,
      water_balance       = herbivore$water_balance,
      distance_moved      = herbivore$distance_moved,
      intake_total_day    = herbivore$intake_total_day,
      intake_pe_day       = herbivore$intake_PE_day,
      intake_npe_day      = herbivore$intake_NPE_day,
      intake_water_forage = herbivore$intake_water_forage,
      intake_water_drink  = herbivore$intake_water_drinking
    )
  } # end herbivory loop

  plants <- backend$apply_herbivory(plants)

  # 6) At the end of day: check water, finalize energy
  # Set water turnover to depend on temperature
  temperature_factor <- 1 + CONSTANTS$TEMP_WATER_SCALING * (today_temp - 20)  # simple example
  herbivore$daily_water_requirement <- calc_water_requirement(herbivore$mass) * temperature_factor

  herbivore <- check_daily_water_balance(herbivore)
  herbivore <- calc_daily_energy_balance(herbivore)

  assert_domain_sanity_state(
    plants = plants,
    herbivore = herbivore,
    day_of_simulation = day_of_simulation,
    minute_of_day = as.integer(minute_limit),
    phase = "end_of_day"
  )

  # 7) Summarize daily outcomes
  daily_summary <- list(
    day_of_simulation     = day_of_simulation,
    today_temp            = today_temp,
    total_distance_moved  = herbivore$distance_moved,
    total_biomass_eaten   = herbivore$intake_total_day,
    daily_water_requirement = herbivore$daily_water_requirement,
    daily_water_forage = herbivore$intake_water_forage,
    daily_metabolic_water = herbivore$metabolic_water_day,
    daily_water_drinking = herbivore$intake_water_drinking,
    daily_net_water_balance = herbivore$daily_net_water_balance,
    energy_balance        = herbivore$energy_balance,
    water_balance         = herbivore$water_balance,
    plant_backend = backend$name
  )

  if (capture_diagnostics) {
    diagnostics$herbivore_end <- herbivore
    diagnostics$plants_end <- plants
  }

  list(
    herbivore = herbivore,
    plants = plants,
    daily_record = daily_record,
    daily_summary = daily_summary,
    diagnostics = diagnostics
  )
  })
}
