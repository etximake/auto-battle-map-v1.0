extends Node

@export var min_round_ends: int = 1

var round_starts: int = 0
var round_ends: int = 0

func _ready() -> void:
	GameState.round_started.connect(_on_round_started)
	GameState.round_ended.connect(_on_round_ended)

func _on_round_started(round_number: int) -> void:
	round_starts += 1
	print("ROUND_TEST started=%d round=%d" % [round_starts, round_number])

func _on_round_ended(results: Dictionary) -> void:
	round_ends += 1
	print("ROUND_TEST ended=%d scores=%s hp=%s" % [round_ends, str(results.get("scores", {})), str(_get_castle_hp())])
	if round_ends >= min_round_ends:
		print("ROUND_TEST_PASS")

func _get_castle_hp() -> Dictionary:
	var hp: Dictionary = {}
	for castle in get_tree().get_nodes_in_group("castles"):
		hp[int(castle.get("player_id"))] = int(round(float(castle.get("current_hp"))))
	return hp
