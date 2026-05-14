extends Node

const UNIT_SCENES := {
	"Scout": preload("res://scenes/units/Scout.tscn"),
	"Soldier": preload("res://scenes/units/Soldier.tscn"),
	"Tank": preload("res://scenes/units/Tank.tscn"),
	"Mage": preload("res://scenes/units/Mage.tscn"),
}

@export var game_map_path: NodePath
@export var units_container_path: NodePath
@export var max_units_per_player: int = 30
@export var prewarm_per_type: int = 4

var unit_pool: Dictionary = {}
var active_units: Array[Node] = []


func _ready() -> void:
	EventBus.round_reset_requested.connect(clear_all_units)
	EventBus.unit_died.connect(_on_unit_removed)
	EventBus.unit_reached_base.connect(_on_unit_reached_base)
	_init_pool()


func spawn_unit(player_id: int, unit_type: String) -> Node:
	if _count_player_units(player_id) >= max_units_per_player:
		return null

	if not UNIT_SCENES.has(unit_type):
		push_error("Unknown unit type: %s" % unit_type)
		return null

	var unit: Node = _get_unit(unit_type)
	var unit_path := _get_path_for_player(player_id)
	if unit_path.is_empty():
		push_error("No march path for player %d." % player_id)
		return null

	_activate_unit(unit, player_id, unit_type, unit_path)
	EventBus.unit_spawned.emit(unit, player_id)
	return unit


func return_to_pool(unit: Node) -> void:
	if unit == null:
		return
	if not active_units.has(unit):
		return

	active_units.erase(unit)
	unit.remove_from_group("units")
	unit.hide()
	unit.process_mode = Node.PROCESS_MODE_DISABLED
	var unit_type := String(unit.get("unit_type"))
	if unit_pool.has(unit_type):
		unit_pool[unit_type].append(unit)


func clear_all_units() -> void:
	for unit in active_units.duplicate():
		return_to_pool(unit)
	active_units.clear()


func get_active_unit_count() -> int:
	return active_units.size()


func get_player_unit_count(player_id: int) -> int:
	return _count_player_units(player_id)


func _init_pool() -> void:
	for unit_type in UNIT_SCENES.keys():
		unit_pool[unit_type] = []
		for _index in prewarm_per_type:
			var unit: Node = UNIT_SCENES[unit_type].instantiate()
			_get_units_container().add_child(unit)
			unit.hide()
			unit.process_mode = Node.PROCESS_MODE_DISABLED
			unit_pool[unit_type].append(unit)


func _get_unit(unit_type: String) -> Node:
	if unit_pool[unit_type].size() > 0:
		return unit_pool[unit_type].pop_back()

	var unit: Node = UNIT_SCENES[unit_type].instantiate()
	_get_units_container().add_child(unit)
	return unit


func _activate_unit(unit: Node, player_id: int, unit_type: String, unit_path: Array[Vector2]) -> void:
	unit.process_mode = Node.PROCESS_MODE_INHERIT
	unit.show()
	unit.add_to_group("units")
	active_units.append(unit)
	unit.setup_unit(player_id, unit_type, unit_path)


func _get_path_for_player(player_id: int) -> Array[Vector2]:
	var game_map := get_node_or_null(game_map_path)
	if game_map == null or not game_map.has_method("get_march_path"):
		return []

	var unit_path: Array[Vector2] = []
	unit_path.assign(game_map.get_march_path(player_id))
	return unit_path


func _get_units_container() -> Node:
	var units_container := get_node_or_null(units_container_path)
	if units_container != null:
		return units_container

	return self


func _count_player_units(player_id: int) -> int:
	var count := 0
	for unit in active_units:
		if is_instance_valid(unit) and int(unit.get("player_id")) == player_id:
			count += 1

	return count


func _on_unit_removed(unit: Node, _killer_player_id: int) -> void:
	return_to_pool(unit)


func _on_unit_reached_base(unit: Node, _target_base: Node) -> void:
	return_to_pool(unit)
