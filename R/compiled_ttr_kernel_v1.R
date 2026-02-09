# Optional compiled kernels for TTR hot-path experiments.

.compiled_ttr_kernel_env <- new.env(parent = baseenv())

is_truthy_flag_v1 <- function(value) {
  if (isTRUE(value)) {
    return(TRUE)
  }
  if (!is.character(value) || length(value) != 1L || is.na(value)) {
    return(FALSE)
  }
  tolower(trimws(value)) %in% c("1", "true", "yes", "on")
}

compiled_ttr_requested_v1 <- function() {
  is_truthy_flag_v1(getOption("herbivoreTTR.use_compiled_ttr", FALSE)) ||
    is_truthy_flag_v1(Sys.getenv("HERBIVORETTR_USE_COMPILED_TTR", unset = "0"))
}

compiled_minute_loop_requested_v1 <- function() {
  is_truthy_flag_v1(getOption("herbivoreTTR.use_compiled_minute_loop", FALSE)) ||
    is_truthy_flag_v1(Sys.getenv("HERBIVORETTR_USE_COMPILED_MINUTE_LOOP", unset = "0"))
}

compiled_ttr_force_unavailable_v1 <- function() {
  is_truthy_flag_v1(Sys.getenv("HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE", unset = "0"))
}

reset_compiled_ttr_kernel_v1 <- function() {
  rm(list = ls(envir = .compiled_ttr_kernel_env, all.names = TRUE), envir = .compiled_ttr_kernel_env)
  invisible(TRUE)
}

compiled_ttr_last_engine_v1 <- function() {
  engine <- get0("last_engine", envir = .compiled_ttr_kernel_env, ifnotfound = NA_character_)
  if (is.null(engine) || !length(engine)) {
    return(NA_character_)
  }
  as.character(engine[[1]])
}

compiled_ttr_last_fallback_used_v1 <- function() {
  fallback <- get0("last_fallback_used", envir = .compiled_ttr_kernel_env, ifnotfound = NA)
  if (is.null(fallback) || !length(fallback)) {
    return(NA)
  }
  as.logical(fallback[[1]])
}

compiled_ttr_last_requested_v1 <- function() {
  requested <- get0("last_requested", envir = .compiled_ttr_kernel_env, ifnotfound = NA)
  if (is.null(requested) || !length(requested)) {
    return(NA)
  }
  as.logical(requested[[1]])
}

compiled_minute_loop_last_engine_v1 <- function() {
  engine <- get0("last_minute_loop_engine", envir = .compiled_ttr_kernel_env, ifnotfound = NA_character_)
  if (is.null(engine) || !length(engine)) {
    return(NA_character_)
  }
  as.character(engine[[1]])
}

compiled_minute_loop_last_fallback_used_v1 <- function() {
  fallback <- get0("last_minute_loop_fallback_used", envir = .compiled_ttr_kernel_env, ifnotfound = NA)
  if (is.null(fallback) || !length(fallback)) {
    return(NA)
  }
  as.logical(fallback[[1]])
}

compiled_minute_loop_last_requested_v1 <- function() {
  requested <- get0("last_minute_loop_requested", envir = .compiled_ttr_kernel_env, ifnotfound = NA)
  if (is.null(requested) || !length(requested)) {
    return(NA)
  }
  as.logical(requested[[1]])
}

emit_compiled_ttr_fallback_warning_v1 <- function(reason) {
  if (isTRUE(get0("fallback_warning_emitted", envir = .compiled_ttr_kernel_env, ifnotfound = FALSE))) {
    return(invisible(FALSE))
  }
  warning(
    sprintf("Compiled TTR kernel requested but unavailable; falling back to pure R (%s).", reason),
    call. = FALSE
  )
  assign("fallback_warning_emitted", TRUE, envir = .compiled_ttr_kernel_env)
  invisible(TRUE)
}

