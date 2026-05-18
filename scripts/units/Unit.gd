extends CharacterBody2D
class_name Unit
@export var player_id: int = 0
@export var unit_type: String = "Blob"
@export var move_speed: float = 160.0
@export var max_hp: float = 100.0
@export var damage: float = 10.0
@export var attack_range: float = 32.0
@export var attack_cooldown: float = 1.0
enum UnitState { SPAWNING, SEEKING, CHASING, ATTACKING, MARCHING, DEAD }
var current_hp: float = 100.0
var path_points: Array[Vector2] = []
var path_index: int = 0
var is_dead: bool = false
var state: UnitState = UnitState.MARCHING
var attack_timer: float = 0.0
var current_target: Node = null
var movement_mode: String = "lane_path"
var objective_player_id: int = -1
var role: String = "melee_basic"
var attack_style: String = "melee_hit"
var target_priority: String = "nearest_unit"
var prefer_units_over_castle: bool = true
var detection_range: float = 160.0
var chase_range: float = 260.0
var retarget_interval: float = 0.45
var hold_distance: float = 0.0
var separation_radius: float = 22.0
var separation_strength: float = 0.45
var castle_aggression: float = 0.5
var low_hp_focus: float = 0.0
var frontline_bias: float = 0.0
var retarget_timer: float = 0.0
var visual_radius: float = 24.0
var collision_radius: float = 12.0
@onready var body: Polygon2D = $Body
@onready var left_eye: Polygon2D = $LeftEye
@onready var right_eye: Polygon2D = $RightEye
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var name_label: Label = $Label
@onready var hp_bar: ProgressBar = $HPBar
@onready var detection_shape: CollisionShape2D = $DetectionArea/DetectionShape
func _ready() -> void:
	_apply_unit_config()
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
	if movement_mode == "open_field":
		_process_open_field(delta)
		move_and_slide()
		return
	if state == UnitState.ATTACKING:
		_process_lane_path_attack()
		return
	_follow_path(delta)
	if is_dead:
		return
	_check_for_enemy()
	move_and_slide()
func setup_unit(new_player_id: int, new_unit_type: String, new_path_points: Array[Vector2]) -> void:
	player_id = new_player_id
	unit_type = new_unit_type
	movement_mode = "lane_path"
	path_points = new_path_points.duplicate()
	path_index = 0
	is_dead = false
	state = UnitState.MARCHING
	_apply_unit_config()
	current_hp = max_hp
	attack_timer = 0.0
	retarget_timer = 0.0
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
func setup_open_field(new_player_id: int, new_unit_type: String, spawn_position: Vector2, new_objective_player_id: int = -1) -> void:
	player_id = new_player_id
	unit_type = new_unit_type
	movement_mode = "open_field"
	objective_player_id = new_objective_player_id
	path_points.clear()
	path_index = 0
	is_dead = false
	state = UnitState.SEEKING
	_apply_unit_config()
	current_hp = max_hp
	attack_timer = 0.0
	retarget_timer = 0.0
	current_target = null
	global_position = spawn_position
	velocity = Vector2.ZERO
	set_physics_process(true)
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
	set_physics_process(false)
	EventBus.unit_died.emit(self, killer_player_id)
	call_deferred("_fallback_hide_if_not_pooled")
func _follow_path(_delta: float) -> void:
	if path_points.is_empty() or path_index >= path_points.size():
		velocity = Vector2.ZERO
		_reach_base()
		return
	var target_position: Vector2 = path_points[path_index]
	var to_target: Vector2 = target_position - global_position
	if to_target.length() < GameConfig.unit_waypoint_distance:
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
func _process_lane_path_attack() -> void:
	var target_unit := current_target as Unit
	if not _is_valid_enemy(target_unit):
		current_target = null
		state = UnitState.MARCHING
		return
	if global_position.distance_to(target_unit.global_position) > attack_range:
		current_target = null
		state = UnitState.MARCHING
		return
	if attack_timer <= 0.0:
		attack_timer = attack_cooldown
		_perform_attack_feedback(target_unit)
		target_unit.take_damage(damage, player_id)
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
func _process_open_field(delta: float) -> void:
	if state == UnitState.SPAWNING:
		state = UnitState.SEEKING
	retarget_timer = maxf(retarget_timer - delta, 0.0)
	if not _is_valid_open_field_target(current_target) or retarget_timer <= 0.0:
		_retarget_open_field()
	if current_target == null:
		state = UnitState.SEEKING
		_move_to_fallback_objective()
		return
	var distance := _distance_to_target(current_target)
	if state == UnitState.ATTACKING and distance > attack_range:
		state = UnitState.CHASING
	if distance <= attack_range:
		state = UnitState.ATTACKING
		velocity = _get_separation_force().limit_length(move_speed * 0.35)
		_attack_current_target()
		return
	state = UnitState.CHASING
	_move_toward_target(current_target)
