# Outputs Directory Guide

This directory contains generated analysis artifacts: tables, reports, figures, and model objects.

## Reports (`outputs/reports`)

- `dataset_schema_audit.txt`: Schema introspection output (names, structure, field availability, unique labels).
- `no_annotation_analysis_memo.md`: Milestone feasibility memo summarizing baseline no-annotation findings.
- `milestone_diagnostics_summary.md`: Summary of diagnostics checks (followup mapping, no-question models, overlap checks).
- `request_followup_cell_examples.csv`: 200 sampled examples across rooted/non-rooted x followup/no-followup cells, with qualitative coding columns.
- `request_followup_qualitative_audit.md`: Rule-based qualitative audit focusing on rooted vs non-rooted follow-up composition.
- `milestone3_within_dialogue_leadlag_summary.md`: Summary of within-dialogue FE and lead-lag control results.

## Tables (`outputs/tables`)

- `dataset_field_inventory.csv`: Field-level inventory (type, examples, missingness, notes).
- `fact_source_mapping.csv`: Mapping from raw fact source labels to rooted/aspect/general categories.
- `dialogue_act_mapping.csv`: Mapping from dialogue acts to modeled outcome flags.
- `table_A_dataset_counts.csv`: Dataset-level count summary table.
- `table_B_outcome_prevalence.csv`: Outcome prevalence by fact-source type.
- `table_C_missingness.csv`: Key-variable missingness table.
- `table_D_dialogue_act_distribution.csv`: Dialogue act frequencies by role.
- `milestone_primary_models.csv`: Baseline no-annotation model coefficients.
- `request_followup_generic_audit.csv`: Audit counts for generic continuation within `request_followup` labels.
- `milestone_models_excluding_assistant_questions.csv`: Baseline models rerun excluding assistant-question turns.
- `rooted_aspect_overlap.csv`: Rooted/aspect overlap statistics.
- `fact_source_type_model_request_followup.csv`: Model of follow-up using categorical fact source.
- `request_followup_cell_examples_counts.csv`: Confirmatory sample counts for the 200-row qualitative sample.
- `request_followup_qualitative_summary_counts.csv`: Aggregated counts from qualitative coding columns.
- `milestone3_within_dialogue_leadlag_models.csv`: Full coefficient table for within-dialogue, lead-lag, and assistant-robust FE models.

## Models (`outputs/models`)

- `milestone_primary_models.rds`: Serialized baseline model output table object.
- `milestone3_within_dialogue_leadlag_models.rds`: Serialized `fixest` model objects for Milestone 3 controls.
- `.gitkeep`: Placeholder for empty models folder in fresh clones.

## Figures (`outputs/figures`)

- `.gitkeep`: Placeholder for future generated figures.
