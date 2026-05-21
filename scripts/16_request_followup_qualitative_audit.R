#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
  library(glue)
})

source("scripts/_pipeline_utils.R")

ensure_dirs(c("outputs/reports", "outputs/tables"))

sample_path <- "outputs/reports/request_followup_cell_examples.csv"
df <- read_csv(sample_path, show_col_types = FALSE)

generic_re <- regex(
  "^(tell me more|what else|continue|go on|more|interesting|cool|okay|ok|thanks|great|nice|wow|tell me more please|anything else)$",
  ignore_case = TRUE
)

question_starter_re <- regex(
  "^(what|why|how|when|where|who|which|is|are|was|were|do|does|did|can|could|would|will|have|has|had)\\b",
  ignore_case = TRUE
)

explanatory_re <- regex(
  "\\b(why|how did|how does|how could|what caused|what led|reason|because|effect|impact|influence|cause)\\b",
  ignore_case = TRUE
)

comparative_re <- regex(
  "\\b(compare|compared|similar|different|difference|same as|more than|less than|unlike|relative to|than)\\b",
  ignore_case = TRUE
)

evaluative_re <- regex(
  "\\b(important|significant|unusual|rare|common|typical|surprising|notable|famous|known for|matter|better|worse)\\b",
  ignore_case = TRUE
)

narrative_re <- regex(
  "\\b(what happened next|after that|before that|when did|then what|history|origin|began|ended|later on|after|before)\\b",
  ignore_case = TRUE
)

branching_re <- regex(
  "\\b(what about|how about|any information on|tell me about|do you have.*about|regarding|related to)\\b",
  ignore_case = TRUE
)

aspect_terms_re <- regex(
  "\\b(history|geography|culture|politics|government|economy|education|demographics|religion|transport|media|tourism|sports|environment|etymology)\\b",
  ignore_case = TRUE
)

code_specificity <- function(text) {
  txt <- str_squish(str_to_lower(coalesce(text, "")))
  if (txt == "") return(8L)

  has_q <- str_detect(txt, "\\?") || str_detect(txt, question_starter_re)
  has_generic <- str_detect(txt, generic_re) ||
    str_detect(txt, "\\b(anything else|more info|more information|tell me more)\\b")

  if (!has_q && !str_detect(txt, "\\b(tell me|can you|could you|do you have|what about|how about)\\b")) {
    return(0L)
  }
  if (has_generic && !str_detect(txt, explanatory_re) && !str_detect(txt, comparative_re) &&
      !str_detect(txt, evaluative_re) && !str_detect(txt, narrative_re) && !str_detect(txt, branching_re)) {
    return(1L)
  }
  if (str_detect(txt, explanatory_re)) return(3L)
  if (str_detect(txt, comparative_re)) return(4L)
  if (str_detect(txt, evaluative_re)) return(5L)
  if (str_detect(txt, narrative_re)) return(6L)
  if (str_detect(txt, branching_re) || str_detect(txt, aspect_terms_re)) return(7L)
  if (has_q) return(2L)
  8L
}

depth_from_specificity <- function(spec) {
  if (spec == 0L) return(0L)
  if (spec == 1L) return(1L)
  if (spec %in% c(2L, 7L)) return(2L)
  if (spec %in% c(3L, 4L, 5L, 6L)) return(3L)
  1L
}

label_validity <- function(labeled_followup, specificity) {
  if (is.na(labeled_followup)) return("ambiguous")
  if (specificity == 8L) return("ambiguous")
  if (isTRUE(labeled_followup) && specificity == 0L) return("overinclusive")
  if (!isTRUE(labeled_followup) && specificity >= 2L) return("underinclusive")
  "valid"
}

spec_labels <- c(
  "0 no-followup",
  "1 generic-continuation",
  "2 specific-factual-followup",
  "3 explanatory-causal-followup",
  "4 comparative-relational-followup",
  "5 evaluative-significance-followup",
  "6 narrative-temporal-followup",
  "7 branching-related-entity-aspect",
  "8 ambiguous-unclear"
)

depth_labels <- c(
  "0 no-curiosity-signal",
  "1 shallow-engagement",
  "2 specific-information-seeking",
  "3 integrative-deep-curiosity"
)

