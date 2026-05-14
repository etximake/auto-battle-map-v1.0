# SYSTEMS — Chi Tiết Từng Hệ Thống
## Auto Battle TD Simulator — Godot 4.5

---

## 1. ROUND MANAGER SYSTEM

### File: `scripts/systems/RoundManager.gd`

```gdscript
extends Node

@onready var round_timer: Timer = $RoundTimer

var current_round: int = 0
var is_active: bool = false

func _ready() -> void:
    round_timer.timeout.connect(_on_round_timeout)
    GameState.state_changed.connect(_on_state_changed)

func start_round() -> void:
    current_round += 1
    is_active = true
    round_timer.start(GameConfig.round_duration)
    GameState.change_state(GameState.State.ROUND_ACTIVE)
    GameState.round_started.emit(current_round)

func _on_round_timeout() -> void:
    end_round("timeout")

func end_round(reason: String) -> void:
    if not is_active:
        return
    is_active = false
    round_timer.stop()
    
    var results = ScoreManager.calculate_round_results()
    GameState.round_ended.emit(results)
    GameState.change_state(GameState.State.ROUND_END)
    
    # Hiển thị kết quả 3 giây rồi tự next round
    await get_tree().create_timer(3.0).timeout
    _prepare_next_round()

func _prepare_next_round() -> void:
    if current_round >= GameConfig.rounds_per_session:
        _end_session()
        return
    
    # Reset tất cả units, gold, bases
    EventBus.emit_signal("round_reset_requested")
    await get_tree().create_timer(1.0).timeout
    start_round()

func _end_session() -> void:
    GameState.change_state(GameState.State.SESSION_END)
    print("=== SESSION ENDED ===")
    ScoreManager.print_session_results()
    
    if GameConfig.auto_restart:
        await get_tree().create_timer(5.0).timeout
        current_round = 0
        ScoreManager.reset_session()
        start_round()
```

---

## 2. RESOURCE MANAGER SYSTEM

### File: `scripts/systems/ResourceManager.gd`

```gdscript
extends Node

# gold[player_id] = current gold amount
var gold: Dictionary = {}

func _ready() -> void:
    EventBus.round_reset_requested.connect(_reset_all)
    GameState.round_started.connect(_on_round_started)

func _on_round_started(_round: int) -> void:
    _reset_all()

func _reset_all() -> void:
    for i in range(GameConfig.player_count):
        gold[i] = GameConfig.starting_gold
        EventBus.gold_changed.emit(i, gold[i])

func _process(delta: float) -> void:
    if GameState.current_state != GameState.State.ROUND_ACTIVE:
        return
    
    for player_id in gold.keys():
        var earned = GameConfig.gold_per_second * delta
        add_gold(player_id, earned)

func add_gold(player_id: int, amount: float) -> void:
    gold[player_id] = min(gold[player_id] + amount, GameConfig.gold_max)
    EventBus.gold_changed.emit(player_id, gold[player_id])

func spend_gold(player_id: int, amount: float) -> bool:
    if gold.get(player_id, 0) < amount:
        return false
    gold[player_id] -= amount
    EventBus.gold_changed.emit(player_id, gold[player_id])
    return true

func get_gold(player_id: int) -> float:
    return gold.get(player_id, 0.0)
```

---

## 3. AI CONTROLLER SYSTEM

### File: `scripts/players/AIController.gd`

