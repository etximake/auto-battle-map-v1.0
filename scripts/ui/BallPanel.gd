extends Node2D
class_name BallPanel

@export var player_id: int = 0
@export var panel_size: Vector2 = Vector2(192, 360)
@export var spawn_interval: float = 0.7
@export var ball_speed: float = 165.0
@export var max_live_balls: int = 8
@export var anchor_count: int = 6
@export var anchor_radius: float = 11.0
@export var anchor_min_y: float = 56.0
@export var anchor_reward_gap: float = 112.0
@export var ball_scene: PackedScene
@export var reward_slot_scene: PackedScene

var spawn_timer: float = 0.0
var spawn_index: int = 0
var reward_types: Array[String] = []
var reward_counts: Dictionary = {}
var anchor_points: Array[Vector2] = []

@onready var background: Polygon2D = $Background
@onready var anchor_points_node: Node2D = $AnchorPoints
@onready var title_label: Label = $TitleLabel
@onready var counter_label: Label = $CounterLabel
@onready var reward_slots: Node2D = $RewardSlots
@onready var ball_container: Node2D = $BallContainer


func _ready() -> void:
	_apply_config()
	add_to_group("ball_panels")
	EventBus.reward_generated.connect(_on_reward_generated)
	EventBus.round_reset_requested.connect(_on_round_reset_requested)
	_setup_visual()
	_create_anchor_points()
	_create_reward_slots()
	_update_counter_label()


func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return
	if ball_container.get_child_count() >= max_live_balls:
		return

	spawn_timer = spawn_interval
	_spawn_ball()


func _setup_visual() -> void:
	var color := _get_player_color()
	background.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(panel_size.x, 0),
		panel_size,
		Vector2(0, panel_size.y),
	])
	background.color = Color(color.r, color.g, color.b, 0.42)

	title_label.text = "P%d" % player_id
	title_label.position = Vector2(12, 8)
	title_label.size = Vector2(panel_size.x - 24, 32)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	counter_label.position = Vector2(8, panel_size.y - 72)
	counter_label.size = Vector2(panel_size.x - 16, 24)


func _apply_config() -> void:
	spawn_interval = GameConfig.ball_panel_spawn_interval
	ball_speed = GameConfig.ball_panel_ball_speed
	max_live_balls = GameConfig.ball_panel_max_live_balls
	anchor_count = GameConfig.ball_panel_anchor_count
	anchor_radius = GameConfig.ball_panel_anchor_radius
	anchor_min_y = GameConfig.ball_panel_anchor_min_y
	anchor_reward_gap = GameConfig.ball_panel_anchor_reward_gap
	reward_types = GameConfig.get_reward_slot_order()


func _create_reward_slots() -> void:
	for child in reward_slots.get_children():
		child.queue_free()

	var tray_left := 17.0
	var tray_width := panel_size.x - tray_left * 2.0
	var slot_step := tray_width / float(reward_types.size())
	for index in reward_types.size():
		var slot := reward_slot_scene.instantiate() as Node2D
		reward_slots.add_child(slot)
		slot.position = Vector2(tray_left + slot_step * (float(index) + 0.5), panel_size.y - 33.5)
		if slot.has_method("configure"):
			slot.call("configure", player_id, reward_types[index], _get_player_color())


func _create_anchor_points() -> void:
	anchor_points.clear()
	for child in anchor_points_node.get_children():
		child.queue_free()

	var rng := RandomNumberGenerator.new()
	rng.seed = int(player_id * 7919 + 104729)
	var min_y := anchor_min_y
	var max_y := panel_size.y - anchor_reward_gap

	for _index in anchor_count:
		var anchor_position := _pick_anchor_position(rng, min_y, max_y)
		anchor_points.append(anchor_position)

		var marker := Polygon2D.new()
		marker.polygon = _make_circle_polygon(anchor_radius, 18)
		marker.position = anchor_position
		marker.color = _get_player_color().lightened(0.45)
		anchor_points_node.add_child(marker)


func _pick_anchor_position(rng: RandomNumberGenerator, min_y: float, max_y: float) -> Vector2:
	var min_distance := anchor_radius * 3.2
	var fallback := Vector2(panel_size.x * 0.5, min_y)

	for _attempt in 16:
		var candidate := Vector2(
			rng.randf_range(26.0, panel_size.x - 26.0),
			rng.randf_range(min_y, max_y)
		)
		fallback = candidate

		var is_valid := true
		for point in anchor_points:
			if candidate.distance_to(point) < min_distance:
				is_valid = false
				break

		if is_valid:
			return candidate

	return fallback


func _spawn_ball() -> void:
	if ball_scene == null:
		return

	var slot_count: int = maxi(1, reward_slots.get_child_count())
	var target_slot := reward_slots.get_child(spawn_index % slot_count) as Node2D
	var start_x := clampf(target_slot.position.x + randf_range(-12.0, 12.0), 18.0, panel_size.x - 18.0)
	var start_position := Vector2(start_x, 48)
	var start_velocity := Vector2(randf_range(-36.0, 36.0), ball_speed)
	var ball := ball_scene.instantiate() as Node2D
	ball_container.add_child(ball)
	if ball.has_method("setup"):
		ball.call("setup", player_id, Rect2(Vector2.ZERO, panel_size), start_position, start_velocity, _get_ball_color(), anchor_points, anchor_radius)
	spawn_index += 1


func _on_reward_generated(event_player_id: int, reward_type: String) -> void:
	if event_player_id != player_id:
		return

	reward_counts[reward_type] = int(reward_counts.get(reward_type, 0)) + 1
	_update_counter_label()


func _on_round_reset_requested() -> void:
	spawn_timer = 0.0
	spawn_index = 0
	reward_counts.clear()
	for child in ball_container.get_children():
		child.queue_free()
	_update_counter_label()


func _update_counter_label() -> void:
	if counter_label == null:
		return

	var parts: Array[String] = []
	for reward_type in reward_types:
		var count := int(reward_counts.get(reward_type, 0))
		parts.append("%s:%d" % [reward_type.left(1), count])
	counter_label.text = " ".join(parts)


func _get_player_color() -> Color:
	return GameConfig.get_player_color(player_id)


func _get_ball_color() -> Color:
	return _get_player_color().lightened(0.35)


func _make_circle_polygon(poly_radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in point_count:
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * poly_radius)

	return points
