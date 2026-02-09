# TTR-specific stability guardrails.

ttr_guardrail_pool_columns <- function() {
  c("ms", "mr", "cs", "cr", "ns", "nr", "bleaf", "bstem", "bdef", "md", "cd", "nd")
}

ttr_guardrail_multiplier_columns <- function() {
  c("ms", "mr", "cs", "cr", "ns", "nr", "bdef")
}

assert_ttr_guardrails <- function(plants,
                                  plants_previous,
                                  day_of_simulation,
                                  phase = "ttr_daily") {
  tol <- CONSTANTS$TOLERANCE
  abs_cap <- CONSTANTS$TTR_MAX_POOL_ABS
  max_mult <- CONSTANTS$TTR_MAX_DAILY_POOL_MULTIPLIER
  max_def_frac <- CONSTANTS$TTR_MAX_DEFENCE_FRACTION

  if (!is.data.frame(plants)) {
    abort_domain_sanity_violation(
      component = "ttr$plants",
      reason = "current TTR state is not a data.frame",
      day_of_simulation = day_of_simulation,
      minute_of_day = 0L,
      phase = phase
    )
  }

  pool_cols <- ttr_guardrail_pool_columns()
  multiplier_cols <- ttr_guardrail_multiplier_columns()
  plant_names <- names(plants)
  missing_cols <- pool_cols[!pool_cols %in% plant_names]
  if (length(missing_cols) > 0L) {
    col <- missing_cols[[1]]
    abort_domain_sanity_violation(
      component = paste0("ttr$", col),
      reason = "required TTR pool column is missing",
      day_of_simulation = day_of_simulation,
      minute_of_day = 0L,
      phase = phase
    )
  }

  for (col in pool_cols) {
    values <- plants[[col]]

    assert_domain_sanity_vector(
      values = values,
      component = paste0("ttr$", col),
      day_of_simulation = day_of_simulation,
      minute_of_day = 0L,
      phase = phase,
      tolerance = tol
    )

    above_cap <- as.integer(match(TRUE, values > abs_cap, nomatch = 0L))
    if (above_cap > 0L) {
      idx <- above_cap
      abort_domain_sanity_violation(
        component = paste0("ttr$", col),
        reason = sprintf(
          "pool exceeded absolute stability cap (cap=%s)",
          format(abs_cap, scientific = TRUE)
        ),
        day_of_simulation = day_of_simulation,
        minute_of_day = 0L,
        phase = phase,
        index = idx,
        value = values[[idx]]
      )
    }
  }

  if (is.data.frame(plants_previous) && nrow(plants_previous) == nrow(plants)) {
    for (col in multiplier_cols) {
      prev <- plants_previous[[col]]
      cur <- plants[[col]]
      valid <- is.finite(prev) & is.finite(cur) & prev > tol
      if (!any(valid)) {
        next
      }

      ratio <- cur[valid] / prev[valid]
      bad_local <- as.integer(match(TRUE, ratio > max_mult, nomatch = 0L))
      if (bad_local > 0L) {
        valid_idx <- seq_along(valid)[valid]
        idx <- valid_idx[[bad_local]]
        abort_domain_sanity_violation(
          component = paste0("ttr$", col),
          reason = sprintf(
            "daily multiplier exceeded stability cap (ratio=%s, cap=%s)",
            format(ratio[[bad_local]], scientific = TRUE),
            format(max_mult, scientific = TRUE)
          ),
          day_of_simulation = day_of_simulation,
          minute_of_day = 0L,
          phase = phase,
          index = idx,
          value = cur[[idx]]
        )
      }
    }
  }

  shoot <- pmax(plants$ms, tol)
  defence_fraction <- ifelse(shoot > tol, plants$bdef / shoot, 0)
  bad_def_frac <- as.integer(match(TRUE, defence_fraction > max_def_frac + tol, nomatch = 0L))
  if (bad_def_frac > 0L) {
    idx <- bad_def_frac
    abort_domain_sanity_violation(
      component = "ttr$bdef",
      reason = sprintf(
        "defence fraction exceeded cap (fraction=%s, cap=%s)",
        format(defence_fraction[[idx]], scientific = TRUE),
        format(max_def_frac, scientific = TRUE)
      ),
      day_of_simulation = day_of_simulation,
      minute_of_day = 0L,
      phase = phase,
      index = idx,
      value = plants$bdef[[idx]]
    )
  }

  mismatch_md <- as.integer(match(TRUE, abs(plants$md - plants$bdef) > tol, nomatch = 0L))
  if (mismatch_md > 0L) {
    idx <- mismatch_md
    abort_domain_sanity_violation(
      component = "ttr$md",
      reason = "defence mass mismatch: md must mirror bdef",
      day_of_simulation = day_of_simulation,
      minute_of_day = 0L,
      phase = phase,
      index = idx,
      value = plants$md[[idx]]
    )
  }

  bad_cd <- as.integer(match(TRUE, plants$cd - plants$cs > tol, nomatch = 0L))
  if (bad_cd > 0L) {
    idx <- bad_cd
    abort_domain_sanity_violation(
      component = "ttr$cd",
      reason = "defence carbon exceeded shoot carbon pool",
      day_of_simulation = day_of_simulation,
      minute_of_day = 0L,
      phase = phase,
      index = idx,
      value = plants$cd[[idx]]
    )
  }

  bad_nd <- as.integer(match(TRUE, plants$nd - plants$ns > tol, nomatch = 0L))
  if (bad_nd > 0L) {
    idx <- bad_nd
    abort_domain_sanity_violation(
      component = "ttr$nd",
      reason = "defence nitrogen exceeded shoot nitrogen pool",
      day_of_simulation = day_of_simulation,
      minute_of_day = 0L,
      phase = phase,
      index = idx,
      value = plants$nd[[idx]]
    )
  }

  invisible(TRUE)
}
