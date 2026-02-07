# Herbivore daily diagnostics and body-condition feedback helpers.

clamp_unit_interval <- function(x) {
  min(max(as.numeric(x), 0), 1)
}

apply_body_condition_feedback <- function(herbivore, minute_limit) {
  baseline <- as.numeric(if (is.null(herbivore$baseline_time_spent_foraging)) {
    herbivore$time_spent_foraging
  } else {
    herbivore$baseline_time_spent_foraging
  })
  if (!is.finite(baseline) || baseline <= 0) {
    baseline <- 12
  }

  herbivore$baseline_time_spent_foraging <- baseline

  enabled <- if (is.null(herbivore$body_condition_feedback_enabled)) TRUE else isTRUE(herbivore$body_condition_feedback_enabled)
  if (!enabled) {
    herbivore$time_spent_foraging <- baseline
    return(herbivore)
  }

  bci <- clamp_unit_interval(if (is.null(herbivore$body_condition_index)) {
    CONSTANTS$BODY_CONDITION_INITIAL
  } else {
    herbivore$body_condition_index
  })
  threshold <- as.numeric(if (is.null(herbivore$body_condition_effort_threshold)) {
    CONSTANTS$BODY_CONDITION_EFFORT_THRESHOLD
  } else {
    herbivore$body_condition_effort_threshold
  })
  max_boost <- as.numeric(if (is.null(herbivore$body_condition_max_foraging_boost)) {
    CONSTANTS$BODY_CONDITION_MAX_FORAGING_BOOST
  } else {
    herbivore$body_condition_max_foraging_boost
  })
  if (!is.finite(threshold) || threshold <= 0) {
    threshold <- CONSTANTS$BODY_CONDITION_EFFORT_THRESHOLD
  }
  if (!is.finite(max_boost) || max_boost < 0) {
    max_boost <- CONSTANTS$BODY_CONDITION_MAX_FORAGING_BOOST
  }

  boost_fraction <- 0
  if (bci < threshold) {
    severity <- (threshold - bci) / threshold
    severity <- min(max(severity, 0), 1)
    boost_fraction <- max_boost * severity
  }

  minute_cap_hours <- max(as.numeric(minute_limit) / 60, 0)
  adjusted <- baseline * (1 + boost_fraction)
  herbivore$time_spent_foraging <- min(adjusted, minute_cap_hours)
  herbivore$body_condition_index <- bci
  herbivore
}

update_herbivore_daily_diagnostics <- function(herbivore) {
  tol <- CONSTANTS$TOLERANCE
  energy_delta <- as.numeric(if (is.null(herbivore$daily_energy_delta)) 0 else herbivore$daily_energy_delta)
  water_delta <- as.numeric(if (is.null(herbivore$daily_net_water_balance)) 0 else herbivore$daily_net_water_balance)

  prev_energy_streak <- as.integer(if (is.null(herbivore$energy_deficit_streak_days)) 0 else herbivore$energy_deficit_streak_days)
  prev_water_streak <- as.integer(if (is.null(herbivore$water_deficit_streak_days)) 0 else herbivore$water_deficit_streak_days)

  herbivore$energy_deficit_streak_days <- if (energy_delta < -tol) prev_energy_streak + 1L else 0L
  herbivore$water_deficit_streak_days <- if (water_delta < -tol) prev_water_streak + 1L else 0L

  bci_prev <- as.numeric(if (is.null(herbivore$body_condition_index)) CONSTANTS$BODY_CONDITION_INITIAL else herbivore$body_condition_index)
  gain <- as.numeric(if (is.null(herbivore$body_condition_gain_coeff)) CONSTANTS$BODY_CONDITION_GAIN_COEFF else herbivore$body_condition_gain_coeff)
  loss <- as.numeric(if (is.null(herbivore$body_condition_loss_coeff)) CONSTANTS$BODY_CONDITION_LOSS_COEFF else herbivore$body_condition_loss_coeff)
  if (!is.finite(gain) || gain < 0) {
    gain <- CONSTANTS$BODY_CONDITION_GAIN_COEFF
  }
  if (!is.finite(loss) || loss < 0) {
    loss <- CONSTANTS$BODY_CONDITION_LOSS_COEFF
  }

  energy_ratio <- as.numeric(if (is.null(herbivore$energy_balance_ratio)) 0 else herbivore$energy_balance_ratio)
  positive_term <- gain * max(energy_ratio, 0)
  negative_term <- loss * abs(min(energy_ratio, 0))
  herbivore$body_condition_index <- clamp_unit_interval(bci_prev + positive_term - negative_term)

  stress_threshold <- as.numeric(if (is.null(herbivore$body_condition_stress_threshold)) {
    CONSTANTS$BODY_CONDITION_STRESS_THRESHOLD
  } else {
    herbivore$body_condition_stress_threshold
  })
  if (!is.finite(stress_threshold)) {
    stress_threshold <- CONSTANTS$BODY_CONDITION_STRESS_THRESHOLD
  }

  herbivore$physiological_stress_flag <- as.integer(
    herbivore$body_condition_index < stress_threshold ||
      herbivore$energy_deficit_streak_days > 0L ||
      herbivore$water_deficit_streak_days > 0L
  )

  herbivore
}

apply_scenario_feedback_config <- function(herbivore, feedback) {
  if (is.null(feedback) || !is.list(feedback)) {
    return(herbivore)
  }

  herbivore$body_condition_feedback_enabled <- isTRUE(feedback$enabled)
  herbivore$body_condition_gain_coeff <- as.numeric(feedback$gain_coeff)
  herbivore$body_condition_loss_coeff <- as.numeric(feedback$loss_coeff)
  herbivore$body_condition_effort_threshold <- as.numeric(feedback$effort_threshold)
  herbivore$body_condition_stress_threshold <- as.numeric(feedback$stress_threshold)
  herbivore$body_condition_max_foraging_boost <- as.numeric(feedback$max_foraging_boost)
  herbivore$body_condition_index <- clamp_unit_interval(as.numeric(feedback$initial_bci))
  herbivore
}
