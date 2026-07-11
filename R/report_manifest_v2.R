# Deterministic report artefact manifest helpers.

report_artifact_files_v2 <- function(output_dir) {
  patterns <- c("\\.html$", "\\.png$", "\\.csv$", "\\.md$")
  files <- list.files(output_dir, recursive = TRUE, full.names = TRUE)
  files[Reduce(`|`, lapply(patterns, grepl, x = files, perl = TRUE))]
}

report_required_content_markers_v2 <- function() {
  c(
    "Experiment A v2 scenario summary",
    "Experiment A v2 delta ensemble summary",
    "Experiment A v2 claim status",
    "Experiment C v2 matrix summary",
    "Experiment C v2 claim status",
    "Pilot ecological validation metrics",
    "Long-horizon stability summary"
  )
}

extract_html_blocks_v2 <- function(content, tag) {
  opening_tag <- sprintf(
    "<%s\\b(?:[^\"'>]|\"[^\"]*\"|'[^']*')*>",
    tag
  )
  pattern <- sprintf("(?is)%s.*?</%s\\s*>", opening_tag, tag)
  matches <- gregexpr(pattern, content, perl = TRUE)[[1]]
  if (identical(matches[[1]], -1L)) {
    return(character())
  }
  regmatches(content, list(matches))[[1]]
}

decode_html_numeric_entities_v2 <- function(text) {
  decode_one <- function(value) {
    pattern <- "&#(?:[xX][0-9A-Fa-f]+|[0-9]+);"
    matches <- gregexpr(pattern, value, perl = TRUE)[[1]]
    if (identical(matches[[1]], -1L)) {
      return(value)
    }

    entities <- regmatches(value, list(matches))[[1]]
    replacements <- vapply(entities, function(entity) {
      hexadecimal <- grepl("^&#[xX]", entity)
      digits <- if (hexadecimal) {
        substring(entity, 4L, nchar(entity) - 1L)
      } else {
        substring(entity, 3L, nchar(entity) - 1L)
      }
      codepoint <- suppressWarnings(strtoi(
        digits,
        base = if (hexadecimal) 16L else 10L
      ))
      invalid <- is.na(codepoint) || codepoint < 0L || codepoint > 0x10FFFFL ||
        (codepoint >= 0xD800L && codepoint <= 0xDFFFL)
      if (invalid) " " else intToUtf8(codepoint)
    }, character(1))
    regmatches(value, list(matches)) <- list(replacements)
    value
  }

  vapply(text, decode_one, character(1), USE.NAMES = FALSE)
}

html_text_content_v2 <- function(blocks) {
  tag_pattern <- "(?is)<(?:[^\"'>]|\"[^\"]*\"|'[^']*')*>"
  text <- gsub(tag_pattern, " ", blocks, perl = TRUE)
  text <- decode_html_numeric_entities_v2(text)
  text <- gsub(
    "(?i)&nbsp;",
    " ",
    text,
    perl = TRUE
  )
  text <- gsub(intToUtf8(160L), " ", text, fixed = TRUE)
  trimws(text)
}

html_table_has_caption_data_v2 <- function(table_html, caption) {
  captions <- extract_html_blocks_v2(table_html, "caption")
  caption_text <- html_text_content_v2(captions)
  caption_present <- any(vapply(
    caption_text,
    grepl,
    logical(1),
    pattern = caption,
    fixed = TRUE
  ))
  if (!caption_present) {
    return(FALSE)
  }

  bodies <- extract_html_blocks_v2(table_html, "tbody")
  any(vapply(bodies, function(body) {
    if (!grepl("(?is)<tr\\b", body, perl = TRUE)) {
      return(FALSE)
    }
    cells <- extract_html_blocks_v2(body, "td")
    cell_text <- html_text_content_v2(cells)
    any(grepl("[[:alnum:]]", cell_text))
  }, logical(1)))
}

