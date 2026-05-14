extends Node

enum State {
	IDLE,
	ROUND_ACTIVE,
	ROUND_END,
	SESSION_END,
}

signal state_changed(new_state: State)
signal round_started(round_number: int)
signal round_ended(results: Dictionary)

var current_state: State = State.IDLE
var current_round: int = 0
var session_scores: Dictionary = {}


func change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	state_changed.emit(new_state)


func start_round(round_number: int) -> void:
	current_round = round_number
	change_state(State.ROUND_ACTIVE)
	round_started.emit(round_number)


func end_round(results: Dictionary) -> void:
	change_state(State.ROUND_END)
	round_ended.emit(results)


func end_session() -> void:
	change_state(State.SESSION_END)


func reset() -> void:
	current_round = 0
	session_scores.clear()
	change_state(State.IDLE)
