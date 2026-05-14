extends CharacterBody2D
class_name Unit

@export var player_id: int = 0
@export var unit_type: String = "Blob"
@export var move_speed: float = 160.0
@export var max_hp: float = 100.0

var current_hp: float = 100.0
var path_points: Array[Vector2] = []
var path_index: int = 0
var is_dead: bool = false

@onready var body: Polygon2D = $Body
@onready var left_eye: Polygon2D = $LeftEye
@onready var right_eye: Polygon2D = $RightEye
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var name_label: Label = $Label


func _ready() -> void:
	current_hp = max_hp
	_setup_jelly_visual()
	_setup_collision()
	_apply_player_color()
	_update_label()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_follow_path(delta)
	move_and_slide()


func setup_unit(new_player_id: int, new_unit_type: String, new_path_points: Array[Vector2]) -> void:
	player_id = new_player_id
	unit_type = new_unit_type
	path_points = new_path_points.duplicate()
	path_index = 0
	is_dead = false
	current_hp = max_hp

	if not path_points.is_empty():
		global_position = path_points[0]
		path_index = 1

	if is_node_ready():
		_apply_player_color()
		_update_label()


func take_damage(amount: float) -> void:
	if is_dead:
		return

	current_hp = maxf(current_hp - amount, 0.0)
	if current_hp <= 0.0:
		die()


func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	queue_free()


func _follow_path(_delta: float) -> void:
	if path_points.is_empty() or path_index >= path_points.size():
		velocity = Vector2.ZERO
		return

	var target_position: Vector2 = path_points[path_index]
	var to_target: Vector2 = target_position - global_position

	if to_target.length() < 8.0:
		path_index += 1
		if path_index >= path_points.size():
			velocity = Vector2.ZERO
			return

		target_position = path_points[path_index]
		to_target = target_position - global_position

	velocity = to_target.normalized() * move_speed
	rotation = velocity.angle()


func _setup_jelly_visual() -> void:
	body.polygon = _make_circle_polygon(24.0, 24)

	left_eye.polygon = _make_circle_polygon(4.0, 12)
	left_eye.position = Vector2(8.0, -7.0)
	left_eye.color = Color.WHITE

	right_eye.polygon = _make_circle_polygon(4.0, 12)
	right_eye.position = Vector2(8.0, 7.0)
	right_eye.color = Color.WHITE

	name_label.position = Vector2(-32.0, 28.0)
	name_label.size = Vector2(64.0, 18.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)


func _setup_collision() -> void:
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = 24.0
	collision_shape.shape = circle_shape


func _apply_player_color() -> void:
	match player_id:
		0:
			body.color = Color("#E74C3C")
		1:
			body.color = Color("#3498DB")
		2:
			body.color = Color("#2ECC71")
		3:
			body.color = Color("#F1C40F")
		_:
			body.color = Color("#AAAAAA")


func _update_label() -> void:
	name_label.text = unit_type


func _make_circle_polygon(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_point_count: int = maxi(point_count, 3)

	for index in safe_point_count:
		var angle := TAU * float(index) / float(safe_point_count)
		var wobble := 1.0 + 0.08 * sin(float(index) * 2.3)
		points.append(Vector2(cos(angle), sin(angle)) * radius * wobble)

	return points
