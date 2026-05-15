extends Node
const DEFAULT_CONFIG_PATH := "res://configs/default_game_config.json"
const USER_CONFIG_PATH := "user://game_config_override.json"
const DEFAULT_REWARDS: Array[String] = ["Melee", "Archer", "Gunner", "Hammer", "Tank", "Mage", "x2"]
var game_mode: String = "base"
var player_count: int = 4; var players_count: int = 4; var player_max_count: int = 6
var player_colors: Array[Color] = []; var ai_strategies: Array[String] = []; var layout_config: Dictionary = {}
var round_duration: float = 75.0; var rounds_per_session: int = 10; var auto_restart: bool = true; var time_scale: float = 1.0
var gold_per_second: float = 5.0; var gold_max: int = 50; var starting_gold: int = 10
var ball_panel_spawn_interval: float = 0.7; var ball_panel_ball_speed: float = 165.0; var ball_panel_max_live_balls: int = 8
var ball_panel_anchor_count: int = 6; var ball_panel_anchor_radius: float = 11.0; var ball_panel_anchor_min_y: float = 56.0; var ball_panel_anchor_reward_gap: float = 112.0; var ball_panel_spawn_angle_random_degrees: float = 15.0
var ball_panel_spawn_y: float = 7.0; var ball_panel_peg_layout_mode: String = "mixed_by_player"; var ball_panel_peg_safe_margin: float = 36.0; var ball_panel_peg_safe_gap: float = 8.0; var ball_panel_peg_jitter: float = 0.3
var reward_slot_order: Array[String] = []; var reward_enabled: Array[String] = []; var reward_max_active_slots: int = 5; var x2_mode: String = "next_reward"
var unit_configs: Dictionary = {}; var auto_battle_config: Dictionary = {}; var unit_body_collision_enabled: bool = false; var unit_waypoint_distance: float = 7.0
var hud_show_scores: bool = true; var hud_show_hp_bars: bool = true; var hud_show_defeated_overlay: bool = true; var hud_show_winner_overlay: bool = true
var hud_width: float = 496.0; var hud_team_row_height: float = 20.0; var hud_hp_bar_width: float = 132.0
var castle_max_hp: float = 500.0; var castle_spawn_cooldown: float = 1.0; var castle_queue_limit: int = 40
var castle_shoot_range: float = 120.0; var castle_shoot_damage: float = 10.0; var castle_shoot_cooldown: float = 1.5
var castle_projectile_speed: float = 300.0; var castle_target_priority: String = "nearest"
var max_units_per_player: int = 30; var max_total_units: int = 120; var max_projectiles: int = 80
var neutral_towers_enabled: bool = false
func _ready() -> void: load_config()
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
func get_player_count() -> int: return player_count
func get_ai_strategy(player_id: int) -> String:
	if player_id >= 0 and player_id < ai_strategies.size():
		return ai_strategies[player_id]
	return "BALANCED"
func get_map_rect() -> Rect2: return _array_to_rect2(layout_config.get("map_rect", []), Rect2(192, 0, 896, 720))
func get_resolution() -> Vector2: return _array_to_vector2(layout_config.get("resolution", []), Vector2(1280, 720))
func get_left_panel_width() -> float: return float(layout_config.get("left_panel_width", 192.0))
func get_right_panel_x() -> float: return float(layout_config.get("right_panel_x", get_resolution().x - get_left_panel_width()))
func get_castle_position(player_id: int) -> Vector2:
	var player_layout := _get_player_count_layout()
	var positions := _to_array(player_layout.get("castle_positions", layout_config.get("castle_positions", [])))
	return _array_to_vector2(positions[player_id], _generated_castle_position(player_id)) if player_id >= 0 and player_id < positions.size() else _generated_castle_position(player_id)
func get_spawn_position(player_id: int) -> Vector2:
	var player_layout := _get_player_count_layout()
	var offsets := _to_array(player_layout.get("spawn_offsets", layout_config.get("spawn_offsets", [])))
	var offset := Vector2.ZERO
	if player_id >= 0 and player_id < offsets.size():
		offset = _array_to_vector2(offsets[player_id], Vector2.ZERO)
	return get_castle_position(player_id) + offset
