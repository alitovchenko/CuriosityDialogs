# Manifest

This file tracks the main reproducibility artifacts for the current Milestone 4 state.

## Core Milestone 4 Data Artifacts

- `data/interim/embeddings/semantic_similarity_mpnet.csv`
- `data/interim/embeddings/semantic_similarity_minilm.csv`
- `data/interim/embeddings/mpnet/manifest.json`
- `data/interim/embeddings/minilm/manifest.json`
- `data/processed/turn_pairs_with_semantic_predictors.csv`

## Core Milestone 4 Result Artifacts

- `outputs/tables/anchored_novelty_model_results.csv`
- `outputs/tables/anchored_novelty_robustness_results.csv`
- `outputs/tables/semantic_predictor_coverage.csv`
- `outputs/reports/anchored_novelty_analysis_memo.md`

## Provenance and Audit Artifacts

- `outputs/reports/run_registry.csv`
- `outputs/reports/artifact_checksums_milestone4.csv`
- `outputs/reports/semantic_predictor_provenance.md`
- `requirements-freeze-milestone4.txt`
- `session_info_milestone4.txt`

## Plotting Inputs

- `outputs/tables/anchored_novelty_plotting_grid_request_followup.csv`
- `outputs/tables/anchored_novelty_plotting_grid_likes.csv`

## Interpretation Note

Current Milestone 4 evidence indicates a **negative** anchored-novelty interaction for request-followup (`prior_similarity_z:novelty_recent_z < 0`), which is not supportive of the original "anchored novelty boost" hypothesis.
