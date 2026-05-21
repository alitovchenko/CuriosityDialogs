# Repository File Index

This index explains the purpose of each tracked file category and points to folder-level READMEs that document file-level roles in detail.

## Root files

- `README.md`: Project overview, dataset access workflow, and milestone pipeline run instructions.
- `REPOSITORY_FILE_INDEX.md`: This top-level index and navigation guide.
- `requirements.txt`: Python dependencies used by embedding and utility scripts.

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

## Scripts

See `scripts/README.md` for detailed, script-by-script purpose descriptions, including:

- setup/utilities
- data audit and transformation scripts
- baseline models
- diagnostics and qualitative audit scripts
- Milestone 3 robustness scripts
- later-stage placeholders
