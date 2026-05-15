extends Node2D

const AI_SCRIPT := preload("res://scripts/players/AIController.gd")
const BALL_PANEL_SCENE := preload("res://scenes/ui/BallPanel.tscn")

@onready var players_root: Node = $Players
@onready var ui_root: CanvasLayer = $UI


func _ready() -> void:
	_setup_ai_controllers()
	_setup_ball_panels()


func _setup_ai_controllers() -> void:
	for child in players_root.get_children():
		child.free()
	for player_id in range(GameConfig.get_player_count()):
		var ai := Node.new()
		ai.name = "AI_%d" % player_id
		ai.set_script(AI_SCRIPT)
		ai.set("player_id", player_id)
		ai.set("strategy", GameConfig.get_ai_strategy(player_id))
		ai.set("game_map_path", NodePath("../../GameMap"))
		ai.set("spawn_manager_path", NodePath("../../Systems/SpawnManager"))
		players_root.add_child(ai)


func _setup_ball_panels() -> void:
	for child in ui_root.get_children():
		if child.name.begins_with("Panel_P"):
			child.free()
	var left_ids := _get_panel_ids(false)
	var right_ids := _get_panel_ids(true)
	_create_panel_column(left_ids, 0.0)
	_create_panel_column(right_ids, GameConfig.get_right_panel_x())


func _create_panel_column(player_ids: Array[int], x_position: float) -> void:
	if player_ids.is_empty():
		return
	var resolution := GameConfig.get_resolution()
	var panel_width := GameConfig.get_left_panel_width()
	var panel_height := resolution.y / float(player_ids.size())
	for index in player_ids.size():
		var panel := BALL_PANEL_SCENE.instantiate()
		panel.name = "Panel_P%d" % player_ids[index]
		panel.set("player_id", player_ids[index])
		panel.set("panel_size", Vector2(panel_width, panel_height))
		panel.position = Vector2(x_position, panel_height * float(index))
		ui_root.add_child(panel)


func _get_panel_ids(is_right_side: bool) -> Array[int]:
	var result: Array[int] = []
	for player_id in range(GameConfig.get_player_count()):
		if (player_id % 2 == 1) == is_right_side:
			result.append(player_id)
	return result
