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

compiled_ttr_force_unavailable_v1 <- function() {
  is_truthy_flag_v1(Sys.getenv("HERBIVORETTR_COMPILED_TTR_FORCE_UNAVAILABLE", unset = "0"))
}

reset_compiled_ttr_kernel_v1 <- function() {
  rm(list = ls(envir = .compiled_ttr_kernel_env, all.names = TRUE), envir = .compiled_ttr_kernel_env)
  invisible(TRUE)
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

compiled_ttr_kernel_available_v1 <- function() {
  is.function(get_ttr_resistance_cpp_kernel_v1())
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

  if (isTRUE(use_compiled_resolved)) {
    kernel <- get_ttr_resistance_cpp_kernel_v1()
    if (is.function(kernel)) {
      out <- kernel(ms_num, mr_num, tr_c_num, tr_n_num, q_scp_num, q_snp_num)
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

  list(
    rsC = as.numeric(calc_RsC(tr_c_num, ms_num, q_scp_num)),
    rrC = as.numeric(calc_RrC(tr_c_num, mr_num, q_scp_num)),
    rsN = as.numeric(calc_RsN(tr_n_num, ms_num, q_snp_num)),
    rrN = as.numeric(calc_RrN(tr_n_num, mr_num, q_snp_num)),
    engine = engine,
    fallback_used = fallback_used
  )
}