func _retarget_open_field() -> void:
	retarget_timer = retarget_interval
	var next_target := _select_open_field_target()
	current_target = next_target
func _select_open_field_target() -> Node:
	match target_priority:
		"nearest_castle", "objective_castle":
			var castle := _find_enemy_castle_target()
			if castle != null:
				return castle
			return _find_enemy_unit_target()
		"any_nearest_enemy":
			return _find_nearest_enemy_target()
		_:
			var unit := _find_enemy_unit_target()
			if unit != null and prefer_units_over_castle:
				return unit
			var castle := _find_enemy_castle_target()
			return castle if castle != null else unit
func _find_enemy_unit_target() -> Unit:
	var best_unit: Unit = null
	var best_score := INF
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if not _is_valid_enemy_unit(unit):
			continue
		var distance := global_position.distance_to(unit.global_position)
		if distance > detection_range:
			continue
		var score := distance
		match target_priority:
			"lowest_hp_unit":
				score = unit.current_hp * 1000.0 + distance
			"toughest_unit":
				score = -unit.current_hp * 1000.0 + distance
			_:
				score = distance
		if score < best_score:
			best_score = score
			best_unit = unit
	return best_unit
func _find_enemy_castle_target() -> Node:
	var objective_castle := _get_castle_for_player(objective_player_id)
	if target_priority == "objective_castle" and _is_valid_enemy_castle(objective_castle):
		return objective_castle
	var best_castle: Node = null
	var best_score := INF
	for castle in get_tree().get_nodes_in_group("castles"):
		if not _is_valid_enemy_castle(castle):
			continue
		var distance := global_position.distance_to(castle.global_position)
		var score := distance
		if int(castle.get("player_id")) == objective_player_id:
			score *= 0.5
		if score < best_score:
			best_score = score
			best_castle = castle
	return best_castle
func _find_nearest_enemy_target() -> Node:
	var best_target: Node = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if not _is_valid_enemy_unit(unit):
			continue
		var distance := global_position.distance_to(unit.global_position)
		if distance <= detection_range and distance < best_distance:
			best_distance = distance
			best_target = unit
	for castle in get_tree().get_nodes_in_group("castles"):
		if not _is_valid_enemy_castle(castle):
			continue
		var distance := global_position.distance_to(castle.global_position)
		if distance < best_distance:
			best_distance = distance
			best_target = castle
	return best_target
func _move_toward_target(target: Node) -> void:
	var target_position: Vector2 = target.global_position
	var to_target: Vector2 = target_position - global_position
	var distance: float = to_target.length()
	var desired_velocity := Vector2.ZERO
	if distance > maxf(hold_distance, attack_range * 0.8):
		desired_velocity = to_target.normalized() * move_speed
	desired_velocity += _get_separation_force()
	desired_velocity += _get_bounds_force()
	velocity = desired_velocity.limit_length(move_speed)
	if velocity.length() > 0.1:
		rotation = velocity.angle()
func _move_to_fallback_objective() -> void:
	var castle := _find_enemy_castle_target()
	if castle != null:
		current_target = castle
		state = UnitState.CHASING
		_move_toward_target(castle)
		return
	var game_map := get_tree().get_first_node_in_group("game_maps")
	var fallback_position := Vector2.ZERO
	if game_map != null and game_map.has_method("get_center_position"):
		fallback_position = game_map.call("get_center_position")
	else:
		fallback_position = global_position
	var to_fallback := fallback_position - global_position
	velocity = (to_fallback.normalized() * move_speed + _get_separation_force() + _get_bounds_force()).limit_length(move_speed) if to_fallback.length() > 1.0 else Vector2.ZERO
	if velocity.length() > 0.1:
		rotation = velocity.angle()
