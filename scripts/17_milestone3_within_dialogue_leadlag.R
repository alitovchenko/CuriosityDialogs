#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(broom)
  library(glue)
})

source("scripts/_pipeline_utils.R")

ensure_dirs(c("outputs/tables", "outputs/reports", "outputs/models"))

local_rlib <- "data/interim/Rlibs"
ensure_dirs(local_rlib)
.libPaths(c(normalizePath(local_rlib), .libPaths()))

if (!requireNamespace("fixest", quietly = TRUE)) {
  install.packages("fixest", repos = "https://cloud.r-project.org", lib = normalizePath(local_rlib))
}
library(fixest)

df <- read_csv("data/processed/turn_pairs.csv", show_col_types = FALSE) %>%
  filter(included_primary) %>%
  mutate(
    any_rooted_fact = as.integer(any_rooted_fact),
    any_aspect_fact = as.integer(any_aspect_fact),
    any_general_fact = as.integer(any_general_fact),
    assistant_word_count = as.numeric(assistant_word_count),
    assistant_n_named_entities = as.numeric(assistant_n_named_entities),
    dialogue_turn_number = as.numeric(dialogue_turn_number),
    prior_assistant_like_rate = as.numeric(prior_assistant_like_rate),
    prior_user_info_seeking_rate = as.numeric(prior_user_info_seeking_rate),
    fact_source_type = factor(fact_source_type),
    next_user_request_followup = as.integer(next_user_request_followup),
    previous_user_request_followup = as.integer(previous_user_request_followup)
  )

base_controls <- ~ assistant_word_count + assistant_n_named_entities + dialogue_turn_number +
  prior_assistant_like_rate + prior_user_info_seeking_rate

models <- list()

# 1) Within-dialogue fixed effects (binary rootedness)
models[["within_dialogue_rooted"]] <- feglm(
  fml = as.formula(
    "next_user_request_followup ~ any_rooted_fact + any_aspect_fact + any_general_fact + assistant_word_count + assistant_n_named_entities + dialogue_turn_number + prior_assistant_like_rate + prior_user_info_seeking_rate | dialogue_id"
  ),
  family = "binomial",
  data = df,
  vcov = ~dialogue_id
)

# 2) Fact-source categorical within-dialogue FE
models[["within_dialogue_fact_source_type"]] <- feglm(
  fml = as.formula(
    "next_user_request_followup ~ i(fact_source_type, ref = 'aspect_only') + assistant_word_count + assistant_n_named_entities + dialogue_turn_number + prior_assistant_like_rate + prior_user_info_seeking_rate | dialogue_id"
  ),
  family = "binomial",
  data = df,
  vcov = ~dialogue_id
)

# 3) Lead-lag negative controls
leadlag_df <- df %>% filter(!is.na(previous_user_request_followup), !is.na(next_user_request_followup))

models[["leadlag_previous_outcome"]] <- feglm(
  fml = as.formula(
    "previous_user_request_followup ~ any_rooted_fact + any_aspect_fact + any_general_fact + assistant_word_count + assistant_n_named_entities + dialogue_turn_number + prior_assistant_like_rate + prior_user_info_seeking_rate | dialogue_id"
  ),
  family = "binomial",
  data = leadlag_df,
  vcov = ~dialogue_id
)

models[["leadlag_next_outcome"]] <- feglm(
  fml = as.formula(
    "next_user_request_followup ~ any_rooted_fact + any_aspect_fact + any_general_fact + assistant_word_count + assistant_n_named_entities + dialogue_turn_number + prior_assistant_like_rate + prior_user_info_seeking_rate | dialogue_id"
  ),
  family = "binomial",
  data = leadlag_df,
  vcov = ~dialogue_id
)

# 4) Assistant-level robustness: dialogue FE + assistant FE and two-way clustering
models[["assistant_robust_two_fe"]] <- feglm(
  fml = as.formula(
    "next_user_request_followup ~ any_rooted_fact + any_aspect_fact + any_general_fact + assistant_word_count + assistant_n_named_entities + dialogue_turn_number + prior_assistant_like_rate + prior_user_info_seeking_rate | dialogue_id + assistant_id"
  ),
  family = "binomial",
  data = df,
  vcov = ~dialogue_id + assistant_id
)

tidy_fixest <- function(model_name, model_obj) {
  tt <- broom::tidy(model_obj, conf.int = TRUE)
  nn <- nobs(model_obj)
  tt %>%
    mutate(
      model = model_name,
      N = nn,
      odds_ratio = exp(estimate),
      conf_low_or = exp(conf.low),
      conf_high_or = exp(conf.high)
    )
}

results <- bind_rows(
  lapply(names(models), function(nm) tidy_fixest(nm, models[[nm]]))
)

write_csv(results, "outputs/tables/milestone3_within_dialogue_leadlag_models.csv")
saveRDS(models, "outputs/models/milestone3_within_dialogue_leadlag_models.rds")

rooted_rows <- results %>%
  filter(term == "any_rooted_fact") %>%
  select(model, estimate, std.error, p.value, odds_ratio, conf_low_or, conf_high_or)

lead <- rooted_rows %>% filter(model == "leadlag_next_outcome")
lag <- rooted_rows %>% filter(model == "leadlag_previous_outcome")

report_lines <- c(
  "# Milestone 3: Within-dialogue and lead-lag controls",
  "",
  "## Models run",
  "- within_dialogue_rooted: `next_user_request_followup ~ any_rooted_fact + controls | dialogue_id`",
  "- within_dialogue_fact_source_type: `next_user_request_followup ~ fact_source_type + controls | dialogue_id`",
  "- leadlag_previous_outcome: `previous_user_request_followup ~ current any_rooted_fact + controls | dialogue_id`",
  "- leadlag_next_outcome: `next_user_request_followup ~ current any_rooted_fact + controls | dialogue_id`",
  "- assistant_robust_two_fe: `next_user_request_followup ~ any_rooted_fact + controls | dialogue_id + assistant_id` with two-way clustered SEs",
  "",
  "## Rootedness coefficient snapshots",
  paste(
    apply(rooted_rows, 1, function(r) {
      glue("- {r[['model']]}: log-odds={sprintf('%.3f', as.numeric(r[['estimate']]))}, OR={sprintf('%.3f', as.numeric(r[['odds_ratio']]))}, p={signif(as.numeric(r[['p.value']]), 3)}")
    }),
    collapse = "\n"
  ),
  "",
  "## Lead-lag specificity check",
  if (nrow(lead) == 1 && nrow(lag) == 1) {
    glue("- Next-turn rootedness effect OR={sprintf('%.3f', lead$odds_ratio)} vs Previous-turn OR={sprintf('%.3f', lag$odds_ratio)}")
  } else {
    "- Could not compute lead-lag rootedness comparison from model table."
  },
  "",
  "Full coefficient table: `outputs/tables/milestone3_within_dialogue_leadlag_models.csv`"
)

writeLines(report_lines, "outputs/reports/milestone3_within_dialogue_leadlag_summary.md")
message("Wrote milestone 3 model outputs and summary.")
