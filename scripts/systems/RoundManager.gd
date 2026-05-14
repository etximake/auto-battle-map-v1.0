extends Node

@export var auto_start: bool = true
@export var round_duration_override: float = -1.0
@export var restart_delay: float = 3.0

var time_left: float = 0.0
var is_running: bool = false

func _ready() -> void:
	add_to_group("round_managers")
	Engine.time_scale = GameConfig.time_scale
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
	var score_manager := get_tree().get_first_node_in_group("score_managers")
	if score_manager != null and score_manager.has_method("get_summary"):
		return score_manager.call("get_summary")
	return {"scores": GameState.session_scores.duplicate()}

func _get_round_duration() -> float:
	if round_duration_override > 0.0:
		return round_duration_override
	return GameConfig.round_duration
