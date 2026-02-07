# Claim-to-evidence registry helpers for experiment report gating.

claim_registry_v1_path <- function() {
  root <- scenario_find_repo_root()
  if (is.null(root)) {
    return(file.path("config", "claims", "claim_registry_v1.csv"))
  }
  file.path(root, "config", "claims", "claim_registry_v1.csv")
}

read_claim_registry_v1 <- function(path = claim_registry_v1_path()) {
  if (!file.exists(path)) {
    rlang::abort(
      "Claim registry file does not exist.",
      class = "herbivoreTTR_claim_registry_missing",
      path = path
    )
  }

  claims <- utils::read.csv(path, stringsAsFactors = FALSE)
  required_cols <- c(
    "claim_id",
    "experiment_id",
    "metric_name",
    "support_rule",
    "threshold",
    "required",
    "description"
  )
  missing_cols <- setdiff(required_cols, names(claims))
  if (length(missing_cols) > 0L) {
    rlang::abort(
      "Claim registry is missing required columns.",
      class = "herbivoreTTR_claim_registry_columns_missing",
      missing_columns = missing_cols
    )
  }

  claims$threshold <- as.numeric(claims$threshold)
  claims$required <- as.logical(claims$required)
  claims
}

evaluate_claim_support_rule <- function(value, support_rule, threshold) {
  if (!is.finite(value)) {
    return("not_supported")
  }

  supported <- switch(
    support_rule,
    gt = value > threshold,
    ge = value >= threshold,
    lt = value < threshold,
    le = value <= threshold,
    eq = abs(value - threshold) <= 1e-8,
    neq = abs(value - threshold) > 1e-8,
    rlang::abort(
      sprintf("Unsupported claim support rule `%s`.", support_rule),
      class = "herbivoreTTR_claim_rule_invalid",
      support_rule = support_rule
    )
  )

  if (isTRUE(supported)) {
    return("supported")
  }

  tolerance <- max(abs(threshold) * 0.1, 1e-8)
  if (abs(value - threshold) <= tolerance) {
    return("partially_supported")
  }
  "not_supported"
}

evaluate_claim_registry_v1 <- function(experiment_id,
                                       metrics,
                                       claims = read_claim_registry_v1()) {
  if (!is.character(experiment_id) || length(experiment_id) != 1L || !nzchar(experiment_id)) {
    rlang::abort(
      "Argument `experiment_id` must be a non-empty scalar character.",
      class = "herbivoreTTR_claim_experiment_id_invalid",
      experiment_id = experiment_id
    )
  }
  if (is.null(names(metrics)) || any(!nzchar(names(metrics)))) {
    rlang::abort(
      "Argument `metrics` must be a named numeric vector/list.",
      class = "herbivoreTTR_claim_metrics_invalid",
      metrics = metrics
    )
  }

  claim_rows <- claims[claims$experiment_id == experiment_id, , drop = FALSE]
  if (nrow(claim_rows) < 1L) {
    rlang::abort(
      sprintf("No claims registered for experiment `%s`.", experiment_id),
      class = "herbivoreTTR_claim_experiment_missing",
      experiment_id = experiment_id
    )
  }

  out <- claim_rows
  out$observed_value <- vapply(
    out$metric_name,
    function(metric_name) {
      value <- metrics[[metric_name]]
      if (is.null(value) || length(value) < 1L) {
        return(NA_real_)
      }
      as.numeric(value[[1]])
    },
    numeric(1L)
  )
  out$status <- vapply(
    seq_len(nrow(out)),
    function(i) evaluate_claim_support_rule(
      value = out$observed_value[[i]],
      support_rule = out$support_rule[[i]],
      threshold = out$threshold[[i]]
    ),
    character(1L)
  )
  out
}

assert_required_claims_supported <- function(claim_status) {
  required <- claim_status[claim_status$required %in% TRUE, , drop = FALSE]
  failures <- required[required$status == "not_supported", , drop = FALSE]
  if (nrow(failures) > 0L) {
    rlang::abort(
      sprintf(
        "Required claims not supported: %s",
        paste(failures$claim_id, collapse = ", ")
      ),
      class = "herbivoreTTR_claim_gate_failed",
      failing_claim_ids = failures$claim_id
    )
  }
  invisible(TRUE)
}
