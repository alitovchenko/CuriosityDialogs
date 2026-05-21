#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

source("scripts/_pipeline_utils.R")

turn_pairs <- read_csv("data/processed/turn_pairs.csv", show_col_types = FALSE)

causal_markers <- c("because", "caused", "due to", "led to", "resulted in", "as a result", "therefore", "since")
comparison_markers <- c("compared", "similar", "different", "unlike", "more than", "less than", "whereas", "while", "in contrast")

count_markers <- function(text, markers) {
  txt <- tolower(text %||% "")
  sum(stringr::str_count(txt, fixed(markers)))
}

count_named_entities_heuristic <- function(text) {
  if (is.na(text) || trimws(text) == "") return(0L)
  # Heuristic fallback in milestone: count title-case tokens, excluding sentence starts.
  tokens <- str_split(text, "\\s+")[[1]]
  sum(str_detect(tokens, "^[A-Z][a-z]+$"))
}

turn_pairs <- turn_pairs %>%
  mutate(
    assistant_char_length = nchar(assistant_text %||% ""),
    assistant_word_count = str_count(assistant_text %||% "", "\\S+"),
    assistant_sentence_count = pmax(1L, str_count(assistant_text %||% "", "[.!?]+")),
    assistant_has_question_mark = as.integer(str_detect(assistant_text %||% "", fixed("?"))),
    assistant_n_question_marks = str_count(assistant_text %||% "", fixed("?")),
    assistant_n_numbers = str_count(assistant_text %||% "", "\\b\\d+(?:\\.\\d+)?\\b"),
    assistant_has_number = as.integer(assistant_n_numbers > 0),
    assistant_n_named_entities = vapply(assistant_text, count_named_entities_heuristic, integer(1)),
    assistant_readability_score = ifelse(
      assistant_word_count > 0,
      206.835 - 1.015 * (assistant_word_count / pmax(assistant_sentence_count, 1)) - 84.6 * ((assistant_char_length / pmax(assistant_word_count, 1)) / 5),
      NA_real_
    ),
    assistant_n_causal_markers = vapply(assistant_text, count_markers, integer(1), markers = causal_markers),
    assistant_n_comparison_markers = vapply(assistant_text, count_markers, integer(1), markers = comparison_markers)
  )

write_csv(turn_pairs, "data/processed/turn_pairs.csv")
message("Updated text-derived control variables in data/processed/turn_pairs.csv")
