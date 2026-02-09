# Portal plan schema and YAML compile helpers for non-coder workflows.

portal_plan_schema_version_v1 <- function() {
  "1.0.0"
}

portal_plan_default_v1 <- function() {
  list(
    schema_version = portal_plan_schema_version_v1(),
    plan_id = "portal_plan_v1",
    description = "",
    execution = list(
      mode = "single",
      base_dir = file.path("artefacts", "portal_runs"),
      dry_run = FALSE,
      write_outputs = TRUE,
      parallel = list(
        execution_mode = "auto",
        workers = NULL,
        reserve_cores = 1L
      )
    ),
    scenario = list(
      source = "reference",
      reference = "canonical_smoke_v1",
      path = NULL,
      overrides = list()
    ),
    sensitivity = list(
      enabled = FALSE,
      design = "one_at_a_time",
      keep_baseline = TRUE,
      parameters = list()
    ),
    outputs = list(
      render_report = TRUE,
      report_formats = c("html"),
      acceptance_profile = "standard",
      include_interactive = TRUE
    )
  )
}

portal_abort_v1 <- function(message,
                            class,
                            ...) {
  rlang::abort(message, class = class, ...)
}

portal_merge_defaults_v1 <- function(defaults, user) {
  if (is.null(user)) {
    return(defaults)
  }
  if (!is.list(defaults) || !is.list(user)) {
    return(user)
  }

  user_names <- names(user)
  default_names <- names(defaults)

  # Indexed lists (for example sensitivity parameter arrays) should replace
  # defaults as whole values; recursive name-merge applies only to keyed lists.
  if (is.null(user_names) || !any(nzchar(user_names))) {
    return(user)
  }
  if (is.null(default_names) || !any(nzchar(default_names))) {
    return(user)
  }

  out <- defaults
  for (nm in user_names) {
    if (!nzchar(nm)) {
      return(user)
    }
    if (!nm %in% names(out)) {
      out[[nm]] <- user[[nm]]
      next
    }
    out[[nm]] <- portal_merge_defaults_v1(out[[nm]], user[[nm]])
  }

  out
}

portal_parse_logical_scalar_v1 <- function(x,
                                           default = FALSE,
                                           field = "value") {
  if (is.null(x)) {
    return(as.logical(default))
  }
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    portal_abort_v1(
      sprintf("Field `%s` must be a non-missing logical scalar.", field),
      class = "herbivoreTTR_portal_plan_invalid",
      field = field,
      value = x
    )
  }
  as.logical(x)
}

portal_parse_character_scalar_v1 <- function(x,
                                             field,
                                             allow_empty = FALSE) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    portal_abort_v1(
      sprintf("Field `%s` must be a character scalar.", field),
      class = "herbivoreTTR_portal_plan_invalid",
      field = field,
      value = x
    )
  }
  if (!allow_empty && !nzchar(x)) {
    portal_abort_v1(
      sprintf("Field `%s` must be non-empty.", field),
      class = "herbivoreTTR_portal_plan_invalid",
      field = field,
      value = x
    )
  }
  as.character(x)
}

portal_parse_integer_scalar_or_null_v1 <- function(x,
                                                    field) {
  if (is.null(x)) {
    return(NULL)
  }
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x)) {
    portal_abort_v1(
      sprintf("Field `%s` must be a finite numeric scalar or null.", field),
      class = "herbivoreTTR_portal_plan_invalid",
      field = field,
      value = x
    )
  }
  as.integer(x)
}

portal_is_integer_token_v1 <- function(token) {
  grepl("^[0-9]+$", token)
}

portal_dot_path_tokens_v1 <- function(path) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
    portal_abort_v1(
      "Dot-path must be a non-empty character scalar.",
      class = "herbivoreTTR_portal_plan_invalid",
      path = path
    )
  }
  strsplit(path, "\\.", fixed = FALSE)[[1]]
}

