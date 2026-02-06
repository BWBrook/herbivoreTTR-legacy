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

  for (col in ttr_guardrail_pool_columns()) {
    if (!col %in% names(plants)) {
      abort_domain_sanity_violation(
        component = paste0("ttr$", col),
        reason = "required TTR pool column is missing",
        day_of_simulation = day_of_simulation,
        minute_of_day = 0L,
        phase = phase
      )
    }

    assert_domain_sanity_vector(
      values = plants[[col]],
      component = paste0("ttr$", col),
      day_of_simulation = day_of_simulation,
      minute_of_day = 0L,
      phase = phase,
      tolerance = tol
    )

    above_cap <- which(plants[[col]] > abs_cap)
    if (length(above_cap)) {
      idx <- above_cap[1]
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
        value = plants[[col]][[idx]]
      )
    }
  }

  if (is.data.frame(plants_previous) && nrow(plants_previous) == nrow(plants)) {
    for (col in ttr_guardrail_multiplier_columns()) {
      prev <- plants_previous[[col]]
      cur <- plants[[col]]
      valid <- is.finite(prev) & is.finite(cur) & prev > tol
      if (!any(valid)) {
        next
      }

      ratio <- cur[valid] / prev[valid]
      bad_local <- which(ratio > max_mult)
      if (length(bad_local)) {
        idx <- which(valid)[bad_local[1]]
        abort_domain_sanity_violation(
          component = paste0("ttr$", col),
          reason = sprintf(
            "daily multiplier exceeded stability cap (ratio=%s, cap=%s)",
            format(ratio[[bad_local[1]]], scientific = TRUE),
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
  bad_def_frac <- which(defence_fraction > max_def_frac + tol)
  if (length(bad_def_frac)) {
    idx <- bad_def_frac[1]
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

  mismatch_md <- which(abs(plants$md - plants$bdef) > tol)
  if (length(mismatch_md)) {
    idx <- mismatch_md[1]
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

  bad_cd <- which(plants$cd - plants$cs > tol)
  if (length(bad_cd)) {
    idx <- bad_cd[1]
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

  bad_nd <- which(plants$nd - plants$ns > tol)
  if (length(bad_nd)) {
    idx <- bad_nd[1]
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
