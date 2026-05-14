extends Node


func _ready() -> void:
	EventBus.reward_queued.connect(_on_reward_queued)
	EventBus.castle_spawn_requested.connect(_on_castle_spawn_requested)
	EventBus.unit_spawned.connect(_on_unit_spawned)


func _on_reward_queued(player_id: int, reward_type: String) -> void:
	print("reward_queued P%d %s" % [player_id, reward_type])


func _on_castle_spawn_requested(player_id: int, unit_type: String) -> void:
	print("castle_spawn_requested P%d %s" % [player_id, unit_type])


func _on_unit_spawned(unit: Node, player_id: int) -> void:
	var path_points: Array = unit.get("path_points")
	var route_end := Vector2.ZERO
	if not path_points.is_empty():
		route_end = path_points[path_points.size() - 1]
	print("unit_spawned P%d route_end=%s" % [player_id, route_end])
