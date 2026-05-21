#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
  library(broom)
})

source("scripts/_pipeline_utils.R")

ensure_dirs(c("outputs/tables", "outputs/reports"))

set.seed(20260521)

df <- read_csv("data/processed/turn_pairs.csv", show_col_types = FALSE) %>%
  filter(included_primary)

# 1) request_followup meaning vs generic continuation
generic_regex <- regex(
  "^(\\s)*(tell me more|what else|continue|go on|more|interesting|cool|okay|ok|thanks|that is interesting)([!.?\\s]*)$",
  ignore_case = TRUE
)

request_followup_rows <- df %>%
  filter(next_user_request_followup == 1) %>%
  mutate(
    next_user_text_l = str_squish(str_to_lower(coalesce(next_user_text, ""))),
    generic_continuation_only = str_detect(next_user_text_l, generic_regex)
  )

request_followup_audit <- tibble(
  metric = c(
    "n_request_followup_rows",
    "n_request_followup_generic_continuation_only",
    "pct_request_followup_generic_continuation_only"
  ),
  value = c(
    nrow(request_followup_rows),
    sum(request_followup_rows$generic_continuation_only, na.rm = TRUE),
    mean(request_followup_rows$generic_continuation_only, na.rm = TRUE)
  )
)

# 2) Models excluding assistant question-mark turns
model_df_no_q <- df %>%
  filter(assistant_has_question_mark == 0)

fit_logit <- function(data, outcome, fact_source_type_mode = FALSE) {
  dat <- data %>%
    mutate(
      dialogue_turn_number = as.numeric(dialogue_turn_number),
      assistant_word_count = as.numeric(assistant_word_count),
      assistant_n_named_entities = as.numeric(assistant_n_named_entities),
      n_total_grounded_facts = as.numeric(n_total_grounded_facts),
      prior_assistant_like_rate = as.numeric(prior_assistant_like_rate),
      prior_user_info_seeking_rate = as.numeric(prior_user_info_seeking_rate),
      any_rooted_fact = as.integer(any_rooted_fact),
      any_aspect_fact = as.integer(any_aspect_fact),
      any_general_fact = as.integer(any_general_fact),
      fact_source_type = factor(fact_source_type)
    ) %>%
    filter(!is.na(.data[[outcome]]))

  formula <- if (!fact_source_type_mode) {
    as.formula(paste0(
      outcome, " ~ any_rooted_fact + any_aspect_fact + any_general_fact + ",
      "dialogue_turn_number + assistant_word_count + assistant_n_named_entities + ",
      "n_total_grounded_facts + prior_assistant_like_rate + prior_user_info_seeking_rate"
    ))
  } else {
    as.formula(paste0(
      outcome, " ~ fact_source_type + ",
      "dialogue_turn_number + assistant_word_count + assistant_n_named_entities + ",
      "n_total_grounded_facts + prior_assistant_like_rate + prior_user_info_seeking_rate"
    ))
  }

  fit <- glm(formula, family = binomial(), data = dat)
  list(
    tidy = broom::tidy(fit, conf.int = TRUE),
    n = nrow(dat),
    prevalence = mean(dat[[outcome]], na.rm = TRUE)
  )
}

outcomes <- c(
  "assistant_liked_binary",
  "next_user_info_seeking",
  "next_user_request_followup",
  "dialogue_survival_2"
)

models_no_q <- bind_rows(lapply(outcomes, function(outcome) {
  base_df <- if (outcome == "assistant_liked_binary") {
    model_df_no_q %>% filter(has_like_label)
  } else {
    model_df_no_q
  }
  res <- fit_logit(base_df, outcome, fact_source_type_mode = FALSE)
  res$tidy %>%
    mutate(
      model = "exclude_assistant_questions",
      outcome = outcome,
      N = res$n,
      outcome_prevalence = res$prevalence,
      odds_ratio = exp(estimate),
      conf_low_or = exp(conf.low),
      conf_high_or = exp(conf.high)
    )
}))

# 3) Rooted vs aspect overlap + fact_source_type model
rooted_aspect_corr <- suppressWarnings(cor(
  as.integer(df$any_rooted_fact),
  as.integer(df$any_aspect_fact),
  use = "complete.obs"
))

