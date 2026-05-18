extends Node

@export var player_id: int = 0
@export var strategy: String = "BALANCED"
@export var active: bool = false
@export var game_map_path: NodePath
@export var spawn_manager_path: NodePath

var balanced_index: int = 0


func _ready() -> void:
	add_to_group("ai_controllers")
	if player_id >= 0 and player_id < GameConfig.ai_strategies.size():
		strategy = GameConfig.get_ai_strategy(player_id)
	var targets := _get_targets()
	if not targets.is_empty():
		balanced_index = player_id % targets.size()


func choose_target_player(unit_type: String) -> int:
	var targets := _get_targets()
	if targets.is_empty():
		return _get_opposite_player()

	match strategy:
		"AGGRESSIVE":
			return _choose_nearest_target(targets)
		"ECONOMY":
			return _get_opposite_player()
		"ADAPTIVE":
			return _choose_low_pressure_target(targets)
		_:
			return _choose_balanced_target(targets, unit_type)


func choose_objective_player(unit_type: String) -> int:
	# Open-field objective selector. Reuses target selection logic but is
	# semantically a hint for Unit to bias toward this enemy castle when
	# no unit target is available.
	return choose_target_player(unit_type)


func get_unit_ai_policy(unit_type: String) -> Dictionary:
	# Allows future per-strategy overrides of behavior profile fields.
	return {
		"objective_player_id": choose_objective_player(unit_type),
		"strategy": strategy,
	}


func choose_route(unit_type: String, target_player_id: int) -> Array[Vector2]:
	var game_map := _get_game_map()
	if game_map != null and game_map.has_method("get_route"):
		var route: Array[Vector2] = []
		route.assign(game_map.call("get_route", player_id, target_player_id, "main"))
		if not route.is_empty():
			return route

	if game_map != null and game_map.has_method("get_march_path"):
		var fallback: Array[Vector2] = []
		fallback.assign(game_map.call("get_march_path", player_id))
		return fallback

	return []


func _get_targets() -> Array[int]:
	var game_map := _get_game_map()
	if game_map != null and game_map.has_method("get_target_player_ids"):
		var targets: Array[int] = []
		targets.assign(game_map.call("get_target_player_ids", player_id))
		return targets

	var result: Array[int] = []
	for index in range(GameConfig.get_player_count()):
		if index != player_id:
			result.append(index)
	return result


func _choose_nearest_target(targets: Array[int]) -> int:
	var game_map := _get_game_map()
	if game_map == null or not game_map.has_method("get_base_position"):
		return targets[0]

	var my_position: Vector2 = game_map.call("get_base_position", player_id)
	var best_target := targets[0]
	var best_distance := INF
	for target_id in targets:
		var target_position: Vector2 = game_map.call("get_base_position", target_id)
		var distance := my_position.distance_to(target_position)
		if distance < best_distance:
			best_distance = distance
			best_target = target_id
	return best_target


func _choose_balanced_target(targets: Array[int], unit_type: String) -> int:
	if ["Tank", "Hammer"].has(unit_type):
		return _get_opposite_player()

	var target := targets[balanced_index % targets.size()]
	balanced_index += 1
	return target


func _choose_low_pressure_target(targets: Array[int]) -> int:
	var best_target := targets[0]
	var best_count := INF
	for target_id in targets:
		var count := _count_units_for_player(target_id)
		if count < best_count:
			best_count = count
			best_target = target_id
	return best_target


func _count_units_for_player(target_player_id: int) -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("units"):
		if int(node.get("player_id")) == target_player_id:
			count += 1
	return count


func _get_opposite_player() -> int:
	var targets := _get_targets()
	if targets.is_empty():
		return (player_id + 1) % maxi(GameConfig.get_player_count(), 1)

	var game_map := _get_game_map()
	if game_map == null or not game_map.has_method("get_base_position"):
		return targets[0]

	var my_position: Vector2 = game_map.call("get_base_position", player_id)
	var best_target := targets[0]
	var best_distance := -1.0
	for target_id in targets:
		var target_position: Vector2 = game_map.call("get_base_position", target_id)
		var distance := my_position.distance_to(target_position)
		if distance > best_distance:
			best_distance = distance
			best_target = target_id
	return best_target


func _get_game_map() -> Node:
	if game_map_path != NodePath(""):
		var node := get_node_or_null(game_map_path)
		if node != null:
			return node
	return get_tree().get_first_node_in_group("game_maps")
