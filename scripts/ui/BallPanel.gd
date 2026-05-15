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
@export var spawn_angle_random_degrees: float = 15.0
@export var spawn_y: float = 7.0
@export var peg_layout_mode: String = "mixed_by_player"
@export var peg_safe_margin: float = 36.0
@export var peg_safe_gap: float = 8.0
@export var peg_jitter: float = 0.3
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
	spawn_angle_random_degrees = GameConfig.ball_panel_spawn_angle_random_degrees
	spawn_y = GameConfig.ball_panel_spawn_y
	peg_layout_mode = GameConfig.ball_panel_peg_layout_mode
	peg_safe_margin = GameConfig.ball_panel_peg_safe_margin
	peg_safe_gap = GameConfig.ball_panel_peg_safe_gap
	peg_jitter = GameConfig.ball_panel_peg_jitter
	reward_types = GameConfig.get_reward_slot_order()

func _create_reward_slots() -> void:
	for child in reward_slots.get_children():
		child.queue_free()

	var slot_width := minf(30.0, (panel_size.x - 34.0) / float(reward_types.size()))
	var slot_size := Vector2(slot_width, 26.0)
	var tray_width := slot_size.x * float(reward_types.size())
	var tray_left := (panel_size.x - tray_width) * 0.5
	for index in reward_types.size():
		var slot := reward_slot_scene.instantiate() as Node2D
		reward_slots.add_child(slot)
		slot.position = Vector2(tray_left + slot_size.x * (float(index) + 0.5), panel_size.y - 33.5)
		slot.set("slot_size", slot_size)
		if slot.has_method("configure"):
			slot.call("configure", player_id, reward_types[index], _get_player_color())

func _create_anchor_points() -> void:
	anchor_points.clear()
	for child in anchor_points_node.get_children():
		child.queue_free()
	if anchor_count <= 0:
		return

	var min_y := anchor_min_y
	var max_y := panel_size.y - anchor_reward_gap
	var ball_radius := 7.0
	var margin := maxf(anchor_radius + ball_radius + 18.0, peg_safe_margin)
	var min_distance := anchor_radius * 2.0 + ball_radius * 2.0 + peg_safe_gap
	var usable_width := panel_size.x - margin * 2.0
	var usable_height := max_y - min_y
	var max_cols := maxi(1, int(floor(usable_width / min_distance)) + 1)
	var max_rows := maxi(1, int(floor(usable_height / min_distance)) + 1)
	var col_count := mini(anchor_count, max_cols)
	var row_count := mini(max_rows, int(ceil(float(anchor_count) / float(col_count))))
	var safe_count := mini(anchor_count, row_count * col_count)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(104729 + player_id * 7919 + anchor_count * 271)
	var candidates := _build_anchor_candidates(row_count, col_count, margin, min_y, max_y, min_distance, safe_count, rng)
	safe_count = mini(safe_count, candidates.size())

	for index in safe_count:
		var anchor_position: Vector2 = candidates[index]
		anchor_points.append(anchor_position)

		var marker := Polygon2D.new()
		marker.polygon = _make_circle_polygon(anchor_radius, 18)
		marker.position = anchor_position
		marker.color = _get_player_color().lightened(0.45)
		anchor_points_node.add_child(marker)

func _build_anchor_candidates(row_count: int, col_count: int, margin: float, min_y: float, max_y: float, min_distance: float, safe_count: int, rng: RandomNumberGenerator) -> Array[Vector2]:
	if _get_layout_mode_index() == 2:
		return _build_random_safe_anchors(safe_count, margin, min_y, max_y, min_distance, rng)

	var points: Array[Vector2] = []
	var x_gap := (panel_size.x - margin * 2.0) / float(maxi(col_count - 1, 1))
	var y_gap := (max_y - min_y) / float(maxi(row_count - 1, 1))
	var layout_mode := _get_layout_mode_index()
	var jitter := _get_safe_jitter(x_gap, y_gap, min_distance)
	for row in row_count:
		for col in col_count:
			var x_ratio := 0.5 if col_count == 1 else float(col) / float(col_count - 1)
			var x := lerpf(margin, panel_size.x - margin, x_ratio)
			var y := lerpf(min_y, max_y, 0.5 if row_count == 1 else float(row) / float(row_count - 1))
			var offset := _get_anchor_offset(layout_mode, row, col, x_gap, y_gap, min_distance)
			var anchor_position := Vector2(
				clampf(x + offset.x, margin, panel_size.x - margin),
				clampf(y + offset.y, min_y, max_y)
			)
			if jitter > 0.0 and layout_mode > 1:
				anchor_position += Vector2(rng.randf_range(-jitter, jitter), rng.randf_range(-jitter, jitter))
				anchor_position = Vector2(
					clampf(anchor_position.x, margin, panel_size.x - margin),
					clampf(anchor_position.y, min_y, max_y)
				)
			points.append(anchor_position)
	return points

func _build_random_safe_anchors(safe_count: int, margin: float, min_y: float, max_y: float, min_distance: float, rng: RandomNumberGenerator) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for _attempt in 160:
		if points.size() >= safe_count:
			return points
		var candidate := Vector2(
			rng.randf_range(margin, panel_size.x - margin),
			rng.randf_range(min_y, max_y)
		)
		if _is_anchor_position_safe(candidate, points, min_distance):
			points.append(candidate)
	return points

func _is_anchor_position_safe(candidate: Vector2, points: Array[Vector2], min_distance: float) -> bool:
	for point in points:
		if candidate.distance_to(point) < min_distance:
			return false
	return true

func _get_anchor_offset(layout_mode: int, row: int, col: int, x_gap: float, y_gap: float, min_distance: float) -> Vector2:
	if layout_mode == 0:
		return Vector2.ZERO
	if layout_mode == 1:
		var safe_x_offset := maxf(0.0, x_gap - min_distance) * 0.95
		return Vector2((1.0 if row % 2 == 0 else -1.0) * safe_x_offset, 0.0)
	var safe_y_offset := maxf(0.0, y_gap - min_distance) * 0.22
	return Vector2(0.0, (1.0 if col % 2 == 0 else -1.0) * safe_y_offset)

func _get_safe_jitter(x_gap: float, y_gap: float, min_distance: float) -> float:
	return maxf(0.0, minf(x_gap, y_gap) - min_distance) * peg_jitter

func _get_layout_mode_index() -> int:
	match peg_layout_mode:
		"aligned": return 0
		"staggered": return 1
		"random_safe": return 2
		_:
			return player_id % 3

func _spawn_ball() -> void:
	if ball_scene == null:
		return

	var slot_count: int = maxi(1, reward_slots.get_child_count())
	var target_slot := reward_slots.get_child(spawn_index % slot_count) as Node2D
	var start_x := clampf(target_slot.position.x + randf_range(-12.0, 12.0), 18.0, panel_size.x - 18.0)
	var start_position := Vector2(start_x, spawn_y)
	var angle := deg_to_rad(randf_range(-spawn_angle_random_degrees, spawn_angle_random_degrees))
	var start_velocity := Vector2.DOWN.rotated(angle) * ball_speed
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

func _get_player_color() -> Color: return GameConfig.get_player_color(player_id)
func _get_ball_color() -> Color: return _get_player_color().lightened(0.35)
func _make_circle_polygon(poly_radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in point_count:
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * poly_radius)
	return points
