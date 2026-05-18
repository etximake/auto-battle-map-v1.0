extends Node
## Unit Phase 9 - Test Monitor cho Open Field Unit Behavior
## Test các hành vi: spawn, target, attack, retarget, role profiles

@export_group("Test Configuration")
@export var test_mode: String = "spawn_basic"  # spawn_basic, target_enemy, castle_attack, retarget_death, role_profiles
@export var auto_start: bool = true
@export var test_duration: float = 15.0

@export_group("Scene References")
@export var unit_scene: PackedScene
@export var castle_scene: PackedScene

var test_timer: float = 0.0
var test_running: bool = false
var test_results: Dictionary = {}
var spawned_units: Array[Node] = []
var spawned_castles: Array[Node] = []

func _ready() -> void:
	if auto_start:
		call_deferred("start_test")

func _process(delta: float) -> void:
	if not test_running:
		return
	
	test_timer += delta
	
	match test_mode:
		"spawn_basic":
			_monitor_spawn_basic()
		"target_enemy":
			_monitor_target_enemy()
		"castle_attack":
			_monitor_castle_attack()
		"retarget_death":
			_monitor_retarget_death()
		"role_profiles":
			_monitor_role_profiles()
	
	if test_timer >= test_duration:
		end_test()

func start_test() -> void:
	print("\n=== Unit Phase 9 Test: %s ===" % test_mode)
	test_running = true
	test_timer = 0.0
	test_results.clear()
	spawned_units.clear()
	spawned_castles.clear()
	
	match test_mode:
		"spawn_basic":
			_setup_spawn_basic_test()
		"target_enemy":
			_setup_target_enemy_test()
		"castle_attack":
			_setup_castle_attack_test()
		"retarget_death":
			_setup_retarget_death_test()
		"role_profiles":
			_setup_role_profiles_test()

func end_test() -> void:
	test_running = false
	print("\n=== Test Results ===")
	for key in test_results.keys():
		print("%s: %s" % [key, test_results[key]])
	print("Test duration: %.2f seconds" % test_timer)
	print("===================\n")

## Test 1: Spawn Basic - Unit spawn không path_points, không biến mất
func _setup_spawn_basic_test() -> void:
	print("Setup: Spawn 4 units open_field mode")
	
	var spawn_positions := [
		Vector2(400, 200),
		Vector2(800, 200),
		Vector2(400, 500),
		Vector2(800, 500),
	]
	
	for i in range(4):
		var unit := _spawn_unit_open_field(i, "Melee", spawn_positions[i])
		spawned_units.append(unit)
	
	test_results["units_spawned"] = spawned_units.size()
	test_results["expected_alive"] = 4

func _monitor_spawn_basic() -> void:
	var alive_count := 0
	var moved_count := 0
	
	for unit in spawned_units:
		if unit == null or not is_instance_valid(unit):
			continue
		if not unit.get("is_dead"):
			alive_count += 1
		if unit.get("velocity") != Vector2.ZERO or unit.global_position.distance_to(unit.get("global_position")) > 1.0:
			moved_count += 1
	
	test_results["units_alive"] = alive_count
	test_results["units_moved"] = moved_count
	test_results["pass"] = alive_count == 4

## Test 2: Target Enemy - 2 unit khác team gần nhau, unit chọn và đánh enemy
func _setup_target_enemy_test() -> void:
	print("Setup: 2 units khác team, gần nhau")
	
	var unit_p0 := _spawn_unit_open_field(0, "Melee", Vector2(600, 350))
	var unit_p1 := _spawn_unit_open_field(1, "Soldier", Vector2(680, 370))
	
	spawned_units.append(unit_p0)
	spawned_units.append(unit_p1)
	
	test_results["units_spawned"] = 2

func _monitor_target_enemy() -> void:
	if spawned_units.size() < 2:
		return
	
	var unit_p0 := spawned_units[0]
	var unit_p1 := spawned_units[1]
	
	if unit_p0 == null or unit_p1 == null:
		return
	
	var p0_target: Variant = unit_p0.get("current_target")
	var p1_target: Variant = unit_p1.get("current_target")
	var p0_has_target: bool = p0_target != null
	var p1_has_target: bool = p1_target != null
	var p0_target_is_enemy := false
	var p1_target_is_enemy := false
	
	if p0_has_target:
		var target: Variant = p0_target
		if target != null and target.has_method("get") and int(target.get("player_id")) != int(unit_p0.get("player_id")):
			p0_target_is_enemy = true
	
	if p1_has_target:
		var target: Variant = p1_target
		if target != null and target.has_method("get") and int(target.get("player_id")) != int(unit_p1.get("player_id")):
			p1_target_is_enemy = true
	
	test_results["p0_has_target"] = p0_has_target
	test_results["p1_has_target"] = p1_has_target
	test_results["p0_target_enemy"] = p0_target_is_enemy
	test_results["p1_target_enemy"] = p1_target_is_enemy
	test_results["pass"] = p0_target_is_enemy and p1_target_is_enemy

## Test 3: Castle Attack - Không có enemy unit, unit đi tới castle và gây damage
func _setup_castle_attack_test() -> void:
	print("Setup: 1 unit, 1 enemy castle")
	
	var castle := _spawn_castle(1, Vector2(800, 360))
	var unit := _spawn_unit_open_field(0, "Hammer", Vector2(400, 360), 1)
	
	spawned_castles.append(castle)
	spawned_units.append(unit)
	
	test_results["castle_initial_hp"] = castle.get("current_hp")

