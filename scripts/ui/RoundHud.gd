extends Control

@export var round_manager_path: NodePath
@export var score_manager_path: NodePath

@onready var status_label: Label = $StatusLabel
@onready var score_label: Label = $ScoreLabel
@onready var castle_label: Label = $CastleLabel
@onready var result_label: Label = $ResultLabel

func _ready() -> void:
	GameState.round_started.connect(_on_round_started)
	GameState.round_ended.connect(_on_round_ended)
	result_label.hide()
	_setup_labels()

func _process(_delta: float) -> void:
	_update_status()
	_update_scores()
	_update_castles()

func _setup_labels() -> void:
	for label in [status_label, score_label, castle_label, result_label]:
		label.add_theme_font_size_override("font_size", 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 20)
	result_label.add_theme_font_size_override("font_size", 22)

func _update_status() -> void:
	var manager := _get_round_manager()
	var time_left := 0.0
	if manager != null and manager.has_method("get_time_left"):
		time_left = float(manager.call("get_time_left"))
	status_label.text = "Round %d  %02d:%02d" % [
		GameState.current_round,
		int(time_left) / 60,
		int(time_left) % 60,
	]

func _update_scores() -> void:
	var scores := _get_scores()
	var parts: Array[String] = []
	for player_id in GameConfig.player_count:
		parts.append("P%d:%d" % [player_id, int(scores.get(player_id, 0))])
	score_label.text = "Score  " + "  ".join(parts)

func _update_castles() -> void:
	var parts: Array[String] = []
	for castle in get_tree().get_nodes_in_group("castles"):
		var player_id := int(castle.get("player_id"))
		var hp := int(round(float(castle.get("current_hp"))))
		parts.append("P%d HP:%d" % [player_id, hp])
	castle_label.text = "Castle  " + "  ".join(parts)

func _on_round_started(_round_number: int) -> void:
	result_label.hide()

func _on_round_ended(results: Dictionary) -> void:
	var scores: Dictionary = results.get("scores", {})
	var winner := _get_winner(scores)
	result_label.text = "Round End  Winner P%d" % winner
	result_label.show()

func _get_round_manager() -> Node:
	if round_manager_path != NodePath(""):
		return get_node_or_null(round_manager_path)
	return get_tree().get_first_node_in_group("round_managers")

func _get_scores() -> Dictionary:
	var score_manager := get_node_or_null(score_manager_path)
	if score_manager != null and score_manager.has_method("get_scores"):
		return score_manager.call("get_scores")
	return GameState.session_scores

func _get_winner(scores: Dictionary) -> int:
	var winner := 0
	var best_score := -1
	for player_id in GameConfig.player_count:
		var score := int(scores.get(player_id, 0))
		if score > best_score:
			best_score = score
			winner = player_id
	return winner
