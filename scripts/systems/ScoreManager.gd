extends Node

var scores: Dictionary = {}
var kill_counts: Dictionary = {}
var castle_damage: Dictionary = {}

func _ready() -> void:
	add_to_group("score_managers")
	_reset_scores()
	EventBus.round_reset_requested.connect(_reset_scores)
	EventBus.unit_died.connect(_on_unit_died)
	EventBus.castle_damaged.connect(_on_castle_damaged)
	EventBus.castle_destroyed.connect(_on_castle_destroyed)

func get_score(player_id: int) -> int:
	return int(scores.get(player_id, 0))

func get_scores() -> Dictionary:
	return scores.duplicate()

func get_summary() -> Dictionary:
	return {
		"scores": scores.duplicate(),
		"kills": kill_counts.duplicate(),
		"castle_damage": castle_damage.duplicate(),
	}

func _reset_scores() -> void:
	scores.clear()
	kill_counts.clear()
	castle_damage.clear()
	for player_id in range(GameConfig.get_player_count()):
		scores[player_id] = 0
		kill_counts[player_id] = 0
		castle_damage[player_id] = 0.0
		EventBus.score_changed.emit(player_id, 0)

func _on_unit_died(unit: Node, killer_player_id: int) -> void:
	if killer_player_id < 0:
		return
	if int(unit.get("player_id")) == killer_player_id:
		return
	kill_counts[killer_player_id] = int(kill_counts.get(killer_player_id, 0)) + 1
	_award_score(killer_player_id, _get_int_value("unit_kill_score", 5), "unit_kill")

func _on_castle_damaged(_castle: Node, amount: float, attacker_player: int) -> void:
	if attacker_player < 0:
		return
	castle_damage[attacker_player] = float(castle_damage.get(attacker_player, 0.0)) + amount
	var score := int(round(amount * GameConfig.get_auto_battle_value("castle_damage_score_per_point", 0.1)))
	_award_score(attacker_player, maxi(score, 1), "castle_damage")

func _on_castle_destroyed(castle: Node) -> void:
	var owner_id := int(castle.get("player_id"))
	var attacker_id := int(castle.get("last_attacker_player"))
	if attacker_id >= 0 and attacker_id != owner_id:
		_award_score(attacker_id, _get_int_value("castle_destroy_score", 50), "castle_destroy")

func _award_score(player_id: int, amount: int, reason: String) -> void:
	if amount <= 0:
		return
	scores[player_id] = int(scores.get(player_id, 0)) + amount
	GameState.session_scores = scores.duplicate()
	EventBus.score_awarded.emit(player_id, amount, reason)
	EventBus.score_changed.emit(player_id, int(scores[player_id]))

func _get_int_value(key: String, fallback: int) -> int:
	return int(round(GameConfig.get_auto_battle_value(key, float(fallback))))