check_report_content_v2 <- function(report_path) {
  if (!is.character(report_path) || length(report_path) != 1L ||
      is.na(report_path) || !file.exists(report_path) || dir.exists(report_path)) {
    return(FALSE)
  }

  content <- paste(readLines(report_path, warn = FALSE), collapse = "\n")
  tables <- extract_html_blocks_v2(content, "table")
  required_present <- all(vapply(
    report_required_content_markers_v2(),
    function(caption) {
      any(vapply(
        tables,
        html_table_has_caption_data_v2,
        logical(1),
        caption = caption
      ))
    },
    logical(1)
  ))
  required_present && !grepl(" is missing.", content, fixed = TRUE)
}

report_manifest_required_columns_v2 <- function() {
  c(
    "artifact_id",
    "path",
    "checksum_md5",
    "bytes",
    "modified_utc",
    "input_files_hash"
  )
}

validate_report_manifest_identity_v2 <- function(manifest, purpose) {
  identity_columns <- c("artifact_id", "checksum_md5")
  if (!is.data.frame(manifest) || nrow(manifest) < 1L ||
      !all(identity_columns %in% names(manifest))) {
    rlang::abort(
      sprintf("%s is missing required identity rows or columns.", purpose),
      class = "herbivoreTTR_report_manifest_malformed",
      purpose = purpose
    )
  }

  artifact_ids <- as.character(manifest$artifact_id)
  checksums <- as.character(manifest$checksum_md5)
  if (anyNA(artifact_ids) || any(!nzchar(artifact_ids)) ||
      anyNA(checksums) || any(!nzchar(checksums))) {
    rlang::abort(
      sprintf("%s contains empty identity values.", purpose),
      class = "herbivoreTTR_report_manifest_malformed",
      purpose = purpose
    )
  }

  duplicate_ids <- unique(artifact_ids[duplicated(artifact_ids)])
  if (length(duplicate_ids) > 0L) {
    rlang::abort(
      sprintf("%s contains duplicate artefact IDs.", purpose),
      class = "herbivoreTTR_report_manifest_duplicate_id",
      purpose = purpose,
      duplicate_ids = duplicate_ids
    )
  }

  invisible(manifest)
}

