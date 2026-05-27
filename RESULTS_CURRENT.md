# Current Results

## Milestone 4 Main Finding

For `next_user_request_followup`, the anchored-novelty interaction is negative:

- Primary anchored model (`model3_anchored_only`): `prior_similarity_z:novelty_recent_z = -0.153` (OR `0.858`, `p = 0.00205`)
- With `fact_source_type` controls (`model4_anchored_plus_fact_source`): `-0.148` (OR `0.862`, `p = 0.00308`)

This pattern is directionally inconsistent with an "anchored novelty boost" interpretation.

## Robustness Snapshot

- Excluding assistant questions: interaction remains negative (`-0.178`, `p < 0.001`)
- Novelty-all variant: interaction remains negative (`-0.149`, `p = 0.0035`)
- Prior-mean variant: interaction remains negative (`-0.151`, `p = 0.0012`)
- MiniLM robustness model: interaction remains negative (`-0.143`, `p = 0.0026`)

## Where to Read Full Outputs

- `outputs/tables/anchored_novelty_model_results.csv`
- `outputs/tables/anchored_novelty_robustness_results.csv`
- `outputs/reports/anchored_novelty_analysis_memo.md`
