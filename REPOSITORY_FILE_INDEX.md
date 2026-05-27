# Repository File Index

This index explains the purpose of each tracked file category and points to folder-level READMEs that document file-level roles in detail.

## Root files

- `README.md`: Project overview, dataset access workflow, and milestone pipeline run instructions.
- `REPOSITORY_FILE_INDEX.md`: This top-level index and navigation guide.
- `requirements.txt`: Python dependencies used by embedding and utility scripts.
- `requirements-freeze-milestone4.txt`: Frozen Python environment snapshot for Milestone 4 reproduction.
- `session_info_milestone4.txt`: R `sessionInfo()` snapshot captured for Milestone 4.
- `MANIFEST.md`: Current manifest of critical Milestone 4 artifacts.
- `ANALYSIS_STATUS.md`: Current pipeline status and interpretation summary.
- `RESULTS_CURRENT.md`: Current headline coefficients/findings.
- `METHODS_CURRENT.md`: Method details for the currently executed pipeline.
- `METHODS_PLANNED.md`: Planned reproducibility and inference extensions.

## Folder-level file guides

- `scripts/README.md`: Explains every script in `scripts/`.
- `data/README.md`: Explains source data files, processed data, intermediates, and local package cache files.
- `outputs/README.md`: Explains every generated output file currently present.
- `docs/README.md`: Explains documentation artifacts.

## Data/source files

See `data/README.md` for the detailed descriptions of:

- `data/curiosity/manifest.json`
- `data/curiosity/v1/curiosity_dialogs.*.json`
- `data/processed/turn_pairs.csv`
- `data/interim/*`

## Generated analysis outputs

See `outputs/README.md` for the detailed descriptions of:

- `outputs/reports/*`
- `outputs/tables/*`
- `outputs/models/*`
- `outputs/figures/*`

Key Milestone 4 provenance/report files include:

- `outputs/reports/run_registry.csv`
- `outputs/reports/artifact_checksums_milestone4.csv`
- `outputs/reports/semantic_predictor_provenance.md`
- `outputs/reports/anchored_novelty_analysis_memo.md`

## Scripts

See `scripts/README.md` for detailed, script-by-script purpose descriptions, including:

- setup/utilities
- data audit and transformation scripts
- baseline models
- diagnostics and qualitative audit scripts
- Milestone 3 robustness scripts
- Milestone 4 embeddings, anchored-novelty models, and plotting-grid export
