extends Node2D

@export var unit_scene: PackedScene
@export var use_game_map_paths: bool = false
@export var game_map_path: NodePath
@export var units_parent_path: NodePath
@export var test_unit_type: String = "Blob"

var test_paths: Dictionary = {
	0: [
		Vector2(280, 80),
		Vector2(400, 200),
		Vector2(560, 320),
		Vector2(640, 360),
	],
	1: [
		Vector2(1000, 80),
		Vector2(880, 200),
		Vector2(720, 320),
		Vector2(640, 360),
	],
	2: [
		Vector2(280, 640),
		Vector2(400, 520),
		Vector2(560, 400),
		Vector2(640, 360),
	],
	3: [
		Vector2(1000, 640),
		Vector2(880, 520),
		Vector2(720, 400),
		Vector2(640, 360),
	],
}


func _ready() -> void:
	if unit_scene == null:
		push_error("UnitTestSpawner needs a unit_scene.")
		return

	for player_id in test_paths.keys():
		var unit := unit_scene.instantiate()
		if not unit.has_method("setup_unit"):
			push_error("unit_scene must provide setup_unit().")
			continue

		var units_parent := _get_units_parent()
		var unit_path := _get_path_for_player(player_id)
		units_parent.add_child(unit)
		unit.setup_unit(player_id, test_unit_type, unit_path)


func _get_units_parent() -> Node:
	if not units_parent_path.is_empty():
		var units_parent := get_node_or_null(units_parent_path)
		if units_parent != null:
			return units_parent

	return self


func _get_path_for_player(player_id: int) -> Array[Vector2]:
	var unit_path: Array[Vector2] = []

	if use_game_map_paths and not game_map_path.is_empty():
		var game_map := get_node_or_null(game_map_path)
		if game_map != null and game_map.has_method("get_march_path"):
			unit_path.assign(game_map.get_march_path(player_id))

	if unit_path.is_empty():
		unit_path.assign(test_paths[player_id])

	return unit_path
