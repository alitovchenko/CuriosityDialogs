# Semantic Predictor Provenance

This note defines the semantic variables used in Milestone 4 and documents how they were generated.

## Embedding Models

- Primary model: `sentence-transformers/all-mpnet-base-v2`
- Robustness model: `sentence-transformers/all-MiniLM-L6-v2`

Primary inference uses MPNet-derived predictors; MiniLM-derived predictors are used for robustness checks.

## Embedded Text Fields

The embedding pipeline encodes these text fields:

- `assistant_fact_text`
- `prior_knowledge_text`
- `previous_context_recent`
- `previous_context_all`
- `focus_entity_aspect_text`
- `known_entity_text` (from dialogue-level known entities)

## Variable Definitions

- `prior_similarity_max`:
  - For each assistant turn, compute cosine similarity between `assistant_fact_text` embedding and each available `known_entity_text` embedding from the same dialogue.
  - Keep the maximum similarity.

- `prior_similarity_mean`:
  - Same set of assistant-to-known-entity similarities as above.
  - Take the mean across all available known entities in that dialogue.

- `novelty_recent`:
  - Defined as `1 - context_similarity_recent`.
  - `context_similarity_recent` is the cosine similarity between `assistant_fact_text` and `previous_context_recent`.
  - Higher `novelty_recent` means lower semantic overlap with recent context.

- `novelty_all`:
  - Defined as `1 - context_similarity_all`.
  - `context_similarity_all` is the cosine similarity between `assistant_fact_text` and `previous_context_all`.
  - Higher `novelty_all` means lower overlap with full prior dialogue context.

## Missing Known-Entity Handling

- Known entities are extracted from dialogue metadata into `data/interim/dialogue_known_entities_long.csv`.
- If a dialogue has no usable `known_entities`, a fallback list from `focus_entity` is generated for coverage support.
- Even with fallback, many rows still lack usable assistant-to-known-entity pairings for `prior_similarity_*` because either:
  - the dialogue lacks a reliable known-entity list, or
  - there are no non-empty comparable known-entity strings for that row.

## Why 60,399 / 90,438 Rows Have Prior Similarity

Coverage in `outputs/tables/semantic_predictor_coverage.csv` shows:

- `rows_total = 90,438`
- `rows_with_prior_similarity_max = 60,399`

This is expected because `prior_similarity_*` requires dialogue-level known-entity embeddings. Rows without usable known-entity candidates cannot produce these scores and are left `NA`.

In contrast, context and topic similarities are row-local constructions and are available for all rows in this run.

## Source Scripts and Artifacts

- Feature construction: `scripts/06_construct_semantic_predictors.R`
- Embedding computation: `scripts/05_compute_embeddings.py`
- MPNet similarities: `data/interim/embeddings/semantic_similarity_mpnet.csv`
- MiniLM similarities: `data/interim/embeddings/semantic_similarity_minilm.csv`
- Final merged dataset: `data/processed/turn_pairs_with_semantic_predictors.csv`
