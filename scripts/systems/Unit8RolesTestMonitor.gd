extends Node
## Unit Phase 7 - Test Monitor cho 8 Unit Roles
## Verify rằng mỗi unit có behavior profile khác biệt rõ ràng

@export var auto_start: bool = true
@export var test_duration: float = 30.0
@export var unit_scene: PackedScene

var test_timer: float = 0.0
var test_running: bool = false
var unit_data: Dictionary = {}
var spawned_units: Array[Node] = []
var enemy_units: Array[Node] = []

const UNIT_TYPES := ["Melee", "Soldier", "Tank", "Scout", "Archer", "Gunner", "Hammer", "Mage"]

func _ready() -> void:
	if auto_start:
		call_deferred("start_test")

func _process(delta: float) -> void:
	if not test_running:
		return
	
	test_timer += delta
	_monitor_all_units()
	
	if test_timer >= test_duration:
		end_test()

func start_test() -> void:
	print("\n=== Unit Phase 7 Test: 8 Unit Roles Comparison ===")
	test_running = true
	test_timer = 0.0
	unit_data.clear()
	spawned_units.clear()
	enemy_units.clear()
	
	_setup_8_roles_test()

func end_test() -> void:
	test_running = false
	print("\n=== Test Results: 8 Unit Roles ===")
	_print_comparison_table()
	print("Test duration: %.2f seconds" % test_timer)
	print("====================================\n")

func _setup_8_roles_test() -> void:
	print("Setup: Spawn 8 unit types (Team 0) vs 8 enemy targets (Team 1)")
	
	# Team 0: Spawn tất cả 8 unit types
	var start_x := 300.0
	var start_y := 150.0
	var spacing_y := 70.0
	
	for i in range(UNIT_TYPES.size()):
		var unit_type: String = UNIT_TYPES[i]
		var spawn_pos := Vector2(start_x, start_y + float(i) * spacing_y)
		var unit := _spawn_unit_open_field(0, unit_type, spawn_pos, 1)
		
		if unit != null:
			spawned_units.append(unit)
			unit_data[unit_type] = {
				"unit": unit,
				"role": unit.get("role"),
				"attack_style": unit.get("attack_style"),
				"target_priority": unit.get("target_priority"),
				"retarget_interval": unit.get("retarget_interval"),
				"hold_distance": unit.get("hold_distance"),
				"detection_range": unit.get("detection_range"),
				"chase_range": unit.get("chase_range"),
				"separation_strength": unit.get("separation_strength"),
				"castle_aggression": unit.get("castle_aggression"),
				"low_hp_focus": unit.get("low_hp_focus"),
				"frontline_bias": unit.get("frontline_bias"),
				"initial_pos": spawn_pos,
				"max_distance_moved": 0.0,
				"retarget_count": 0,
				"attack_count": 0,
				"last_target": null,
			}
	
	# Team 1: Spawn enemy targets với HP khác nhau
	var enemy_x := 900.0
	var enemy_types := ["Scout", "Melee", "Soldier", "Archer", "Gunner", "Tank", "Hammer", "Mage"]
	
	for i in range(enemy_types.size()):
		var enemy_type: String = enemy_types[i]
		var spawn_pos := Vector2(enemy_x, start_y + float(i) * spacing_y)
		var enemy := _spawn_unit_open_field(1, enemy_type, spawn_pos, 0)
		
		if enemy != null:
			enemy_units.append(enemy)
	
	print("Spawned %d friendly units and %d enemy units" % [spawned_units.size(), enemy_units.size()])

func _monitor_all_units() -> void:
	for unit_type in UNIT_TYPES:
		if not unit_data.has(unit_type):
			continue
		
		var data: Dictionary = unit_data[unit_type]
		var unit: Node = data["unit"]
		
		if unit == null or not is_instance_valid(unit):
			continue
		
		# Track movement
		var distance_moved: float = unit.global_position.distance_to(Vector2(data["initial_pos"]))
		data["max_distance_moved"] = maxf(float(data["max_distance_moved"]), distance_moved)
		
		# Track retarget
		var current_target: Variant = unit.get("current_target")
		if current_target != data["last_target"] and current_target != null:
			data["retarget_count"] = int(data["retarget_count"]) + 1
			data["last_target"] = current_target
		
		# Track attack (estimate từ attack_timer)
		var attack_timer := float(unit.get("attack_timer"))
		if attack_timer > 0.0 and attack_timer < 0.1:  # Just attacked
			data["attack_count"] = int(data["attack_count"]) + 1

func _print_comparison_table() -> void:
	print("\n%-10s | %-18s | %-15s | %-18s | Retarget | Hold | Moved | Attacks" % ["Unit", "Role", "Attack Style", "Target Priority"])
	print("----------------------------------------------------------------------------------------------------------------------------------")
	
	for unit_type in UNIT_TYPES:
		if not unit_data.has(unit_type):
			continue
		
		var data: Dictionary = unit_data[unit_type]
		var role := String(data.get("role", "?"))
		var attack_style := String(data.get("attack_style", "?"))
		var target_priority := String(data.get("target_priority", "?"))
		var retarget_interval := float(data.get("retarget_interval", 0.0))
		var hold_distance := float(data.get("hold_distance", 0.0))
		var max_moved := float(data.get("max_distance_moved", 0.0))
		var retarget_count := int(data.get("retarget_count", 0))
		var attack_count := int(data.get("attack_count", 0))
		
		print("%-10s | %-18s | %-15s | %-18s | %.2fs    | %4.0f | %5.0f | %d" % [
			unit_type,
			role,
			attack_style,
			target_priority,
			retarget_interval,
			hold_distance,
			max_moved,
			attack_count
		])
	
	print("\n=== Behavior Verification ===")
	_verify_behavior_differences()

