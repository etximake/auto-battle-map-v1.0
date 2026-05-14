# CODEX PROMPT - Godot 4.5
## Ball-Drop Auto Battle Castle Simulator

---

## MASTER PROMPT

```text
Ban la Godot 4.5 GDScript developer. Project la game auto battle simulator de quay video YouTube.

Huong game chinh:
- 4 AI players.
- Hai ben man hinh co cac Ball Panel mau.
- Ball tu roi/chay trong panel va cham RewardSlot.
- RewardSlot tao unit/item reward cho castle cua player tuong ung.
- Castle dua reward vao queue va spawn unit ra map theo cooldown.
- AI khong mua unit bang gold trong base mode. AI chon route/target cho unit sau khi castle spawn.
- Unit tu di chuyen, tu combat, vao castle dich thi gay damage/score.
- Game chay tu dong, khong dung player input.

Tech:
- Godot 4.5, GDScript 4.x.
- 2D top-down, resolution 1280x720.
- Prototype dung primitive nodes, chua dung sprite/image asset that.
- Khong dung Input.*.
- Moi GDScript file nen duoi 200 dong.
- Tham so gameplay phai tien toi JSON config qua GameConfig, khong hardcode them tham so moi neu co the config duoc.

Base mode:
Ball Panel -> Reward Slot -> RewardManager -> Castle Queue -> Castle Spawn -> AI Route -> Auto Battle.

NeutralTower:
- Da co the giu file de tai dung.
- Khong active trong base mode.
- Chi dung cho optional Neutral Tower / Hazard / Capture mode sau.
```

---

## PROJECT FACTS

```text
Map area: x=192..1088, y=0..720
Center: Vector2(640, 360)

P0 castle: Vector2(304, 134)
P1 castle: Vector2(976, 134)
P2 castle: Vector2(304, 586)
P3 castle: Vector2(976, 586)
```

Colors:

```text
P0 #E74C3C
P1 #3498DB
P2 #2ECC71
P3 #F1C40F
other #AAAAAA
```

---

## REQUIRED AUTOLOADS

```text
GameConfig
GameState
EventBus
```

Config load direction:

```text
GameConfig safe defaults
  -> res://configs/default_game_config.json
  -> user://game_config_override.json
  -> validate / clamp
```

Config schema: `docs/07_CONFIG_SCHEMA.md`.

EventBus target signals:

```gdscript
signal reward_generated(player_id: int, reward_type: String)
signal reward_queued(player_id: int, reward_type: String)
signal castle_spawn_requested(player_id: int, unit_type: String)
signal unit_spawned(unit: Node, player_id: int)
signal unit_died(unit: Node, killer_player_id: int)
signal unit_reached_castle(unit: Node, target_castle: Node)
signal castle_damaged(castle: Node, amount: float, attacker_player: int)
signal castle_destroyed(castle: Node)
signal round_reset_requested()
```

---

## TASK PROMPTS

### Task 0: Add JSON config foundation

```text
Cap nhat GameConfig.gd de load JSON config cho Godot 4.5.
Load order:
1. Safe defaults trong GameConfig.gd
2. res://configs/default_game_config.json neu ton tai
3. user://game_config_override.json neu ton tai
4. validate/clamp

Tao configs/default_game_config.json theo docs/07_CONFIG_SCHEMA.md.
Khong de BallPanel/Unit/SpawnManager parse JSON truc tiep.
Game systems chi doc qua GameConfig.
Neu JSON loi, game khong crash; push_warning va dung fallback.
```

### Task 1: Reconcile GameMap base mode

```text
Doc GameMap.gd va GameMap.tscn. Hay bo/tat NeutralTower khoi base mode.
Khong xoa scripts/towers/NeutralTower.gd hoac scenes/towers/NeutralTower.tscn.
Neu can giu vi tri T, doi thanh optional_tower_positions/OptionalTowerMarkers va khong active.
Dam bao Main.tscn hoac scene test chay khong co tower ban unit.
```

### Task 2: Update EventBus for reward loop

