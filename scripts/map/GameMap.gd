extends Node2D
class_name GameMap

const CENTER_POSITION := Vector2(640, 360)
const MAP_RECT := Rect2(192, 0, 896, 720)
const BASE_POSITIONS := {
	0: Vector2(304, 134),
	1: Vector2(976, 134),
	2: Vector2(304, 586),
	3: Vector2(976, 586),
}
const OPTIONAL_TOWER_POSITIONS := [
	Vector2(396, 221),
	Vector2(508, 295),
	Vector2(848, 221),
	Vector2(744, 295),
	Vector2(508, 423),
	Vector2(396, 501),
	Vector2(744, 423),
	Vector2(848, 501),
]
const PLAYER_COLORS := {
	0: Color("#E74C3C"),
	1: Color("#3498DB"),
	2: Color("#2ECC71"),
	3: Color("#F1C40F"),
}

var path_waypoints: Dictionary = {}

@onready var path_visual: Node2D = $PathVisual
@onready var base_markers: Node2D = $BaseMarkers
@onready var optional_tower_markers: Node2D = $OptionalTowerMarkers


func _ready() -> void:
	_setup_default_paths()
	_load_paths_from_nodes()
	_draw_path_lines()
	_setup_map_markers()


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


func get_map_rect() -> Rect2:
	return MAP_RECT


func get_optional_tower_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for position in OPTIONAL_TOWER_POSITIONS:
		positions.append(position)

	return positions


func _setup_default_paths() -> void:
	path_waypoints = {
		0: [
			BASE_POSITIONS[0],
			Vector2(324, 146),
			Vector2(375, 189),
			Vector2(416, 249),
			Vector2(477, 309),
			Vector2(538, 343),
			Vector2(579, 360),
			CENTER_POSITION,
		],
		1: [
			BASE_POSITIONS[1],
			Vector2(956, 146),
			Vector2(905, 189),
			Vector2(864, 249),
			Vector2(803, 309),
			Vector2(742, 343),
			Vector2(701, 357),
			CENTER_POSITION,
		],
		2: [
			BASE_POSITIONS[2],
			Vector2(334, 574),
			Vector2(375, 523),
			Vector2(416, 471),
			Vector2(477, 411),
			Vector2(538, 381),
			Vector2(579, 363),
			CENTER_POSITION,
		],
		3: [
			BASE_POSITIONS[3],
			Vector2(946, 574),
			Vector2(905, 523),
			Vector2(864, 471),
			Vector2(803, 411),
			Vector2(742, 377),
			Vector2(701, 360),
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


func _setup_map_markers() -> void:
	for player_id in BASE_POSITIONS.keys():
		var marker := base_markers.get_node_or_null("BaseMarker_%d" % player_id) as Polygon2D
		if marker == null:
			continue

		marker.position = BASE_POSITIONS[player_id]
		marker.polygon = _make_circle_polygon(24.0, 24)
		marker.color = PLAYER_COLORS[player_id]

	for index in OPTIONAL_TOWER_POSITIONS.size():
		var marker := optional_tower_markers.get_node_or_null("OptionalTowerMarker_%d" % index) as Polygon2D
		if marker == null:
			continue

		marker.position = OPTIONAL_TOWER_POSITIONS[index]
		marker.polygon = _make_square_polygon(16.0)
		marker.color = Color("#777777")


func _make_circle_polygon(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in point_count:
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	return points


func _make_square_polygon(size: float) -> PackedVector2Array:
	var half_size := size * 0.5
	return PackedVector2Array([
		Vector2(-half_size, -half_size),
		Vector2(half_size, -half_size),
		Vector2(half_size, half_size),
		Vector2(-half_size, half_size),
	])


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
