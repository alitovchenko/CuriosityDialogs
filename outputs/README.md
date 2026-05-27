# Outputs Directory Guide

This directory stores generated artifacts used to reproduce the Curiosity Dialogs analysis pipeline.

## Milestone 4 Result Status

Milestone 4 tests do **not** support an "anchored novelty boost" for `next_user_request_followup`.
The key interaction (`prior_similarity_z:novelty_recent_z`) is negative in the primary FE model and most robustness checks.

## Reports (`outputs/reports`)

- `anchored_novelty_analysis_memo.md`: Narrative summary of Milestone 4 coefficients and robustness findings.
- `artifact_checksums_milestone4.csv`: SHA256, byte size, and modified time for major Milestone 4 artifacts.
- `run_registry.csv`: One-row-per-run audit log with command, git state, row counts, env versions, and status.
- `semantic_predictor_provenance.md`: Definitions and derivation details for semantic predictors.
- `dataset_schema_audit.txt`: Raw schema introspection from early pipeline stage.
- `no_annotation_analysis_memo.md`: Baseline pre-embedding milestone memo.
- `milestone_diagnostics_summary.md`: Diagnostics for follow-up labels and rooted/aspect overlap.
- `request_followup_qualitative_audit.md`: Rule-based qualitative audit of follow-up specificity/depth.
- `milestone3_within_dialogue_leadlag_summary.md`: Within-dialogue/lead-lag robustness summary.

## Tables (`outputs/tables`)

- `anchored_novelty_model_results.csv`: Primary FE models for Milestone 4.
- `anchored_novelty_robustness_results.csv`: Robustness and secondary-outcome Milestone 4 models.
- `semantic_predictor_coverage.csv`: Coverage counts for embedding-derived variables (`rows_total=90438`, `rows_with_prior_similarity_max=60399`).
- `anchored_novelty_plotting_grid_request_followup.csv`: Exact prediction grid used for request-followup interaction plotting (includes `warning_flag` and CI).
- `anchored_novelty_plotting_grid_likes.csv`: Matching prediction grid for assistant likes.
- `dataset_field_inventory.csv`: Field-level inventory (type, examples, missingness, notes).
- `fact_source_mapping.csv`: Mapping from raw fact source labels to rooted/aspect/general categories.
- `dialogue_act_mapping.csv`: Mapping from dialogue acts to modeled outcome flags.
- `table_A_dataset_counts.csv`: Dataset-level count summary.
- `table_B_outcome_prevalence.csv`: Outcome prevalence by fact-source type.
- `table_C_missingness.csv`: Key-variable missingness summary.
- `table_D_dialogue_act_distribution.csv`: Dialogue act frequencies by role.
- `milestone_primary_models.csv`: Baseline no-annotation model coefficients.
- `request_followup_generic_audit.csv`: Generic-continuation audit among `request_followup`.
- `milestone_models_excluding_assistant_questions.csv`: Baseline models excluding assistant-question turns.
- `rooted_aspect_overlap.csv`: Rooted/aspect overlap statistics.
- `fact_source_type_model_request_followup.csv`: Follow-up model using categorical fact source.
- `request_followup_cell_examples_counts.csv`: Cell counts for qualitative sample construction.
- `request_followup_qualitative_summary_counts.csv`: Aggregated qualitative coding counts.
- `milestone3_within_dialogue_leadlag_models.csv`: Milestone 3 FE/lead-lag coefficient table.

## Models (`outputs/models`)

- `anchored_novelty_models.rds`: Serialized Milestone 4 `fixest` model objects.
- `milestone_primary_models.rds`: Serialized baseline milestone model object.
- `milestone3_within_dialogue_leadlag_models.rds`: Serialized Milestone 3 `fixest` model objects.

## Figures (`outputs/figures`)

- `anchored_novelty_interaction_request_followup.png`: Interaction plot from non-FE GLM prediction surface.
- `anchored_novelty_surface_request_followup.png`: 2D probability surface from non-FE GLM.