validate_report_manifest_rows_v2 <- function(manifest,
                                             purpose,
                                             manifest_path = NULL) {
  required_columns <- report_manifest_required_columns_v2()
  if (!is.data.frame(manifest) || nrow(manifest) < 1L ||
      !all(required_columns %in% names(manifest))) {
    rlang::abort(
      sprintf("%s is missing required rows or columns.", purpose),
      class = "herbivoreTTR_report_manifest_malformed",
      purpose = purpose,
      missing_columns = if (is.data.frame(manifest)) {
        setdiff(required_columns, names(manifest))
      } else {
        required_columns
      }
    )
  }

  validate_report_manifest_identity_v2(manifest, purpose)
  artifact_ids <- as.character(manifest$artifact_id)
  paths <- as.character(manifest$path)
  checksums <- as.character(manifest$checksum_md5)
  modified <- as.character(manifest$modified_utc)
  input_hashes <- as.character(manifest$input_files_hash)
  modified_parsed <- as.POSIXct(
    modified,
    format = "%Y-%m-%dT%H:%M:%SZ",
    tz = "UTC"
  )
  valid_rows <- !anyNA(paths) && all(nzchar(paths)) && !anyDuplicated(paths) &&
    all(basename(paths) == artifact_ids) &&
    all(basename(artifact_ids) == artifact_ids) &&
    all(grepl("^[0-9A-Fa-f]{32}$", checksums)) &&
    is.numeric(manifest$bytes) && all(is.finite(manifest$bytes)) &&
    all(manifest$bytes >= 0) && all(manifest$bytes == floor(manifest$bytes)) &&
    !anyNA(modified) &&
    all(grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", modified)) &&
    !anyNA(modified_parsed) &&
    !anyNA(input_hashes) && all(grepl("^[0-9A-Fa-f]{32}$", input_hashes))
  if (!is.null(manifest_path)) {
    valid_rows <- valid_rows &&
      !any(artifact_ids == basename(manifest_path))
  }
  if (!valid_rows) {
    rlang::abort(
      sprintf("%s contains malformed or ambiguous rows.", purpose),
      class = "herbivoreTTR_report_manifest_malformed",
      purpose = purpose,
      manifest_path = manifest_path
    )
  }

  invisible(manifest)
}

resolve_report_manifest_paths_v2 <- function(paths, manifest_path) {
  resolved <- as.character(paths)
  relative <- startsWith(resolved, "./")
  resolved[relative] <- file.path(
    dirname(normalizePath(manifest_path, winslash = "/", mustWork = TRUE)),
    substring(resolved[relative], 3L)
  )
  resolved
}

validate_report_artifact_manifest_v2 <- function(manifest_path,
                                                 verify_files = TRUE) {
  if (!is.character(manifest_path) || length(manifest_path) != 1L ||
      is.na(manifest_path) || !file.exists(manifest_path) ||
      dir.exists(manifest_path)) {
    rlang::abort(
      "The report artefact manifest is missing or invalid.",
      class = "herbivoreTTR_report_manifest_malformed",
      manifest_path = manifest_path
    )
  }

  manifest <- tryCatch(
    utils::read.csv(manifest_path, stringsAsFactors = FALSE),
    error = identity
  )
  if (inherits(manifest, "error")) {
    rlang::abort(
      "The report artefact manifest could not be read.",
      class = "herbivoreTTR_report_manifest_malformed",
      manifest_path = manifest_path
    )
  }

  validate_report_manifest_rows_v2(
    manifest,
    "Report artefact manifest",
    manifest_path = manifest_path
  )
  paths <- resolve_report_manifest_paths_v2(manifest$path, manifest_path)
  checksums <- as.character(manifest$checksum_md5)

  if (isTRUE(verify_files)) {
    files_valid <- all(file.exists(paths)) && !any(dir.exists(paths))
    if (files_valid) {
      files_valid <- identical(unname(tools::md5sum(paths)), checksums) &&
        identical(as.numeric(file.info(paths)$size), as.numeric(manifest$bytes))
    }
    if (!files_valid) {
      rlang::abort(
        "The report artefact manifest does not match its files.",
        class = "herbivoreTTR_report_manifest_file_mismatch",
        manifest_path = manifest_path
      )
    }
  }

  invisible(manifest)
}

rebase_copied_report_manifest_v2 <- function(manifest_path) {
  manifest <- validate_report_artifact_manifest_v2(
    manifest_path,
    verify_files = FALSE
  )
  copied_paths <- file.path(dirname(manifest_path), manifest$artifact_id)
  files_valid <- all(file.exists(copied_paths)) && !any(dir.exists(copied_paths))
  if (files_valid) {
    files_valid <- identical(
      unname(tools::md5sum(copied_paths)),
      as.character(manifest$checksum_md5)
    ) && identical(
      as.numeric(file.info(copied_paths)$size),
      as.numeric(manifest$bytes)
    )
  }
  if (!files_valid) {
    rlang::abort(
      "The copied report manifest does not match the copied report files.",
      class = "herbivoreTTR_report_manifest_file_mismatch",
      manifest_path = manifest_path
    )
  }

  manifest$path <- paste0("./", manifest$artifact_id)
  utils::write.csv(manifest, manifest_path, row.names = FALSE)
  validate_report_artifact_manifest_v2(manifest_path)
  manifest_path
}

hash_file_md5 <- function(path) {
  unname(tools::md5sum(path))
}

hash_report_input_files_v2 <- function(input_files) {
  if (length(input_files) < 1L) {
    return(hash_scenario_parameters("none"))
  }
  valid_paths <- is.character(input_files) &&
    !anyNA(input_files) && all(nzchar(input_files)) &&
    all(file.exists(input_files)) && !any(dir.exists(input_files))
  if (!valid_paths) {
    rlang::abort(
      "Every declared report input must be an existing file.",
      class = "herbivoreTTR_report_manifest_input_missing",
      missing_inputs = input_files[!file.exists(input_files) | dir.exists(input_files)]
    )
  }

  content_checksums <- unname(tools::md5sum(input_files))
  if (anyNA(content_checksums)) {
    rlang::abort(
      "A declared report input could not be hashed.",
      class = "herbivoreTTR_report_manifest_input_missing",
      input_files = input_files
    )
  }
  provenance <- data.frame(
    path = normalize_manifest_path(input_files),
    checksum_md5 = content_checksums,
    stringsAsFactors = FALSE
  )
  hash_scenario_parameters(provenance)
}

write_report_artifact_manifest_v2 <- function(output_dir,
                                              input_files = character(),
                                              manifest_path = file.path(output_dir, "figure_table_manifest_v2.csv")) {
  if (!dir.exists(output_dir)) {
    rlang::abort(
      "Report output directory does not exist.",
      class = "herbivoreTTR_report_manifest_output_dir_missing",
      output_dir = output_dir
    )
  }

  files <- report_artifact_files_v2(output_dir)
  files <- files[file.exists(files)]
  manifest_path_normalized <- normalizePath(
    manifest_path,
    winslash = "/",
    mustWork = FALSE
  )
  files <- files[
    normalizePath(files, winslash = "/", mustWork = TRUE) != manifest_path_normalized
  ]
  files <- sort(unique(files))
  if (length(files) < 1L) {
    rlang::abort(
      "No report artefacts found for manifest generation.",
      class = "herbivoreTTR_report_manifest_no_files",
      output_dir = output_dir
    )
  }

  input_hash <- hash_report_input_files_v2(input_files)

  rows <- lapply(files, function(path) {
    info <- file.info(path)
    data.frame(
      artifact_id = basename(path),
      path = normalize_manifest_path(path),
      checksum_md5 = hash_file_md5(path),
      bytes = as.numeric(info$size),
      modified_utc = format(info$mtime, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      input_files_hash = input_hash,
      stringsAsFactors = FALSE
    )
  })
  manifest <- do.call(rbind, rows)
  rownames(manifest) <- NULL
  validate_report_manifest_rows_v2(manifest, "Generated report manifest")

  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(manifest, manifest_path, row.names = FALSE)
  manifest_path
}

check_report_manifest_determinism_v2 <- function(current_manifest_path, previous_manifest_path) {
  if (!file.exists(current_manifest_path) || !file.exists(previous_manifest_path)) {
    rlang::abort(
      "Both current and previous report manifests must exist.",
      class = "herbivoreTTR_report_manifest_compare_missing",
      current_manifest_path = current_manifest_path,
      previous_manifest_path = previous_manifest_path
    )
  }

  current <- validate_report_artifact_manifest_v2(
    current_manifest_path,
    verify_files = FALSE
  )
  previous <- validate_report_artifact_manifest_v2(
    previous_manifest_path,
    verify_files = FALSE
  )
  current_ids <- as.character(current$artifact_id)
  previous_ids <- as.character(previous$artifact_id)
  if (!setequal(current_ids, previous_ids)) {
    rlang::abort(
      "Current and previous report manifests contain different artefact ID sets.",
      class = "herbivoreTTR_report_manifest_artifact_set_mismatch",
      current_only = setdiff(current_ids, previous_ids),
      previous_only = setdiff(previous_ids, current_ids)
    )
  }
  merged <- merge(
    current[, c("artifact_id", "checksum_md5")],
    previous[, c("artifact_id", "checksum_md5")],
    by = "artifact_id",
    suffixes = c("_current", "_previous")
  )
  merged$matches <- merged$checksum_md5_current == merged$checksum_md5_previous
  merged
}