func _monitor_castle_attack() -> void:
	if spawned_castles.is_empty() or spawned_units.is_empty():
		return
	
	var castle := spawned_castles[0]
	var unit := spawned_units[0]
	
	if castle == null or unit == null:
		return
	
	var castle_hp := float(castle.get("current_hp"))
	var initial_hp := float(test_results.get("castle_initial_hp", castle_hp))
	var damage_dealt := initial_hp - castle_hp
	
	var unit_target: Variant = unit.get("current_target")
	var targeting_castle: bool = unit_target == castle
	
	test_results["castle_current_hp"] = castle_hp
	test_results["damage_dealt"] = damage_dealt
	test_results["unit_targeting_castle"] = targeting_castle
	test_results["pass"] = damage_dealt > 0.0

## Test 4: Retarget On Death - Target chết, unit chọn target mới
func _setup_retarget_death_test() -> void:
	print("Setup: 1 unit vs 2 enemy units, kill first target")
	
	var attacker := _spawn_unit_open_field(0, "Gunner", Vector2(500, 360))
	var target1 := _spawn_unit_open_field(1, "Scout", Vector2(600, 360))  # Low HP, sẽ chết trước
	var target2 := _spawn_unit_open_field(1, "Tank", Vector2(650, 380))
	
	spawned_units.append(attacker)
	spawned_units.append(target1)
	spawned_units.append(target2)
	
	test_results["initial_targets"] = 2

func _monitor_retarget_death() -> void:
	if spawned_units.size() < 3:
		return
	
	var attacker := spawned_units[0]
	var target1 := spawned_units[1]
	var target2 := spawned_units[2]
	
	if attacker == null:
		return
	
	var target1_dead: bool = target1 == null or bool(target1.get("is_dead"))
	var target2_dead: bool = target2 == null or bool(target2.get("is_dead"))
	var attacker_target: Variant = attacker.get("current_target")
	var retargeted := false
	
	if target1_dead and attacker_target == target2:
		retargeted = true
	
	test_results["target1_dead"] = target1_dead
	test_results["target2_dead"] = target2_dead
	test_results["attacker_has_target"] = attacker_target != null
	test_results["retargeted_to_target2"] = retargeted
	test_results["pass"] = retargeted or (target1_dead and target2_dead)

## Test 5: Role Profiles - Scout retarget nhanh hơn Tank, Archer giữ khoảng cách
func _setup_role_profiles_test() -> void:
	print("Setup: Scout vs Tank vs Archer behavior comparison")
	
	# Scout - retarget nhanh, low_hp_focus cao
	var scout := _spawn_unit_open_field(0, "Scout", Vector2(400, 300))
	
	# Tank - retarget chậm, frontline_bias cao
	var tank := _spawn_unit_open_field(0, "Tank", Vector2(400, 400))
	
	# Archer - hold_distance cao
	var archer := _spawn_unit_open_field(0, "Archer", Vector2(400, 500))
	
	# Enemy targets
	var enemy1 := _spawn_unit_open_field(1, "Melee", Vector2(700, 300))
	var enemy2 := _spawn_unit_open_field(1, "Soldier", Vector2(700, 400))
	var enemy3 := _spawn_unit_open_field(1, "Hammer", Vector2(700, 500))
	
	spawned_units.append(scout)
	spawned_units.append(tank)
	spawned_units.append(archer)
	spawned_units.append(enemy1)
	spawned_units.append(enemy2)
	spawned_units.append(enemy3)
	
	test_results["scout_retarget_interval"] = scout.get("retarget_interval")
	test_results["tank_retarget_interval"] = tank.get("retarget_interval")
	test_results["archer_hold_distance"] = archer.get("hold_distance")

func _monitor_role_profiles() -> void:
	if spawned_units.size() < 6:
		return
	
	var scout := spawned_units[0]
	var tank := spawned_units[1]
	var archer := spawned_units[2]
	var enemy1 := spawned_units[3]
	
	if scout == null or tank == null or archer == null or enemy1 == null:
		return
	
	# Check Scout retarget nhanh hơn Tank
	var scout_retarget := float(scout.get("retarget_interval"))
	var tank_retarget := float(tank.get("retarget_interval"))
	var scout_faster := scout_retarget < tank_retarget
	
	# Check Archer giữ khoảng cách
	var archer_hold := float(archer.get("hold_distance"))
	var archer_keeps_distance := archer_hold > 0.0
	
	var archer_distance_to_target := INF
	var archer_target: Variant = archer.get("current_target")
	if archer_target != null:
		archer_distance_to_target = archer.global_position.distance_to(archer_target.global_position)
	
	test_results["scout_retarget_faster"] = scout_faster
	test_results["archer_keeps_distance"] = archer_keeps_distance
	test_results["archer_distance_to_target"] = archer_distance_to_target
	test_results["pass"] = scout_faster and archer_keeps_distance

## Helper functions
func _spawn_unit_open_field(player_id: int, unit_type: String, spawn_pos: Vector2, objective_id: int = -1) -> Node:
	if unit_scene == null:
		push_error("unit_scene not set")
		return null
	
	var unit := unit_scene.instantiate()
	add_child(unit)
	
	if unit.has_method("setup_open_field"):
		unit.call("setup_open_field", player_id, unit_type, spawn_pos, objective_id)
	
	return unit

func _spawn_castle(player_id: int, castle_pos: Vector2) -> Node:
	if castle_scene == null:
		push_error("castle_scene not set")
		return null
	
	var castle := castle_scene.instantiate()
	add_child(castle)
	castle.global_position = castle_pos
	
	if castle.has_method("set"):
		castle.set("player_id", player_id)
	
	return castle
