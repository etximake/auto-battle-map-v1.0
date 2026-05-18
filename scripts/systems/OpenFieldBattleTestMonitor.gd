extends Node

# Integration monitor for the open-field base mode.
# Spawns dynamic AIControllers (no hardcoded N teams), seeds rewards, and
# verifies the open-field loop produces movement, combat, and castle damage.

const AI_SCRIPT := preload("res://scripts/players/AIController.gd")

@export var ai_root_path: NodePath
@export var spawn_manager_path: NodePath = NodePath("../SpawnManager")
@export var game_map_path: NodePath = NodePath("../../GameMap")
@export var report_delay: float = 18.0
@export var seed_rewards: Array[String] = ["Soldier", "Soldier", "Archer", "Mage"]
@export var seed_all_players: bool = true
@export var auto_seed: bool = true

var elapsed_time: float = 0.0
var reported: bool = false
var castle_damage_events: int = 0
var unit_spawn_events: int = 0
var unit_death_events: int = 0
var spawn_positions: Dictionary = {}
var movement_distances: Dictionary = {}


func _ready() -> void:
	EventBus.castle_damaged.connect(_on_castle_damaged)
	EventBus.unit_spawned.connect(_on_unit_spawned)
	EventBus.unit_died.connect(_on_unit_died)
	call_deferred("_setup_ai_controllers")
	if auto_seed:
		call_deferred("_seed_castles")


func _process(delta: float) -> void:
	if reported:
		return
	elapsed_time += delta
	_sample_unit_movement()
	if elapsed_time < report_delay:
		return
	reported = true
	_print_summary()


func _setup_ai_controllers() -> void:
	var ai_root := get_node_or_null(ai_root_path)
	if ai_root == null:
		push_warning("OpenFieldBattleTestMonitor: ai_root_path is not set or invalid.")
		return
	for child in ai_root.get_children():
		child.queue_free()
	var resolved_map_path := ai_root.get_path_to(get_node_or_null(game_map_path)) if get_node_or_null(game_map_path) != null else NodePath("")
	var resolved_spawn_path := ai_root.get_path_to(get_node_or_null(spawn_manager_path)) if get_node_or_null(spawn_manager_path) != null else NodePath("")
	for player_id in range(GameConfig.get_player_count()):
		var ai := Node.new()
		ai.name = "AI_%d" % player_id
		ai.set_script(AI_SCRIPT)
		ai.set("player_id", player_id)
		ai.set("strategy", GameConfig.get_ai_strategy(player_id))
		ai.set("game_map_path", resolved_map_path)
		ai.set("spawn_manager_path", resolved_spawn_path)
		ai_root.add_child(ai)


func _seed_castles() -> void:
	for castle in get_tree().get_nodes_in_group("castles"):
		if not seed_all_players and int(castle.get("player_id")) != 0:
			continue
		if not castle.has_method("queue_reward"):
			continue
		for reward_type in seed_rewards:
			castle.call("queue_reward", reward_type)


func _on_castle_damaged(_castle: Node, _amount: float, _attacker_player: int) -> void:
	castle_damage_events += 1


func _on_unit_spawned(unit: Node, _player_id: int) -> void:
	unit_spawn_events += 1
	if unit is Node2D:
		spawn_positions[unit.get_instance_id()] = (unit as Node2D).global_position
		movement_distances[unit.get_instance_id()] = 0.0


func _on_unit_died(_unit: Node, _killer_player_id: int) -> void:
	unit_death_events += 1


func _sample_unit_movement() -> void:
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Node2D
		if unit == null:
			continue
		var instance_id := unit.get_instance_id()
		if not spawn_positions.has(instance_id):
			spawn_positions[instance_id] = unit.global_position
			movement_distances[instance_id] = 0.0
			continue
		var distance := unit.global_position.distance_to(spawn_positions[instance_id])
		if distance > float(movement_distances.get(instance_id, 0.0)):
			movement_distances[instance_id] = distance


func _print_summary() -> void:
	var moved_count := 0
	for distance in movement_distances.values():
		if float(distance) > 32.0:
			moved_count += 1
	print("OPEN_FIELD_BATTLE_TEST players=%d spawns=%d deaths=%d castle_damage_events=%d moved_units=%d" % [
		GameConfig.get_player_count(),
		unit_spawn_events,
		unit_death_events,
		castle_damage_events,
		moved_count,
	])
