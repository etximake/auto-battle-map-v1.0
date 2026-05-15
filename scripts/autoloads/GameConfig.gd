extends Node
const DEFAULT_CONFIG_PATH := "res://configs/default_game_config.json"
const USER_CONFIG_PATH := "user://game_config_override.json"
const VALID_REWARDS: Array[String] = ["Scout", "Soldier", "Tank", "Mage", "x2"]
var game_mode: String = "base"
var player_count: int = 4
var player_colors: Array[Color] = []
var ai_strategies: Array[String] = []
var round_duration: float = 75.0
var rounds_per_session: int = 10
var auto_restart: bool = true
var time_scale: float = 1.0
var gold_per_second: float = 5.0
var gold_max: int = 50
var starting_gold: int = 10
var ball_panel_spawn_interval: float = 0.7
var ball_panel_ball_speed: float = 165.0
var ball_panel_max_live_balls: int = 8
var ball_panel_anchor_count: int = 6
var ball_panel_anchor_radius: float = 11.0
var ball_panel_anchor_min_y: float = 56.0
var ball_panel_anchor_reward_gap: float = 112.0
var reward_slot_order: Array[String] = []
var x2_mode: String = "next_reward"
var unit_configs: Dictionary = {}
var auto_battle_config: Dictionary = {}
var unit_body_collision_enabled: bool = false
var unit_waypoint_distance: float = 7.0
var castle_max_hp: float = 500.0
var castle_spawn_cooldown: float = 1.0
var castle_queue_limit: int = 40
var castle_shoot_range: float = 120.0
var castle_shoot_damage: float = 10.0
var castle_shoot_cooldown: float = 1.5
var castle_projectile_speed: float = 300.0
var castle_target_priority: String = "nearest"
var max_units_per_player: int = 30
var max_total_units: int = 120
var max_projectiles: int = 80
var neutral_towers_enabled: bool = false
func _ready() -> void:
	load_config()
func load_config() -> void:
	var config := _get_default_config()
	_merge_config(config, _load_json_file(DEFAULT_CONFIG_PATH))
	_merge_config(config, _load_json_file(USER_CONFIG_PATH))
	_apply_config(config)
	_validate_config()
func get_player_color(player_id: int) -> Color:
	if player_id >= 0 and player_id < player_colors.size():
		return player_colors[player_id]
	return Color("#AAAAAA")
func get_reward_slot_order() -> Array[String]:
	return reward_slot_order.duplicate()
func get_unit_config(unit_type: String) -> Dictionary:
	var config: Dictionary = unit_configs.get(unit_type, {})
	return config.duplicate(true)
func get_auto_battle_value(key: String, fallback: float) -> float:
	return maxf(float(auto_battle_config.get(key, fallback)), 0.0)
func get_config_summary() -> String:
	return "players=%d round=%.1f ball_spawn=%.2f rewards=%s" % [player_count, round_duration, ball_panel_spawn_interval, ",".join(reward_slot_order)]
func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Invalid config JSON: %s" % path)
		return {}
	return parsed as Dictionary