func get_reward_slot_order() -> Array[String]: return reward_slot_order.duplicate()
func get_unit_types() -> Array[String]:
	var result: Array[String] = []
	for unit_type in unit_configs.keys():
		if String(unit_type).begins_with("_"):
			continue
		result.append(String(unit_type))
	return result
func is_unit_type(unit_type: String) -> bool: return not unit_type.begins_with("_") and unit_configs.has(unit_type)
func get_unit_config(unit_type: String) -> Dictionary:
	var config: Dictionary = unit_configs.get(unit_type, {})
	return config.duplicate(true)
func get_auto_battle_value(key: String, fallback: float) -> float: return maxf(float(auto_battle_config.get(key, fallback)), 0.0)
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
	layout_config = _to_dictionary(config.get("layout", {}))
	_apply_round(config.get("round", {}))
	_apply_ball_panel(config.get("ball_panel", {}))
	unit_configs = _without_metadata(_to_dictionary(config.get("units", {})))
	_apply_rewards(config.get("rewards", {}))
	auto_battle_config = _to_dictionary(config.get("auto_battle", {}))
	_apply_hud(config.get("hud", {}))
	_apply_unit_behavior(config.get("unit_behavior", {}))
	_apply_castle(config.get("castle", {}))
	_apply_limits(config.get("limits", {}))
	var optional_modes := _to_dictionary(config.get("optional_modes", {}))
	neutral_towers_enabled = bool(optional_modes.get("neutral_towers_enabled", false))
func _apply_players(value: Variant) -> void:
	var players := _to_dictionary(value)
	player_count = int(players.get("count", 4))
	player_max_count = int(players.get("max_count", 6))
	player_colors = _parse_colors(players.get("colors", []))
	ai_strategies = _parse_string_array(players.get("ai_strategies", []))
func _apply_round(value: Variant) -> void:
	var round_config := _to_dictionary(value)
	round_duration = float(round_config.get("duration", 75.0)); rounds_per_session = int(round_config.get("rounds_per_session", 10))
	auto_restart = bool(round_config.get("auto_restart", true)); time_scale = float(round_config.get("time_scale", 1.0))
func _apply_ball_panel(value: Variant) -> void:
	var ball_config := _to_dictionary(value)
	ball_panel_spawn_interval = float(ball_config.get("spawn_interval", 0.7)); ball_panel_ball_speed = float(ball_config.get("ball_speed", 165.0))
	ball_panel_max_live_balls = int(ball_config.get("max_live_balls", 8)); ball_panel_anchor_count = int(ball_config.get("anchor_count", 6))
	ball_panel_anchor_radius = float(ball_config.get("anchor_radius", 11.0)); ball_panel_anchor_min_y = float(ball_config.get("anchor_min_y", 56.0))
	ball_panel_anchor_reward_gap = float(ball_config.get("anchor_reward_gap", 112.0))
	ball_panel_spawn_angle_random_degrees = float(ball_config.get("spawn_angle_random_degrees", 15.0))
	ball_panel_spawn_y = float(ball_config.get("spawn_y", 7.0)); ball_panel_peg_layout_mode = String(ball_config.get("peg_layout_mode", "mixed_by_player"))
	ball_panel_peg_safe_margin = float(ball_config.get("peg_safe_margin", 36.0)); ball_panel_peg_safe_gap = float(ball_config.get("peg_safe_gap", 8.0)); ball_panel_peg_jitter = float(ball_config.get("peg_jitter", 0.3))
func _apply_rewards(value: Variant) -> void:
	var reward_config := _to_dictionary(value)
	reward_slot_order = _parse_string_array(reward_config.get("slot_order", DEFAULT_REWARDS))
	reward_enabled = _parse_string_array(reward_config.get("enabled_rewards", reward_slot_order)); reward_max_active_slots = int(reward_config.get("max_active_slots", 5))
	x2_mode = String(reward_config.get("x2_mode", "next_reward"))
func _apply_hud(value: Variant) -> void:
	var hud_config := _to_dictionary(value)
	hud_show_scores = bool(hud_config.get("show_scores", true)); hud_show_hp_bars = bool(hud_config.get("show_hp_bars", true))
	hud_show_defeated_overlay = bool(hud_config.get("show_defeated_overlay", true)); hud_show_winner_overlay = bool(hud_config.get("show_winner_overlay", true))
	hud_width = float(hud_config.get("width", 496.0)); hud_team_row_height = float(hud_config.get("team_row_height", 20.0)); hud_hp_bar_width = float(hud_config.get("hp_bar_width", 132.0))