```gdscript
extends Node

var player_id: int = 0
var strategy: String = "BALANCED"

# Cooldown giữa các lần AI "suy nghĩ"
var think_interval: float = 0.5
var think_timer: float = 0.0

# Unit costs (phải match với UnitData)
const UNIT_COSTS = {
    "Scout": 5,
    "Soldier": 10,
    "Mage": 15,
    "Tank": 20,
}

func _process(delta: float) -> void:
    if GameState.current_state != GameState.State.ROUND_ACTIVE:
        return
    
    think_timer += delta
    if think_timer >= think_interval:
        think_timer = 0.0
        _think()

func _think() -> void:
    match strategy:
        "AGGRESSIVE": _strategy_aggressive()
        "BALANCED":   _strategy_balanced()
        "ECONOMY":    _strategy_economy()
        "ADAPTIVE":   _strategy_adaptive()

# ── Strategies ──────────────────────────────────

func _strategy_aggressive() -> void:
    # Mua unit rẻ nhất có thể mua ngay
    var gold = ResourceManager.get_gold(player_id)
    if gold >= UNIT_COSTS["Scout"]:
        _buy_unit("Scout")
    elif gold >= UNIT_COSTS["Soldier"]:
        _buy_unit("Soldier")

func _strategy_balanced() -> void:
    # Luân phiên mua các loại unit
    var gold = ResourceManager.get_gold(player_id)
    var round_time = RoundManager.round_timer.time_left
    
    if round_time > 50 and gold >= UNIT_COSTS["Soldier"]:
        _buy_unit("Soldier")
    elif round_time > 25 and gold >= UNIT_COSTS["Mage"]:
        _buy_unit("Mage")
    elif gold >= UNIT_COSTS["Scout"]:
        _buy_unit("Scout")

func _strategy_economy() -> void:
    # Tích tiền mua unit đắt
    var gold = ResourceManager.get_gold(player_id)
    if gold >= UNIT_COSTS["Tank"]:
        _buy_unit("Tank")
    elif gold >= UNIT_COSTS["Mage"] and gold < UNIT_COSTS["Tank"] - 2:
        # Tiết kiệm, không mua Mage nếu còn thiếu 2 gold để mua Tank
        pass
    elif gold >= UNIT_COSTS["Mage"]:
        _buy_unit("Mage")

func _strategy_adaptive() -> void:
    # Đọc tình hình: nếu đang thua → defensive (mua Tank)
    # Nếu đang thắng → aggressive (spam Scout)
    var gold = ResourceManager.get_gold(player_id)
    var my_units = _count_my_units_on_map()
    var enemy_units = _count_enemy_units_near_base()
    
    if enemy_units > my_units * 1.5:
        # Đang bị áp đảo → mua Tank để block
        if gold >= UNIT_COSTS["Tank"]:
            _buy_unit("Tank")
    elif my_units > 5:
        # Đang thắng → tiếp tục spam
        if gold >= UNIT_COSTS["Scout"]:
            _buy_unit("Scout")
    else:
        _strategy_balanced()

# ── Helpers ─────────────────────────────────────

func _buy_unit(unit_type: String) -> void:
    var cost = UNIT_COSTS[unit_type]
    if ResourceManager.spend_gold(player_id, cost):
        SpawnManager.spawn_unit(player_id, unit_type)

func _count_my_units_on_map() -> int:
    # Đếm units còn sống của player này
    var count = 0
    for unit in get_tree().get_nodes_in_group("units"):
        if unit.player_id == player_id:
            count += 1
    return count

func _count_enemy_units_near_base() -> int:
    # Đếm unit địch trong vùng gần base mình
    # Dùng OverlapCircle hoặc check distance
    var base_pos = _get_my_base_position()
    var count = 0
    for unit in get_tree().get_nodes_in_group("units"):
        if unit.player_id != player_id:
            if unit.global_position.distance_to(base_pos) < 200:
                count += 1
    return count

func _get_my_base_position() -> Vector2:
    for base in get_tree().get_nodes_in_group("bases"):
        if base.player_id == player_id:
            return base.global_position
    return Vector2.ZERO
```

---

## 4. SPAWN MANAGER SYSTEM

### File: `scripts/systems/SpawnManager.gd`

