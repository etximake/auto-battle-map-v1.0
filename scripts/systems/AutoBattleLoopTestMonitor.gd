extends Node

@export var report_delay: float = 12.0
@export var seed_player_id: int = 0
@export var seed_rewards: Array[String] = ["Scout", "Soldier", "Mage", "Tank"]

var elapsed_time: float = 0.0
var reported: bool = false
var castle_damage_events: int = 0
var score_events: int = 0
var death_events: int = 0

func _ready() -> void:
	EventBus.castle_damaged.connect(_on_castle_damaged)
	EventBus.score_awarded.connect(_on_score_awarded)
	EventBus.unit_died.connect(_on_unit_died)
	call_deferred("_seed_castles")

func _process(delta: float) -> void:
	if reported:
		return
	elapsed_time += delta
	if elapsed_time < report_delay:
		return
	reported = true
	_print_summary()

func _on_castle_damaged(_castle: Node, _amount: float, _attacker_player: int) -> void:
	castle_damage_events += 1

func _on_score_awarded(_player_id: int, _amount: int, _reason: String) -> void:
	score_events += 1

func _on_unit_died(_unit: Node, _killer_player_id: int) -> void:
	death_events += 1

func _print_summary() -> void:
	var score_manager := get_tree().get_first_node_in_group("score_managers")
	var scores := {}
	if score_manager != null and score_manager.has_method("get_scores"):
		scores = score_manager.call("get_scores")
	print("AUTO_BATTLE_TEST damage_events=%d death_events=%d score_events=%d scores=%s" % [
		castle_damage_events,
		death_events,
		score_events,
		str(scores),
	])

func _seed_castles() -> void:
	for castle in get_tree().get_nodes_in_group("castles"):
		if seed_player_id >= 0 and int(castle.get("player_id")) != seed_player_id:
			continue
		if not castle.has_method("queue_reward"):
			continue
		for reward_type in seed_rewards:
			castle.call("queue_reward", reward_type)
