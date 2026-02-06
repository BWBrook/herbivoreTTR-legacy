# Internal domain sanity guards used by simulation runners.

domain_sanity_required_plant_columns <- function() {
  c("ms", "mr", "bleaf", "bstem", "bdef", "cs", "cr", "ns", "nr", "cd", "nd", "md")
}

abort_domain_sanity_violation <- function(component,
                                          reason,
                                          day_of_simulation,
                                          minute_of_day,
                                          phase,
                                          index = NA_integer_,
                                          value = NA_real_) {
  msg <- sprintf(
    paste(
      "Domain sanity violation [%s] at day %s minute %s phase=%s:",
      "%s (index=%s, value=%s)"
    ),
    component,
    as.integer(day_of_simulation),
    as.integer(minute_of_day),
    phase,
    reason,
    ifelse(is.na(index), "NA", as.character(as.integer(index))),
    ifelse(is.na(value), "NA", format(value, scientific = TRUE))
  )

  rlang::abort(
    msg,
    class = "herbivoreTTR_domain_sanity_violation",
    component = component,
    reason = reason,
    day = as.integer(day_of_simulation),
    minute = as.integer(minute_of_day),
    phase = phase,
    index = ifelse(is.na(index), NA_integer_, as.integer(index)),
    value = ifelse(is.na(value), NA_real_, as.numeric(value))
  )
}

assert_domain_sanity_vector <- function(values,
                                        component,
                                        day_of_simulation,
                                        minute_of_day,
                                        phase,
                                        tolerance = CONSTANTS$TOLERANCE) {
  non_finite_idx <- which(!is.finite(values))
  if (length(non_finite_idx)) {
    idx <- non_finite_idx[1]
    abort_domain_sanity_violation(
      component = component,
      reason = "encountered non-finite value",
      day_of_simulation = day_of_simulation,
      minute_of_day = minute_of_day,
      phase = phase,
      index = idx,
      value = values[[idx]]
    )
  }

  below_idx <- which(values < -tolerance)
  if (length(below_idx)) {
    idx <- below_idx[1]
    abort_domain_sanity_violation(
      component = component,
      reason = sprintf("value dropped below tolerance (tol=%s)", format(tolerance, scientific = TRUE)),
      day_of_simulation = day_of_simulation,
      minute_of_day = minute_of_day,
      phase = phase,
      index = idx,
      value = values[[idx]]
    )
  }

  invisible(TRUE)
}

assert_daily_balance_jump <- function(previous_value,
                                      current_value,
                                      max_jump,
                                      component,
                                      day_of_simulation,
                                      phase = "daily_balance_check") {
  if (!is.finite(previous_value) || !is.finite(current_value)) {
    return(invisible(TRUE))
  }
  jump <- abs(current_value - previous_value)
  if (jump > max_jump) {
    abort_domain_sanity_violation(
      component = component,
      reason = sprintf(
        "day-to-day jump exceeded threshold (jump=%s, threshold=%s)",
        format(jump, scientific = TRUE),
        format(max_jump, scientific = TRUE)
      ),
      day_of_simulation = day_of_simulation,
      minute_of_day = 0L,
      phase = phase,
      index = NA_integer_,
      value = current_value
    )
  }

  invisible(TRUE)
}

