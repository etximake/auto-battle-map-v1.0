# ARCHITECTURE — Godot 4.5 Project Structure
## Auto Battle TD Simulator

---

## 1. CÂY THƯ MỤC PROJECT

```
res://
├── project.godot
├── autoloads/
│   ├── GameConfig.gd          # Cấu hình toàn cục (player count, round time...)
│   ├── GameState.gd           # State machine toàn cục
│   └── EventBus.gd            # Signal bus trung tâm
├── scenes/
│   ├── main/
│   │   └── Main.tscn          # Scene gốc, chứa tất cả
│   ├── map/
│   │   ├── GameMap.tscn       # Bản đồ + path + towers
│   │   └── Path.tscn          # Path2D component
│   ├── players/
│   │   ├── PlayerBase.tscn    # Base của mỗi player (HP, spawn point)
│   │   └── PlayerPanel.tscn   # UI panel góc màn hình
│   ├── units/
│   │   ├── Unit.tscn          # Unit base scene
│   │   ├── Scout.tscn
│   │   ├── Soldier.tscn
│   │   ├── Tank.tscn
│   │   └── Mage.tscn
│   ├── towers/
│   │   └── NeutralTower.tscn
│   └── ui/
│       ├── HUD.tscn           # Timer, round counter
│       └── RoundResult.tscn   # Bảng kết quả cuối round
├── scripts/
│   ├── autoloads/
│   │   ├── GameConfig.gd
│   │   ├── GameState.gd
│   │   └── EventBus.gd
│   ├── map/
│   │   └── GameMap.gd
│   ├── players/
│   │   ├── PlayerBase.gd
│   │   ├── PlayerPanel.gd
│   │   └── AIController.gd    # Logic AI mua unit
│   ├── units/
│   │   ├── Unit.gd            # Base class
│   │   ├── UnitData.gd        # Resource: stats config
│   │   └── UnitCombat.gd      # Combat logic
│   ├── towers/
│   │   └── NeutralTower.gd
│   └── systems/
│       ├── RoundManager.gd    # Quản lý round, timer
│       ├── SpawnManager.gd    # Spawn unit
│       ├── ResourceManager.gd # Gold tick
│       └── ScoreManager.gd    # Tính điểm
└── resources/
    ├── unit_configs/
    │   ├── scout_data.tres
    │   ├── soldier_data.tres
    │   ├── tank_data.tres
    │   └── mage_data.tres
    └── player_configs/
        └── default_config.tres
```

---

## 2. SCENE HIERARCHY (Main.tscn)

```
Main (Node2D)
├── GameMap (Node2D)
│   ├── TileMapLayer (ground)
│   ├── Paths (Node2D)
│   │   ├── Path_P1_to_P2 (Path2D)
│   │   ├── Path_P3_to_P4 (Path2D)
│   │   ├── Path_P1_to_P3 (Path2D)  [optional cross paths]
│   │   └── Path_P2_to_P4 (Path2D)
│   ├── Towers (Node2D)
│   │   ├── Tower_01 (NeutralTower)
│   │   ├── Tower_02
│   │   └── ... (8 towers total)
│   └── SpawnedUnits (Node2D)        [container cho units runtime]
│
├── Players (Node2D)
│   ├── Player_1 (PlayerBase)
│   ├── Player_2 (PlayerBase)
│   ├── Player_3 (PlayerBase)
│   └── Player_4 (PlayerBase)
│
├── UI (CanvasLayer)
│   ├── HUD (Control)
│   │   ├── TimerLabel
│   │   └── RoundLabel
│   ├── Panel_P1 (PlayerPanel) [góc trên trái]
│   ├── Panel_P2 (PlayerPanel) [góc trên phải]
│   ├── Panel_P3 (PlayerPanel) [góc dưới trái]
│   └── Panel_P4 (PlayerPanel) [góc dưới phải]
│
└── Systems (Node)               [invisible managers]
    ├── RoundManager
    ├── SpawnManager
    ├── ResourceManager
    └── ScoreManager
```

---

## 3. AUTOLOAD / SINGLETON

### GameConfig.gd
```gdscript
# Đây là nơi thay đổi config khi quay video khác nhau
extends Node

# Player settings
var player_count: int = 4
var player_colors: Array[Color] = [
    Color(0.9, 0.2, 0.2),   # Red
    Color(0.2, 0.4, 0.9),   # Blue
    Color(0.2, 0.8, 0.2),   # Green
    Color(0.9, 0.8, 0.1),   # Yellow
    Color(0.1, 0.8, 0.8),   # Cyan
    Color(0.6, 0.2, 0.8),   # Purple
]

# Round settings
var round_duration: float = 75.0
var rounds_per_session: int = 10
var auto_restart: bool = true

# Economy settings
var gold_per_second: float = 5.0
var gold_max: int = 50
var starting_gold: int = 10

# Simulation speed
var time_scale: float = 1.0

# AI strategies per player (index matches player index)
var ai_strategies: Array[String] = [
    "AGGRESSIVE", "BALANCED", "ECONOMY", "ADAPTIVE"
]
```

