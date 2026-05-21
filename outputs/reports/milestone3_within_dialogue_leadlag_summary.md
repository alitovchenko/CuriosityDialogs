# Milestone 3: Within-dialogue and lead-lag controls

## Models run
- within_dialogue_rooted: `next_user_request_followup ~ any_rooted_fact + controls | dialogue_id`
- within_dialogue_fact_source_type: `next_user_request_followup ~ fact_source_type + controls | dialogue_id`
- leadlag_previous_outcome: `previous_user_request_followup ~ current any_rooted_fact + controls | dialogue_id`
- leadlag_next_outcome: `next_user_request_followup ~ current any_rooted_fact + controls | dialogue_id`
- assistant_robust_two_fe: `next_user_request_followup ~ any_rooted_fact + controls | dialogue_id + assistant_id` with two-way clustered SEs

## Rootedness coefficient snapshots
- within_dialogue_rooted: log-odds=1.217, OR=3.378, p=1.82e-54
- leadlag_previous_outcome: log-odds=-0.954, OR=0.385, p=1.03e-24
- leadlag_next_outcome: log-odds=0.963, OR=2.621, p=5.82e-23
- assistant_robust_two_fe: log-odds=1.217, OR=3.378, p=1.03e-42

## Lead-lag specificity check
- Next-turn rootedness effect OR=2.621 vs Previous-turn OR=0.385

Full coefficient table: `outputs/tables/milestone3_within_dialogue_leadlag_models.csv`
