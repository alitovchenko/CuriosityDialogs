#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(purrr)
  library(readr)
  library(tibble)
  library(stringr)
})

source("scripts/_pipeline_utils.R")

ensure_dirs(c("outputs/reports", "outputs/tables", "data/interim"))

dialogs_tbl <- load_all_dialogs("data/curiosity/v1")
all_dialogs <- dialogs_tbl$dialog

extract_message_rows <- function(dialog, split) {
  messages <- dialog$messages %||% list()
  if (length(messages) == 0) return(tibble())
  tibble(
    split = split,
    dialog_id = as.character(dialog$dialog_id %||% NA),
    message = messages
  ) %>%
    mutate(
      sender = map_chr(message, ~ safe_chr(.x$sender)),
      dialog_acts = map_chr(message, ~ collapse_vec(.x$dialog_acts)),
      liked = map_lgl(message, ~ safe_lgl(.x$liked)),
      facts_n = map_int(message, ~ length(.x$facts %||% list())),
      facts_source_values = map_chr(message, ~ collapse_vec(unique(map_chr(.x$facts %||% list(), ~ safe_chr(.x$source)))))
    )
}

messages_tbl <- map2_dfr(dialogs_tbl$dialog, dialogs_tbl$split, extract_message_rows)

field_inventory <- tibble(
  field_name = c(
    "dialog.dialog_id",
    "dialog.user_id",
    "dialog.assistant_id",
    "dialog.focus_entity",
    "dialog.aspects",
    "dialog.known_entities",
    "dialog.related_entities",
    "dialog.reported",
    "dialog.messages",
    "message.message_id",
    "message.sender",
    "message.message",
    "message.liked",
    "message.dialog_acts",
    "message.facts",
    "fact.fid",
    "fact.source",
    "fact.used"
  ),
  field_type = c(
    "integer", "character", "character", "character",
    "list[character]", "list[character]", "list[character]", "logical", "list[message]",
    "character", "character", "character", "logical", "list[character]", "list[fact]",
    "integer", "character", "logical"
  )
)

example_from_dialog <- function(path) {
  vals <- map_chr(all_dialogs, function(d) {
    if (path == "dialog.aspects") return(collapse_vec(d$aspects))
    if (path == "dialog.known_entities") return(collapse_vec(d$known_entities))
    if (path == "dialog.related_entities") return(collapse_vec(d$related_entities))
    if (path == "dialog.messages") return(as.character(length(d$messages %||% list())))
    key <- str_remove(path, "^dialog\\.")
    val <- d[[key]]
    if (is.null(val)) return(NA_character_)
    as.character(val[[1]])
  })
  vals[!is.na(vals) & vals != ""][1] %||% NA_character_
}

example_from_messages <- function(path) {
  path2 <- str_remove(path, "^message\\.")
  vals <- map_chr(messages_tbl$message, function(m) {
    if (path2 == "dialog_acts") return(collapse_vec(m$dialog_acts))
    if (path2 == "facts") return(as.character(length(m$facts %||% list())))
    val <- m[[path2]]
    if (is.null(val)) return(NA_character_)
    as.character(val[[1]])
  })
  vals[!is.na(vals) & vals != ""][1] %||% NA_character_
}

all_facts <- map(messages_tbl$message, ~ .x$facts %||% list()) %>% flatten()
fact_df <- tibble(fact = all_facts) %>%
  mutate(
    fid = map_chr(fact, ~ as.character(.x$fid %||% NA)),
    source = map_chr(fact, ~ safe_chr(.x$source)),
    used = map_lgl(fact, ~ safe_lgl(.x$used))
  )

