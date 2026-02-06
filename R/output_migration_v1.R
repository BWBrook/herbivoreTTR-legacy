# Output schema v1 migration helpers.

infer_csv_sep <- function(path) {
  header <- readLines(path, n = 1L, warn = FALSE)
  if (length(header) == 0L) {
    return(",")
  }
  if (grepl(";", header, fixed = TRUE)) {
    return(";")
  }
  ","
}

migrate_plants_output_v0_to_v1 <- function(plants_df, run_id) {
  if (!is.data.frame(plants_df)) {
    rlang::abort(
      "Argument `plants_df` must be a data.frame.",
      class = "herbivoreTTR_migrate_plants_not_df"
    )
  }
  if (!all(required_plant_output_columns_v0() %in% names(plants_df))) {
    rlang::abort(
      "Plant table does not satisfy v0 column contract.",
      class = "herbivoreTTR_migrate_plants_v0_columns_invalid"
    )
  }
  if (!is.character(run_id) || length(run_id) != 1L || !nzchar(run_id)) {
    rlang::abort(
      "Argument `run_id` must be a non-empty scalar character.",
      class = "herbivoreTTR_migrate_run_id_invalid",
      run_id = run_id
    )
  }

  out <- plants_df
  out$SchemaVersion <- output_schema_version()
  out$RunID <- rep(run_id, nrow(out))
  out <- out[, required_plant_output_columns_v1(), drop = FALSE]
  rownames(out) <- NULL
  out
}

migrate_herbivore_output_v0_to_v1 <- function(herb_df, run_id, herbivore_id = "herbivore_1") {
  if (!is.data.frame(herb_df)) {
    rlang::abort(
      "Argument `herb_df` must be a data.frame.",
      class = "herbivoreTTR_migrate_herb_not_df"
    )
  }
  if (!all(required_herbivore_output_columns_v0() %in% names(herb_df))) {
    rlang::abort(
      "Herbivore table does not satisfy v0 column contract.",
      class = "herbivoreTTR_migrate_herb_v0_columns_invalid"
    )
  }
  if (!is.character(run_id) || length(run_id) != 1L || !nzchar(run_id)) {
    rlang::abort(
      "Argument `run_id` must be a non-empty scalar character.",
      class = "herbivoreTTR_migrate_run_id_invalid",
      run_id = run_id
    )
  }
  if (!is.character(herbivore_id) || length(herbivore_id) != 1L || !nzchar(herbivore_id)) {
    rlang::abort(
      "Argument `herbivore_id` must be a non-empty scalar character.",
      class = "herbivoreTTR_migrate_herb_id_invalid",
      herbivore_id = herbivore_id
    )
  }

  out <- herb_df
  out$SchemaVersion <- output_schema_version()
  out$RunID <- rep(run_id, nrow(out))
  out$HerbivoreID <- rep(herbivore_id, nrow(out))
  out <- out[, required_herbivore_output_columns_v1(), drop = FALSE]
  rownames(out) <- NULL
  out
}

migrate_output_csv_v0_to_v1 <- function(input_path,
                                        output_path,
                                        table = c("plants", "herbivore"),
                                        run_id,
                                        herbivore_id = "herbivore_1") {
  table <- match.arg(table)
  sep <- infer_csv_sep(input_path)
  in_df <- utils::read.csv(input_path, sep = sep, stringsAsFactors = FALSE)

  out_df <- if (table == "plants") {
    migrate_plants_output_v0_to_v1(in_df, run_id = run_id)
  } else {
    migrate_herbivore_output_v0_to_v1(in_df, run_id = run_id, herbivore_id = herbivore_id)
  }

  out_sep <- if (table == "plants") ";" else ";"
  utils::write.table(
    out_df,
    file = output_path,
    sep = out_sep,
    row.names = FALSE,
    col.names = TRUE,
    quote = FALSE,
    fileEncoding = "UTF-8",
    eol = "\n"
  )

  invisible(output_path)
}
