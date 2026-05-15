extends Node

@export var auto_start: bool = true
@export var round_duration_override: float = -1.0
@export var restart_delay: float = 3.0

var time_left: float = 0.0
var is_running: bool = false

func _ready() -> void:
	add_to_group("round_managers")
	Engine.time_scale = GameConfig.time_scale
	EventBus.castle_destroyed.connect(_on_castle_destroyed)
	if auto_start:
		call_deferred("start_next_round")

func _process(delta: float) -> void:
	if not is_running:
		return
	time_left = maxf(time_left - delta, 0.0)
	if time_left <= 0.0:
		_end_current_round()

func start_next_round() -> void:
	if GameConfig.rounds_per_session > 0 and GameState.current_round >= GameConfig.rounds_per_session:
		GameState.end_session()
		is_running = false
		return
	EventBus.round_reset_requested.emit()
	time_left = _get_round_duration()
	is_running = true
	GameState.start_round(GameState.current_round + 1)

func get_time_left() -> float:
	return time_left

func get_round_duration() -> float:
	return _get_round_duration()

func _end_current_round() -> void:
	if not is_running:
		return
	is_running = false
	var results := _build_results()
	GameState.end_round(results)
	if GameConfig.auto_restart:
		_restart_after_delay()

func _restart_after_delay() -> void:
	await get_tree().create_timer(restart_delay).timeout
	if GameState.current_state == GameState.State.ROUND_END:
		start_next_round()

func _build_results() -> Dictionary:
	var alive_players := _get_alive_player_ids()
	var winner_id := alive_players[0] if alive_players.size() == 1 else -1
	var score_manager := get_tree().get_first_node_in_group("score_managers")
	if score_manager != null and score_manager.has_method("get_summary"):
		var summary: Dictionary = score_manager.call("get_summary")
		summary["alive_players"] = alive_players
		summary["winner_player_id"] = winner_id
		return summary
	return {"scores": GameState.session_scores.duplicate(), "alive_players": alive_players, "winner_player_id": winner_id}

func _get_round_duration() -> float:
	if round_duration_override > 0.0:
		return round_duration_override
	return GameConfig.round_duration

func _on_castle_destroyed(_castle: Node) -> void:
	if is_running and _get_alive_player_ids().size() <= 1:
		_end_current_round()

func _get_alive_player_ids() -> Array[int]:
	var alive: Array[int] = []
	for player_id in range(GameConfig.get_player_count()):
		if _is_player_alive(player_id):
			alive.append(player_id)
	return alive

func _is_player_alive(player_id: int) -> bool:
	for castle in get_tree().get_nodes_in_group("castles"):
		if int(castle.get("player_id")) == player_id:
			return not bool(castle.get("is_destroyed"))
	return false