func _attack_current_target() -> void:
	if attack_timer > 0.0 or not _is_valid_open_field_target(current_target):
		return
	attack_timer = attack_cooldown
	_perform_attack_feedback(current_target)
	var unit := current_target as Unit
	if unit != null:
		unit.take_damage(damage, player_id)
		return
	if current_target.has_method("take_damage"):
		var multiplier := GameConfig.get_auto_battle_value("castle_unit_damage_multiplier", 1.0)
		current_target.call("take_damage", damage * multiplier, player_id)
func _perform_attack_feedback(target: Node) -> void:
	if target == null:
		return
	EventBus.unit_attack_performed.emit(self, target, attack_style)
	match attack_style:
		"arrow_shot", "rapid_fire", "magic_bolt":
			_spawn_attack_line(target)
		"heavy_slam", "heavy_body_hit":
			_spawn_attack_impact(target, 1.35)
		"quick_stab":
			_spawn_attack_line(target)
			_spawn_attack_impact(target, 0.75)
		_:
			_spawn_attack_impact(target, 1.0)
func _spawn_attack_line(target: Node) -> void:
	var effect_parent := _get_effect_parent()
	var line := Line2D.new()
	line.width = _get_attack_line_width()
	line.default_color = _get_attack_color()
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.add_point(effect_parent.to_local(global_position))
	line.add_point(effect_parent.to_local(target.global_position))
	effect_parent.add_child(line)
	var tween := get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, _get_attack_effect_duration())
	tween.tween_callback(line.queue_free)
func _spawn_attack_impact(target: Node, scale_multiplier: float) -> void:
	var effect_parent := _get_effect_parent()
	var impact := Polygon2D.new()
	impact.polygon = _make_circle_polygon(maxf(visual_radius * 0.35 * scale_multiplier, 4.0), 16)
	impact.color = _get_attack_color()
	impact.position = effect_parent.to_local(target.global_position)
	effect_parent.add_child(impact)
	var tween := get_tree().create_tween()
	tween.tween_property(impact, "scale", Vector2.ONE * (1.0 + scale_multiplier * 0.55), _get_attack_effect_duration())
	tween.parallel().tween_property(impact, "modulate:a", 0.0, _get_attack_effect_duration())
	tween.tween_callback(impact.queue_free)
func _get_effect_parent() -> Node2D:
	var game_map := get_tree().get_first_node_in_group("game_maps")
	if game_map != null:
		var projectiles := game_map.get_node_or_null("Projectiles") as Node2D
		if projectiles != null:
			return projectiles
	var parent := get_parent() as Node2D
	return parent if parent != null else self
func _get_attack_color() -> Color:
	match attack_style:
		"arrow_shot":
			return Color("#F4D03F")
		"rapid_fire":
			return Color("#F8F9F9")
		"magic_bolt":
			return Color("#8E44AD")
		"heavy_slam", "heavy_body_hit":
			return Color("#E67E22")
		"quick_stab":
			return Color("#2ECC71")
		"steady_slash":
			return Color("#BDC3C7")
		_:
			return GameConfig.get_player_color(player_id).lightened(0.35)
func _get_attack_line_width() -> float:
	match attack_style:
		"rapid_fire":
			return 2.0
		"magic_bolt":
			return 5.0
		"arrow_shot":
			return 3.0
		"quick_stab":
			return 2.5
		_:
			return 4.0
func _get_attack_effect_duration() -> float:
	match attack_style:
		"rapid_fire", "quick_stab":
			return 0.12
		"heavy_slam", "heavy_body_hit":
			return 0.22
		"magic_bolt":
			return 0.18
		_:
			return 0.15
func _get_separation_force() -> Vector2:
	if separation_radius <= 0.0 or separation_strength <= 0.0:
		return Vector2.ZERO
	var force := Vector2.ZERO
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit == null or unit == self or unit.is_dead or unit.player_id != player_id:
			continue
		var offset := global_position - unit.global_position
		var distance := offset.length()
		if distance <= 0.01 or distance >= separation_radius:
			continue
		force += offset.normalized() * ((separation_radius - distance) / separation_radius) * move_speed * separation_strength
	return force
func _get_bounds_force() -> Vector2:
	var game_map := get_tree().get_first_node_in_group("game_maps")
	if game_map == null or not game_map.has_method("get_map_rect"):
		return Vector2.ZERO
	var rect: Rect2 = game_map.call("get_map_rect")
	var padding := 8.0
	var force := Vector2.ZERO
	if global_position.x < rect.position.x + padding:
		force.x += move_speed
	elif global_position.x > rect.end.x - padding:
		force.x -= move_speed
	if global_position.y < rect.position.y + padding:
		force.y += move_speed
	elif global_position.y > rect.end.y - padding:
		force.y -= move_speed
	return force
