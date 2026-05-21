#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
  library(purrr)
})

source("scripts/_pipeline_utils.R")

ensure_dirs(c("data/processed", "outputs/tables"))

turn_pairs <- read_csv("data/processed/turn_pairs.csv", show_col_types = FALSE)

act_values <- turn_pairs %>%
  transmute(dialogue_act = str_split(next_user_dialogue_act %||% "", "\\|")) %>%
  unnest(dialogue_act) %>%
  mutate(dialogue_act = trimws(dialogue_act)) %>%
  filter(dialogue_act != "") %>%
  distinct(dialogue_act) %>%
  arrange(dialogue_act)

map_info_seeking <- function(act) {
  act %in% c("request_followup", "request_aspect", "request_topic", "request_other")
}

map_followup <- function(act) {
  act %in% c("request_followup")
}

map_aspect_shift <- function(act) {
  act %in% c("request_aspect", "shift_aspect", "request_topic")
}

map_closure <- function(act) {
  act %in% c("social_goodbye", "offer_decline", "closing")
}

dialogue_act_mapping <- act_values %>%
  mutate(
    mapped_next_user_info_seeking = as.integer(map_lgl(dialogue_act, map_info_seeking)),
    mapped_generic_engagement = as.integer(dialogue_act %in% c("feedback_positive", "feedback_ask", "offer_accept", "request_followup", "request_aspect", "request_topic", "request_other")),
    mapped_closure = as.integer(map_lgl(dialogue_act, map_closure)),
    notes = case_when(
      dialogue_act == "request_followup" ~ "Strict follow-up request",
      dialogue_act %in% c("request_aspect", "request_topic", "request_other") ~ "Information-seeking acts",
      dialogue_act %in% c("feedback_positive", "feedback_negative") ~ "Feedback, not direct information request",
      TRUE ~ ""
    )
  )

write_csv(dialogue_act_mapping, "outputs/tables/dialogue_act_mapping.csv")

turn_pairs <- turn_pairs %>%
  group_by(dialogue_id) %>%
  arrange(assistant_turn_index, .by_group = TRUE) %>%
  mutate(
    assistant_liked_binary = case_when(
      has_like_label & !is.na(assistant_liked) ~ as.integer(assistant_liked),
      TRUE ~ NA_integer_
    ),
    next_user_info_seeking = as.integer(str_detect(next_user_dialogue_act %||% "", "request_followup|request_aspect|request_topic|request_other")),
    next_user_request_followup = as.integer(str_detect(next_user_dialogue_act %||% "", "\\brequest_followup\\b")),
    next_user_aspect_shift = as.integer(str_detect(next_user_dialogue_act %||% "", "request_aspect|shift_aspect|request_topic")),
    remaining_turns_total = pmax(0L, max(assistant_turn_index, na.rm = TRUE) - assistant_turn_index),
    remaining_user_turns = purrr::map_int(
      assistant_turn_index,
      ~ sum(unique(na.omit(user_next_turn_index)) > .x)
    ),
    remaining_assistant_turns = (n() - row_number()),
    dialogue_survival_1 = as.integer(remaining_user_turns >= 1),
    dialogue_survival_2 = as.integer(remaining_user_turns >= 2),
    dialogue_survival_3 = as.integer(remaining_user_turns >= 3),
    prior_dialogue_turns = assistant_turn_index - 1L,
    prior_assistant_likes_count = lag(cumsum(coalesce(assistant_liked_binary, 0L)), default = 0L),
    prior_assistant_like_rate = ifelse(prior_dialogue_turns > 0, prior_assistant_likes_count / prior_dialogue_turns, 0),
    prior_user_info_seeking_count = lag(cumsum(coalesce(next_user_info_seeking, 0L)), default = 0L),
    prior_user_info_seeking_rate = ifelse(prior_dialogue_turns > 0, prior_user_info_seeking_count / prior_dialogue_turns, 0),
    prior_user_request_followup_count = lag(cumsum(coalesce(next_user_request_followup, 0L)), default = 0L),
    prior_user_request_followup_rate = ifelse(prior_dialogue_turns > 0, prior_user_request_followup_count / prior_dialogue_turns, 0),
    previous_user_info_seeking = lag(next_user_info_seeking),
    previous_user_request_followup = lag(next_user_request_followup)
  ) %>%
  ungroup()

write_csv(turn_pairs, "data/processed/turn_pairs.csv")
message("Updated data/processed/turn_pairs.csv with existing-label outcomes.")
