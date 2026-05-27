# Planned Methods

## Reproducibility and Audit Extensions

- Run a clean-environment Milestone 4 replay (fresh workspace, rebuild embeddings, rerun scripts `06`, `09`, `12`).
- Compare replay checksums against `outputs/reports/artifact_checksums_milestone4.csv`.
- If replay differs, isolate whether drift comes from package versions, model cache state, or random ordering.

## Inference Extensions

- Add tighter controls for dialogue-stage effects and potential post-treatment variables.
- Evaluate alternative follow-up outcomes after manual label adjudication.
- Quantify calibration between dialogue-act labels and manual depth/specificity coding.

## Annotation Plan Trigger

- If manual adjudication confirms high label validity and meaningful depth variation, proceed to pilot/full human annotation.
- Given current negative interaction results, prioritize annotation designs that test competing mechanisms beyond "anchored novelty boost."