func _distance_to_target(target: Node) -> float:
	if target == null:
		return INF
	return global_position.distance_to(target.global_position)
func _is_valid_open_field_target(target: Node) -> bool:
	var unit := target as Unit
	if unit != null:
		if not _is_valid_enemy_unit(unit):
			return false
		return global_position.distance_to(unit.global_position) <= chase_range
	return _is_valid_enemy_castle(target)
func _is_valid_enemy_unit(unit: Unit) -> bool:
	if unit == null or unit == self:
		return false
	return not unit.is_dead and unit.player_id != player_id
func _is_valid_enemy_castle(castle: Node) -> bool:
	if castle == null:
		return false
	if not castle.is_in_group("castles"):
		return false
	if int(castle.get("player_id")) == player_id:
		return false
	return not bool(castle.get("is_destroyed"))
func _get_castle_for_player(target_player_id: int) -> Node:
	if target_player_id < 0:
		return null
	for castle in get_tree().get_nodes_in_group("castles"):
		if int(castle.get("player_id")) == target_player_id:
			return castle
	return null
func _reach_base() -> void:
	is_dead = true
	state = UnitState.DEAD
	velocity = Vector2.ZERO
	set_physics_process(false)
	EventBus.unit_reached_castle.emit(self, _find_nearest_enemy_base())
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
	body.polygon = _make_circle_polygon(visual_radius, 24)
	left_eye.polygon = _make_circle_polygon(maxf(visual_radius * 0.16, 2.2), 12)
	left_eye.position = Vector2(visual_radius * 0.32, -visual_radius * 0.28)
	left_eye.color = Color.WHITE
	right_eye.polygon = _make_circle_polygon(maxf(visual_radius * 0.16, 2.2), 12)
	right_eye.position = Vector2(visual_radius * 0.32, visual_radius * 0.28)
	right_eye.color = Color.WHITE
	name_label.position = Vector2(-30.0, visual_radius + 3.0)
	name_label.size = Vector2(60.0, 14.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 8)
func _setup_collision() -> void:
	collision_layer = 1 if GameConfig.unit_body_collision_enabled else 0
	collision_mask = 1 if GameConfig.unit_body_collision_enabled else 0
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = collision_radius
	collision_shape.shape = circle_shape
	var detection_circle := CircleShape2D.new()
	detection_circle.radius = maxf(attack_range, detection_range)
	detection_shape.shape = detection_circle
func _apply_player_color() -> void:
	body.color = GameConfig.get_player_color(player_id)
func _apply_unit_config() -> void:
	var config := GameConfig.get_unit_config(unit_type)
	var behavior := GameConfig.get_unit_behavior_config(unit_type)
	max_hp = float(config.get("hp", max_hp))
	damage = float(config.get("damage", damage))
	move_speed = float(config.get("speed", move_speed))
	attack_range = float(config.get("range", attack_range))
	attack_cooldown = float(config.get("cooldown", attack_cooldown))
	visual_radius = float(config.get("visual_radius", visual_radius))
	collision_radius = float(config.get("collision_radius", maxf(visual_radius * 0.6, 4.0)))
	role = String(behavior.get("role", role))
	attack_style = String(behavior.get("attack_style", attack_style))
	target_priority = String(behavior.get("target_priority", target_priority))
	prefer_units_over_castle = bool(behavior.get("prefer_units_over_castle", prefer_units_over_castle))
	detection_range = float(behavior.get("detection_range", detection_range))
	chase_range = float(behavior.get("chase_range", chase_range))
	retarget_interval = float(behavior.get("retarget_interval", retarget_interval))
	hold_distance = float(behavior.get("hold_distance", hold_distance))
	separation_radius = float(behavior.get("separation_radius", separation_radius))
	separation_strength = float(behavior.get("separation_strength", separation_strength))
	castle_aggression = float(behavior.get("castle_aggression", castle_aggression))
	low_hp_focus = float(behavior.get("low_hp_focus", low_hp_focus))
	frontline_bias = float(behavior.get("frontline_bias", frontline_bias))
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