missing_rate_lookup <- function(field) {
  if (startsWith(field, "dialog.")) {
    key <- str_remove(field, "^dialog\\.")
    vals <- map(all_dialogs, ~ .x[[key]])
    miss <- mean(map_lgl(vals, ~ is.null(.x) || length(.x) == 0))
    return(miss)
  }
  if (startsWith(field, "message.")) {
    key <- str_remove(field, "^message\\.")
    vals <- map(messages_tbl$message, ~ .x[[key]])
    miss <- mean(map_lgl(vals, ~ is.null(.x) || length(.x) == 0))
    return(miss)
  }
  key <- str_remove(field, "^fact\\.")
  vals <- fact_df[[key]]
  mean(is.na(vals) | vals == "")
}

field_inventory <- field_inventory %>%
  mutate(
    example_values = case_when(
      startsWith(field_name, "dialog.") ~ map_chr(field_name, example_from_dialog),
      startsWith(field_name, "message.") ~ map_chr(field_name, example_from_messages),
      field_name == "fact.fid" ~ fact_df$fid[which(!is.na(fact_df$fid))[1]] %||% NA_character_,
      field_name == "fact.source" ~ fact_df$source[which(!is.na(fact_df$source))[1]] %||% NA_character_,
      field_name == "fact.used" ~ as.character(fact_df$used[which(!is.na(fact_df$used))[1]] %||% NA),
      TRUE ~ NA_character_
    ),
    missing_rate = map_dbl(field_name, missing_rate_lookup),
    notes = case_when(
      field_name == "fact.source" ~ "Observed values: known, section, random",
      field_name == "fact.used" ~ "TRUE indicates selected/used fact",
      field_name == "message.liked" ~ "Message-level like label",
      TRUE ~ ""
    )
  )

write_csv(field_inventory, "outputs/tables/dataset_field_inventory.csv")

audit_lines <- c(
  "=== Dataset schema audit ===",
  sprintf("Total dialogs: %d", length(all_dialogs)),
  sprintf("Total messages: %d", nrow(messages_tbl)),
  "",
  "Top-level names(data):",
  paste(names(jsonlite::fromJSON("data/curiosity/v1/curiosity_dialogs.train.json")), collapse = ", "),
  "",
  "str(data) (train split, top level):",
  capture.output(str(jsonlite::fromJSON("data/curiosity/v1/curiosity_dialogs.train.json"), max.level = 1)),
  "",
  "Sample rows (first two dialogs, selected fields):",
  capture.output(
    tibble(
      dialog_id = map_chr(all_dialogs[1:2], ~ as.character(.x$dialog_id %||% NA)),
      focus_entity = map_chr(all_dialogs[1:2], ~ safe_chr(.x$focus_entity)),
      aspects = map_chr(all_dialogs[1:2], ~ collapse_vec(.x$aspects)),
      n_messages = map_int(all_dialogs[1:2], ~ length(.x$messages %||% list()))
    )
  ),
  "",
  "Nested structures observed:",
  "- dialogs[] contains messages[]",
  "- each message contains facts[]",
  "",
  "Unique speaker labels:",
  paste(sort(unique(messages_tbl$sender)), collapse = ", "),
  "",
  "Unique dialogue acts (all senders):",
  paste(sort(unique(unlist(strsplit(na.omit(messages_tbl$dialog_acts), "\\|")))), collapse = ", "),
  "",
  "Available grounding fields:",
  "message.facts, fact.source, fact.used, fact.fid",
  "",
  "Available fact-source fields:",
  paste(sort(unique(na.omit(fact_df$source))), collapse = ", "),
  "",
  "Available like/reaction fields:",
  "message.liked, dialog.user_dialog_rating, dialog.assistant_dialog_rating",
  "",
  "Available known-entity fields:",
  "dialog.known_entities, dialog.related_entities, dialog.focus_entity"
)

writeLines(audit_lines, "outputs/reports/dataset_schema_audit.txt")
saveRDS(dialogs_tbl, "data/interim/dialogs_all_splits.rds")

message("Wrote outputs/reports/dataset_schema_audit.txt")
message("Wrote outputs/tables/dataset_field_inventory.csv")