func _apply_unit_behavior(value: Variant) -> void:
	var behavior := _to_dictionary(value)
	unit_body_collision_enabled = bool(behavior.get("body_collision_enabled", false))
	unit_waypoint_distance = float(behavior.get("waypoint_distance", 7.0))
func _apply_castle(value: Variant) -> void:
	var castle_config := _to_dictionary(value)
	castle_max_hp = float(castle_config.get("max_hp", 500.0)); castle_spawn_cooldown = float(castle_config.get("spawn_cooldown", 1.0))
	castle_queue_limit = int(castle_config.get("queue_limit", 40)); castle_shoot_range = float(castle_config.get("shoot_range", 120.0))
	castle_shoot_damage = float(castle_config.get("shoot_damage", 10.0)); castle_shoot_cooldown = float(castle_config.get("shoot_cooldown", 1.5))
	castle_projectile_speed = float(castle_config.get("projectile_speed", 300.0))
	castle_target_priority = String(castle_config.get("target_priority", "nearest"))
func _apply_limits(value: Variant) -> void:
	var limits := _to_dictionary(value)
	max_units_per_player = int(limits.get("max_units_per_player", 30))
	max_total_units = int(limits.get("max_total_units", 120))
	max_projectiles = int(limits.get("max_projectiles", 80))
func _validate_config() -> void:
	player_max_count = clampi(player_max_count, 2, 12); player_count = clampi(player_count, 2, player_max_count)
	players_count = player_count
	round_duration = maxf(round_duration, 10.0); rounds_per_session = maxi(rounds_per_session, 1); time_scale = clampf(time_scale, 0.25, 4.0)
	ball_panel_spawn_interval = maxf(ball_panel_spawn_interval, 0.1); ball_panel_max_live_balls = clampi(ball_panel_max_live_balls, 1, 50)
	ball_panel_anchor_count = clampi(ball_panel_anchor_count, 0, 24); ball_panel_anchor_radius = maxf(ball_panel_anchor_radius, 1.0)
	ball_panel_anchor_reward_gap = maxf(ball_panel_anchor_reward_gap, 64.0); unit_waypoint_distance = clampf(unit_waypoint_distance, 2.0, 24.0)
	ball_panel_spawn_angle_random_degrees = clampf(ball_panel_spawn_angle_random_degrees, 0.0, 45.0)
	ball_panel_spawn_y = maxf(ball_panel_spawn_y, 0.0); ball_panel_peg_safe_margin = maxf(ball_panel_peg_safe_margin, 0.0); ball_panel_peg_safe_gap = maxf(ball_panel_peg_safe_gap, 0.0); ball_panel_peg_jitter = clampf(ball_panel_peg_jitter, 0.0, 0.45)
	if not ["mixed_by_player", "aligned", "staggered", "random_safe"].has(ball_panel_peg_layout_mode): ball_panel_peg_layout_mode = "mixed_by_player"
	hud_width = clampf(hud_width, 240.0, 900.0); hud_team_row_height = clampf(hud_team_row_height, 16.0, 36.0); hud_hp_bar_width = clampf(hud_hp_bar_width, 64.0, 260.0)
	castle_max_hp = maxf(castle_max_hp, 1.0); castle_queue_limit = clampi(castle_queue_limit, 1, 200); castle_shoot_range = maxf(castle_shoot_range, 0.0)
	castle_shoot_damage = maxf(castle_shoot_damage, 0.0); castle_shoot_cooldown = maxf(castle_shoot_cooldown, 0.1); castle_projectile_speed = maxf(castle_projectile_speed, 1.0)
	if not ["nearest", "lowest_hp", "first_entered"].has(castle_target_priority):
		castle_target_priority = "nearest"
	max_units_per_player = clampi(max_units_per_player, 1, 200); max_total_units = max(max_total_units, max_units_per_player); max_projectiles = clampi(max_projectiles, 1, 500)
	reward_max_active_slots = clampi(reward_max_active_slots, 1, reward_slot_order.size())
	_validate_colors()
	_validate_rewards()
