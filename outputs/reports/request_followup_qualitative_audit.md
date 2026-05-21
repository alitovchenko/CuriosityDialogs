# Request-Followup Qualitative Audit

This audit uses transparent rule-based coding on the 200-row balanced sample in `outputs/reports/request_followup_cell_examples.csv`.
New columns added: `qual_followup_specificity`, `qual_curiosity_depth`, `qual_label_validity`, `qual_notes`.

## Coding scheme
- Follow-up specificity: 0-8 per requested rubric.
- Curiosity depth: 0-3 per requested rubric.
- Label validity: valid / overinclusive / underinclusive / ambiguous.

## Focused comparison: rooted request-followup vs nonrooted request-followup

- nonrooted_request_followup: 1 generic-continuation -> n=6 (12.0%)
- nonrooted_request_followup: 2 specific-factual-followup -> n=25 (50.0%)
- nonrooted_request_followup: 3 explanatory-causal-followup -> n=3 (6.0%)
- nonrooted_request_followup: 5 evaluative-significance-followup -> n=1 (2.0%)
- nonrooted_request_followup: 6 narrative-temporal-followup -> n=4 (8.0%)
- nonrooted_request_followup: 7 branching-related-entity-aspect -> n=11 (22.0%)
- rooted_request_followup: 0 no-followup -> n=1 (2.0%)
- rooted_request_followup: 1 generic-continuation -> n=5 (10.0%)
- rooted_request_followup: 2 specific-factual-followup -> n=29 (58.0%)
- rooted_request_followup: 3 explanatory-causal-followup -> n=5 (10.0%)
- rooted_request_followup: 4 comparative-relational-followup -> n=2 (4.0%)
- rooted_request_followup: 5 evaluative-significance-followup -> n=1 (2.0%)
- rooted_request_followup: 7 branching-related-entity-aspect -> n=7 (14.0%)

### Curiosity depth distribution

- nonrooted_request_followup: 1 shallow-engagement -> n=6 (12.0%)
- nonrooted_request_followup: 2 specific-information-seeking -> n=36 (72.0%)
- nonrooted_request_followup: 3 integrative-deep-curiosity -> n=8 (16.0%)
- rooted_request_followup: 0 no-curiosity-signal -> n=1 (2.0%)
- rooted_request_followup: 1 shallow-engagement -> n=5 (10.0%)
- rooted_request_followup: 2 specific-information-seeking -> n=36 (72.0%)
- rooted_request_followup: 3 integrative-deep-curiosity -> n=8 (16.0%)

### Label validity distribution

- nonrooted_no_request_followup: underinclusive -> n=36 (72.0%)
- nonrooted_no_request_followup: valid -> n=14 (28.0%)
- nonrooted_request_followup: valid -> n=50 (100.0%)
- rooted_no_request_followup: underinclusive -> n=36 (72.0%)
- rooted_no_request_followup: valid -> n=14 (28.0%)
- rooted_request_followup: overinclusive -> n=1 (2.0%)
- rooted_request_followup: valid -> n=49 (98.0%)

## Interpretation
- Compare rooted vs nonrooted request-followup rows using specificity/depth mix rather than just follow-up rate.
- If rooted rows shift toward categories 3/4/5/6 or depth=3, that supports deeper curiosity coding feasibility.
- If both look similar and mostly category 1/2, framing should stay on follow-up likelihood rather than depth.

## Notes
- This is a rule-based pre-audit, not final human annotation.
- Use this file to prioritize rows for manual adjudication.