assert_domain_sanity_state <- function(plants,
                                       herbivore,
                                       day_of_simulation,
                                       minute_of_day = 0L,
                                       phase = "runtime",
                                       check_plants = TRUE,
                                       check_herbivore = TRUE) {
  tol <- CONSTANTS$TOLERANCE

  if (isTRUE(check_plants)) {
    if (!is.data.frame(plants)) {
      abort_domain_sanity_violation(
        component = "plants",
        reason = "plants state is not a data.frame",
        day_of_simulation = day_of_simulation,
        minute_of_day = minute_of_day,
        phase = phase
      )
    }

    for (col in domain_sanity_required_plant_columns()) {
      if (!col %in% names(plants)) {
        abort_domain_sanity_violation(
          component = paste0("plants$", col),
          reason = "required plant column is missing",
          day_of_simulation = day_of_simulation,
          minute_of_day = minute_of_day,
          phase = phase
        )
      }
      if (!is.numeric(plants[[col]])) {
        abort_domain_sanity_violation(
          component = paste0("plants$", col),
          reason = "plant column is not numeric",
          day_of_simulation = day_of_simulation,
          minute_of_day = minute_of_day,
          phase = phase
        )
      }
      assert_domain_sanity_vector(
        values = plants[[col]],
        component = paste0("plants$", col),
        day_of_simulation = day_of_simulation,
        minute_of_day = minute_of_day,
        phase = phase,
        tolerance = tol
      )
    }
  }

  if (isTRUE(check_herbivore)) {
    if (!is.list(herbivore)) {
      abort_domain_sanity_violation(
        component = "herbivore",
        reason = "herbivore state is not a list",
        day_of_simulation = day_of_simulation,
        minute_of_day = minute_of_day,
        phase = phase
      )
    }

    gut_capacity <- herbivore$gut_capacity
    gut_content <- herbivore$gut_content
    distance_moved <- herbivore$distance_moved
    energy_balance <- herbivore$energy_balance
    water_balance <- herbivore$water_balance

    if (!is.finite(gut_capacity) || gut_capacity <= 0) {
      abort_domain_sanity_violation(
        component = "herbivore$gut_capacity",
        reason = "gut capacity must be finite and > 0",
        day_of_simulation = day_of_simulation,
        minute_of_day = minute_of_day,
        phase = phase,
        value = gut_capacity
      )
    }

    if (!is.finite(gut_content) || gut_content < -tol) {
      abort_domain_sanity_violation(
        component = "herbivore$gut_content",
        reason = "gut content must be finite and non-negative",
        day_of_simulation = day_of_simulation,
        minute_of_day = minute_of_day,
        phase = phase,
        value = gut_content
      )
    }

    if (gut_content > gut_capacity + tol) {
      abort_domain_sanity_violation(
        component = "herbivore$gut_content",
        reason = "gut content exceeded gut capacity",
        day_of_simulation = day_of_simulation,
        minute_of_day = minute_of_day,
        phase = phase,
        value = gut_content
      )
    }

    if (!is.finite(distance_moved) || distance_moved < -tol) {
      abort_domain_sanity_violation(
        component = "herbivore$distance_moved",
        reason = "distance moved must be finite and non-negative",
        day_of_simulation = day_of_simulation,
        minute_of_day = minute_of_day,
        phase = phase,
        value = distance_moved
      )
    }

    if (!is.finite(energy_balance)) {
      abort_domain_sanity_violation(
        component = "herbivore$energy_balance",
        reason = "energy balance must be finite",
        day_of_simulation = day_of_simulation,
        minute_of_day = minute_of_day,
        phase = phase,
        value = energy_balance
      )
    }

    if (!is.finite(water_balance)) {
      abort_domain_sanity_violation(
        component = "herbivore$water_balance",
        reason = "water balance must be finite",
        day_of_simulation = day_of_simulation,
        minute_of_day = minute_of_day,
        phase = phase,
        value = water_balance
      )
    }

    if (!is.list(herbivore$digestion)) {
      abort_domain_sanity_violation(
        component = "herbivore$digestion",
        reason = "digestion state must be a list of numeric queues",
        day_of_simulation = day_of_simulation,
        minute_of_day = minute_of_day,
        phase = phase
      )
    }

    for (nm in names(herbivore$digestion)) {
      queue <- herbivore$digestion[[nm]]
      if (!is.numeric(queue)) {
        abort_domain_sanity_violation(
          component = paste0("herbivore$digestion$", nm),
          reason = "digestion queue is not numeric",
          day_of_simulation = day_of_simulation,
          minute_of_day = minute_of_day,
          phase = phase
        )
      }
      assert_domain_sanity_vector(
        values = queue,
        component = paste0("herbivore$digestion$", nm),
        day_of_simulation = day_of_simulation,
        minute_of_day = minute_of_day,
        phase = phase,
        tolerance = tol
      )
    }
  }

  invisible(TRUE)
}
