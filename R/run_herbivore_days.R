#' Run a multi-day herbivore simulation
#'
#' Convenience wrapper that spins up default conditions, then advances the
#' coupled herbivore–plant system for a specified number of days after the
#' vegetation spin-up period. Returns both the daily summaries and the final
#' state objects for downstream inspection.
#'
#' @param days Positive integer number of days to simulate after spin-up.
#' @param minute_limit Number of minutes per day to simulate (default 1440).
#' @param temp_mode Mode passed to `init_conditions()`; defaults to `"flat"`.
#' @param veg_types Vegetation types passed to `init_plants()`.
#' @param herbivore_mass Starting herbivore mass in grams.
#' @param seed Optional integer seed for deterministic RNG behavior during this
#'   function call. The caller RNG state is restored afterwards.
#' @return List with elements `daily_summary` (data.frame), `herbivore`,
#'   `plants`, and `start_day`.
#' @examples
#' res <- run_herbivore_days(days = 3, minute_limit = 60)
#' res$daily_summary
#' @export
run_herbivore_days <- function(days = 3L,
                               minute_limit = 1440,
                               temp_mode = "flat",
                               veg_types = c(0, 1, 2),
                               herbivore_mass = 5e5,
                               seed = NULL) {

  with_optional_seed(seed, {

  if (!exists("%>%", inherits = TRUE) && requireNamespace("magrittr", quietly = TRUE)) {
    `%>%` <<- magrittr::`%>%`
  }

  if (!is.numeric(days) || length(days) != 1L || is.na(days) || days < 1) {
    rlang::abort(
      "Argument `days` must be a positive scalar integer.",
      class = "herbivoreTTR_run_days_invalid",
      days = days
    )
  }
  if (!is.numeric(minute_limit) || length(minute_limit) != 1L ||
      is.na(minute_limit) || minute_limit <= 0) {
    rlang::abort(
      "Argument `minute_limit` must be a positive scalar.",
      class = "herbivoreTTR_run_days_minute_limit_invalid",
      minute_limit = minute_limit
    )
  }

  days <- as.integer(days)
  minute_limit <- as.numeric(minute_limit)

  sim <- init_simulation(
    temp_mode = temp_mode,
    veg_types = veg_types,
    herbivore_mass = herbivore_mass
  )

  conditions <- sim[["conditions"]]
  plants <- sim[["plants"]]
  herbivore <- sim[["herbivore"]]

  start_day <- CONSTANTS$SPIN_UP_LENGTH * nrow(conditions) + 1L
  summaries <- vector("list", days)

  for (i in seq_len(days)) {
    current_day <- start_day + i - 1L
    step_res <- run_daily_herbivore_simulation(
      herbivore = herbivore,
      plants = plants,
      conditions = conditions,
      day_of_simulation = current_day,
      minute_limit = minute_limit
    )
    summaries[[i]] <- step_res[["daily_summary"]]
    herbivore <- step_res[["herbivore"]]
    plants <- step_res[["plants"]]
  }

  summary_df <- do.call(
    rbind,
    lapply(summaries, function(x) {
      data.frame(
        day_of_simulation = x$day_of_simulation,
        today_temp = x$today_temp,
        total_distance_moved = x$total_distance_moved,
        total_biomass_eaten = x$total_biomass_eaten,
        energy_balance = x$energy_balance,
        water_balance = x$water_balance,
        stringsAsFactors = FALSE
      )
    })
  )
  rownames(summary_df) <- NULL

  list(
    daily_summary = summary_df,
    herbivore = herbivore,
    plants = plants,
    start_day = start_day
  )
  })
}
