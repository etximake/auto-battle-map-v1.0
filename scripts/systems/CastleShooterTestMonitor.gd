extends Node

const SCOUT_SCENE := preload("res://scenes/units/Scout.tscn")

@export var report_delay: float = 4.0

var elapsed_time: float = 0.0
var reported: bool = false
var shot_events: int = 0
var same_team_shots: int = 0
var enemy_unit: Unit
var ally_unit: Unit
var enemy_start_hp: float = 0.0
var ally_start_hp: float = 0.0


func _ready() -> void:
	EventBus.castle_shot_fired.connect(_on_castle_shot_fired)
	call_deferred("_seed_units")


func _process(delta: float) -> void:
	if reported:
		return
	elapsed_time += delta
	if elapsed_time < report_delay:
		return
	reported = true
	_print_summary()


func _on_castle_shot_fired(castle: Node, target: Node) -> void:
	shot_events += 1
	if int(castle.get("player_id")) == int(target.get("player_id")):
		same_team_shots += 1


func _seed_units() -> void:
	var castle := _get_castle(0)
	var container := _get_unit_container()
	if castle == null or container == null:
		push_warning("CastleShooter test missing castle or unit container.")
		return

	enemy_unit = _spawn_stationary_unit(container, 1, castle.global_position + Vector2(78, 0))
	ally_unit = _spawn_stationary_unit(container, 0, castle.global_position + Vector2(0, 90))
	enemy_start_hp = enemy_unit.current_hp
	ally_start_hp = ally_unit.current_hp


func _spawn_stationary_unit(container: Node, player_id: int, spawn_position: Vector2) -> Unit:
	var unit := SCOUT_SCENE.instantiate() as Unit
	container.add_child(unit)
	unit.setup_unit(player_id, "Scout", [spawn_position, spawn_position + Vector2(200, 0)])
	unit.add_to_group("units")
	unit.move_speed = 0.0
	return unit


func _print_summary() -> void:
	var enemy_hp := _get_hp(enemy_unit)
	var ally_hp := _get_hp(ally_unit)
	print("CASTLE_SHOOTER_TEST shots=%d same_team_shots=%d enemy_hp %.1f->%.1f ally_hp %.1f->%.1f projectiles=%d" % [
		shot_events,
		same_team_shots,
		enemy_start_hp,
		enemy_hp,
		ally_start_hp,
		ally_hp,
		get_tree().get_nodes_in_group("projectiles").size(),
	])


func _get_castle(player_id: int) -> Node2D:
	for castle in get_tree().get_nodes_in_group("castles"):
		if int(castle.get("player_id")) == player_id:
			return castle as Node2D
	return null


func _get_unit_container() -> Node:
	var game_map := get_tree().get_first_node_in_group("game_maps")
	if game_map != null:
		var container := game_map.get_node_or_null("SpawnedUnits")
		if container != null:
			return container
	return self


func _get_hp(unit: Unit) -> float:
	if unit == null or not is_instance_valid(unit):
		return 0.0
	return unit.current_hp