rooted_aspect_table <- table(
  factor(df$any_rooted_fact, levels = c(FALSE, TRUE)),
  factor(df$any_aspect_fact, levels = c(FALSE, TRUE))
)
phi <- suppressWarnings({
  a <- as.numeric(rooted_aspect_table[2, 2])
  b <- as.numeric(rooted_aspect_table[2, 1])
  c <- as.numeric(rooted_aspect_table[1, 2])
  d <- as.numeric(rooted_aspect_table[1, 1])
  (a * d - b * c) / sqrt((a + b) * (c + d) * (a + c) * (b + d))
})

overlap_summary <- tibble(
  metric = c("cor_any_rooted_any_aspect", "phi_any_rooted_any_aspect"),
  value = c(rooted_aspect_corr, phi)
)

model_fact_source_type <- fit_logit(df, "next_user_request_followup", fact_source_type_mode = TRUE)
fact_source_type_terms <- model_fact_source_type$tidy %>%
  mutate(
    model = "fact_source_type_request_followup",
    N = model_fact_source_type$n,
    outcome_prevalence = model_fact_source_type$prevalence,
    odds_ratio = exp(estimate),
    conf_low_or = exp(conf.low),
    conf_high_or = exp(conf.high)
  )

# 4) 50 examples per rooted x follow-up cell
examples_cells <- df %>%
  filter(!is.na(next_user_request_followup)) %>%
  transmute(
    dialogue_id,
    assistant_turn_id,
    user_next_turn_id,
    focus_entity,
    fact_source_type,
    rooted = any_rooted_fact,
    request_followup = next_user_request_followup == 1,
    assistant_dialogue_act,
    next_user_dialogue_act,
    assistant_has_question_mark,
    assistant_text,
    next_user_text,
    cell = case_when(
      rooted & request_followup ~ "rooted_request_followup",
      rooted & !request_followup ~ "rooted_no_request_followup",
      !rooted & request_followup ~ "nonrooted_request_followup",
      !rooted & !request_followup ~ "nonrooted_no_request_followup",
      TRUE ~ "unclassified"
    )
  ) %>%
  filter(cell != "unclassified") %>%
  group_by(cell) %>%
  group_modify(~ dplyr::slice_sample(.x, n = min(50, nrow(.x)))) %>%
  ungroup()

examples_counts <- examples_cells %>% count(cell, name = "n_sampled")

write_csv(request_followup_audit, "outputs/tables/request_followup_generic_audit.csv")
write_csv(models_no_q, "outputs/tables/milestone_models_excluding_assistant_questions.csv")
write_csv(overlap_summary, "outputs/tables/rooted_aspect_overlap.csv")
write_csv(fact_source_type_terms, "outputs/tables/fact_source_type_model_request_followup.csv")
write_csv(examples_cells, "outputs/reports/request_followup_cell_examples.csv")
write_csv(examples_counts, "outputs/tables/request_followup_cell_examples_counts.csv")

report_lines <- c(
  "# Milestone diagnostics",
  "",
  "## request-followup label audit",
  sprintf("- request_followup rows: %d", request_followup_audit$value[request_followup_audit$metric == "n_request_followup_rows"]),
  sprintf("- generic continuation only rows: %d", request_followup_audit$value[request_followup_audit$metric == "n_request_followup_generic_continuation_only"]),
  sprintf("- generic continuation only share: %.4f", request_followup_audit$value[request_followup_audit$metric == "pct_request_followup_generic_continuation_only"]),
  "",
  "## rooted vs aspect overlap",
  sprintf("- cor(any_rooted_fact, any_aspect_fact): %.4f", rooted_aspect_corr),
  sprintf("- phi(any_rooted_fact, any_aspect_fact): %.4f", phi),
  "",
  "## outputs",
  "- outputs/tables/milestone_models_excluding_assistant_questions.csv",
  "- outputs/tables/fact_source_type_model_request_followup.csv",
  "- outputs/reports/request_followup_cell_examples.csv"
)

writeLines(report_lines, "outputs/reports/milestone_diagnostics_summary.md")
message("Wrote milestone diagnostics outputs.")
