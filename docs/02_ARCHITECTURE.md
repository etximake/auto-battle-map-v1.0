# ARCHITECTURE - Godot 4.5
## Ball-Drop Auto Battle Castle Simulator

---

## 1. DINH HUONG KIEN TRUC

Project da pivot sang base mode moi:

```text
Ball Panel -> Reward Slot -> Castle Queue -> Castle Spawn -> AI Route -> Auto Battle
```

Neutral tower khong nam trong base mode. File tower hien co duoc giu trong `scenes/towers/` va `scripts/towers/` de lam optional mode sau.

---

## 2. PROJECT TREE MUC TIEU

```text
res://
|-- project.godot
|-- configs/
|   |-- default_game_config.json
|   +-- presets/
|-- scenes/
|   |-- main/
|   |   |-- Main.tscn
|   |   |-- TestMapPath.tscn
|   |   |-- TestPhase4AI.tscn        # legacy test, se thay bang test reward/castle
|   |   +-- TestUnits.tscn
|   |-- map/
|   |   +-- GameMap.tscn
|   |-- players/
|   |   +-- PlayerBase.tscn          # refactor thanh castle role
|   |-- units/
|   |   |-- Unit.tscn
|   |   |-- Scout.tscn
|   |   |-- Soldier.tscn
|   |   |-- Tank.tscn
|   |   +-- Mage.tscn
|   |-- ui/
|   |   |-- BallPanel.tscn
|   |   |-- PanelBall.tscn
|   |   |-- RewardSlot.tscn
|   |   |-- PlayerPanel.tscn
|   |   +-- HUD.tscn
|   +-- towers/
|       +-- NeutralTower.tscn        # optional mode only
|-- scripts/
|   |-- autoloads/
|   |   |-- GameConfig.gd
|   |   |-- GameState.gd
|   |   +-- EventBus.gd
|   |-- map/
|   |   +-- GameMap.gd
|   |-- players/
|   |   |-- PlayerBase.gd            # castle queue/spawn role
|   |   +-- AIController.gd          # route/target decision
|   |-- units/
|   |   +-- Unit.gd
|   |-- ui/
|   |   |-- BallPanel.gd
|   |   |-- PanelBall.gd
|   |   +-- RewardSlot.gd
|   |-- systems/
|   |   |-- RewardManager.gd
|   |   |-- SpawnManager.gd
|   |   |-- RoundManager.gd
|   |   +-- ScoreManager.gd
|   +-- towers/
|       +-- NeutralTower.gd          # optional mode only
+-- docs/
```

`ResourceManager.gd` neu con ton tai thi la legacy cua gold-buy prototype, khong phai core cua base mode.

---

## 3. MAIN SCENE HIERARCHY MUC TIEU

```text
Main (Node2D)
|-- GameMap (Node2D)
|   |-- Background
|   |-- Paths
|   |-- BaseMarkers / Castles
|   +-- SpawnedUnits
|-- Players (Node2D)
|   |-- Player_0
|   |   |-- PlayerBase or PlayerCastle
|   |   +-- AIController
|   |-- Player_1
|   |-- Player_2
|   +-- Player_3
|-- Systems (Node)
|   |-- RewardManager
|   |-- SpawnManager
|   |-- RoundManager
|   +-- ScoreManager
+-- UI (CanvasLayer)
    |-- BallPanel_P0
    |-- BallPanel_P1
    |-- BallPanel_P2
    |-- BallPanel_P3
    |-- HUD
    +-- ResultPanel
```

Khong dat `Towers` active trong base mode.

---

## 4. AUTOLOADS

### GameConfig

Chua cau hinh toan cuc:
- `player_count`
- `player_colors`
- `round_duration`
- `time_scale`
- `panel_ball_spawn_interval`
- `castle_spawn_cooldown`
- `max_units_per_player`
- `ai_strategies`

Gold config chi giu neu can legacy/optional mode.

GameConfig phai tien toi JSON-driven config:

```text
safe defaults in GameConfig.gd
  -> res://configs/default_game_config.json
  -> user://game_config_override.json
  -> validation/clamp
```

Systems khong doc JSON truc tiep. Tat ca doc qua `GameConfig`.

Config schema chi tiet: `docs/07_CONFIG_SCHEMA.md`.

### GameState

State goi y:

```gdscript
enum State { IDLE, ROUND_ACTIVE, ROUND_END, SESSION_END }
```

### EventBus

Signal trung tam giua UI panel, reward, castle, unit va round.

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

## 5. NODE ROLES

| Node | Type | Script | Vai tro |
|---|---|---|---|
| Main | Node2D | Main.gd | Bootstrap va wiring |
| GameMap | Node2D | GameMap.gd | Map, castle positions, route/path data |
| BallPanel | Control/Node2D | BallPanel.gd | Sinh ball va quan ly slots cua player |
| PanelBall | Area2D/CharacterBody2D | PanelBall.gd | Ball roi trong panel, cham reward slot |
| RewardSlot | Area2D/Control | RewardSlot.gd | Tao reward khi ball cham |
| RewardManager | Node | RewardManager.gd | Nhan reward, dua vao castle queue |
| PlayerBase/Castle | Area2D | PlayerBase.gd | HP, queue, spawn cooldown |
| AIController | Node | AIController.gd | Chon route/target cho unit |
| SpawnManager | Node | SpawnManager.gd | Factory/object pool spawn unit |
| Unit | CharacterBody2D | Unit.gd | Move, combat, die/reach castle |
| ScoreManager | Node | ScoreManager.gd | Score round/session |
| NeutralTower | StaticBody2D | NeutralTower.gd | Optional mode only |

---

## 6. DATA FLOW BASE MODE

```text
BallPanel
  -> PanelBall hits RewardSlot
  -> EventBus.reward_generated(player_id, reward_type)
  -> RewardManager queues reward to player's castle
  -> PlayerCastle stores reward in queue
  -> PlayerCastle spawn cooldown pops unit reward
  -> AIController chooses route/target
  -> SpawnManager.spawn_unit(player_id, unit_type, route)
  -> Unit follows route and fights enemies
  -> Unit reaches enemy castle
  -> castle_damaged / score update
  -> RoundManager ends or resets round
```

---

## 7. MAP & ROUTE MODEL

Hien tai path dang la waypoint array. Huong sap toi:

```gdscript
func get_route(player_id: int, target_player_id: int, route_id: String = "main") -> Array[Vector2]:
    pass
```

Base mode can nhieu route/target de AI co vai tro that:
- attack opposite castle
- attack nearest castle
- defend center lane
- split route neu map co nhanh

`get_march_path(player_id)` co the giu lam fallback tam thoi.

---

## 8. OPTIONAL MODES

### Neutral Tower Mode

Bat lai:
- `NeutralTower.tscn`
- `NeutralTower.gd`
- `optional_tower_positions`
- group `"towers"`

Dieu kien: khong anh huong base mode va khong duoc dat active mac dinh trong `Main.tscn`.
