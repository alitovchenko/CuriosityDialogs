# Turn-Pair Dataset Codebook

Primary file: `data/processed/turn_pairs.csv`

Unit of analysis: one assistant turn (`t`) with outcomes from the next user turn (`t + 1`).

## Key identifiers
- `dialogue_id`
- `assistant_turn_id`
- `assistant_turn_index`
- `user_next_turn_id`
- `user_next_turn_index`

## Dialogue context
- `focus_entity`
- `aspects`
- `user_id`
- `assistant_id`
- `dialogue_turn_number`
- `previous_user_text`
- `previous_assistant_text`

## Text fields
- `assistant_text`
- `next_user_text`

## Dialogue acts
- `assistant_dialogue_act`
- `next_user_dialogue_act`
- `previous_user_dialogue_act`

## Inclusion indicators
- `has_next_user_turn`
- `has_grounding`
- `has_like_label`
- `has_known_entities`
- `has_fact_source`
- `is_flagged_dialogue`
- `included_primary`
- `included_grounded`

## Fact-source predictors
- `any_rooted_fact`
- `any_aspect_fact`
- `any_general_fact`
- `n_rooted_facts`
- `n_aspect_facts`
- `n_general_facts`
- `n_total_grounded_facts`
- `rooted_share`
- `fact_source_type`

Fact-source mapping used in this milestone:
- `known -> rooted`
- `section -> aspect`
- `random -> general`

## Existing-label outcomes
- `assistant_liked_binary`
- `next_user_info_seeking`
- `next_user_request_followup`
- `next_user_aspect_shift`
- `dialogue_survival_1`
- `dialogue_survival_2`
- `dialogue_survival_3`
- `remaining_turns_total`
- `remaining_user_turns`
- `remaining_assistant_turns`

## Prior engagement controls
- `prior_assistant_likes_count`
- `prior_assistant_like_rate`
- `prior_user_info_seeking_count`
- `prior_user_info_seeking_rate`
- `prior_user_request_followup_count`
- `prior_user_request_followup_rate`
- `prior_dialogue_turns`

## Text-derived controls (milestone implementation)
- `assistant_char_length`
- `assistant_word_count`
- `assistant_sentence_count`
- `assistant_has_question_mark`
- `assistant_n_question_marks`
- `assistant_n_named_entities` (heuristic in milestone)
- `assistant_n_numbers`
- `assistant_has_number`
- `assistant_readability_score`
- `assistant_n_causal_markers`
- `assistant_n_comparison_markers`