```text
Cap nhat EventBus.gd cho Godot 4.5.
Them reward/castle signals:
- reward_generated(player_id: int, reward_type: String)
- reward_queued(player_id: int, reward_type: String)
- castle_spawn_requested(player_id: int, unit_type: String)
- unit_reached_castle(unit: Node, target_castle: Node)
- castle_damaged(castle: Node, amount: float, attacker_player: int)
- castle_destroyed(castle: Node)
Giu signal unit_spawned/unit_died/round_reset_requested neu dang co.
Signals gold/tower neu dang co thi de lai nhung comment la legacy/optional.
```

### Task 3: Create BallPanel prototype

```text
Tao scenes/ui/BallPanel.tscn va scripts/ui/BallPanel.gd.
BallPanel tu spawn PanelBall theo timer.
Exports:
- player_id: int
- ball_scene: PackedScene
- spawn_interval: float
- panel_bounds: Rect2

Khong dung Input.*.
Prototype co the dung scripted motion, chua can physics phuc tap.
Moi khi ball cham RewardSlot, RewardSlot se emit reward_generated.
```

### Task 4: Create PanelBall

```text
Tao scenes/ui/PanelBall.tscn va scripts/ui/PanelBall.gd.
Node co the la Area2D hoac CharacterBody2D.
Dung primitive visual, khong sprite.
Ball co:
- player_id
- velocity
- panel_bounds
- setup(new_player_id, bounds)
- reset/despawn

Ball di chuyen tu dong trong panel va bi xoa/reset sau khi cham slot.
```

### Task 5: Create RewardSlot

```text
Tao scenes/ui/RewardSlot.tscn va scripts/ui/RewardSlot.gd.
RewardSlot la Area2D.
Exports:
- player_id: int
- reward_type: String

Khi PanelBall cua cung player cham slot:
- emit EventBus.reward_generated(player_id, reward_type)
- goi despawn/reset tren ball

Visual dung primitive ColorRect/Polygon2D/Label.
```

### Task 6: Create RewardManager

```text
Tao scripts/systems/RewardManager.gd.
RewardManager listen EventBus.reward_generated.
Tim PlayerBase/PlayerCastle theo player_id trong group "castles".
Goi castle.queue_reward(reward_type).
Emit reward_queued.
Khong spawn unit truc tiep trong RewardManager.
```

### Task 7: Refactor PlayerBase into castle queue

```text
Cap nhat scripts/players/PlayerBase.gd de dong vai tro castle.
Them:
- reward_queue: Array[String]
- queue_reward(reward_type: String) -> void
- spawn_timer/spawn_cooldown
- _process(delta) pop queue khi cooldown het

Khi reward la unit:
1. Tim AIController cua player.
2. Lay route_points tu AI/GameMap.
3. Goi SpawnManager.spawn_unit(player_id, reward_type, route_points).

Giu HP/damage/base destroyed logic neu dang co.
```

### Task 8: Refactor SpawnManager API

```text
Cap nhat SpawnManager.gd.
API muc tieu:
spawn_unit(player_id: int, unit_type: String, path_points: Array[Vector2]) -> Unit

SpawnManager:
- Lay/instantiate unit scene.
- Dat spawn position theo castle/player.
- Goi setup/init tren Unit voi path_points.
- Add vao SpawnedUnits.
- Emit unit_spawned.

Khong yeu cau ResourceManager.spend_gold trong base mode.
```

### Task 9: Refactor AIController

```text
Cap nhat AIController.gd.
Bo logic mua unit bang gold khoi base mode.
AIController chi cung cap:
- choose_target_player(unit_type: String) -> int
- choose_route(unit_type: String, target_player_id: int) -> Array[Vector2]

Strategy:
AGGRESSIVE chon target gan/yeu.
BALANCED xoay vong target.
ECONOMY co the giu burst/item sau.
ADAPTIVE doc so unit tren map va doi target.
```

### Task 10: Integrated test scene

```text
Tao TestCastleQueue.tscn hoac cap nhat Main.tscn de test:
BallPanel spawn ball -> RewardSlot -> RewardManager -> Castle queue -> SpawnManager -> Unit di path.
Khong co NeutralTower active.
Khong co loi console.
Khong dung Input.*.
```

---

## BUILD ORDER MOI

```text
1. Reconcile GameMap, remove active towers from base mode
2. EventBus reward/castle signals
3. BallPanel + PanelBall + RewardSlot
4. RewardManager
5. PlayerBase castle queue
6. SpawnManager API from castle queue
7. AIController route decision
8. Round/UI integration
9. Optional Neutral Tower mode later
```
