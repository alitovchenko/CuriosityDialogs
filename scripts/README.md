# Scripts Directory Guide

This directory contains all executable pipeline stages and support utilities.

## Core data access scripts

- `fetch_curiosity_dataset.py`: Downloads required Curiosity Dialogs splits from canonical media URLs and verifies hash/size.
- `verify_curiosity_dataset.py`: Verifies remote availability and local file integrity against the dataset manifest.

## Pipeline setup and shared utilities

- `00_setup.R`: Installs/validates required R packages for the analysis pipeline.
- `_pipeline_utils.R`: Shared helper functions used across scripts (directory creation, safe extraction, data loading, mapping helpers).

## Minimal milestone pipeline (implemented)

- `01_load_and_audit_data.R`: Loads all splits, inspects schema, writes dataset audit report and field inventory.
- `02_build_turn_pair_dataset.R`: Builds assistant-turn unit dataset with next-user outcomes and inclusion indicators.
- `03_construct_existing_label_outcomes.R`: Constructs existing-label outcomes and prior-turn engagement controls.
- `04_construct_text_features.R`: Adds text-derived controls (length, questions, heuristic entities, marker counts).
- `07_descriptive_tables.R`: Produces milestone descriptive tables (counts, prevalence, missingness, dialogue acts).
- `08_primary_existing_label_models.R`: Runs baseline no-annotation logistic models for key outcomes.
- `14_write_feasibility_memo.R`: Writes milestone feasibility memo from generated outputs.
- `99_run_minimal_milestone.R`: End-to-end runner for the minimal milestone scripts above.

## Diagnostics and robustness scripts (implemented)

- `15_milestone_diagnostics.R`: Runs request-followup mapping checks, no-question sensitivity models, rooted/aspect overlap checks, and 200-example sampling export.
- `16_request_followup_qualitative_audit.R`: Adds rule-based qualitative coding columns to sampled examples and writes qualitative audit markdown.
- `17_milestone3_within_dialogue_leadlag.R`: Runs within-dialogue FE, fact-source FE, lead-lag negative controls, and assistant-level robustness models.

## Planned later-stage scripts (placeholders)

- `05_compute_embeddings.py`: Placeholder for semantic embedding generation.
- `06_construct_semantic_predictors.R`: Placeholder for semantic predictor construction.
- `09_anchored_novelty_models.R`: Placeholder for anchored-novelty interaction modeling.
- `10_within_dialogue_models.R`: Placeholder for expanded within-dialogue robustness suite.
- `11_rule_based_deep_followup_proxy.R`: Placeholder for exploratory deep-followup proxy implementation.
- `12_figures.R`: Placeholder for full figure generation.
- `13_sensitivity_models.R`: Placeholder for broad sensitivity analyses.