func _validate_colors() -> void:
	while player_colors.size() < player_count:
		player_colors.append(Color("#AAAAAA"))
	while ai_strategies.size() < player_count:
		ai_strategies.append("BALANCED")
func _validate_rewards() -> void:
	var filtered: Array[String] = []
	for reward_type in reward_enabled:
		if reward_type == "x2" or is_unit_type(reward_type):
			filtered.append(reward_type)
		else:
			push_warning("Unknown reward ignored: %s" % reward_type)
	if filtered.is_empty():
		filtered = DEFAULT_REWARDS.duplicate()
	reward_slot_order = filtered.slice(0, reward_max_active_slots)
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
func _to_dictionary(value: Variant) -> Dictionary: return (value as Dictionary) if typeof(value) == TYPE_DICTIONARY else {}
func _to_array(value: Variant) -> Array: return (value as Array) if typeof(value) == TYPE_ARRAY else []
func _without_metadata(value: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in value.keys():
		if String(key).begins_with("_"):
			continue
		result[key] = value[key]
	return result
func _get_player_count_layout() -> Dictionary:
	var layouts := _to_dictionary(layout_config.get("player_count_layouts", {}))
	var count_layout := _without_metadata(_to_dictionary(layouts.get(str(player_count), {})))
	var variants := _without_metadata(_to_dictionary(count_layout.get("variants", {})))
	if variants.is_empty():
		return count_layout
	var variant_name := String(layout_config.get("position_variant", "default"))
	var selected_layout := _to_dictionary(variants.get(variant_name, {}))
	if selected_layout.is_empty():
		selected_layout = _to_dictionary(variants.get("default", {}))
	if selected_layout.is_empty():
		selected_layout = _get_first_variant_layout(variants)
	return _without_metadata(selected_layout)
func _get_first_variant_layout(variants: Dictionary) -> Dictionary:
	for key in variants.keys():
		var layout := _to_dictionary(variants[key])
		if not layout.is_empty():
			return layout
	return {}
func _array_to_vector2(value: Variant, fallback: Vector2) -> Vector2:
	var items := _to_array(value)
	return Vector2(float(items[0]), float(items[1])) if items.size() >= 2 else fallback
func _array_to_rect2(value: Variant, fallback: Rect2) -> Rect2:
	var items := _to_array(value)
	return Rect2(float(items[0]), float(items[1]), float(items[2]), float(items[3])) if items.size() >= 4 else fallback
func _generated_castle_position(player_id: int) -> Vector2:
	var map_rect := get_map_rect()
	var side_count := int(ceil(float(player_count) * 0.5)) if player_id % 2 == 0 else player_count / 2
	var side_index := player_id / 2
	var y := map_rect.position.y + map_rect.size.y * float(side_index + 1) / float(maxi(side_count + 1, 2))
	var x := map_rect.position.x + 112.0 if player_id % 2 == 0 else map_rect.end.x - 112.0
	return Vector2(x, y)
func _get_default_config() -> Dictionary:
	return {
		"game_mode": "base",
		"players": {"count": 4, "max_count": 6, "colors": ["#E74C3C", "#3498DB", "#9B59B6", "#F1C40F", "#2ECC71", "#1ABC9C"], "ai_strategies": ["BALANCED", "BALANCED", "ADAPTIVE", "ECONOMY", "BALANCED", "AGGRESSIVE"]},
		"layout": _get_default_layout_config(),
		"round": {"duration": 75.0, "rounds_per_session": 10, "auto_restart": true, "time_scale": 1.0},
		"ball_panel": {"spawn_interval": 0.7, "ball_speed": 165.0, "max_live_balls": 8, "anchor_count": 6, "anchor_radius": 11.0, "anchor_min_y": 56.0, "anchor_reward_gap": 112.0, "spawn_angle_random_degrees": 15.0, "spawn_y": 7.0, "peg_layout_mode": "mixed_by_player", "peg_safe_margin": 36.0, "peg_safe_gap": 8.0, "peg_jitter": 0.3},
		"rewards": {"slot_order": DEFAULT_REWARDS, "enabled_rewards": ["Melee", "Archer", "Gunner", "Tank", "Mage"], "max_active_slots": 5, "x2_mode": "next_reward"},
		"auto_battle": {"castle_unit_damage_multiplier": 1.0, "unit_kill_score": 5, "castle_damage_score_per_point": 0.1, "castle_destroy_score": 50},
		"hud": {"show_scores": true, "show_hp_bars": true, "show_defeated_overlay": true, "show_winner_overlay": true, "width": 496.0, "team_row_height": 20.0, "hp_bar_width": 132.0},
		"units": {"Melee": {"hp": 45, "damage": 14, "speed": 145, "range": 32, "cooldown": 0.95, "visual_radius": 14, "collision_radius": 8}, "Archer": {"hp": 28, "damage": 12, "speed": 135, "range": 95, "cooldown": 1.15, "visual_radius": 13, "collision_radius": 7}, "Gunner": {"hp": 35, "damage": 8, "speed": 150, "range": 105, "cooldown": 0.65, "visual_radius": 13, "collision_radius": 7}, "Hammer": {"hp": 75, "damage": 28, "speed": 105, "range": 36, "cooldown": 1.6, "visual_radius": 16, "collision_radius": 10}, "Tank": {"hp": 150, "damage": 8, "speed": 85, "range": 32, "cooldown": 1.5, "visual_radius": 18, "collision_radius": 11}, "Mage": {"hp": 30, "damage": 40, "speed": 115, "range": 85, "cooldown": 2.0, "visual_radius": 14, "collision_radius": 8}, "Scout": {"hp": 20, "damage": 5, "speed": 190, "range": 28, "cooldown": 0.8, "visual_radius": 12, "collision_radius": 7}, "Soldier": {"hp": 50, "damage": 15, "speed": 140, "range": 34, "cooldown": 1.0, "visual_radius": 15, "collision_radius": 9}},
		"unit_behavior": {"body_collision_enabled": false, "waypoint_distance": 7.0},
		"castle": {"max_hp": 500.0, "spawn_cooldown": 1.0, "queue_limit": 40, "shoot_range": 120.0, "shoot_damage": 10.0, "shoot_cooldown": 1.5, "projectile_speed": 300.0, "target_priority": "nearest"},
		"limits": {"max_units_per_player": 30, "max_total_units": 120, "max_projectiles": 80},
		"optional_modes": {"neutral_towers_enabled": false},
	}

func _get_default_layout_config() -> Dictionary:
	return {
		"resolution": [1280, 720],
		"left_panel_width": 192,
		"right_panel_x": 1088,
		"map_rect": [192, 0, 896, 720],
		"position_variant": "default",
		"castle_positions": [[304, 134], [976, 134], [304, 360], [976, 360], [304, 586], [976, 586]],
		"spawn_offsets": [[28, 18], [-28, 18], [28, 0], [-28, 0], [28, -18], [-28, -18]],
		"player_count_layouts": {
			"2": {"variants": {
				"default": {"castle_positions": [[304, 360], [976, 360]], "spawn_offsets": [[28, 0], [-28, 0]]},
				"vertical": {"castle_positions": [[640, 150], [640, 570]], "spawn_offsets": [[0, 32], [0, -32]]},
				"diagonal": {"castle_positions": [[304, 170], [976, 550]], "spawn_offsets": [[30, 18], [-30, -18]]},
				"close_center": {"castle_positions": [[424, 360], [856, 360]], "spawn_offsets": [[30, 0], [-30, 0]]},
			}},
			"4": {"variants": {
				"default": {"castle_positions": [[304, 220], [976, 220], [304, 500], [976, 500]], "spawn_offsets": [[28, 12], [-28, 12], [28, -12], [-28, -12]]},
				"corners": {"castle_positions": [[304, 140], [976, 140], [304, 580], [976, 580]], "spawn_offsets": [[30, 22], [-30, 22], [30, -22], [-30, -22]]},
				"diamond": {"castle_positions": [[640, 128], [980, 360], [640, 592], [300, 360]], "spawn_offsets": [[0, 34], [-34, 0], [0, -34], [34, 0]]},
				"staggered": {"castle_positions": [[304, 165], [976, 270], [304, 555], [976, 450]], "spawn_offsets": [[28, 18], [-28, 12], [28, -18], [-28, -12]]},
			}},
			"6": {"castle_positions": [[304, 134], [976, 134], [304, 360], [976, 360], [304, 586], [976, 586]], "spawn_offsets": [[28, 18], [-28, 18], [28, 0], [-28, 0], [28, -18], [-28, -18]]},
		},
	}