portal_get_path_v1 <- function(x,
                               path,
                               required = TRUE) {
  tokens <- portal_dot_path_tokens_v1(path)
  cursor <- x

  for (token in tokens) {
    if (is.list(cursor)) {
      if (token %in% names(cursor)) {
        cursor <- cursor[[token]]
      } else if (portal_is_integer_token_v1(token)) {
        idx <- as.integer(token)
        if (idx >= 1L && idx <= length(cursor)) {
          cursor <- cursor[[idx]]
        } else {
          if (!isTRUE(required)) {
            return(list(found = FALSE, value = NULL))
          }
          portal_abort_v1(
            sprintf("Path `%s` index token `%s` is out of bounds.", path, token),
            class = "herbivoreTTR_portal_plan_path_invalid",
            path = path,
            token = token
          )
        }
      } else {
        if (!isTRUE(required)) {
          return(list(found = FALSE, value = NULL))
        }
        portal_abort_v1(
          sprintf("Path `%s` token `%s` does not exist.", path, token),
          class = "herbivoreTTR_portal_plan_path_invalid",
          path = path,
          token = token
        )
      }
    } else {
      if (!isTRUE(required)) {
        return(list(found = FALSE, value = NULL))
      }
      portal_abort_v1(
        sprintf("Path `%s` traverses non-list value at token `%s`.", path, token),
        class = "herbivoreTTR_portal_plan_path_invalid",
        path = path,
        token = token
      )
    }
  }

  list(found = TRUE, value = cursor)
}

portal_set_path_tokens_v1 <- function(x,
                                      tokens,
                                      value,
                                      full_path) {
  token <- tokens[[1]]
  is_last <- length(tokens) == 1L

  if (!is.list(x)) {
    portal_abort_v1(
      sprintf("Path `%s` traverses non-list value before assignment.", full_path),
      class = "herbivoreTTR_portal_plan_path_invalid",
      path = full_path,
      token = token
    )
  }

  access_by_name <- token %in% names(x)
  access_by_index <- portal_is_integer_token_v1(token)

  if (!access_by_name && !access_by_index) {
    portal_abort_v1(
      sprintf("Path `%s` token `%s` does not exist in scenario object.", full_path, token),
      class = "herbivoreTTR_portal_plan_path_invalid",
      path = full_path,
      token = token
    )
  }

  if (access_by_index && !access_by_name) {
    idx <- as.integer(token)
    if (idx < 1L || idx > length(x)) {
      portal_abort_v1(
        sprintf("Path `%s` index token `%s` is out of bounds.", full_path, token),
        class = "herbivoreTTR_portal_plan_path_invalid",
        path = full_path,
        token = token
      )
    }
    key <- idx
  } else {
    key <- token
  }

  if (is_last) {
    x[[key]] <- value
    return(x)
  }

  x[[key]] <- portal_set_path_tokens_v1(
    x = x[[key]],
    tokens = tokens[-1],
    value = value,
    full_path = full_path
  )
  x
}

portal_set_path_v1 <- function(x,
                               path,
                               value) {
  tokens <- portal_dot_path_tokens_v1(path)
  portal_set_path_tokens_v1(x = x, tokens = tokens, value = value, full_path = path)
}

portal_collect_override_leaf_paths_v1 <- function(x,
                                                  prefix = NULL) {
  if (!is.list(x)) {
    if (is.null(prefix) || !nzchar(prefix)) {
      return(list())
    }
    out <- list(x)
    names(out) <- prefix
    return(out)
  }

  if (length(x) < 1L) {
    return(list())
  }

  out <- list()
  x_names <- names(x)
  if (is.null(x_names)) {
    x_names <- rep("", length(x))
  }

  for (i in seq_along(x)) {
    token <- x_names[[i]]
    if (!nzchar(token)) {
      token <- as.character(i)
    }

    next_prefix <- if (is.null(prefix) || !nzchar(prefix)) {
      token
    } else {
      paste(prefix, token, sep = ".")
    }

    out <- c(out, portal_collect_override_leaf_paths_v1(x[[i]], prefix = next_prefix))
  }

  out
}

portal_apply_scenario_overrides_v1 <- function(scenario,
                                               overrides) {
  if (is.null(overrides) || (is.list(overrides) && length(overrides) < 1L)) {
    return(validate_scenario_v1(scenario))
  }
  if (!is.list(overrides)) {
    portal_abort_v1(
      "Field `scenario.overrides` must be a list when provided.",
      class = "herbivoreTTR_portal_plan_invalid",
      overrides = overrides
    )
  }

  out <- scenario
  leaves <- portal_collect_override_leaf_paths_v1(overrides)
  for (path in names(leaves)) {
    out <- portal_set_path_v1(out, path = path, value = leaves[[path]])
  }

  validate_scenario_v1(out)
}

portal_value_string_v1 <- function(x) {
  if (length(x) != 1L) {
    return(paste(x, collapse = "|"))
  }
  if (is.character(x)) {
    return(x)
  }
  if (is.logical(x)) {
    return(ifelse(isTRUE(x), "TRUE", "FALSE"))
  }
  as.character(x)
}

