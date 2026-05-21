# Data Directory Guide

This directory stores raw source files, processed datasets, and intermediate artifacts.

## Source dataset mirror

- `curiosity/manifest.json`: Canonical manifest with source URLs, expected sizes, and SHA256 checksums.
- `curiosity/v1/curiosity_dialogs.train.json`: Training split from Curiosity Dialogs.
- `curiosity/v1/curiosity_dialogs.val.json`: Validation split from Curiosity Dialogs.
- `curiosity/v1/curiosity_dialogs.test.json`: Test split from Curiosity Dialogs.
- `curiosity/v1/curiosity_dialogs.test_zero.json`: Zero-shot test split from Curiosity Dialogs.

## Processed analysis dataset

- `processed/turn_pairs.csv`: Assistant-turn unit dataset used for milestone modeling and audits.

## Intermediate artifacts

- `interim/dialogs_all_splits.rds`: R serialized combined split object used to speed downstream script stages.

## Local R package cache (tooling dependency)

The `interim/Rlibs/` subtree contains locally installed CRAN package binaries and package files used to run fixed-effects models without requiring system-level package installs.

Installed package subtrees currently include:

- `interim/Rlibs/fixest/*`: `fixest` package runtime, docs, and native library files.
- `interim/Rlibs/dreamerr/*`: `dreamerr` package files (dependency of `fixest`).
- `interim/Rlibs/stringmagic/*`: `stringmagic` package files (dependency of `fixest`).

These files are generated dependency artifacts, not primary study data.

## Scaffold directories

- `raw/.gitkeep`: Placeholder to preserve empty raw directory scaffold.
- `external/.gitkeep`: Placeholder to preserve empty external-data directory scaffold.
