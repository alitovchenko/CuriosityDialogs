# Analysis Status

## Current Phase

- Milestone 4 (embeddings + anchored-novelty models) is completed.
- Provenance hardening is completed for this run (registry, checksums, env snapshots, semantic-variable documentation, plotting grids).

## Current Conclusion

- The anchored-novelty interaction for `next_user_request_followup` is negative in the primary FE model and most robustness checks.
- This does **not** support the original "anchored novelty boost" hypothesis.

## Completed Provenance Items

- Added `outputs/reports/run_registry.csv`.
- Added `outputs/reports/artifact_checksums_milestone4.csv`.
- Added `outputs/reports/semantic_predictor_provenance.md`.
- Added `requirements-freeze-milestone4.txt` and `session_info_milestone4.txt`.
- Added `outputs/tables/anchored_novelty_plotting_grid_request_followup.csv` and `outputs/tables/anchored_novelty_plotting_grid_likes.csv`.

## Open Follow-ups

- Optional clean-environment replay drill for end-to-end Milestone 4 rerun.
- Optional human annotation pilot focused on follow-up specificity/depth given the negative interaction result.