func _merge_config(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		var source_value: Variant = source[key]
		if target.has(key) and typeof(target[key]) == TYPE_DICTIONARY and typeof(source_value) == TYPE_DICTIONARY:
			var target_dict: Dictionary = target[key]
			_merge_config(target_dict, source_value as Dictionary)
		else:
			target[key] = source_value
func _apply_config(config: Dictionary) -> void:
	game_mode = String(config.get("game_mode", "base"))
	_apply_players(config.get("players", {}))
	_apply_round(config.get("round", {}))
	_apply_ball_panel(config.get("ball_panel", {}))
	_apply_rewards(config.get("rewards", {}))
	unit_configs = _to_dictionary(config.get("units", {}))
	auto_battle_config = _to_dictionary(config.get("auto_battle", {}))
	_apply_unit_behavior(config.get("unit_behavior", {}))
	_apply_castle(config.get("castle", {}))
	_apply_limits(config.get("limits", {}))
	var optional_modes := _to_dictionary(config.get("optional_modes", {}))
	neutral_towers_enabled = bool(optional_modes.get("neutral_towers_enabled", false))
func _apply_players(value: Variant) -> void:
	var players := _to_dictionary(value)
	player_count = int(players.get("count", 4))
	player_colors = _parse_colors(players.get("colors", []))
	ai_strategies = _parse_string_array(players.get("ai_strategies", []))
func _apply_round(value: Variant) -> void:
	var round_config := _to_dictionary(value)
	round_duration = float(round_config.get("duration", 75.0))
	rounds_per_session = int(round_config.get("rounds_per_session", 10))
	auto_restart = bool(round_config.get("auto_restart", true))
	time_scale = float(round_config.get("time_scale", 1.0))
func _apply_ball_panel(value: Variant) -> void:
	var ball_config := _to_dictionary(value)
	ball_panel_spawn_interval = float(ball_config.get("spawn_interval", 0.7))
	ball_panel_ball_speed = float(ball_config.get("ball_speed", 165.0))
	ball_panel_max_live_balls = int(ball_config.get("max_live_balls", 8))
	ball_panel_anchor_count = int(ball_config.get("anchor_count", 6))
	ball_panel_anchor_radius = float(ball_config.get("anchor_radius", 11.0))
	ball_panel_anchor_min_y = float(ball_config.get("anchor_min_y", 56.0))
	ball_panel_anchor_reward_gap = float(ball_config.get("anchor_reward_gap", 112.0))
func _apply_rewards(value: Variant) -> void:
	var reward_config := _to_dictionary(value)
	reward_slot_order = _parse_string_array(reward_config.get("slot_order", VALID_REWARDS))
	x2_mode = String(reward_config.get("x2_mode", "next_reward"))
func _apply_unit_behavior(value: Variant) -> void:
	var behavior := _to_dictionary(value)
	unit_body_collision_enabled = bool(behavior.get("body_collision_enabled", false))
	unit_waypoint_distance = float(behavior.get("waypoint_distance", 7.0))
func _apply_castle(value: Variant) -> void:
	var castle_config := _to_dictionary(value)
	castle_max_hp = float(castle_config.get("max_hp", 500.0))
	castle_spawn_cooldown = float(castle_config.get("spawn_cooldown", 1.0))
	castle_queue_limit = int(castle_config.get("queue_limit", 40))
	castle_shoot_range = float(castle_config.get("shoot_range", 120.0))
	castle_shoot_damage = float(castle_config.get("shoot_damage", 10.0))
	castle_shoot_cooldown = float(castle_config.get("shoot_cooldown", 1.5))
	castle_projectile_speed = float(castle_config.get("projectile_speed", 300.0))
	castle_target_priority = String(castle_config.get("target_priority", "nearest"))
func _apply_limits(value: Variant) -> void:
	var limits := _to_dictionary(value)
	max_units_per_player = int(limits.get("max_units_per_player", 30))
	max_total_units = int(limits.get("max_total_units", 120))
	max_projectiles = int(limits.get("max_projectiles", 80))
func _validate_config() -> void:
	player_count = clampi(player_count, 2, 6)
	round_duration = maxf(round_duration, 10.0)
	rounds_per_session = maxi(rounds_per_session, 1)
	time_scale = clampf(time_scale, 0.25, 4.0)
	ball_panel_spawn_interval = maxf(ball_panel_spawn_interval, 0.1)
	ball_panel_max_live_balls = clampi(ball_panel_max_live_balls, 1, 50)
	ball_panel_anchor_count = clampi(ball_panel_anchor_count, 0, 24)
	ball_panel_anchor_radius = maxf(ball_panel_anchor_radius, 1.0)
	ball_panel_anchor_reward_gap = maxf(ball_panel_anchor_reward_gap, 64.0)
	unit_waypoint_distance = clampf(unit_waypoint_distance, 2.0, 24.0)
	castle_max_hp = maxf(castle_max_hp, 1.0)
	castle_queue_limit = clampi(castle_queue_limit, 1, 200)
	castle_shoot_range = maxf(castle_shoot_range, 0.0)
	castle_shoot_damage = maxf(castle_shoot_damage, 0.0)
	castle_shoot_cooldown = maxf(castle_shoot_cooldown, 0.1)
	castle_projectile_speed = maxf(castle_projectile_speed, 1.0)
	if not ["nearest", "lowest_hp", "first_entered"].has(castle_target_priority):
		castle_target_priority = "nearest"
	max_units_per_player = clampi(max_units_per_player, 1, 200)
	max_total_units = max(max_total_units, max_units_per_player)
	max_projectiles = clampi(max_projectiles, 1, 500)
	_validate_colors()
	_validate_rewards()
func _validate_colors() -> void:
	while player_colors.size() < player_count:
		player_colors.append(Color("#AAAAAA"))
func _validate_rewards() -> void:
	var filtered: Array[String] = []
	for reward_type in reward_slot_order:
		if VALID_REWARDS.has(reward_type):
			filtered.append(reward_type)
		else:
			push_warning("Unknown reward ignored: %s" % reward_type)
	if filtered.is_empty():
		filtered = VALID_REWARDS.duplicate()
	reward_slot_order = filtered
func _parse_colors(value: Variant) -> Array[Color]:
	var result: Array[Color] = []
	for color_value in _to_array(value):
		result.append(Color(String(color_value)))
	return result
func _parse_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for item in _to_array(value):
		result.append(String(item))
	return result
func _to_dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary) if typeof(value) == TYPE_DICTIONARY else {}
func _to_array(value: Variant) -> Array:
	return (value as Array) if typeof(value) == TYPE_ARRAY else []
