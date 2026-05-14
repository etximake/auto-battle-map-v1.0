# CODEX PROMPT — Import vào AI Coding Assistant
## Auto Battle TD Simulator — Godot 4.5

---

## MASTER PROMPT (dán toàn bộ vào Codex/Cursor/Claude Code)

```
Bạn là Godot 4.5 GDScript expert. Tôi đang build một Auto Battle Tower Defense Simulator 
để quay video YouTube. Game chạy hoàn toàn tự động (không cần player input).

=== MÔ TẢ GAME ===
- 4 AI player (config được 2-6) mỗi góc màn hình 1280x720
- Mỗi AI tự động mua unit bằng gold tích theo thời gian
- Unit spawn tại base, tự march theo path waypoints đến base địch
- Unit gặp nhau → auto combat (dừng lại, attack nhau)
- Unit sống sót → tiếp tục march, vào base địch → gây damage
- Round kết thúc sau 75 giây hoặc khi 1 base bị phá
- Tự động reset và chạy round mới (loop vô hạn)

=== TECH STACK ===
- Godot 4.5, GDScript
- 2D top-down
- Không dùng Tilemap phức tạp (dùng ColorRect/Line2D cho map)
- Không cần âm thanh, animation phức tạp
- Không cần player input

=== AUTOLOADS (Singletons) ===
- GameConfig: player_count=4, round_duration=75.0, gold_per_second=5.0, gold_max=50
- GameState: State enum {IDLE, ROUND_ACTIVE, ROUND_END, SESSION_END}, signals
- EventBus: tất cả signals trung tâm

=== SIGNALS (EventBus) ===
- unit_spawned(unit, player_id)
- unit_died(unit, killer_player_id)
- unit_reached_base(unit, target_base)
- base_damaged(base, amount, attacker_player)
- base_destroyed(base)
- gold_changed(player_id, new_amount)
- round_reset_requested()
- tower_attacked(tower, target)

=== NODE TYPES ===
- Unit: CharacterBody2D, có states MARCHING/ATTACKING/DEAD
- PlayerBase: Area2D, HP=100, detect units entering
- NeutralTower: StaticBody2D, auto-attack units in range
- AIController: Node, think() mỗi 0.5s

=== COLLISION LAYERS ===
Layer 1=world, 2=units, 3=unit_detection, 4=bases, 5=towers

=== AI STRATEGIES ===
- AGGRESSIVE: spam unit rẻ nhất (Scout cost=5)
- BALANCED: mix Scout/Soldier/Mage theo thời gian còn lại
- ECONOMY: tích gold mua Tank (cost=20) và Mage (cost=15)
- ADAPTIVE: đọc trạng thái map, phản ứng theo số unit địch

=== UNIT STATS ===
Scout:   hp=20,  dmg=5,  speed=120, range=25, cooldown=0.8,  cost=5
Soldier: hp=50,  dmg=15, speed=80,  range=30, cooldown=1.0,  cost=10
Tank:    hp=150, dmg=8,  speed=50,  range=25, cooldown=1.5,  cost=20
Mage:    hp=30,  dmg=40, speed=70,  range=80, cooldown=2.0,  cost=15

=== PATH SYSTEM ===
- Waypoint-based (Array[Vector2]), không dùng NavigationAgent
- Path từ base mỗi player → center → base đối thủ
- Mỗi unit lưu array waypoints và current_waypoint_index
- Khi đến waypoint trong 8px → tăng index

=== OBJECT POOL ===
- SpawnManager dùng object pool để tái sử dụng Unit instances
- Pool pre-warm 10 units/loại khi khởi động
- Unit.reset() để clear state khi return to pool

=== PERFORMANCE ===
- Max 30 units/player (tổng max 120 units trên map)
- AI think() mỗi 0.5s (không phải mỗi frame)
- Unit combat check mỗi frame nhưng chỉ attack khi cooldown hết

Khi tôi hỏi về một file cụ thể, hãy viết code đầy đủ, không truncate.
Luôn dùng GDScript 4.x syntax (không phải GDScript 2.x).
Dùng type hints khi có thể: var x: int = 0, func foo() -> void:
```

---

## PROMPT THEO TỪNG TASK

