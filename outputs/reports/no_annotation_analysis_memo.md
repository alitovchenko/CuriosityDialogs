# No-Annotation Feasibility Memo (Milestone)

## 1. Dataset viability
- Usable assistant->user pairs (`included_primary`): **76567**
- Assistant turns with grounding available: **90438**
- Rooted assistant turns: **10438**
Schema and field inventory were generated in `outputs/reports/dataset_schema_audit.txt` and `outputs/tables/dataset_field_inventory.csv`.

## 2. Existing-label findings (milestone models)
Rootedness (`any_rooted_fact`) effect estimates from baseline logit models:
- `assistant_liked_binary`: log-odds=0.681, OR=1.976, p=3.48e-84
- `next_user_info_seeking`: log-odds=0.367, OR=1.444, p=2.06e-17
- `next_user_request_followup`: log-odds=0.652, OR=1.919, p=1.12e-38
- `dialogue_survival_2`: log-odds=0.155, OR=1.168, p=0.000767

## 3. Interpretation at this stage
- This milestone establishes a reproducible assistant-turn pair dataset and baseline outcome signal checks.
- Effects here are associative and preliminary; they do not support claims about subjective curiosity or causality.
- Next required step is semantic anchored-novelty modeling (embeddings + interaction terms) and within-dialogue robustness.

## 4. Recommendation
Proceed to the next phase: implement semantic predictors and within-dialogue/negative-control analyses before deciding on full human annotation.