```gdscript
extends Node

# Preload all unit scenes
const UNIT_SCENES = {
    "Scout":   preload("res://scenes/units/Scout.tscn"),
    "Soldier": preload("res://scenes/units/Soldier.tscn"),
    "Tank":    preload("res://scenes/units/Tank.tscn"),
    "Mage":    preload("res://scenes/units/Mage.tscn"),
}

# Object pool
var unit_pool: Dictionary = {}  # unit_type → Array[Unit]
var active_units: Array[Unit] = []

# Max units per player (để tránh lag)
var max_units_per_player: int = 30

@onready var units_container: Node2D = get_node("/root/Main/GameMap/SpawnedUnits")

func _ready() -> void:
    EventBus.round_reset_requested.connect(_clear_all_units)
    _init_pool()

func _init_pool() -> void:
    for unit_type in UNIT_SCENES.keys():
        unit_pool[unit_type] = []
        # Pre-warm pool với 10 units mỗi loại
        for i in range(10):
            var unit = UNIT_SCENES[unit_type].instantiate()
            unit.hide()
            units_container.add_child(unit)
            unit_pool[unit_type].append(unit)

func spawn_unit(player_id: int, unit_type: String) -> Unit:
    # Check max units
    var current_count = _count_player_units(player_id)
    if current_count >= max_units_per_player:
        return null
    
    # Lấy từ pool hoặc tạo mới
    var unit = _get_from_pool(unit_type)
    if not unit:
        unit = UNIT_SCENES[unit_type].instantiate()
        units_container.add_child(unit)
    
    # Setup unit
    var spawn_pos = _get_spawn_position(player_id)
    var path = _get_path_for_player(player_id)
    
    unit.initialize(player_id, spawn_pos, path)
    unit.show()
    active_units.append(unit)
    
    EventBus.unit_spawned.emit(unit, player_id)
    return unit

func return_to_pool(unit: Unit) -> void:
    active_units.erase(unit)
    unit.hide()
    unit.reset()
    unit_pool[unit.unit_type].append(unit)

func _get_from_pool(unit_type: String) -> Unit:
    if unit_pool[unit_type].size() > 0:
        return unit_pool[unit_type].pop_back()
    return null

func _get_spawn_position(player_id: int) -> Vector2:
    for base in get_tree().get_nodes_in_group("bases"):
        if base.player_id == player_id:
            # Thêm random offset nhỏ để units không chồng nhau
            var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
            return base.spawn_point.global_position + offset
    return Vector2.ZERO

func _get_path_for_player(player_id: int) -> Array[Vector2]:
    return GameMap.get_march_path(player_id)

func _count_player_units(player_id: int) -> int:
    var count = 0
    for unit in active_units:
        if is_instance_valid(unit) and unit.player_id == player_id:
            count += 1
    return count

func _clear_all_units() -> void:
    for unit in active_units.duplicate():
        return_to_pool(unit)
    active_units.clear()
```

---

## 5. UNIT SYSTEM

### File: `scripts/units/Unit.gd`

Current prototype status:
- Phase 2 uses Jelly Blob placeholder visuals.
- `Unit.tscn` visual nodes are `Body`, `LeftEye`, `RightEye`, `CollisionShape2D`, `Label`.
- Scout/Soldier/Tank/Mage scenes inherit `Unit.tscn` and override `unit_type`, `move_speed`, `max_hp`.
- Combat, HP bar, `DetectionArea`, object pool reset and EventBus integration are Phase 5 upgrades, not part of the current placeholder unit.

