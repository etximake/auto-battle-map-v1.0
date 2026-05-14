extends Node2D
class_name GameMap

const CENTER_POSITION := Vector2(640, 360)
const BASE_POSITIONS := {
	0: Vector2(280, 80),
	1: Vector2(1000, 80),
	2: Vector2(280, 640),
	3: Vector2(1000, 640),
}

var path_waypoints: Dictionary = {}

@onready var path_visual: Node2D = $PathVisual


func _ready() -> void:
	_setup_default_paths()
	_load_paths_from_nodes()
	_draw_path_lines()


func get_march_path(player_id: int) -> Array[Vector2]:
	var full_path: Array[Vector2] = []
	var my_path: Array = path_waypoints.get(player_id, [])
	var opponent_path: Array = path_waypoints.get(_get_main_opponent(player_id), [])

	for point in my_path:
		full_path.append(point)

	for index in range(opponent_path.size() - 2, -1, -1):
		full_path.append(opponent_path[index])

	return full_path


func get_base_position(player_id: int) -> Vector2:
	return BASE_POSITIONS.get(player_id, CENTER_POSITION)


func get_center_position() -> Vector2:
	return CENTER_POSITION


func _setup_default_paths() -> void:
	path_waypoints = {
		0: [
			Vector2(280, 80),
			Vector2(320, 150),
			Vector2(400, 200),
			Vector2(480, 280),
			Vector2(560, 320),
			CENTER_POSITION,
		],
		1: [
			Vector2(1000, 80),
			Vector2(960, 150),
			Vector2(880, 200),
			Vector2(800, 280),
			Vector2(720, 320),
			CENTER_POSITION,
		],
		2: [
			Vector2(280, 640),
			Vector2(320, 570),
			Vector2(400, 520),
			Vector2(480, 440),
			Vector2(560, 400),
			CENTER_POSITION,
		],
		3: [
			Vector2(1000, 640),
			Vector2(960, 570),
			Vector2(880, 520),
			Vector2(800, 440),
			Vector2(720, 400),
			CENTER_POSITION,
		],
	}


func _load_paths_from_nodes() -> void:
	for player_id in BASE_POSITIONS.keys():
		var path_node := get_node_or_null("Paths/Path_P%d" % player_id)
		if path_node is Path2D and path_node.curve != null and path_node.curve.point_count > 0:
			path_waypoints[player_id] = _path2d_to_waypoints(path_node)


func _path2d_to_waypoints(path_node: Path2D) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for index in path_node.curve.point_count:
		points.append(path_node.global_position + path_node.curve.get_point_position(index))

	return points


func _draw_path_lines() -> void:
	for player_id in path_waypoints.keys():
		var line := path_visual.get_node_or_null("PathLine_P%d" % player_id) as Line2D
		if line == null:
			continue

		var points := PackedVector2Array()
		for point in path_waypoints[player_id]:
			points.append(point)
		line.points = points


func _get_main_opponent(player_id: int) -> int:
	match player_id:
		0:
			return 3
		1:
			return 2
		2:
			return 1
		3:
			return 0
		_:
			return 0