emit_compiled_minute_loop_fallback_warning_v1 <- function(reason) {
  if (isTRUE(get0("minute_loop_fallback_warning_emitted", envir = .compiled_ttr_kernel_env, ifnotfound = FALSE))) {
    return(invisible(FALSE))
  }
  warning(
    sprintf("Compiled minute-loop kernel requested but unavailable; falling back to pure R (%s).", reason),
    call. = FALSE
  )
  assign("minute_loop_fallback_warning_emitted", TRUE, envir = .compiled_ttr_kernel_env)
  invisible(TRUE)
}

get_ttr_resistance_cpp_kernel_v1 <- function() {
  if (compiled_ttr_force_unavailable_v1()) {
    return(NULL)
  }

  cached <- get0("ttr_resistance_cpp_kernel", envir = .compiled_ttr_kernel_env, ifnotfound = NULL)
  if (is.function(cached)) {
    return(cached)
  }

  if (!requireNamespace("Rcpp", quietly = TRUE)) {
    return(NULL)
  }

  cpp_code <- "
  Rcpp::List ttr_resistance_cpp_kernel(Rcpp::NumericVector ms,
                                       Rcpp::NumericVector mr,
                                       double tr_c,
                                       double tr_n,
                                       double q_scp,
                                       double q_snp) {
    int n = ms.size();
    if (mr.size() != n) {
      Rcpp::stop(\"`ms` and `mr` must have matching length.\");
    }

    const double large = 1e12;
    const double trC = std::max(tr_c, 0.0);
    const double trN = std::max(tr_n, 0.0);
    const double qC = std::max(q_scp, 0.0);
    const double qN = std::max(q_snp, 0.0);

    Rcpp::NumericVector rsC(n);
    Rcpp::NumericVector rrC(n);
    Rcpp::NumericVector rsN(n);
    Rcpp::NumericVector rrN(n);

    for (int i = 0; i < n; ++i) {
      double msi = ms[i];
      double mri = mr[i];

      double rsC_val = large;
      double rrC_val = large;
      double rsN_val = large;
      double rrN_val = large;

      if (std::isfinite(msi) && msi > 0.0) {
        rsC_val = trC / std::pow(msi, qC);
        rsN_val = trN / std::pow(msi, qN);
      }

      if (std::isfinite(mri) && mri > 0.0) {
        rrC_val = trC / std::pow(mri, qC);
        rrN_val = trN / std::pow(mri, qN);
      }

      if (!std::isfinite(rsC_val)) rsC_val = large;
      if (!std::isfinite(rrC_val)) rrC_val = large;
      if (!std::isfinite(rsN_val)) rsN_val = large;
      if (!std::isfinite(rrN_val)) rrN_val = large;

      rsC[i] = std::min(std::max(rsC_val, 0.0), large);
      rrC[i] = std::min(std::max(rrC_val, 0.0), large);
      rsN[i] = std::min(std::max(rsN_val, 0.0), large);
      rrN[i] = std::min(std::max(rrN_val, 0.0), large);
    }

    return Rcpp::List::create(
      Rcpp::Named(\"rsC\") = rsC,
      Rcpp::Named(\"rrC\") = rrC,
      Rcpp::Named(\"rsN\") = rsN,
      Rcpp::Named(\"rrN\") = rrN
    );
  }
  "

  compiled <- tryCatch(
    {
      Rcpp::cppFunction(
        code = cpp_code,
        env = .compiled_ttr_kernel_env
      )
      get("ttr_resistance_cpp_kernel", envir = .compiled_ttr_kernel_env)
    },
    error = function(e) {
      assign("last_compile_error", conditionMessage(e), envir = .compiled_ttr_kernel_env)
      NULL
    }
  )

  compiled
}

get_minute_loop_cpp_kernel_v1 <- function() {
  if (compiled_ttr_force_unavailable_v1()) {
    return(NULL)
  }

  cached <- get0("minute_loop_cpp_kernel", envir = .compiled_ttr_kernel_env, ifnotfound = NULL)
  if (is.function(cached)) {
    return(cached)
  }

  if (!requireNamespace("Rcpp", quietly = TRUE)) {
    return(NULL)
  }

  cpp_code <- "
  Rcpp::NumericVector minute_loop_cpp_kernel(Rcpp::NumericVector functional_multiplier,
                                             Rcpp::NumericVector size_bonus,
                                             Rcpp::NumericVector ratio_diff,
                                             Rcpp::NumericVector distance,
                                             Rcpp::NumericVector defence,
                                             Rcpp::LogicalVector eligible,
                                             double ratio_weight,
                                             double distance_weight,
                                             double defence_weight,
                                             double epsilon) {
    int n = functional_multiplier.size();
    if (size_bonus.size() != n || ratio_diff.size() != n ||
        distance.size() != n || defence.size() != n || eligible.size() != n) {
      Rcpp::stop(\"Minute-loop kernel input vectors must have matching lengths.\");
    }

    const double ratioW = std::max(ratio_weight, 0.0);
    const double distanceW = std::max(distance_weight, 0.0);
    const double defenceW = std::max(defence_weight, 0.0);
    const double eps = std::max(epsilon, 1e-12);

    Rcpp::NumericVector out(n);
    for (int i = 0; i < n; ++i) {
      if (!eligible[i]) {
        out[i] = 0.0;
        continue;
      }

      double denom = eps +
        ratioW * ratio_diff[i] +
        distanceW * distance[i] +
        defenceW * defence[i];

      double score = functional_multiplier[i] * size_bonus[i] / denom;
      if (!std::isfinite(score) || score < 0.0) {
        score = 0.0;
      }
      out[i] = score;
    }

    return out;
  }
  "

  compiled <- tryCatch(
    {
      Rcpp::cppFunction(
        code = cpp_code,
        env = .compiled_ttr_kernel_env
      )
      get("minute_loop_cpp_kernel", envir = .compiled_ttr_kernel_env)
    },
    error = function(e) {
      assign("last_minute_loop_compile_error", conditionMessage(e), envir = .compiled_ttr_kernel_env)
      NULL
    }
  )

  compiled
}

compiled_ttr_kernel_available_v1 <- function() {
  is.function(get_ttr_resistance_cpp_kernel_v1())
}

compiled_minute_loop_kernel_available_v1 <- function() {
  is.function(get_minute_loop_cpp_kernel_v1())
}

compute_ttr_resistances_kernel_v1 <- function(ms,
                                              mr,
                                              tr_c,
                                              tr_n,
                                              q_scp,
                                              q_snp = q_scp,
                                              use_compiled = FALSE) {
  ms_num <- as.numeric(ms)
  mr_num <- as.numeric(mr)
  tr_c_num <- as.numeric(tr_c[[1]])
  tr_n_num <- as.numeric(tr_n[[1]])
  q_scp_num <- as.numeric(q_scp[[1]])
  q_snp_num <- as.numeric(q_snp[[1]])

  fallback_used <- FALSE
  engine <- "r"
  use_compiled_resolved <- isTRUE(use_compiled) || compiled_ttr_requested_v1()
  assign("last_requested", use_compiled_resolved, envir = .compiled_ttr_kernel_env)

  if (isTRUE(use_compiled_resolved)) {
    kernel <- get_ttr_resistance_cpp_kernel_v1()
    if (is.function(kernel)) {
      out <- kernel(ms_num, mr_num, tr_c_num, tr_n_num, q_scp_num, q_snp_num)
      assign("last_engine", "compiled_cpp", envir = .compiled_ttr_kernel_env)
      assign("last_fallback_used", FALSE, envir = .compiled_ttr_kernel_env)
      return(list(
        rsC = as.numeric(out$rsC),
        rrC = as.numeric(out$rrC),
        rsN = as.numeric(out$rsN),
        rrN = as.numeric(out$rrN),
        engine = "compiled_cpp",
        fallback_used = FALSE
      ))
    }
    fallback_used <- TRUE
    emit_compiled_ttr_fallback_warning_v1(
      reason = if (compiled_ttr_force_unavailable_v1()) {
        "forced unavailable by HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE"
      } else if (!requireNamespace("Rcpp", quietly = TRUE)) {
        "Rcpp namespace not available"
      } else {
        "cppFunction compilation failed"
      }
    )
  }

  assign("last_engine", "r", envir = .compiled_ttr_kernel_env)
  assign("last_fallback_used", fallback_used, envir = .compiled_ttr_kernel_env)

  list(
    rsC = as.numeric(calc_RsC(tr_c_num, ms_num, q_scp_num)),
    rrC = as.numeric(calc_RrC(tr_c_num, mr_num, q_scp_num)),
    rsN = as.numeric(calc_RsN(tr_n_num, ms_num, q_snp_num)),
    rrN = as.numeric(calc_RrN(tr_n_num, mr_num, q_snp_num)),
    engine = engine,
    fallback_used = fallback_used
  )
}

compute_minute_loop_tastiness_kernel_v1 <- function(functional_multiplier,
                                                    size_bonus,
                                                    ratio_diff,
                                                    distance,
                                                    defence,
                                                    eligible,
                                                    ratio_weight,
                                                    distance_weight,
                                                    defence_weight,
                                                    epsilon,
                                                    use_compiled = FALSE) {
  n <- length(functional_multiplier)
  fmult <- as.numeric(functional_multiplier)
  sb <- as.numeric(size_bonus)
  ratio <- as.numeric(ratio_diff)
  dist <- as.numeric(distance)
  def <- as.numeric(defence)
  elig <- as.logical(eligible)

  if (!(length(sb) == n && length(ratio) == n && length(dist) == n && length(def) == n && length(elig) == n)) {
    rlang::abort(
      "Minute-loop tastiness kernel inputs must have matching lengths.",
      class = "herbivoreTTR_compiled_minute_loop_length_mismatch"
    )
  }

  ratio_w <- as.numeric(ratio_weight[[1]])
  distance_w <- as.numeric(distance_weight[[1]])
  defence_w <- as.numeric(defence_weight[[1]])
  eps <- as.numeric(epsilon[[1]])
  fallback_used <- FALSE
  use_compiled_resolved <- isTRUE(use_compiled) || compiled_minute_loop_requested_v1()
  assign("last_minute_loop_requested", use_compiled_resolved, envir = .compiled_ttr_kernel_env)

  if (isTRUE(use_compiled_resolved)) {
    kernel <- get_minute_loop_cpp_kernel_v1()
    if (is.function(kernel)) {
      scores <- kernel(
        functional_multiplier = fmult,
        size_bonus = sb,
        ratio_diff = ratio,
        distance = dist,
        defence = def,
        eligible = elig,
        ratio_weight = ratio_w,
        distance_weight = distance_w,
        defence_weight = defence_w,
        epsilon = eps
      )
      assign("last_minute_loop_engine", "compiled_cpp", envir = .compiled_ttr_kernel_env)
      assign("last_minute_loop_fallback_used", FALSE, envir = .compiled_ttr_kernel_env)
      return(list(
        scores = as.numeric(scores),
        engine = "compiled_cpp",
        fallback_used = FALSE
      ))
    }
    fallback_used <- TRUE
    emit_compiled_minute_loop_fallback_warning_v1(
      reason = if (compiled_ttr_force_unavailable_v1()) {
        "forced unavailable by HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE"
      } else if (!requireNamespace("Rcpp", quietly = TRUE)) {
        "Rcpp namespace not available"
      } else {
        "cppFunction compilation failed"
      }
    )
  }

  denom <- pmax(eps, 1e-12) +
    pmax(ratio_w, 0) * ratio +
    pmax(distance_w, 0) * dist +
    pmax(defence_w, 0) * def
  scores <- fmult * sb / denom
  scores[!is.finite(scores)] <- 0
  scores[!elig] <- 0
  scores <- pmax(scores, 0)

  assign("last_minute_loop_engine", "r", envir = .compiled_ttr_kernel_env)
  assign("last_minute_loop_fallback_used", fallback_used, envir = .compiled_ttr_kernel_env)
  list(
    scores = as.numeric(scores),
    engine = "r",
    fallback_used = fallback_used
  )
}
