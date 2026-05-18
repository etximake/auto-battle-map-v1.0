extends Node2D
class_name GameMap

const PLAYER_BASE_SCENE := preload("res://scenes/players/PlayerBase.tscn")
const CENTER_POSITION := Vector2(640, 360)
const OPTIONAL_TOWER_POSITIONS := [
	Vector2(396, 221), Vector2(508, 295), Vector2(848, 221), Vector2(744, 295),
	Vector2(508, 423), Vector2(396, 501), Vector2(744, 423), Vector2(848, 501),
]

var path_waypoints: Dictionary = {}

@onready var path_visual: Node2D = $PathVisual
@onready var base_markers: Node2D = $BaseMarkers
@onready var optional_tower_markers: Node2D = $OptionalTowerMarkers
@onready var bases: Node2D = $Bases


func _ready() -> void:
	add_to_group("game_maps")
	_setup_bases()
	_setup_paths_for_mode()
	_setup_map_markers()


func _setup_paths_for_mode() -> void:
	if GameConfig.is_open_field_movement():
		path_waypoints.clear()
		_clear_path_visual()
		if path_visual != null:
			path_visual.visible = false
		return
	if path_visual != null:
		path_visual.visible = true
	_setup_default_paths()
	_draw_path_lines()


func _clear_path_visual() -> void:
	if path_visual == null:
		return
	for child in path_visual.get_children():
		child.free()


func get_march_path(player_id: int) -> Array[Vector2]:
	return get_route(player_id, _get_main_opponent(player_id))


func get_route(from_player_id: int, target_player_id: int, _route_id: String = "main") -> Array[Vector2]:
	var full_path: Array[Vector2] = []
	var my_path: Array = path_waypoints.get(from_player_id, [])
	var target_path: Array = path_waypoints.get(target_player_id, [])
	for point in my_path:
		full_path.append(point)
	for index in range(target_path.size() - 2, -1, -1):
		full_path.append(target_path[index])
	return full_path


func get_target_player_ids(from_player_id: int) -> Array[int]:
	var targets: Array[int] = []
	for target_id in get_active_player_ids():
		if target_id != from_player_id and _is_castle_alive(target_id):
			targets.append(target_id)
	return targets


func get_active_player_ids() -> Array[int]:
	var ids: Array[int] = []
	for player_id in range(GameConfig.get_player_count()):
		ids.append(player_id)
	return ids


func get_base_position(player_id: int) -> Vector2:
	return GameConfig.get_castle_position(player_id)


func get_spawn_position(player_id: int) -> Vector2:
	return GameConfig.get_spawn_position(player_id)


func get_center_position() -> Vector2:
	return GameConfig.get_map_rect().get_center()


func get_map_rect() -> Rect2:
	return GameConfig.get_map_rect()


func get_optional_tower_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for position in OPTIONAL_TOWER_POSITIONS:
		positions.append(position)
	return positions


func _setup_bases() -> void:
	for child in bases.get_children():
		child.free()
	for player_id in range(GameConfig.get_player_count()):
		var base := PLAYER_BASE_SCENE.instantiate() as Node2D
		base.name = "Base_%d" % player_id
		base.position = get_base_position(player_id)
		base.set("player_id", player_id)
		bases.add_child(base)


func _setup_default_paths() -> void:
	path_waypoints.clear()
	for player_id in range(GameConfig.get_player_count()):
		var spawn_position := get_spawn_position(player_id)
		var center := get_center_position()
		var bend := spawn_position.lerp(center, 0.55)
		path_waypoints[player_id] = [spawn_position, bend, center]


func _draw_path_lines() -> void:
	for child in path_visual.get_children():
		child.free()
	for player_id in range(GameConfig.get_player_count()):
		var line := Line2D.new()
		line.name = "PathLine_P%d" % player_id
		line.width = 40.0
		line.default_color = Color(0.909804, 0.772549, 0.423529, 1)
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		var points := PackedVector2Array()
		for point in path_waypoints[player_id]:
			points.append(point)
		line.points = points
		path_visual.add_child(line)


func _setup_map_markers() -> void:
	for child in base_markers.get_children():
		child.free()
	for player_id in range(GameConfig.get_player_count()):
		var marker := Polygon2D.new()
		marker.name = "BaseMarker_%d" % player_id
		marker.position = get_base_position(player_id)
		marker.polygon = _make_circle_polygon(24.0, 24)
		marker.color = GameConfig.get_player_color(player_id)
		base_markers.add_child(marker)
	for index in OPTIONAL_TOWER_POSITIONS.size():
		var marker := optional_tower_markers.get_node_or_null("OptionalTowerMarker_%d" % index) as Polygon2D
		if marker != null:
			marker.position = OPTIONAL_TOWER_POSITIONS[index]
			marker.polygon = _make_square_polygon(16.0)
			marker.color = Color("#777777")


func _is_castle_alive(player_id: int) -> bool:
	for castle in get_tree().get_nodes_in_group("castles"):
		if int(castle.get("player_id")) == player_id:
			return not bool(castle.get("is_destroyed"))
	return true


func _get_main_opponent(player_id: int) -> int:
	var targets := get_target_player_ids(player_id)
	if targets.is_empty():
		return (player_id + 1) % maxi(GameConfig.get_player_count(), 1)
	var my_position := get_base_position(player_id)
	var best_target := targets[0]
	var best_distance := -1.0
	for target_id in targets:
		var distance := my_position.distance_to(get_base_position(target_id))
		if distance > best_distance:
			best_distance = distance
			best_target = target_id
	return best_target


func _make_circle_polygon(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in point_count:
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _make_square_polygon(size: float) -> PackedVector2Array:
	var half_size := size * 0.5
	return PackedVector2Array([
		Vector2(-half_size, -half_size), Vector2(half_size, -half_size),
		Vector2(half_size, half_size), Vector2(-half_size, half_size),
	])
