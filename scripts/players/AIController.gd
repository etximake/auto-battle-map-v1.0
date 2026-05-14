extends Node

const UNIT_COSTS := {
	"Scout": 5.0,
	"Soldier": 10.0,
	"Mage": 15.0,
	"Tank": 20.0,
}

@export var player_id: int = 0
@export var strategy: String = "BALANCED"
@export var think_interval: float = 0.5
@export var active: bool = true
@export var resource_manager_path: NodePath
@export var spawn_manager_path: NodePath

var think_timer: float = 0.0
var balanced_index: int = 0


func _process(delta: float) -> void:
	if not active:
		return

	think_timer += delta
	if think_timer < think_interval:
		return

	think_timer = 0.0
	think()


func think() -> void:
	match strategy:
		"AGGRESSIVE":
			_strategy_aggressive()
		"ECONOMY":
			_strategy_economy()
		"ADAPTIVE":
			_strategy_adaptive()
		_:
			_strategy_balanced()


func _strategy_aggressive() -> void:
	_buy_unit("Scout")


func _strategy_balanced() -> void:
	var order := ["Scout", "Soldier", "Mage", "Soldier"]
	for offset in order.size():
		var unit_type: String = order[(balanced_index + offset) % order.size()]
		if _buy_unit(unit_type):
			balanced_index = (balanced_index + offset + 1) % order.size()
			return


func _strategy_economy() -> void:
	if not _buy_unit("Tank"):
		_buy_unit("Mage")


func _strategy_adaptive() -> void:
	var spawn_manager := _get_spawn_manager()
	if spawn_manager == null:
		return

	var my_units: int = spawn_manager.get_player_unit_count(player_id)
	if my_units < 3:
		_strategy_aggressive()
	elif my_units < 8:
		_strategy_balanced()
	else:
		_strategy_economy()


func _buy_unit(unit_type: String) -> bool:
	var resource_manager := _get_resource_manager()
	var spawn_manager := _get_spawn_manager()
	if resource_manager == null or spawn_manager == null:
		return false

	var cost: float = UNIT_COSTS[unit_type]
	if not resource_manager.spend_gold(player_id, cost):
		return false

	var unit: Node = spawn_manager.spawn_unit(player_id, unit_type)
	if unit == null:
		resource_manager.add_gold(player_id, cost)
		return false

	return true


func _get_resource_manager() -> Node:
	return get_node_or_null(resource_manager_path)


func _get_spawn_manager() -> Node:
	return get_node_or_null(spawn_manager_path)
