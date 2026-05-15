extends Node2D
class_name CastleShooter

const PROJECTILE_SCENE := preload("res://scenes/units/Projectile.tscn")

@export var shoot_range: float = 120.0
@export var shoot_damage: float = 10.0
@export var shoot_cooldown: float = 1.5
@export var projectile_speed: float = 300.0
@export var target_priority: String = "nearest"

var cooldown_timer: float = 0.0
var castle: Node2D

@onready var shoot_shape: CollisionShape2D = $ShootDetectionArea/CollisionShape2D


func _ready() -> void:
	castle = get_parent() as Node2D
	add_to_group("castle_shooters")
	EventBus.round_reset_requested.connect(_on_round_reset_requested)
	_apply_config()


func _process(delta: float) -> void:
	if not _can_shoot():
		return

	cooldown_timer = maxf(cooldown_timer - delta, 0.0)
	if cooldown_timer > 0.0:
		return

	var target := _select_target()
	if target == null:
		return

	if _spawn_projectile(target):
		cooldown_timer = shoot_cooldown


func _apply_config() -> void:
	shoot_range = GameConfig.castle_shoot_range
	shoot_damage = GameConfig.castle_shoot_damage
	shoot_cooldown = GameConfig.castle_shoot_cooldown
	projectile_speed = GameConfig.castle_projectile_speed
	target_priority = GameConfig.castle_target_priority
	_setup_detection_area()


func _setup_detection_area() -> void:
	if shoot_shape == null:
		return
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = shoot_range
	shoot_shape.shape = circle_shape


func _select_target() -> Unit:
	match target_priority:
		"lowest_hp":
			return _select_lowest_hp_target()
		"first_entered":
			return _select_first_target()
		_:
			return _select_nearest_target()


func _select_nearest_target() -> Unit:
	var best_target: Unit = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if not _is_valid_target(unit):
			continue
		var distance := castle.global_position.distance_to(unit.global_position)
		if distance < best_distance:
			best_distance = distance
			best_target = unit
	return best_target


func _select_lowest_hp_target() -> Unit:
	var best_target: Unit = null
	var best_hp := INF
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if not _is_valid_target(unit):
			continue
		if unit.current_hp < best_hp:
			best_hp = unit.current_hp
			best_target = unit
	return best_target


func _select_first_target() -> Unit:
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if _is_valid_target(unit):
			return unit
	return null


func _spawn_projectile(target: Unit) -> bool:
	if get_tree().get_nodes_in_group("projectiles").size() >= GameConfig.max_projectiles:
		return false

	var projectile := PROJECTILE_SCENE.instantiate() as Node2D
	_get_projectile_parent().add_child(projectile)
	projectile.global_position = castle.global_position
	if projectile.has_method("setup"):
		projectile.call("setup", int(castle.get("player_id")), target, shoot_damage, projectile_speed, _get_projectile_color())
	EventBus.castle_shot_fired.emit(castle, target)
	return true


func _get_projectile_parent() -> Node:
	var game_map := get_tree().get_first_node_in_group("game_maps")
	if game_map != null:
		var container := game_map.get_node_or_null("Projectiles")
		if container != null:
			return container
	return castle.get_parent()


func _get_projectile_color() -> Color:
	return GameConfig.get_player_color(int(castle.get("player_id"))).lightened(0.25)


func _is_valid_target(unit: Unit) -> bool:
	if unit == null or unit.is_dead:
		return false
	if int(unit.player_id) == int(castle.get("player_id")):
		return false
	return castle.global_position.distance_to(unit.global_position) <= shoot_range


func _can_shoot() -> bool:
	if castle == null or shoot_range <= 0.0 or shoot_damage <= 0.0:
		return false
	return not bool(castle.get("is_destroyed"))


func _on_round_reset_requested() -> void:
	cooldown_timer = 0.0