### Task 1: Tạo GameConfig.gd
```
Viết file GameConfig.gd (Autoload/Singleton) cho Godot 4.5.
File này chứa tất cả config của game:
- player_count: int = 4
- player_colors: Array[Color] (6 màu cho 6 player tối đa)
- round_duration: float = 75.0
- rounds_per_session: int = 10  
- auto_restart: bool = true
- gold_per_second: float = 5.0
- gold_max: int = 50
- starting_gold: int = 10
- time_scale: float = 1.0
- ai_strategies: Array[String] = ["AGGRESSIVE", "BALANCED", "ECONOMY", "ADAPTIVE"]

Dùng GDScript 4.5 syntax đầy đủ với type hints.
```

### Task 2: Tạo EventBus.gd
```
Viết EventBus.gd (Autoload) cho Godot 4.5 game Auto Battle TD.
Đây là signal bus trung tâm, chứa tất cả signals:
- unit_spawned(unit: Node, player_id: int)
- unit_died(unit: Node, killer_player_id: int)
- unit_reached_base(unit: Node, target_base: Node)
- base_damaged(base: Node, amount: float, attacker_player: int)
- base_destroyed(base: Node)
- gold_changed(player_id: int, new_amount: float)
- round_reset_requested()
- tower_attacked(tower: Node, target: Node)

Chỉ cần extends Node và khai báo signals. Không logic gì khác.
```

### Task 3: Tạo Unit.gd (base class)
```
Viết Unit.gd cho Godot 4.5. Node type: CharacterBody2D.

Stats: player_id, unit_type, max_hp, current_hp, damage, move_speed, 
       attack_range, attack_cooldown

State machine: enum UnitState {MARCHING, ATTACKING, DEAD}

Waypoint system: waypoints: Array[Vector2], current_waypoint_index: int
- Trong MARCHING: move toward current waypoint, nếu đến gần < 8px thì tăng index
- Nếu hết waypoints: gọi _reach_base()

Combat: 
- Trong MARCHING: check DetectionArea.get_overlapping_bodies() tìm enemy unit
- Nếu có enemy → switch sang ATTACKING, dừng lại
- Trong ATTACKING: attack enemy mỗi attack_cooldown giây
- Nếu enemy chết hoặc ra khỏi range → switch về MARCHING

Functions:
- initialize(p_id, spawn_pos, path) → setup unit
- take_damage(amount, attacker_id) → reduce hp, gọi _die nếu hp <= 0
- reset() → clear state cho object pool

Dùng EventBus signals. Dùng call_deferred khi free/return to pool.
```

### Task 4: Tạo AIController.gd
```
Viết AIController.gd cho Godot 4.5. Node type: Node.

Exports: player_id: int, strategy: String

think() được gọi mỗi 0.5s (dùng Timer hoặc accumulate delta).

4 strategies:
- AGGRESSIVE: mua Scout (cost 5) ngay khi đủ gold
- BALANCED: suy nghĩ theo thời gian còn lại của round, mix unit types
- ECONOMY: tích gold, ưu tiên Tank (20) và Mage (15)
- ADAPTIVE: đọc count units trên map, so sánh my_units vs enemy_units gần base

Mỗi strategy gọi _buy_unit(unit_type) nếu đủ gold.
_buy_unit gọi ResourceManager.spend_gold() và SpawnManager.spawn_unit().
Dùng get_tree().get_nodes_in_group("units") để đếm units.
```

### Task 5: Tạo GameMap.gd + setup path
```
Viết GameMap.gd cho Godot 4.5. Node type: Node2D.

Resolution: 1280x720. Map area: x=200 to x=1080, y=0 to y=720.

Base positions:
  Player 0: Vector2(280, 80)    - top-left
  Player 1: Vector2(1000, 80)   - top-right
  Player 2: Vector2(280, 640)   - bottom-left
  Player 3: Vector2(1000, 640)  - bottom-right
  Center:   Vector2(640, 360)

Hardcode waypoints cho 4 paths từ mỗi base đến center.
Function get_march_path(player_id) → ghép path player → reversed path đối thủ.
Main opponent: 0↔3, 1↔2.

Cũng có _load_paths_from_nodes() để đọc từ Path2D nodes nếu có trong scene.
```