```gdscript
extends CharacterBody2D
class_name Unit

# Config
var player_id: int = 0
var unit_type: String = "Scout"
var max_hp: float = 20.0
var current_hp: float = 20.0
var damage: float = 5.0
var move_speed: float = 80.0
var attack_range: float = 30.0
var attack_cooldown: float = 1.0

# State
enum UnitState { MARCHING, ATTACKING, DEAD }
var state: UnitState = UnitState.MARCHING

# Path following
var waypoints: Array[Vector2] = []
var current_waypoint_index: int = 0

# Combat
var attack_timer: float = 0.0
var current_target: Unit = null

# Visual
@onready var body: Polygon2D = $Body
@onready var left_eye: Polygon2D = $LeftEye
@onready var right_eye: Polygon2D = $RightEye
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var name_label: Label = $Label

func initialize(p_id: int, spawn_pos: Vector2, path: Array[Vector2]) -> void:
    player_id = p_id
    global_position = spawn_pos
    waypoints = path
    current_waypoint_index = 0
    current_hp = max_hp
    state = UnitState.MARCHING
    attack_timer = 0.0
    current_target = null
    
    # Set màu theo player
    sprite.color = GameConfig.player_colors[player_id]
    
    add_to_group("units")

func reset() -> void:
    remove_from_group("units")
    waypoints.clear()
    current_target = null

func _physics_process(delta: float) -> void:
    if state == UnitState.DEAD:
        return
    
    attack_timer -= delta
    
    match state:
        UnitState.MARCHING:
            _process_march(delta)
            _check_for_enemies()
        UnitState.ATTACKING:
            _process_attack(delta)

func _process_march(_delta: float) -> void:
    if current_waypoint_index >= waypoints.size():
        _reach_base()
        return
    
    var target_pos = waypoints[current_waypoint_index]
    var direction = (target_pos - global_position).normalized()
    velocity = direction * move_speed
    
    if global_position.distance_to(target_pos) < 8.0:
        current_waypoint_index += 1
    
    move_and_slide()

func _check_for_enemies() -> void:
    var enemies = detection_area.get_overlapping_bodies()
    for body in enemies:
        if body is Unit and body.player_id != player_id and body.state != UnitState.DEAD:
            current_target = body
            state = UnitState.ATTACKING
            velocity = Vector2.ZERO
            return

func _process_attack(_delta: float) -> void:
    # Kiểm tra target còn hợp lệ không
    if not is_instance_valid(current_target) or current_target.state == UnitState.DEAD:
        current_target = null
        state = UnitState.MARCHING
        return
    
    # Kiểm tra target còn trong range không
    if global_position.distance_to(current_target.global_position) > attack_range * 1.5:
        current_target = null
        state = UnitState.MARCHING
        return
    
    # Attack
    if attack_timer <= 0:
        attack_timer = attack_cooldown
        current_target.take_damage(damage, player_id)

func take_damage(amount: float, attacker_id: int) -> void:
    current_hp -= amount
    _update_hp_bar()
    
    if current_hp <= 0:
        _die(attacker_id)

func _die(killer_id: int) -> void:
    state = UnitState.DEAD
    EventBus.unit_died.emit(self, killer_id)
    # Return to pool sau frame này
    call_deferred("_deferred_return_to_pool")

func _deferred_return_to_pool() -> void:
    SpawnManager.return_to_pool(self)

func _reach_base() -> void:
    # Tìm base địch gần nhất ở điểm cuối path
    EventBus.unit_reached_base.emit(self, _find_nearest_enemy_base())
    call_deferred("_deferred_return_to_pool")

func _find_nearest_enemy_base() -> PlayerBase:
    var nearest = null
    var nearest_dist = INF
    for base in get_tree().get_nodes_in_group("bases"):
        if base.player_id != player_id:
            var d = global_position.distance_to(base.global_position)
            if d < nearest_dist:
                nearest_dist = d
                nearest = base
    return nearest

func _update_hp_bar() -> void:
    if hp_bar:
        hp_bar.value = (current_hp / max_hp) * 100.0
```

---

## 6. NEUTRAL TOWER SYSTEM

### File: `scripts/towers/NeutralTower.gd`

```gdscript
extends StaticBody2D
class_name NeutralTower

var hp: float = 200.0
var damage: float = 20.0
var attack_rate: float = 1.5
var attack_range: float = 100.0

var attack_timer: float = 0.0
var current_target: Unit = null

@onready var range_area: Area2D = $RangeArea

func _process(delta: float) -> void:
    if GameState.current_state != GameState.State.ROUND_ACTIVE:
        return
    
    attack_timer -= delta
    
    # Tìm target gần nhất trong range
    _find_target()
    
    if current_target and attack_timer <= 0:
        attack_timer = attack_rate
        _shoot(current_target)

func _find_target() -> void:
    if is_instance_valid(current_target) and current_target.state != Unit.UnitState.DEAD:
        return  # Giữ target cũ
    
    current_target = null
    var bodies = range_area.get_overlapping_bodies()
    if bodies.size() > 0:
        # Target unit đầu tiên trong range
        for body in bodies:
            if body is Unit and body.state != Unit.UnitState.DEAD:
                current_target = body
                break

func _shoot(target: Unit) -> void:
    target.take_damage(damage, -1)  # -1 = tower (không phải player)
    EventBus.tower_attacked.emit(self, target)
```

---

## 7. PLAYER BASE SYSTEM

### File: `scripts/players/PlayerBase.gd`

```gdscript
extends Area2D
class_name PlayerBase

var player_id: int = 0
var max_hp: float = 100.0
var current_hp: float = 100.0

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var hp_bar: ProgressBar = $HPBar

func _ready() -> void:
    body_entered.connect(_on_unit_entered)
    add_to_group("bases")
    EventBus.round_reset_requested.connect(_reset)
    EventBus.unit_reached_base.connect(_on_unit_reached_base)

func _reset() -> void:
    current_hp = max_hp
    _update_display()

func _on_unit_reached_base(unit: Unit, target_base: PlayerBase) -> void:
    if target_base == self:
        take_damage(unit.damage * 3, unit.player_id)

func take_damage(amount: float, attacker_id: int) -> void:
    current_hp -= amount
    _update_display()
    EventBus.base_damaged.emit(self, amount, attacker_id)
    
    if current_hp <= 0:
        current_hp = 0
        EventBus.base_destroyed.emit(self)
        RoundManager.end_round("base_destroyed")

func _update_display() -> void:
    if hp_bar:
        hp_bar.value = (current_hp / max_hp) * 100.0
```

