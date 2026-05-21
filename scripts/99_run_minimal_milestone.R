#!/usr/bin/env Rscript

scripts <- c(
  "scripts/00_setup.R",
  "scripts/01_load_and_audit_data.R",
  "scripts/02_build_turn_pair_dataset.R",
  "scripts/03_construct_existing_label_outcomes.R",
  "scripts/04_construct_text_features.R",
  "scripts/07_descriptive_tables.R",
  "scripts/08_primary_existing_label_models.R",
  "scripts/14_write_feasibility_memo.R"
)

for (s in scripts) {
  message("Running ", s)
  status <- system2("Rscript", s)
  if (status != 0) {
    stop("Failed script: ", s)
  }
}

message("Minimal milestone completed.")
