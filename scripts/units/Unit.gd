extends CharacterBody2D
class_name Unit

@export var player_id: int = 0
@export var unit_type: String = "Blob"
@export var move_speed: float = 160.0
@export var max_hp: float = 100.0
@export var damage: float = 10.0
@export var attack_range: float = 32.0
@export var attack_cooldown: float = 1.0

enum UnitState { MARCHING, ATTACKING, DEAD }

var current_hp: float = 100.0
var path_points: Array[Vector2] = []
var path_index: int = 0
var is_dead: bool = false
var state: UnitState = UnitState.MARCHING
var attack_timer: float = 0.0
var current_target: Unit = null

@onready var body: Polygon2D = $Body
@onready var left_eye: Polygon2D = $LeftEye
@onready var right_eye: Polygon2D = $RightEye
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var name_label: Label = $Label
@onready var hp_bar: ProgressBar = $HPBar
@onready var detection_shape: CollisionShape2D = $DetectionArea/DetectionShape

func _ready() -> void:
	current_hp = max_hp
	_setup_jelly_visual()
	_setup_collision()
	_apply_player_color()
	_update_label()
	_update_hp_bar()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	if state == UnitState.ATTACKING:
		_process_attack()
		return
	_follow_path(delta)
	_check_for_enemy()
	move_and_slide()

func setup_unit(new_player_id: int, new_unit_type: String, new_path_points: Array[Vector2]) -> void:
	player_id = new_player_id
	unit_type = new_unit_type
	path_points = new_path_points.duplicate()
	path_index = 0
	is_dead = false
	state = UnitState.MARCHING
	current_hp = max_hp
	attack_timer = 0.0
	current_target = null
	set_physics_process(true)
	if not path_points.is_empty():
		global_position = path_points[0]
		path_index = 1
	if is_node_ready():
		_setup_jelly_visual()
		_setup_collision()
		_apply_player_color()
		_update_label()
		_update_hp_bar()

func take_damage(amount: float, attacker_id: int = -1) -> void:
	if is_dead:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	_update_hp_bar()
	if current_hp <= 0.0:
		die(attacker_id)

func die(killer_player_id: int = -1) -> void:
	is_dead = true
	state = UnitState.DEAD
	velocity = Vector2.ZERO
	EventBus.unit_died.emit(self, killer_player_id)
	call_deferred("_fallback_hide_if_not_pooled")

func _follow_path(_delta: float) -> void:
	if path_points.is_empty() or path_index >= path_points.size():
		velocity = Vector2.ZERO
		_reach_base()
		return
	var target_position: Vector2 = path_points[path_index]
	var to_target: Vector2 = target_position - global_position
	if to_target.length() < 8.0:
		path_index += 1
		if path_index >= path_points.size():
			velocity = Vector2.ZERO
			_reach_base()
			return
		target_position = path_points[path_index]
		to_target = target_position - global_position
	velocity = to_target.normalized() * move_speed
	rotation = velocity.angle()

func _check_for_enemy() -> void:
	current_target = _find_enemy_in_range()
	if current_target == null:
		return
	velocity = Vector2.ZERO
	state = UnitState.ATTACKING

func _process_attack() -> void:
	if not _is_valid_enemy(current_target):
		current_target = null
		state = UnitState.MARCHING
		return
	if global_position.distance_to(current_target.global_position) > attack_range:
		current_target = null
		state = UnitState.MARCHING
		return
	if attack_timer <= 0.0:
		attack_timer = attack_cooldown
		current_target.take_damage(damage, player_id)

func _find_enemy_in_range() -> Unit:
	var nearest_unit: Unit = null
	var nearest_distance := INF
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if not _is_valid_enemy(unit):
			continue
		var distance := global_position.distance_to(unit.global_position)
		if distance <= attack_range and distance < nearest_distance:
			nearest_distance = distance
			nearest_unit = unit
	return nearest_unit

func _is_valid_enemy(unit: Unit) -> bool:
	if unit == null or unit == self:
		return false
	return not unit.is_dead and unit.player_id != player_id

func _reach_base() -> void:
	is_dead = true
	state = UnitState.DEAD
	EventBus.unit_reached_base.emit(self, _find_nearest_enemy_base())
	call_deferred("_fallback_hide_if_not_pooled")

func _find_nearest_enemy_base() -> Node:
	var nearest_base: Node = null
	var nearest_distance := INF
	for base in get_tree().get_nodes_in_group("bases"):
		if int(base.get("player_id")) == player_id:
			continue
		var distance := global_position.distance_to(base.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_base = base
	return nearest_base

func _setup_jelly_visual() -> void:
	var body_radius := _get_visual_radius()
	body.polygon = _make_circle_polygon(body_radius, 24)
	left_eye.polygon = _make_circle_polygon(maxf(body_radius * 0.16, 3.0), 12)
	left_eye.position = Vector2(body_radius * 0.32, -body_radius * 0.28)
	left_eye.color = Color.WHITE
	right_eye.polygon = _make_circle_polygon(maxf(body_radius * 0.16, 3.0), 12)
	right_eye.position = Vector2(body_radius * 0.32, body_radius * 0.28)
	right_eye.color = Color.WHITE
	name_label.position = Vector2(-38.0, body_radius + 4.0)
	name_label.size = Vector2(76.0, 18.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)

func _setup_collision() -> void:
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = _get_visual_radius()
	collision_shape.shape = circle_shape
	var detection_circle := CircleShape2D.new()
	detection_circle.radius = attack_range
	detection_shape.shape = detection_circle

func _apply_player_color() -> void:
	body.color = GameConfig.get_player_color(player_id)

func _update_label() -> void:
	name_label.text = unit_type

func _update_hp_bar() -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

func _fallback_hide_if_not_pooled() -> void:
	if visible:
		hide()
		set_physics_process(false)

func _make_circle_polygon(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_point_count: int = maxi(point_count, 3)
	for index in safe_point_count:
		var angle := TAU * float(index) / float(safe_point_count)
		var wobble := 1.0 + 0.08 * sin(float(index) * 2.3)
		points.append(Vector2(cos(angle), sin(angle)) * radius * wobble)
	return points

func _get_visual_radius() -> float:
	match unit_type:
		"Scout": return 18.0
		"Soldier": return 24.0
		"Tank": return 30.0
		"Mage": return 22.0
		_: return 24.0
