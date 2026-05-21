#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(stringr)
})

source("scripts/_pipeline_utils.R")

ensure_dirs(c("outputs/tables", "outputs/reports"))

turn_pairs <- read_csv("data/processed/turn_pairs.csv", show_col_types = FALSE)

dataset_counts <- tibble(
  metric = c(
    "n_dialogues",
    "n_total_turns_proxy_assistant_plus_next_user",
    "n_assistant_turns",
    "n_assistant_turns_with_next_user_turn",
    "n_assistant_turns_with_grounding",
    "n_assistant_turns_with_likes",
    "n_rooted_assistant_turns",
    "n_aspect_assistant_turns",
    "n_general_assistant_turns",
    "n_likes",
    "n_next_turn_followup_acts",
    "n_usable_assistant_user_turn_pairs"
  ),
  value = c(
    n_distinct(turn_pairs$dialogue_id),
    nrow(turn_pairs) + sum(!is.na(turn_pairs$user_next_turn_id)),
    nrow(turn_pairs),
    sum(turn_pairs$has_next_user_turn, na.rm = TRUE),
    sum(turn_pairs$has_grounding, na.rm = TRUE),
    sum(turn_pairs$has_like_label, na.rm = TRUE),
    sum(turn_pairs$any_rooted_fact, na.rm = TRUE),
    sum(turn_pairs$any_aspect_fact, na.rm = TRUE),
    sum(turn_pairs$any_general_fact, na.rm = TRUE),
    sum(turn_pairs$assistant_liked_binary == 1, na.rm = TRUE),
    sum(turn_pairs$next_user_request_followup == 1, na.rm = TRUE),
    sum(turn_pairs$included_primary, na.rm = TRUE)
  )
)

outcome_prevalence <- turn_pairs %>%
  filter(included_primary) %>%
  group_by(fact_source_type) %>%
  summarise(
    n = n(),
    assistant_liked_binary = mean(assistant_liked_binary, na.rm = TRUE),
    next_user_info_seeking = mean(next_user_info_seeking, na.rm = TRUE),
    next_user_request_followup = mean(next_user_request_followup, na.rm = TRUE),
    next_user_aspect_shift = mean(next_user_aspect_shift, na.rm = TRUE),
    dialogue_survival_2 = mean(dialogue_survival_2, na.rm = TRUE),
    dialogue_survival_3 = mean(dialogue_survival_3, na.rm = TRUE),
    remaining_user_turns = mean(remaining_user_turns, na.rm = TRUE),
    .groups = "drop"
  )

missingness <- turn_pairs %>%
  summarise(across(
    c(
      assistant_text, next_user_text, assistant_liked_binary, next_user_info_seeking,
      next_user_request_followup, any_rooted_fact, rooted_share, assistant_word_count
    ),
    ~ sum(is.na(.x))
  )) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "n_missing") %>%
  mutate(percent_missing = n_missing / nrow(turn_pairs))

dialogue_act_distribution <- turn_pairs %>%
  select(assistant_dialogue_act, next_user_dialogue_act) %>%
  pivot_longer(everything(), names_to = "actor_field", values_to = "acts") %>%
  separate_rows(acts, sep = "\\|") %>%
  filter(!is.na(acts), acts != "") %>%
  mutate(actor = ifelse(actor_field == "assistant_dialogue_act", "assistant", "user_next")) %>%
  count(actor, acts, sort = TRUE)

write_csv(dataset_counts, "outputs/tables/table_A_dataset_counts.csv")
write_csv(outcome_prevalence, "outputs/tables/table_B_outcome_prevalence.csv")
write_csv(missingness, "outputs/tables/table_C_missingness.csv")
write_csv(dialogue_act_distribution, "outputs/tables/table_D_dialogue_act_distribution.csv")
message("Wrote descriptive tables A-D under outputs/tables")
