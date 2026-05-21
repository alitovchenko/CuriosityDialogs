#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(tibble)
  library(stringr)
  library(readr)
})

source("scripts/_pipeline_utils.R")

ensure_dirs(c("data/processed", "outputs/tables", "outputs/reports"))

dialogs_tbl <- if (file.exists("data/interim/dialogs_all_splits.rds")) {
  readRDS("data/interim/dialogs_all_splits.rds")
} else {
  load_all_dialogs("data/curiosity/v1")
}

build_turn_rows <- function(dialog) {
  msgs <- dialog$messages %||% list()
  if (length(msgs) == 0) return(tibble())

  rows <- vector("list", length(msgs))
  for (i in seq_along(msgs)) {
    m <- msgs[[i]]
    if (!identical(m$sender, "assistant")) next

    next_user_idx <- which(map_chr(msgs, ~ safe_chr(.x$sender)) == "user" & seq_along(msgs) > i)
    next_user_idx <- if (length(next_user_idx) > 0) next_user_idx[1] else NA_integer_

    prev_user_idx <- which(map_chr(msgs, ~ safe_chr(.x$sender)) == "user" & seq_along(msgs) < i)
    prev_user_idx <- if (length(prev_user_idx) > 0) prev_user_idx[length(prev_user_idx)] else NA_integer_

    prev_assistant_idx <- which(map_chr(msgs, ~ safe_chr(.x$sender)) == "assistant" & seq_along(msgs) < i)
    prev_assistant_idx <- if (length(prev_assistant_idx) > 0) prev_assistant_idx[length(prev_assistant_idx)] else NA_integer_

    next_user <- if (!is.na(next_user_idx)) msgs[[next_user_idx]] else NULL
    prev_user <- if (!is.na(prev_user_idx)) msgs[[prev_user_idx]] else NULL
    prev_assistant <- if (!is.na(prev_assistant_idx)) msgs[[prev_assistant_idx]] else NULL

    used_sources <- extract_used_fact_sources(m$facts)
    n_rooted <- sum(used_sources == "known")
    n_aspect <- sum(used_sources == "section")
    n_general <- sum(used_sources == "random")
    n_total <- n_rooted + n_aspect + n_general

    assistant_text <- trim_or_na(safe_chr(m$message))
    is_flagged <- isTRUE(dialog$reported %||% FALSE)
    has_next <- !is.null(next_user)
    included_primary <- isTRUE(has_next) && !isTRUE(is_flagged) && !is.na(assistant_text)

    rows[[i]] <- tibble(
      dialogue_id = as.character(dialog$dialog_id %||% NA),
      assistant_turn_id = safe_chr(m$message_id),
      assistant_turn_index = i,
      user_next_turn_id = if (has_next) safe_chr(next_user$message_id) else NA_character_,
      user_next_turn_index = if (has_next) as.integer(next_user_idx) else NA_integer_,
      focus_entity = safe_chr(dialog$focus_entity),
      aspects = collapse_vec(dialog$aspects),
      user_id = safe_chr(dialog$user_id),
      assistant_id = safe_chr(dialog$assistant_id),
      assistant_text = assistant_text,
      next_user_text = if (has_next) trim_or_na(safe_chr(next_user$message)) else NA_character_,
      previous_user_text = if (!is.null(prev_user)) trim_or_na(safe_chr(prev_user$message)) else NA_character_,
      previous_assistant_text = if (!is.null(prev_assistant)) trim_or_na(safe_chr(prev_assistant$message)) else NA_character_,
      dialogue_turn_number = i,
      assistant_dialogue_act = collapse_vec(m$dialog_acts),
      next_user_dialogue_act = if (has_next) collapse_vec(next_user$dialog_acts) else NA_character_,
      previous_user_dialogue_act = if (!is.null(prev_user)) collapse_vec(prev_user$dialog_acts) else NA_character_,
      assistant_liked = safe_lgl(m$liked),
      has_next_user_turn = has_next,
      has_grounding = length(m$facts %||% list()) > 0,
      has_like_label = !is.na(safe_lgl(m$liked)),
      has_known_entities = length(dialog$known_entities %||% list()) > 0,
      has_fact_source = length(unique(map_chr(m$facts %||% list(), ~ safe_chr(.x$source)))) > 0,
      is_flagged_dialogue = is_flagged,
      included_primary = included_primary,
      included_grounded = included_primary && (length(m$facts %||% list()) > 0),
      any_rooted_fact = n_rooted > 0,
      any_aspect_fact = n_aspect > 0,
      any_general_fact = n_general > 0,
      n_rooted_facts = n_rooted,
      n_aspect_facts = n_aspect,
      n_general_facts = n_general,
      n_total_grounded_facts = n_total,
      rooted_share = ifelse(n_total > 0, n_rooted / n_total, NA_real_),
      fact_source_type = map_fact_source_type(n_rooted, n_aspect, n_general)
    )
  }

  bind_rows(rows)
}

turn_pairs <- dialogs_tbl %>%
  mutate(rows = map(dialog, build_turn_rows)) %>%
  select(split, rows) %>%
  tidyr::unnest(rows)

write_csv(turn_pairs, "data/processed/turn_pairs.csv")

source_mapping <- tibble(
  raw_source_value = c("known", "section", "random"),
  mapped_category = c("rooted", "aspect", "general"),
  notes = c(
    "Mapped to rooted facts (user prior knowledge anchor)",
    "Mapped to aspect facts (focus entity section-level facts)",
    "Mapped to general/random facts"
  )
)
write_csv(source_mapping, "outputs/tables/fact_source_mapping.csv")

message("Wrote data/processed/turn_pairs.csv with ", nrow(turn_pairs), " assistant-turn rows")
