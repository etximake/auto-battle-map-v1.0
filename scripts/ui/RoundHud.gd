extends Control

@export var round_manager_path: NodePath
@export var score_manager_path: NodePath

var team_rows: Dictionary = {}
var rows_root: Control

@onready var status_label: Label = $StatusLabel
@onready var score_label: Label = $ScoreLabel
@onready var castle_label: Label = $CastleLabel
@onready var result_label: Label = $ResultLabel

func _ready() -> void:
	GameState.round_started.connect(_on_round_started)
	GameState.round_ended.connect(_on_round_ended)
	EventBus.round_reset_requested.connect(_on_round_reset_requested)
	_setup_static_labels()
	_setup_rows_root()
	_rebuild_team_rows()
	_update_layout()
	result_label.hide()

func _process(_delta: float) -> void:
	if team_rows.size() != GameConfig.get_player_count():
		_rebuild_team_rows()
		_update_layout()
	_update_status()
	_update_team_rows()

func _setup_static_labels() -> void:
	for label in [status_label, result_label]:
		label.add_theme_font_size_override("font_size", 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 20)
	result_label.add_theme_font_size_override("font_size", 22)
	score_label.hide()
	castle_label.hide()

func _setup_rows_root() -> void:
	rows_root = Control.new()
	rows_root.name = "TeamRows"
	add_child(rows_root)

func _update_layout() -> void:
	var resolution := GameConfig.get_resolution()
	var hud_width := GameConfig.hud_width
	var row_height := GameConfig.hud_team_row_height
	var row_top := 30.0
	position = Vector2((resolution.x - hud_width) * 0.5, 0.0)
	size = Vector2(hud_width, row_top + row_height * float(GameConfig.get_player_count()) + 34.0)
	status_label.position = Vector2.ZERO
	status_label.size = Vector2(hud_width, 26.0)
	rows_root.position = Vector2(0.0, row_top)
	rows_root.size = Vector2(hud_width, row_height * float(GameConfig.get_player_count()))
	result_label.position = Vector2(0.0, row_top + rows_root.size.y + 2.0)
	result_label.size = Vector2(hud_width, 30.0)

func _rebuild_team_rows() -> void:
	if rows_root == null:
		return
	for child in rows_root.get_children():
		child.queue_free()
	team_rows.clear()
	for player_id in range(GameConfig.get_player_count()):
		_create_team_row(player_id)

func _create_team_row(player_id: int) -> void:
	var row_height := GameConfig.hud_team_row_height
	var row := Control.new()
	row.name = "TeamRow_P%d" % player_id
	row.position = Vector2(0.0, row_height * float(player_id))
	row.size = Vector2(GameConfig.hud_width, row_height)
	rows_root.add_child(row)

	var color_strip := ColorRect.new()
	color_strip.color = GameConfig.get_player_color(player_id)
	color_strip.position = Vector2(0.0, 2.0)
	color_strip.size = Vector2(8.0, row_height - 4.0)
	row.add_child(color_strip)

	var name_label := _make_row_label(Vector2(12.0, 0.0), Vector2(42.0, row_height), HORIZONTAL_ALIGNMENT_LEFT)
	name_label.text = "P%d" % player_id
	row.add_child(name_label)

	var hp_bar := ProgressBar.new()
	hp_bar.position = Vector2(52.0, 2.0)
	hp_bar.size = Vector2(GameConfig.hud_hp_bar_width, row_height - 4.0)
	hp_bar.show_percentage = false
	hp_bar.visible = GameConfig.hud_show_hp_bars
	row.add_child(hp_bar)

	var hp_label := _make_row_label(Vector2(58.0 + GameConfig.hud_hp_bar_width, 0.0), Vector2(84.0, row_height), HORIZONTAL_ALIGNMENT_LEFT)
	hp_label.visible = GameConfig.hud_show_hp_bars
	row.add_child(hp_label)

	var score_x := 148.0 + GameConfig.hud_hp_bar_width
	var score_value_label := _make_row_label(Vector2(score_x, 0.0), Vector2(92.0, row_height), HORIZONTAL_ALIGNMENT_LEFT)
	score_value_label.visible = GameConfig.hud_show_scores
	row.add_child(score_value_label)

	var defeated_overlay := ColorRect.new()
	defeated_overlay.color = Color(0.05, 0.05, 0.05, 0.62)
	defeated_overlay.size = row.size
	defeated_overlay.visible = false
	row.add_child(defeated_overlay)

	var defeated_label := _make_row_label(Vector2(0.0, 0.0), row.size, HORIZONTAL_ALIGNMENT_CENTER)
	defeated_label.text = "DEFEATED"
	defeated_label.visible = false
	row.add_child(defeated_label)

	team_rows[player_id] = {
		"root": row,
		"hp_bar": hp_bar,
		"hp_label": hp_label,
		"score_label": score_value_label,
		"defeated_overlay": defeated_overlay,
		"defeated_label": defeated_label,
	}

func _make_row_label(label_position: Vector2, label_size: Vector2, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.position = label_position
	label.size = label_size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	return label

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

func _update_team_rows() -> void:
	var scores := _get_scores()
	for player_id in range(GameConfig.get_player_count()):
		var row_data: Dictionary = team_rows.get(player_id, {})
		if row_data.is_empty():
			continue
		_update_team_row(player_id, row_data, scores)

func _update_team_row(player_id: int, row_data: Dictionary, scores: Dictionary) -> void:
	var castle := _get_castle(player_id)
	var max_hp := GameConfig.castle_max_hp
	var current_hp := 0.0
	var is_defeated := false
	if castle != null:
		max_hp = maxf(float(castle.get("max_hp")), 1.0)
		current_hp = clampf(float(castle.get("current_hp")), 0.0, max_hp)
		is_defeated = bool(castle.get("is_destroyed"))

	var hp_bar := row_data["hp_bar"] as ProgressBar
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_bar.visible = GameConfig.hud_show_hp_bars

	var hp_label := row_data["hp_label"] as Label
	hp_label.text = "HP %d/%d" % [int(round(current_hp)), int(round(max_hp))]
	hp_label.visible = GameConfig.hud_show_hp_bars

	var score_value_label := row_data["score_label"] as Label
	score_value_label.text = "Score %d" % int(scores.get(player_id, 0))
	score_value_label.visible = GameConfig.hud_show_scores

	var defeated_visible := GameConfig.hud_show_defeated_overlay and is_defeated
	(row_data["defeated_overlay"] as ColorRect).visible = defeated_visible
	(row_data["defeated_label"] as Label).visible = defeated_visible

func _on_round_started(_round_number: int) -> void:
	result_label.hide()
	_rebuild_team_rows()
	_update_layout()

func _on_round_reset_requested() -> void:
	result_label.hide()

func _on_round_ended(results: Dictionary) -> void:
	if not GameConfig.hud_show_winner_overlay:
		result_label.hide()
		return
	var scores: Dictionary = results.get("scores", {})
	var winner := int(results.get("winner_player_id", -1))
	if winner < 0:
		winner = _get_winner(scores)
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
	for player_id in range(GameConfig.get_player_count()):
		var score := int(scores.get(player_id, 0))
		if score > best_score:
			best_score = score
			winner = player_id
	return winner

func _get_castle(player_id: int) -> Node:
	for castle in get_tree().get_nodes_in_group("castles"):
		if int(castle.get("player_id")) == player_id:
			return castle
	return null
