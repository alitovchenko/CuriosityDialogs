#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
})

source("scripts/_pipeline_utils.R")
ensure_dirs(c("outputs/figures", "outputs/tables"))

df <- read_csv("data/processed/turn_pairs_with_semantic_predictors.csv", show_col_types = FALSE) %>%
  filter(
    included_primary,
    !is.na(prior_similarity_z),
    !is.na(novelty_recent_z),
    !is.na(topic_similarity_z)
  ) %>%
  mutate(
    next_user_request_followup = as.integer(next_user_request_followup),
    assistant_liked_binary = as.integer(assistant_liked_binary),
    fact_source_type = factor(fact_source_type),
    assistant_has_question_mark = as.integer(assistant_has_question_mark),
    dialogue_turn_number = as.numeric(dialogue_turn_number),
    assistant_word_count = as.numeric(assistant_word_count),
    assistant_n_named_entities = as.numeric(assistant_n_named_entities),
    n_total_grounded_facts = as.numeric(n_total_grounded_facts),
    prior_user_request_followup_rate = as.numeric(prior_user_request_followup_rate),
    prior_assistant_like_rate = as.numeric(prior_assistant_like_rate)
  )

fit_plot_model <- function(outcome, data) {
  glm(
    as.formula(
      paste0(
        outcome,
        " ~ prior_similarity_z * novelty_recent_z + fact_source_type + topic_similarity_z + dialogue_turn_number + assistant_word_count + assistant_n_named_entities + assistant_has_question_mark + n_total_grounded_facts + prior_user_request_followup_rate + prior_assistant_like_rate"
      )
    ),
    family = binomial(),
    data = data
  )
}

predict_with_ci <- function(model, newdata) {
  warning_flag <- FALSE
  pred <- withCallingHandlers(
    predict(model, newdata = newdata, type = "link", se.fit = TRUE),
    warning = function(w) {
      warning_flag <<- TRUE
      invokeRestart("muffleWarning")
    }
  )
  tibble(
    predicted_probability = plogis(pred$fit),
    conf_low = plogis(pred$fit - 1.96 * pred$se.fit),
    conf_high = plogis(pred$fit + 1.96 * pred$se.fit),
    warning_flag = warning_flag
  )
}

base_vals <- df %>%
  summarise(
    fact_source_type = names(sort(table(fact_source_type), decreasing = TRUE))[1],
    topic_similarity_z = mean(topic_similarity_z, na.rm = TRUE),
    dialogue_turn_number = mean(dialogue_turn_number, na.rm = TRUE),
    assistant_word_count = mean(assistant_word_count, na.rm = TRUE),
    assistant_n_named_entities = mean(assistant_n_named_entities, na.rm = TRUE),
    assistant_has_question_mark = as.integer(round(mean(assistant_has_question_mark, na.rm = TRUE))),
    n_total_grounded_facts = mean(n_total_grounded_facts, na.rm = TRUE),
    prior_user_request_followup_rate = mean(prior_user_request_followup_rate, na.rm = TRUE),
    prior_assistant_like_rate = mean(prior_assistant_like_rate, na.rm = TRUE)
  )

base_source_type <- as.character(base_vals$fact_source_type[[1]])
request_plot_model <- fit_plot_model(
  "next_user_request_followup",
  df %>% filter(!is.na(next_user_request_followup))
)
likes_plot_model <- fit_plot_model(
  "assistant_liked_binary",
  df %>% filter(!is.na(assistant_liked_binary))
)

novelty_grid <- seq(-2, 2, length.out = 100)
prior_levels <- c(-1, 0, 1)
plot_df_request_followup <- expand.grid(
  novelty_recent_z = novelty_grid,
  prior_similarity_z = prior_levels
) %>%
  mutate(
    fact_source_type = factor(base_source_type, levels = levels(df$fact_source_type)),
    topic_similarity_z = base_vals$topic_similarity_z,
    dialogue_turn_number = base_vals$dialogue_turn_number,
    assistant_word_count = base_vals$assistant_word_count,
    assistant_n_named_entities = base_vals$assistant_n_named_entities,
    assistant_has_question_mark = base_vals$assistant_has_question_mark,
    n_total_grounded_facts = base_vals$n_total_grounded_facts,
    prior_user_request_followup_rate = base_vals$prior_user_request_followup_rate,
    prior_assistant_like_rate = base_vals$prior_assistant_like_rate
  ) %>%
  bind_cols(
    predict_with_ci(
      model = request_plot_model,
      newdata = .
    )
  ) %>%
  mutate(
    model_name = "glm_request_followup_non_fe",
    prior_label = factor(
      prior_similarity_z,
      levels = c(-1, 0, 1),
      labels = c("Low prior similarity (-1 SD)", "Mean prior similarity", "High prior similarity (+1 SD)")
    )
  )