### Task 6: Tạo RoundManager.gd
```
Viết RoundManager.gd cho Godot 4.5. Node type: Node.

Flow:
- start_round(): tăng current_round, start Timer(75s), emit GameState signals
- _on_round_timeout(): gọi end_round("timeout")
- end_round(reason): tính score, emit round_ended, chờ 3s, gọi _prepare_next_round
- _prepare_next_round(): nếu đủ rounds → _end_session, không thì emit reset + start mới
- _end_session(): print kết quả, nếu auto_restart chờ 5s rồi restart

Cần node con: Timer tên "RoundTimer".
Kết nối EventBus.base_destroyed để gọi end_round("base_destroyed").
```

### Task 7: Tạo SpawnManager.gd với Object Pool
```
Viết SpawnManager.gd cho Godot 4.5. Node type: Node.

Object pool: Dictionary unit_type → Array[Unit]
Pre-warm: 10 units mỗi loại khi _ready()

spawn_unit(player_id, unit_type):
1. Check max units/player (30)
2. Lấy unit từ pool (hoặc instantiate mới nếu pool trống)
3. Setup: initialize(player_id, spawn_pos, path)
4. Show unit, add to active_units
5. emit EventBus.unit_spawned

return_to_pool(unit):
1. Remove từ active_units
2. unit.hide() + unit.reset()
3. Append về pool

Scenes preload: Scout, Soldier, Tank, Mage từ res://scenes/units/
Container node cho units: /root/Main/GameMap/SpawnedUnits
```

### Task 8: Tạo ResourceManager.gd
```
Viết ResourceManager.gd cho Godot 4.5. Node type: Node.

gold: Dictionary [player_id → float]

_process(delta): nếu state là ROUND_ACTIVE, cộng gold_per_second*delta cho mỗi player
add_gold(player_id, amount): cộng gold, clamp với gold_max, emit EventBus.gold_changed
spend_gold(player_id, amount) → bool: nếu đủ thì trừ và return true
get_gold(player_id) → float

Reset khi nhận EventBus.round_reset_requested.
```

### Task 9: Tạo PlayerPanel.gd (UI)
```
Viết PlayerPanel.gd cho Godot 4.5. Node type: PanelContainer (Control).

Export: player_id: int

Nodes con cần có:
- ScoreLabel: Label (số lớn)
- GoldBar: ProgressBar (max=50)
- GoldLabel: Label ("Gold: XX/50")
- Scout_Count, Soldier_Count, Tank_Count, Mage_Count: Labels

Connect EventBus.gold_changed → update gold display
Connect EventBus.unit_spawned + unit_died → update unit counts
Connect GameState.round_ended → update score display

update_gold(amount): cập nhật GoldBar và GoldLabel
update_unit_count(): đếm units trong group "units" với player_id đúng
```

### Task 10: Bootstrap — Main.gd (khởi động simulation)
```
Viết Main.gd cho Godot 4.5. Node type: Node2D.

_ready():
1. Set Engine.time_scale = GameConfig.time_scale
2. Setup PlayerBase nodes: gán player_id cho từng base
3. Setup AIController nodes: gán player_id và strategy
4. Setup PlayerPanel: gán player_id
5. Đợi 1 frame rồi gọi RoundManager.start_round()

Không cần _process, không cần input handling.
Chỉ là bootstrap và wiring.
```

---

## THỨ TỰ BUILD (Recommended)

```
Phase 1 - Core Foundation:
  1. GameConfig.gd        (autoload)
  2. GameState.gd         (autoload)
  3. EventBus.gd          (autoload)
  4. Unit.gd              (base class)
  5. GameMap.gd           (paths & waypoints)

Phase 2 - Systems:
  6. ResourceManager.gd
  7. SpawnManager.gd
  8. AIController.gd
  9. RoundManager.gd
  10. ScoreManager.gd

Phase 3 - Entities:
  11. PlayerBase.gd
  12. NeutralTower.gd
  13. Scout/Soldier/Tank/Mage.tscn (set stats)

Phase 4 - UI:
  14. PlayerPanel.gd
  15. HUD.gd

Phase 5 - Wiring:
  16. Main.gd (bootstrap)
  17. Test & tune AI strategies
```
