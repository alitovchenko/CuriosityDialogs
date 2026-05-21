#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(glue)
})

source("scripts/_pipeline_utils.R")

ensure_dirs(c("outputs/reports", "docs"))

turn_pairs <- read_csv("data/processed/turn_pairs.csv", show_col_types = FALSE)
counts <- read_csv("outputs/tables/table_A_dataset_counts.csv", show_col_types = FALSE)
models <- read_csv("outputs/tables/milestone_primary_models.csv", show_col_types = FALSE)

metric <- function(name) counts$value[counts$metric == name][1] %||% NA_real_
rooted_effect <- models %>%
  filter(term == "any_rooted_fact") %>%
  select(outcome, estimate, odds_ratio, p.value)

rooted_lines <- rooted_effect %>%
  mutate(
    line = glue("- `{outcome}`: log-odds={round(estimate, 3)}, OR={round(odds_ratio, 3)}, p={signif(p.value, 3)}")
  ) %>%
  pull(line)

memo <- c(
  "# No-Annotation Feasibility Memo (Milestone)",
  "",
  "## 1. Dataset viability",
  glue("- Usable assistant->user pairs (`included_primary`): **{metric('n_usable_assistant_user_turn_pairs')}**"),
  glue("- Assistant turns with grounding available: **{metric('n_assistant_turns_with_grounding')}**"),
  glue("- Rooted assistant turns: **{metric('n_rooted_assistant_turns')}**"),
  "Schema and field inventory were generated in `outputs/reports/dataset_schema_audit.txt` and `outputs/tables/dataset_field_inventory.csv`.",
  "",
  "## 2. Existing-label findings (milestone models)",
  "Rootedness (`any_rooted_fact`) effect estimates from baseline logit models:",
  rooted_lines,
  "",
  "## 3. Interpretation at this stage",
  "- This milestone establishes a reproducible assistant-turn pair dataset and baseline outcome signal checks.",
  "- Effects here are associative and preliminary; they do not support claims about subjective curiosity or causality.",
  "- Next required step is semantic anchored-novelty modeling (embeddings + interaction terms) and within-dialogue robustness.",
  "",
  "## 4. Recommendation",
  "Proceed to the next phase: implement semantic predictors and within-dialogue/negative-control analyses before deciding on full human annotation."
)

writeLines(memo, "outputs/reports/no_annotation_analysis_memo.md")
writeLines(memo, "docs/annotation_feasibility_memo.md")
message("Wrote feasibility memo to outputs/reports and docs/")
