extends Node

@export var auto_start: bool = true
@export var require_round_active: bool = false

var gold: Dictionary = {}


func _ready() -> void:
	EventBus.round_reset_requested.connect(reset_all)
	reset_all()


func _process(delta: float) -> void:
	if not _should_tick():
		return

	for player_id in range(GameConfig.get_player_count()):
		add_gold(player_id, GameConfig.gold_per_second * delta)


func reset_all() -> void:
	gold.clear()
	for player_id in range(GameConfig.get_player_count()):
		gold[player_id] = float(GameConfig.starting_gold)
		EventBus.gold_changed.emit(player_id, gold[player_id])


func add_gold(player_id: int, amount: float) -> void:
	var current_gold := get_gold(player_id)
	gold[player_id] = minf(current_gold + amount, float(GameConfig.gold_max))
	EventBus.gold_changed.emit(player_id, gold[player_id])


func spend_gold(player_id: int, amount: float) -> bool:
	var current_gold := get_gold(player_id)
	if current_gold < amount:
		return false

	gold[player_id] = current_gold - amount
	EventBus.gold_changed.emit(player_id, gold[player_id])
	return true


func get_gold(player_id: int) -> float:
	return float(gold.get(player_id, 0.0))


func _should_tick() -> bool:
	if not auto_start:
		return false

	if require_round_active and GameState.current_state != GameState.State.ROUND_ACTIVE:
		return false

	return true