portal_expand_sensitivity_design_v1 <- function(plan,
                                                base_scenario) {
  sens <- plan$sensitivity
  if (!isTRUE(sens$enabled)) {
    return(list(specs = list(), design_table = data.frame()))
  }

  params <- sens$parameters
  if (!is.list(params) || length(params) < 1L) {
    portal_abort_v1(
      "Sensitivity mode requires at least one parameter definition.",
      class = "herbivoreTTR_portal_plan_sensitivity_invalid"
    )
  }

  parsed <- vector("list", length(params))
  for (i in seq_along(params)) {
    entry <- params[[i]]
    if (!is.list(entry)) {
      portal_abort_v1(
        "Each sensitivity parameter definition must be a list.",
        class = "herbivoreTTR_portal_plan_sensitivity_invalid",
        index = i
      )
    }

    path <- portal_parse_character_scalar_v1(entry$path, sprintf("sensitivity.parameters[%d].path", i))
    values <- entry$values
    if (is.null(values) || length(values) < 1L) {
      portal_abort_v1(
        sprintf("Sensitivity parameter `%s` must define at least one value.", path),
        class = "herbivoreTTR_portal_plan_sensitivity_invalid",
        index = i,
        path = path
      )
    }

    resolved <- portal_get_path_v1(base_scenario, path = path, required = FALSE)
    if (!isTRUE(resolved$found)) {
      portal_abort_v1(
        sprintf("Sensitivity path `%s` does not exist in scenario object.", path),
        class = "herbivoreTTR_portal_plan_path_invalid",
        path = path
      )
    }

    parsed[[i]] <- list(path = path, values = as.list(values))
  }

  specs <- list()
  table_rows <- list()
  idx <- 0L

  if (identical(sens$design, "one_at_a_time")) {
    if (isTRUE(sens$keep_baseline)) {
      idx <- idx + 1L
      specs[[idx]] <- list(
        run_index = idx,
        run_label = "baseline",
        changes = list(),
        change_summary = "baseline",
        design = "one_at_a_time"
      )
      table_rows[[idx]] <- data.frame(
        run_index = idx,
        run_label = "baseline",
        design = "one_at_a_time",
        parameter_path = "baseline",
        parameter_value = "baseline",
        change_summary = "baseline",
        stringsAsFactors = FALSE
      )
    }

    for (param in parsed) {
      safe_path <- gsub("[^a-zA-Z0-9]+", "_", param$path)
      for (j in seq_along(param$values)) {
        idx <- idx + 1L
        value <- param$values[[j]]
        label <- sprintf("oat_%s_%02d", safe_path, j)
        changes <- list(value)
        names(changes) <- param$path
        summary <- sprintf("%s=%s", param$path, portal_value_string_v1(value))

        specs[[idx]] <- list(
          run_index = idx,
          run_label = label,
          changes = changes,
          change_summary = summary,
          design = "one_at_a_time"
        )
        table_rows[[idx]] <- data.frame(
          run_index = idx,
          run_label = label,
          design = "one_at_a_time",
          parameter_path = param$path,
          parameter_value = portal_value_string_v1(value),
          change_summary = summary,
          stringsAsFactors = FALSE
        )
      }
    }
  } else {
    value_indices <- lapply(parsed, function(p) seq_along(p$values))
    names(value_indices) <- vapply(parsed, `[[`, character(1L), "path")

    if (length(value_indices) == 1L) {
      combos <- data.frame(idx1 = value_indices[[1]], stringsAsFactors = FALSE)
      names(combos) <- names(value_indices)
    } else {
      combos <- expand.grid(value_indices, stringsAsFactors = FALSE)
    }

    if (isTRUE(sens$keep_baseline)) {
      idx <- idx + 1L
      specs[[idx]] <- list(
        run_index = idx,
        run_label = "baseline",
        changes = list(),
        change_summary = "baseline",
        design = "grid"
      )
      table_rows[[idx]] <- data.frame(
        run_index = idx,
        run_label = "baseline",
        design = "grid",
        parameter_path = "baseline",
        parameter_value = "baseline",
        change_summary = "baseline",
        stringsAsFactors = FALSE
      )
    }

    for (i in seq_len(nrow(combos))) {
      idx <- idx + 1L
      changes <- list()
      parts <- character(length(parsed))

      for (k in seq_along(parsed)) {
        path <- parsed[[k]]$path
        val_idx <- as.integer(combos[i, k])
        value <- parsed[[k]]$values[[val_idx]]
        changes[[path]] <- value
        parts[[k]] <- sprintf("%s=%s", path, portal_value_string_v1(value))
      }

      summary <- paste(parts, collapse = "; ")
      label <- sprintf("grid_%03d", i)

      specs[[idx]] <- list(
        run_index = idx,
        run_label = label,
        changes = changes,
        change_summary = summary,
        design = "grid"
      )
      table_rows[[idx]] <- data.frame(
        run_index = idx,
        run_label = label,
        design = "grid",
        parameter_path = "multiple",
        parameter_value = "multiple",
        change_summary = summary,
        stringsAsFactors = FALSE
      )
    }
  }

  design_table <- do.call(rbind, table_rows)
  rownames(design_table) <- NULL

  list(specs = specs, design_table = design_table)
}

