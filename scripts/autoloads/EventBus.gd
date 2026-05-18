extends Node

# Reward loop events for base mode:
# BallPanel -> RewardSlot -> RewardManager -> Castle queue.
signal reward_generated(player_id: int, reward_type: String)
signal reward_queued(player_id: int, reward_type: String)
signal reward_consumed(player_id: int, reward_type: String)

# Castle spawn and damage events for the new base mode.
signal castle_spawn_requested(player_id: int, unit_type: String)
signal unit_reached_castle(unit: Node, target_castle: Node)
signal castle_damaged(castle: Node, amount: float, attacker_player: int)
signal castle_destroyed(castle: Node)
signal castle_shot_fired(castle: Node, target: Node)
signal score_awarded(player_id: int, amount: int, reason: String)
signal score_changed(player_id: int, new_score: int)

# Existing unit events kept for current movement/combat code.
signal unit_spawned(unit: Node, player_id: int)
signal unit_died(unit: Node, killer_player_id: int)
signal unit_reached_base(unit: Node, target_base: Node)
signal unit_attack_performed(unit: Node, target: Node, attack_style: String)

# Legacy base events kept until PlayerBase is refactored into castle role.
signal base_damaged(base: Node, amount: float, attacker_player: int)
signal base_destroyed(base: Node)

# Legacy economy event. Gold-buy AI is not base-mode core anymore.
signal gold_changed(player_id: int, new_amount: float)

signal round_reset_requested()

# Optional mode only. NeutralTower is not active in base mode.
signal tower_attacked(tower: Node, target: Node)
