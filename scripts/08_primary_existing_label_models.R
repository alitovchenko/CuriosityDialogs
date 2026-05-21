#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(broom)
})

source("scripts/_pipeline_utils.R")

ensure_dirs(c("outputs/models", "outputs/tables"))

turn_pairs <- read_csv("data/processed/turn_pairs.csv", show_col_types = FALSE) %>%
  filter(included_primary)

fit_logit <- function(df, outcome) {
  model_df <- df %>%
    mutate(
      across(c(any_rooted_fact, any_aspect_fact, any_general_fact, assistant_has_question_mark), as.integer),
      dialogue_turn_number = as.numeric(dialogue_turn_number),
      assistant_word_count = as.numeric(assistant_word_count),
      assistant_n_named_entities = as.numeric(assistant_n_named_entities),
      n_total_grounded_facts = as.numeric(n_total_grounded_facts),
      prior_assistant_like_rate = as.numeric(prior_assistant_like_rate),
      prior_user_info_seeking_rate = as.numeric(prior_user_info_seeking_rate)
    ) %>%
    filter(!is.na(.data[[outcome]]))

  formula <- as.formula(paste0(
    outcome, " ~ any_rooted_fact + any_aspect_fact + any_general_fact + ",
    "dialogue_turn_number + assistant_word_count + assistant_n_named_entities + ",
    "assistant_has_question_mark + n_total_grounded_facts + ",
    "prior_assistant_like_rate + prior_user_info_seeking_rate"
  ))

  fit <- glm(formula, family = binomial(), data = model_df)

  broom::tidy(fit, conf.int = TRUE) %>%
    mutate(
      outcome = .env$outcome,
      odds_ratio = exp(estimate),
      conf_low_or = exp(conf.low),
      conf_high_or = exp(conf.high),
      N = nobs(fit),
      N_dialogues = n_distinct(model_df$dialogue_id),
      N_users = n_distinct(model_df$user_id),
      N_assistants = n_distinct(model_df$assistant_id),
      N_focus_entities = n_distinct(model_df$focus_entity),
      outcome_prevalence = mean(model_df[[.env$outcome]], na.rm = TRUE)
    )
}

model_outputs <- bind_rows(
  fit_logit(turn_pairs %>% filter(has_like_label), "assistant_liked_binary"),
  fit_logit(turn_pairs, "next_user_info_seeking"),
  fit_logit(turn_pairs, "next_user_request_followup"),
  fit_logit(turn_pairs, "dialogue_survival_2")
)

write_csv(model_outputs, "outputs/tables/milestone_primary_models.csv")
saveRDS(model_outputs, "outputs/models/milestone_primary_models.rds")
message("Wrote outputs/tables/milestone_primary_models.csv")