p1 <- ggplot(plot_df_request_followup, aes(x = novelty_recent_z, y = predicted_probability, color = prior_label)) +
  geom_line(linewidth = 1.1) +
  labs(
    title = "Anchored Novelty Interaction and Follow-up Requests",
    x = "Novelty (z, recent context)",
    y = "Predicted P(next_user_request_followup)",
    color = "Prior similarity level"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  filename = "outputs/figures/anchored_novelty_interaction_request_followup.png",
  plot = p1,
  width = 9,
  height = 5.5,
  dpi = 180
)

write_csv(
  plot_df_request_followup %>%
    select(
      prior_similarity_z,
      novelty_recent_z,
      predicted_probability,
      conf_low,
      conf_high,
      model_name,
      warning_flag
    ),
  "outputs/tables/anchored_novelty_plotting_grid_request_followup.csv"
)

plot_df_likes <- expand.grid(
  novelty_recent_z = novelty_grid,
  prior_similarity_z = prior_levels
) %>%
  mutate(
    fact_source_type = factor(base_source_type, levels = levels(df$fact_source_type)),
    topic_similarity_z = base_vals$topic_similarity_z,
    dialogue_turn_number = base_vals$dialogue_turn_number,
    assistant_word_count = base_vals$assistant_word_count,
    assistant_n_named_entities = base_vals$assistant_n_named_entities,
    assistant_has_question_mark = base_vals$assistant_has_question_mark,
    n_total_grounded_facts = base_vals$n_total_grounded_facts,
    prior_user_request_followup_rate = base_vals$prior_user_request_followup_rate,
    prior_assistant_like_rate = base_vals$prior_assistant_like_rate
  ) %>%
  bind_cols(
    predict_with_ci(
      model = likes_plot_model,
      newdata = .
    )
  ) %>%
  mutate(model_name = "glm_assistant_liked_binary_non_fe")

write_csv(
  plot_df_likes %>%
    select(
      prior_similarity_z,
      novelty_recent_z,
      predicted_probability,
      conf_low,
      conf_high,
      model_name,
      warning_flag
    ),
  "outputs/tables/anchored_novelty_plotting_grid_likes.csv"
)

surface_df <- expand.grid(
  prior_similarity_z = seq(-2, 2, length.out = 80),
  novelty_recent_z = seq(-2, 2, length.out = 80)
) %>%
  mutate(
    fact_source_type = factor(base_source_type, levels = levels(df$fact_source_type)),
    topic_similarity_z = base_vals$topic_similarity_z,
    dialogue_turn_number = base_vals$dialogue_turn_number,
    assistant_word_count = base_vals$assistant_word_count,
    assistant_n_named_entities = base_vals$assistant_n_named_entities,
    assistant_has_question_mark = base_vals$assistant_has_question_mark,
    n_total_grounded_facts = base_vals$n_total_grounded_facts,
    prior_user_request_followup_rate = base_vals$prior_user_request_followup_rate,
    prior_assistant_like_rate = base_vals$prior_assistant_like_rate
  ) %>%
  bind_cols(
    predict_with_ci(
      model = request_plot_model,
      newdata = .
    )
  )

p2 <- ggplot(surface_df, aes(x = prior_similarity_z, y = novelty_recent_z, fill = predicted_probability)) +
  geom_tile() +
  scale_fill_viridis_c(option = "magma") +
  labs(
    title = "Anchored Novelty Surface: Predicted Follow-up Request Probability",
    x = "Prior similarity (z)",
    y = "Novelty (z, recent context)",
    fill = "Predicted probability"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  filename = "outputs/figures/anchored_novelty_surface_request_followup.png",
  plot = p2,
  width = 8.5,
  height = 6.5,
  dpi = 180
)

message("Wrote anchored novelty figures and plotting grids under outputs/")
