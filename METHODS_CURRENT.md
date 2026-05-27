# Current Methods

## Data and Feature Construction

- `scripts/06_construct_semantic_predictors.R` builds semantic text fields and merges embedding similarities into `data/processed/turn_pairs_with_semantic_predictors.csv`.
- Primary embeddings: `sentence-transformers/all-mpnet-base-v2`.
- Robustness embeddings: `sentence-transformers/all-MiniLM-L6-v2`.
- `renv` is not currently configured in this repository, so no `renv.lock` snapshot was produced for this run.

## Modeling

- Primary inferential models are fixed-effects logistic regressions in `scripts/09_anchored_novelty_models.R`.
- Target test: whether `prior_similarity_z * novelty_recent_z` predicts `next_user_request_followup` above controls and `fact_source_type`.
- Main outputs:
  - `outputs/tables/anchored_novelty_model_results.csv`
  - `outputs/tables/anchored_novelty_robustness_results.csv`

## Plotting Method (Important Difference)

- `scripts/12_figures.R` uses non-FE `glm` models for smooth prediction surfaces/lines.
- These plotting models are descriptive visualization models, not the primary FE inference models.
- Exact plotting inputs were saved for auditability:
  - `outputs/tables/anchored_novelty_plotting_grid_request_followup.csv`
  - `outputs/tables/anchored_novelty_plotting_grid_likes.csv`
- These files include `warning_flag` because prediction calls triggered rank-deficiency warnings.

## Current Interpretation

The anchored-novelty interaction in the primary FE request-followup models is negative, so current evidence does not support an anchored novelty boost mechanism.