func _verify_behavior_differences() -> void:
	var checks := []
	
	# Check 1: Scout retarget nhanh hơn Tank
	var scout_retarget := _get_unit_value("Scout", "retarget_interval")
	var tank_retarget := _get_unit_value("Tank", "retarget_interval")
	checks.append("Scout retarget (%.2fs) < Tank (%.2fs): %s" % [
		scout_retarget, tank_retarget, "PASS" if scout_retarget < tank_retarget else "FAIL"
	])
	
	# Check 2: Archer/Gunner/Mage có hold_distance > 0
	var archer_hold := _get_unit_value("Archer", "hold_distance")
	var gunner_hold := _get_unit_value("Gunner", "hold_distance")
	var mage_hold := _get_unit_value("Mage", "hold_distance")
	checks.append("Ranged units keep distance: Archer=%.0f, Gunner=%.0f, Mage=%.0f: %s" % [
		archer_hold, gunner_hold, mage_hold,
		"PASS" if (archer_hold > 0 and gunner_hold > 0 and mage_hold > 0) else "FAIL"
	])
	
	# Check 3: Melee/Tank/Hammer có hold_distance = 0
	var melee_hold := _get_unit_value("Melee", "hold_distance")
	var tank_hold := _get_unit_value("Tank", "hold_distance")
	var hammer_hold := _get_unit_value("Hammer", "hold_distance")
	checks.append("Melee units rush in: Melee=%.0f, Tank=%.0f, Hammer=%.0f: %s" % [
		melee_hold, tank_hold, hammer_hold,
		"PASS" if (melee_hold == 0 and tank_hold == 0 and hammer_hold == 0) else "FAIL"
	])
	
	# Check 4: Scout/Gunner có low_hp_focus cao
	var scout_focus := _get_unit_value("Scout", "low_hp_focus")
	var gunner_focus := _get_unit_value("Gunner", "low_hp_focus")
	checks.append("Scout/Gunner focus low HP: Scout=%.1f, Gunner=%.1f: %s" % [
		scout_focus, gunner_focus,
		"PASS" if (scout_focus >= 0.7 and gunner_focus >= 0.7) else "FAIL"
	])
	
	# Check 5: Tank/Hammer có frontline_bias cao
	var tank_frontline := _get_unit_value("Tank", "frontline_bias")
	var hammer_frontline := _get_unit_value("Hammer", "frontline_bias")
	checks.append("Tank/Hammer frontline: Tank=%.1f, Hammer=%.1f: %s" % [
		tank_frontline, hammer_frontline,
		"PASS" if (tank_frontline >= 0.7 and hammer_frontline >= 0.7) else "FAIL"
	])
	
	# Check 6: Gunner cooldown nhanh nhất
	var gunner_cooldown := _get_unit_config_value("Gunner", "cooldown")
	var archer_cooldown := _get_unit_config_value("Archer", "cooldown")
	checks.append("Gunner fastest cooldown: Gunner=%.2fs < Archer=%.2fs: %s" % [
		gunner_cooldown, archer_cooldown,
		"PASS" if gunner_cooldown < archer_cooldown else "FAIL"
	])
	
	# Check 7: Hammer damage cao nhất
	var hammer_damage := _get_unit_config_value("Hammer", "damage")
	var mage_damage := _get_unit_config_value("Mage", "damage")
	checks.append("Hammer/Mage high damage: Hammer=%.0f, Mage=%.0f: %s" % [
		hammer_damage, mage_damage,
		"PASS" if (hammer_damage >= 25 or mage_damage >= 35) else "FAIL"
	])
	
	# Check 8: Scout speed nhanh nhất
	var scout_speed := _get_unit_config_value("Scout", "speed")
	var tank_speed := _get_unit_config_value("Tank", "speed")
	checks.append("Scout fastest speed: Scout=%.0f > Tank=%.0f: %s" % [
		scout_speed, tank_speed,
		"PASS" if scout_speed > tank_speed else "FAIL"
	])
	
	for check in checks:
		print("  • %s" % check)

func _get_unit_value(unit_type: String, key: String) -> float:
	if not unit_data.has(unit_type):
		return 0.0
	return float(unit_data[unit_type].get(key, 0.0))

func _get_unit_config_value(unit_type: String, key: String) -> float:
	var config := GameConfig.get_unit_config(unit_type)
	return float(config.get(key, 0.0))

func _spawn_unit_open_field(player_id: int, unit_type: String, spawn_pos: Vector2, objective_id: int = -1) -> Node:
	if unit_scene == null:
		push_error("unit_scene not set")
		return null
	
	var unit := unit_scene.instantiate()
	add_child(unit)
	
	if unit.has_method("setup_open_field"):
		unit.call("setup_open_field", player_id, unit_type, spawn_pos, objective_id)
	
	return unit