---

## 8. SCORE MANAGER SYSTEM

### File: `scripts/systems/ScoreManager.gd`

```gdscript
extends Node

# round_scores[player_id] = score trong round này
var round_scores: Dictionary = {}
# session_scores[player_id] = tổng score cả session
var session_scores: Dictionary = {}

func _ready() -> void:
    EventBus.unit_reached_base.connect(_on_unit_reached_base)
    EventBus.base_destroyed.connect(_on_base_destroyed)
    GameState.round_started.connect(_reset_round_scores)

func _reset_round_scores(_round: int) -> void:
    for i in range(GameConfig.player_count):
        round_scores[i] = 0

func _on_unit_reached_base(unit: Unit, _base: PlayerBase) -> void:
    # +1 cho player khi unit của họ vào base địch
    round_scores[unit.player_id] = round_scores.get(unit.player_id, 0) + 1

func _on_base_destroyed(base: PlayerBase) -> void:
    # Ai phá base → +10
    # (Tracking qua base_damaged signal để biết attacker cuối)
    pass

func calculate_round_results() -> Dictionary:
    # Tìm winner (điểm cao nhất)
    var winner = -1
    var max_score = -1
    for pid in round_scores:
        if round_scores[pid] > max_score:
            max_score = round_scores[pid]
            winner = pid
    
    # Cộng vào session
    if winner >= 0:
        session_scores[winner] = session_scores.get(winner, 0) + 3
    
    return {
        "winner": winner,
        "round_scores": round_scores.duplicate(),
        "session_scores": session_scores.duplicate()
    }

func reset_session() -> void:
    session_scores.clear()
    round_scores.clear()

func print_session_results() -> void:
    print("=== SESSION RESULTS ===")
    for pid in session_scores:
        print("Player %d: %d points" % [pid, session_scores[pid]])
```

---

## 9. GAME MAP SYSTEM

### File: `scripts/map/GameMap.gd`

```gdscript
extends Node2D
class_name GameMap

# Waypoints định nghĩa cho 4 player (Vector2 positions)
# Phải khớp với kích thước map thật trong scene

# Path từ mỗi base đến trung tâm
@export var path_waypoints: Dictionary = {
    # player_id → array of waypoints từ base ra trung tâm
    0: [],  # Player 1 (top-left)
    1: [],  # Player 2 (top-right)
    2: [],  # Player 3 (bottom-left)
    3: [],  # Player 4 (bottom-right)
}

func _ready() -> void:
    # Auto-populate từ Path2D nodes nếu có
    _load_paths_from_nodes()

func _load_paths_from_nodes() -> void:
    for i in range(GameConfig.player_count):
        var path_node = get_node_or_null("Paths/Path_P%d" % (i + 1))
        if path_node and path_node is Path2D:
            path_waypoints[i] = _path2d_to_waypoints(path_node)

func _path2d_to_waypoints(path: Path2D) -> Array[Vector2]:
    var points: Array[Vector2] = []
    var curve = path.curve
    for i in range(curve.point_count):
        points.append(path.global_position + curve.get_point_position(i))
    return points

func get_march_path(player_id: int) -> Array[Vector2]:
    # Trả về path từ base player → đến base đối diện
    # Ghép path của player với path ngược của đối thủ
    var my_path = path_waypoints.get(player_id, [])
    var opponent_id = _get_main_opponent(player_id)
    var opp_path = path_waypoints.get(opponent_id, [])
    
    var full_path: Array[Vector2] = []
    full_path.append_array(my_path)
    # Đảo ngược path của đối thủ để đi về phía base họ
    var reversed_opp = opp_path.duplicate()
    reversed_opp.reverse()
    full_path.append_array(reversed_opp)
    
    return full_path

func _get_main_opponent(player_id: int) -> int:
    # Player 0 ↔ Player 3 (đối góc)
    # Player 1 ↔ Player 2 (đối góc)
    match player_id:
        0: return 3
        1: return 2
        2: return 1
        3: return 0
        _: return (player_id + 1) % GameConfig.player_count
```
