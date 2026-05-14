extends Node

signal unit_spawned(unit: Node, player_id: int)
signal unit_died(unit: Node, killer_player_id: int)
signal unit_reached_base(unit: Node, target_base: Node)

signal base_damaged(base: Node, amount: float, attacker_player: int)
signal base_destroyed(base: Node)

signal gold_changed(player_id: int, new_amount: float)

signal round_reset_requested()

signal tower_attacked(tower: Node, target: Node)