### GameState.gd
```gdscript
extends Node

enum State { IDLE, ROUND_ACTIVE, ROUND_END, SESSION_END }

signal state_changed(new_state: State)
signal round_started(round_number: int)
signal round_ended(results: Dictionary)

var current_state: State = State.IDLE
var current_round: int = 0
var session_scores: Dictionary = {}  # player_id → total score

func change_state(new_state: State) -> void:
    current_state = new_state
    state_changed.emit(new_state)
```

### EventBus.gd
```gdscript
extends Node

# Unit events
signal unit_spawned(unit: Unit, player_id: int)
signal unit_died(unit: Unit, killer_player_id: int)
signal unit_reached_base(unit: Unit, target_base: PlayerBase)

# Combat events
signal base_damaged(base: PlayerBase, amount: float, attacker_player: int)
signal base_destroyed(base: PlayerBase)

# Resource events
signal gold_changed(player_id: int, new_amount: float)

# Round events
signal tower_attacked(tower: NeutralTower, target: Unit)
```

---

## 4. NODE TYPES & ROLES

| Node | Type | Script | Vai trò |
|---|---|---|---|
| Main | Node2D | - | Root, khởi tạo |
| GameMap | Node2D | GameMap.gd | Chứa map, paths, towers |
| PlayerBase | Area2D | PlayerBase.gd | Base HP, spawn point, detect unit vào |
| PlayerPanel | Control | PlayerPanel.gd | Hiển thị gold, unit count, score |
| Unit | CharacterBody2D | Unit.gd | Di chuyển, combat |
| NeutralTower | StaticBody2D | NeutralTower.gd | Auto-attack units |
| AIController | Node | AIController.gd | Logic mua unit của mỗi player |
| RoundManager | Node | RoundManager.gd | Timer, round flow |
| SpawnManager | Node | SpawnManager.gd | Factory spawn unit |
| ResourceManager | Node | ResourceManager.gd | Gold tick mỗi giây |
| ScoreManager | Node | ScoreManager.gd | Tính & lưu điểm |

---

## 5. DATA FLOW

```
ResourceManager
    → gold_changed (EventBus)
        → AIController [nhận gold, quyết định mua]
            → SpawnManager.spawn_unit(player_id, unit_type)
                → Unit instance tạo ra
                    → Unit.follow_path()
                        → Unit.detect_enemies()
                            → UnitCombat.attack()
                                → Unit.die() → EventBus.unit_died
                    → Unit.reach_base()
                        → EventBus.base_damaged
                            → PlayerBase.take_damage()
                                → EventBus.base_destroyed (nếu HP = 0)
                                    → RoundManager.end_round()
```

---

## 6. PATH SYSTEM

### Cách implement path trong Godot 4.5:

```gdscript
# Mỗi unit dùng PathFollow2D approach
# Nhưng vì nhiều unit cùng lúc, dùng waypoint system thay thế

# Trong Unit.gd:
var waypoints: Array[Vector2] = []
var current_waypoint_index: int = 0
var move_speed: float = 80.0

func _physics_process(delta):
    if current_waypoint_index >= waypoints.size():
        _reach_destination()
        return
    
    var target = waypoints[current_waypoint_index]
    var direction = (target - global_position).normalized()
    velocity = direction * move_speed
    
    if global_position.distance_to(target) < 8.0:
        current_waypoint_index += 1
    
    move_and_slide()
```

### Path Definition (trong GameMap.gd):
```gdscript
# Waypoints cho từng path, define bằng tay hoặc lấy từ Path2D
func get_path_for_player(from_player: int, to_player: int) -> Array[Vector2]:
    # Return array of Vector2 waypoints
    pass
```

---

## 7. COLLISION LAYERS

| Layer | Tên | Dùng cho |
|---|---|---|
| 1 | world | Tường, obstacles |
| 2 | units | Unit bodies |
| 3 | unit_detection | Unit attack range (Area2D) |
| 4 | bases | PlayerBase areas |
| 5 | towers | Tower attack range |

---

## 8. PERFORMANCE NOTES (quan trọng cho simulation)

- Dùng **object pooling** cho units (tránh instantiate/free liên tục)
- Mỗi unit chỉ check combat mỗi 0.2s (không phải mỗi frame)
- **Tối đa units trên map**: Config được, mặc định 50/player
- Nếu lag: tăng `Engine.physics_ticks_per_second` hoặc giảm unit cap
- Dùng `call_deferred()` khi free unit trong physics process
