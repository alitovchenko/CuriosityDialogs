`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

ensure_dirs <- function(paths) {
  for (p in paths) {
    if (!dir.exists(p)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
  }
}

safe_chr <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA_character_)
  as.character(x[[1]])
}

safe_lgl <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA)
  as.logical(x[[1]])
}

collapse_vec <- function(x, sep = "|") {
  if (is.null(x) || length(x) == 0) return(NA_character_)
  paste(as.character(x), collapse = sep)
}

trim_or_na <- function(x) {
  y <- trimws(x %||% NA_character_)
  ifelse(is.na(y) | y == "", NA_character_, y)
}

read_curiosity_split <- function(path, split_name) {
  payload <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  dialogs <- payload$dialogs %||% list()
  tibble::tibble(
    split = split_name,
    fold = payload$fold %||% split_name,
    dialog = dialogs
  )
}

load_all_dialogs <- function(data_dir = "data/curiosity/v1") {
  split_files <- c("train", "val", "test", "test_zero")
  full_paths <- file.path(data_dir, paste0("curiosity_dialogs.", split_files, ".json"))
  keep <- file.exists(full_paths)
  if (!all(keep)) {
    warning("Missing splits: ", paste(split_files[!keep], collapse = ", "))
  }
  rows <- purrr::map2_dfr(full_paths[keep], split_files[keep], read_curiosity_split)
  rows
}

extract_used_fact_sources <- function(facts) {
  if (is.null(facts) || length(facts) == 0) {
    return(character(0))
  }
  sources <- purrr::map_chr(facts, function(f) {
    used <- f$used %||% TRUE
    if (!isTRUE(used)) return(NA_character_)
    as.character(f$source %||% NA_character_)
  })
  sources <- sources[!is.na(sources)]
  sources
}

map_fact_source_type <- function(n_rooted, n_aspect, n_general) {
  n_total <- n_rooted + n_aspect + n_general
  if (n_total == 0) return("ungrounded_or_unknown")
  if (n_rooted > 0 && n_aspect == 0 && n_general == 0) return("rooted_only")
  if (n_rooted == 0 && n_aspect > 0 && n_general == 0) return("aspect_only")
  if (n_rooted == 0 && n_aspect == 0 && n_general > 0) return("general_only")
  if (n_rooted > 0) return("mixed_rooted")
  "mixed_nonrooted"
}
