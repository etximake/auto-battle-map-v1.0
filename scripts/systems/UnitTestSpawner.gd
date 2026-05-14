extends Node2D

@export var unit_scene: PackedScene

var test_paths: Dictionary = {
	0: [
		Vector2(192, 108),
		Vector2(576, 324),
		Vector2(864, 432),
		Vector2(960, 540),
	],
	1: [
		Vector2(1728, 108),
		Vector2(1344, 324),
		Vector2(1056, 432),
		Vector2(960, 540),
	],
	2: [
		Vector2(192, 972),
		Vector2(576, 756),
		Vector2(864, 648),
		Vector2(960, 540),
	],
	3: [
		Vector2(1728, 972),
		Vector2(1344, 756),
		Vector2(1056, 648),
		Vector2(960, 540),
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

		var unit_path: Array[Vector2] = []
		unit_path.assign(test_paths[player_id])
		add_child(unit)
		unit.setup_unit(player_id, "Blob", unit_path)