func _get_default_config() -> Dictionary:
	return {
		"game_mode": "base",
		"players": {"count": 4, "colors": ["#E74C3C", "#3498DB", "#2ECC71", "#F1C40F"], "ai_strategies": ["BALANCED", "BALANCED", "BALANCED", "BALANCED"]},
		"round": {"duration": 75.0, "rounds_per_session": 10, "auto_restart": true, "time_scale": 1.0},
		"ball_panel": {"spawn_interval": 0.7, "ball_speed": 165.0, "max_live_balls": 8, "anchor_count": 6, "anchor_radius": 11.0, "anchor_min_y": 56.0, "anchor_reward_gap": 112.0},
		"rewards": {"slot_order": VALID_REWARDS, "x2_mode": "next_reward"},
		"auto_battle": {"castle_unit_damage_multiplier": 1.0, "unit_kill_score": 5, "castle_damage_score_per_point": 0.1, "castle_destroy_score": 50},
		"units": {"Scout": {"hp": 20, "damage": 5, "speed": 190, "range": 28, "cooldown": 0.8, "visual_radius": 12, "collision_radius": 7}, "Soldier": {"hp": 50, "damage": 15, "speed": 140, "range": 34, "cooldown": 1.0, "visual_radius": 15, "collision_radius": 9}, "Tank": {"hp": 150, "damage": 8, "speed": 85, "range": 32, "cooldown": 1.5, "visual_radius": 18, "collision_radius": 11}, "Mage": {"hp": 30, "damage": 40, "speed": 115, "range": 85, "cooldown": 2.0, "visual_radius": 14, "collision_radius": 8}},
		"unit_behavior": {"body_collision_enabled": false, "waypoint_distance": 7.0},
		"castle": {"max_hp": 500.0, "spawn_cooldown": 1.0, "queue_limit": 40, "shoot_range": 120.0, "shoot_damage": 10.0, "shoot_cooldown": 1.5, "projectile_speed": 300.0, "target_priority": "nearest"},
		"limits": {"max_units_per_player": 30, "max_total_units": 120, "max_projectiles": 80},
		"optional_modes": {"neutral_towers_enabled": false},
	}