resolve_portal_plan_path_v1 <- function(path) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
    portal_abort_v1(
      "Portal plan path must be a non-empty character scalar.",
      class = "herbivoreTTR_portal_plan_invalid",
      path = path
    )
  }

  if (file.exists(path)) {
    return(normalizePath(path, winslash = "/", mustWork = TRUE))
  }

  repo_root <- scenario_find_repo_root()
  if (!is.null(repo_root)) {
    rooted <- file.path(repo_root, path)
    if (file.exists(rooted)) {
      return(normalizePath(rooted, winslash = "/", mustWork = TRUE))
    }
  }

  portal_abort_v1(
    "Portal plan YAML file does not exist.",
    class = "herbivoreTTR_portal_plan_path_missing",
    path = path
  )
}

validate_portal_plan_v1 <- function(plan) {
  if (!is.list(plan)) {
    portal_abort_v1(
      "Portal plan must be a list.",
      class = "herbivoreTTR_portal_plan_invalid",
      plan = plan
    )
  }

  schema_version <- portal_parse_character_scalar_v1(plan$schema_version, "schema_version")
  if (!identical(schema_version, portal_plan_schema_version_v1())) {
    portal_abort_v1(
      sprintf("Unsupported portal schema version `%s`.", schema_version),
      class = "herbivoreTTR_portal_plan_invalid",
      schema_version = schema_version,
      expected = portal_plan_schema_version_v1()
    )
  }

  plan$plan_id <- portal_parse_character_scalar_v1(plan$plan_id, "plan_id")
  plan$description <- portal_parse_character_scalar_v1(plan$description, "description", allow_empty = TRUE)

  if (!is.list(plan$execution)) {
    portal_abort_v1(
      "Field `execution` must be a list.",
      class = "herbivoreTTR_portal_plan_invalid"
    )
  }

  plan$execution$mode <- match.arg(
    portal_parse_character_scalar_v1(plan$execution$mode, "execution.mode"),
    choices = c("single", "sensitivity")
  )
  plan$execution$base_dir <- portal_parse_character_scalar_v1(plan$execution$base_dir, "execution.base_dir")
  plan$execution$dry_run <- portal_parse_logical_scalar_v1(plan$execution$dry_run, FALSE, "execution.dry_run")
  plan$execution$write_outputs <- portal_parse_logical_scalar_v1(plan$execution$write_outputs, TRUE, "execution.write_outputs")

  if (!is.list(plan$execution$parallel)) {
    portal_abort_v1(
      "Field `execution.parallel` must be a list.",
      class = "herbivoreTTR_portal_plan_invalid"
    )
  }
  plan$execution$parallel$execution_mode <- match.arg(
    portal_parse_character_scalar_v1(plan$execution$parallel$execution_mode, "execution.parallel.execution_mode"),
    choices = c("auto", "serial", "multicore")
  )
  plan$execution$parallel$workers <- portal_parse_integer_scalar_or_null_v1(plan$execution$parallel$workers, "execution.parallel.workers")
  reserve_cores <- portal_parse_integer_scalar_or_null_v1(
    plan$execution$parallel$reserve_cores,
    "execution.parallel.reserve_cores"
  )
  if (is.null(reserve_cores)) {
    reserve_cores <- 1L
  }
  plan$execution$parallel$reserve_cores <- as.integer(reserve_cores)

  if (!is.list(plan$scenario)) {
    portal_abort_v1(
      "Field `scenario` must be a list.",
      class = "herbivoreTTR_portal_plan_invalid"
    )
  }
  plan$scenario$source <- match.arg(
    portal_parse_character_scalar_v1(plan$scenario$source, "scenario.source"),
    choices = c("reference", "path")
  )

  if (identical(plan$scenario$source, "reference")) {
    plan$scenario$reference <- portal_parse_character_scalar_v1(plan$scenario$reference, "scenario.reference")
    ref_path <- scenario_contract_reference_path(plan$scenario$reference)
    if (!file.exists(ref_path)) {
      portal_abort_v1(
        sprintf("Scenario reference `%s` could not be resolved.", plan$scenario$reference),
        class = "herbivoreTTR_portal_plan_invalid",
        reference = plan$scenario$reference,
        path = ref_path
      )
    }
    plan$scenario$path <- NULL
  } else {
    plan$scenario$path <- portal_parse_character_scalar_v1(plan$scenario$path, "scenario.path")
    resolve_scenario_yaml_path(plan$scenario$path)
    plan$scenario$reference <- ""
  }

  if (is.null(plan$scenario$overrides)) {
    plan$scenario$overrides <- list()
  }
  if (!is.list(plan$scenario$overrides)) {
    portal_abort_v1(
      "Field `scenario.overrides` must be a list.",
      class = "herbivoreTTR_portal_plan_invalid"
    )
  }

  if (!is.list(plan$sensitivity)) {
    portal_abort_v1(
      "Field `sensitivity` must be a list.",
      class = "herbivoreTTR_portal_plan_invalid"
    )
  }
  plan$sensitivity$enabled <- portal_parse_logical_scalar_v1(plan$sensitivity$enabled, FALSE, "sensitivity.enabled")
  plan$sensitivity$design <- match.arg(
    portal_parse_character_scalar_v1(plan$sensitivity$design, "sensitivity.design"),
    choices = c("one_at_a_time", "grid")
  )
  plan$sensitivity$keep_baseline <- portal_parse_logical_scalar_v1(plan$sensitivity$keep_baseline, TRUE, "sensitivity.keep_baseline")
  if (is.null(plan$sensitivity$parameters)) {
    plan$sensitivity$parameters <- list()
  }
  if (!is.list(plan$sensitivity$parameters)) {
    portal_abort_v1(
      "Field `sensitivity.parameters` must be a list.",
      class = "herbivoreTTR_portal_plan_invalid"
    )
  }

  if (identical(plan$execution$mode, "sensitivity")) {
    plan$sensitivity$enabled <- TRUE
  }

  if (isTRUE(plan$sensitivity$enabled) && length(plan$sensitivity$parameters) < 1L) {
    portal_abort_v1(
      "Sensitivity mode requires at least one parameter block.",
      class = "herbivoreTTR_portal_plan_sensitivity_invalid"
    )
  }

  if (!is.list(plan$outputs)) {
    portal_abort_v1(
      "Field `outputs` must be a list.",
      class = "herbivoreTTR_portal_plan_invalid"
    )
  }
  plan$outputs$render_report <- portal_parse_logical_scalar_v1(plan$outputs$render_report, TRUE, "outputs.render_report")
  plan$outputs$include_interactive <- portal_parse_logical_scalar_v1(plan$outputs$include_interactive, TRUE, "outputs.include_interactive")
  acceptance_profile <- portal_parse_character_scalar_v1(plan$outputs$acceptance_profile, "outputs.acceptance_profile")
  allowed_acceptance <- c("standard", "balanced_demo", "stress_demo")
  if (!acceptance_profile %in% allowed_acceptance) {
    portal_abort_v1(
      "Field `outputs.acceptance_profile` contains unsupported value.",
      class = "herbivoreTTR_portal_plan_invalid",
      acceptance_profile = acceptance_profile,
      allowed = allowed_acceptance
    )
  }
  plan$outputs$acceptance_profile <- acceptance_profile

  formats <- plan$outputs$report_formats
  if (is.null(formats) || length(formats) < 1L) {
    formats <- c("html")
  }
  if (!is.character(formats)) {
    portal_abort_v1(
      "Field `outputs.report_formats` must be a character vector.",
      class = "herbivoreTTR_portal_plan_invalid"
    )
  }
  formats <- unique(tolower(formats))
  allowed_formats <- c("html", "pdf")
  if (!all(formats %in% allowed_formats)) {
    portal_abort_v1(
      "Field `outputs.report_formats` contains unsupported values.",
      class = "herbivoreTTR_portal_plan_invalid",
      report_formats = formats
    )
  }
  plan$outputs$report_formats <- formats

  plan
}

compile_portal_plan_yaml <- function(path) {
  resolved_path <- resolve_portal_plan_path_v1(path)
  raw <- yaml::read_yaml(resolved_path)

  if (is.null(raw) || !is.list(raw)) {
    portal_abort_v1(
      "Portal plan YAML must decode to a named list.",
      class = "herbivoreTTR_portal_plan_invalid",
      path = resolved_path
    )
  }

  defaults <- portal_plan_default_v1()
  merged <- portal_merge_defaults_v1(defaults, raw)
  validated <- validate_portal_plan_v1(merged)
  validated$plan_path <- resolved_path
  validated
}
