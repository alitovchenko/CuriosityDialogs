# Curiosity Dialogs Access Toolkit

This repository provides a stable access workflow for the Curiosity Dialogs dataset.

## Why this exists

- The Hugging Face dataset loader script references `obj.umiacs.umd.edu`, which can return `403`.
- This toolkit uses GitHub media URLs as the canonical upstream and mirrors files locally.
- All local files are verified with pinned `size_bytes` and `sha256` values.

## Canonical source and local layout

- Canonical source base URL:
  - `https://media.githubusercontent.com/media/facebookresearch/curiosity/main/dialog_data`
- Manifest:
  - `data/curiosity/manifest.json`
- Default local mirror root:
  - `data/curiosity/v1`
- Override local mirror root with:
  - `CURIOSITY_DATA_DIR=/your/path`

## Download dataset files

Required split files only:

```bash
python3 scripts/fetch_curiosity_dataset.py
```

Include optional auxiliary files:

```bash
python3 scripts/fetch_curiosity_dataset.py --include-optional
```

Force re-download:

```bash
python3 scripts/fetch_curiosity_dataset.py --force
```

## Verify access and integrity

Verify remote reachability + local mirror integrity for required files:

```bash
python3 scripts/verify_curiosity_dataset.py
```

Verify all files (including optional):

```bash
python3 scripts/verify_curiosity_dataset.py --include-optional
```

Remote-only health check:

```bash
python3 scripts/verify_curiosity_dataset.py --skip-local
```

Local-only integrity check:

```bash
python3 scripts/verify_curiosity_dataset.py --skip-remote
```

## Suggested operational cadence

- Run downloader once to populate local mirror.
- Run verifier before training/evaluation jobs.
- Optionally run remote-only verification on a schedule (CI or cron) to detect upstream drift.

## Anchored-novelty analysis pipeline (milestone)

This repository now includes a reproducible first milestone for the Curiosity Dialogs
anchored-novelty analysis.

### Run the minimal milestone

```bash
Rscript scripts/99_run_minimal_milestone.R
```

### Milestone outputs

- `outputs/reports/dataset_schema_audit.txt`
- `outputs/tables/dataset_field_inventory.csv`
- `data/processed/turn_pairs.csv`
- `outputs/tables/dialogue_act_mapping.csv`
- `outputs/tables/table_A_dataset_counts.csv`
- `outputs/tables/table_B_outcome_prevalence.csv`
- `outputs/tables/table_C_missingness.csv`
- `outputs/tables/table_D_dialogue_act_distribution.csv`
- `outputs/tables/milestone_primary_models.csv`
- `outputs/reports/no_annotation_analysis_memo.md`

### Script stages

- `scripts/00_setup.R` package setup
- `scripts/01_load_and_audit_data.R` schema audit
- `scripts/02_build_turn_pair_dataset.R` assistant→user turn pairs
- `scripts/03_construct_existing_label_outcomes.R` no-annotation outcomes
- `scripts/04_construct_text_features.R` text controls
- `scripts/07_descriptive_tables.R` core descriptive tables
- `scripts/08_primary_existing_label_models.R` baseline rootedness models

## Repository documentation map

- `REPOSITORY_FILE_INDEX.md` top-level file index
- `scripts/README.md` script-by-script reference
- `data/README.md` data and intermediate file guide
- `outputs/README.md` output artifact guide
- `docs/README.md` documentation artifact guide