df_coded <- df %>%
  mutate(
    qual_followup_specificity = vapply(next_user_text, code_specificity, integer(1)),
    qual_curiosity_depth = vapply(qual_followup_specificity, depth_from_specificity, integer(1)),
    qual_label_validity = mapply(label_validity, request_followup, qual_followup_specificity),
    qual_notes = case_when(
      qual_followup_specificity == 1L ~ "Auto-coded as generic continuation wording.",
      qual_followup_specificity == 3L ~ "Auto-coded as explanatory/causal question.",
      qual_followup_specificity == 4L ~ "Auto-coded as comparative/relational question.",
      qual_followup_specificity == 5L ~ "Auto-coded as evaluative/significance question.",
      qual_followup_specificity == 6L ~ "Auto-coded as narrative/temporal question.",
      qual_followup_specificity == 7L ~ "Auto-coded as branching to related entity/aspect.",
      qual_followup_specificity == 2L ~ "Auto-coded as specific factual follow-up.",
      qual_followup_specificity == 0L ~ "No clear follow-up request in text.",
      TRUE ~ "Ambiguous wording."
    )
  )

write_csv(df_coded, sample_path)

summary_specificity <- df_coded %>%
  mutate(
    specificity_label = factor(spec_labels[qual_followup_specificity + 1], levels = spec_labels),
    depth_label = factor(depth_labels[qual_curiosity_depth + 1], levels = depth_labels)
  ) %>%
  count(cell, specificity_label, depth_label, qual_label_validity, sort = TRUE)

write_csv(summary_specificity, "outputs/tables/request_followup_qualitative_summary_counts.csv")

focused_compare <- df_coded %>%
  filter(cell %in% c("rooted_request_followup", "nonrooted_request_followup")) %>%
  mutate(
    specificity_label = spec_labels[qual_followup_specificity + 1],
    depth_label = depth_labels[qual_curiosity_depth + 1]
  )

focused_spec <- focused_compare %>%
  count(cell, specificity_label) %>%
  group_by(cell) %>%
  mutate(pct = n / sum(n)) %>%
  ungroup()

focused_depth <- focused_compare %>%
  count(cell, depth_label) %>%
  group_by(cell) %>%
  mutate(pct = n / sum(n)) %>%
  ungroup()

validity_tab <- df_coded %>%
  count(cell, qual_label_validity) %>%
  group_by(cell) %>%
  mutate(pct = n / sum(n)) %>%
  ungroup()

render_lines <- c(
  "# Request-Followup Qualitative Audit",
  "",
  "This audit uses transparent rule-based coding on the 200-row balanced sample in `outputs/reports/request_followup_cell_examples.csv`.",
  "New columns added: `qual_followup_specificity`, `qual_curiosity_depth`, `qual_label_validity`, `qual_notes`.",
  "",
  "## Coding scheme",
  "- Follow-up specificity: 0-8 per requested rubric.",
  "- Curiosity depth: 0-3 per requested rubric.",
  "- Label validity: valid / overinclusive / underinclusive / ambiguous.",
  "",
  "## Focused comparison: rooted request-followup vs nonrooted request-followup",
  ""
)

for (rw in seq_len(nrow(focused_spec))) {
  row <- focused_spec[rw, ]
  render_lines <- c(
    render_lines,
    glue("- {row$cell}: {row$specificity_label} -> n={row$n} ({sprintf('%.1f', 100 * row$pct)}%)")
  )
}

render_lines <- c(render_lines, "", "### Curiosity depth distribution", "")
for (rw in seq_len(nrow(focused_depth))) {
  row <- focused_depth[rw, ]
  render_lines <- c(
    render_lines,
    glue("- {row$cell}: {row$depth_label} -> n={row$n} ({sprintf('%.1f', 100 * row$pct)}%)")
  )
}

render_lines <- c(render_lines, "", "### Label validity distribution", "")
for (rw in seq_len(nrow(validity_tab))) {
  row <- validity_tab[rw, ]
  render_lines <- c(
    render_lines,
    glue("- {row$cell}: {row$qual_label_validity} -> n={row$n} ({sprintf('%.1f', 100 * row$pct)}%)")
  )
}

render_lines <- c(
  render_lines,
  "",
  "## Interpretation",
  "- Compare rooted vs nonrooted request-followup rows using specificity/depth mix rather than just follow-up rate.",
  "- If rooted rows shift toward categories 3/4/5/6 or depth=3, that supports deeper curiosity coding feasibility.",
  "- If both look similar and mostly category 1/2, framing should stay on follow-up likelihood rather than depth.",
  "",
  "## Notes",
  "- This is a rule-based pre-audit, not final human annotation.",
  "- Use this file to prioritize rows for manual adjudication."
)

writeLines(render_lines, "outputs/reports/request_followup_qualitative_audit.md")
message("Wrote qualitative coding columns and audit report.")
