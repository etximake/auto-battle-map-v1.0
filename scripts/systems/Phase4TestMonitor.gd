extends Node

@export var resource_manager_path: NodePath
@export var spawn_manager_path: NodePath
@export var check_delay: float = 2.0

var elapsed_time: float = 0.0
var has_checked: bool = false


func _process(delta: float) -> void:
	if has_checked:
		return

	elapsed_time += delta
	if elapsed_time < check_delay:
		return

	has_checked = true
	set_process(false)

	var resource_manager := get_node_or_null(resource_manager_path)
	var spawn_manager := get_node_or_null(spawn_manager_path)
	if resource_manager == null or spawn_manager == null:
		push_error("Phase4TestMonitor missing managers.")
		return

	var active_units: int = spawn_manager.get_active_unit_count()
	var gold_values: Array[float] = []
	for player_id in range(GameConfig.player_count):
		gold_values.append(resource_manager.get_gold(player_id))

	if active_units <= 0:
		push_error("Phase 4 test failed: no units spawned.")
		return

	print("PHASE4_TEST active_units=%d gold=%s" % [active_units, str(gold_values)])
