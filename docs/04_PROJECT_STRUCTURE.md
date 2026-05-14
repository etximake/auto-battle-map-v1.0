# PROJECT STRUCTURE - Godot 4.5
## Ball-Drop Auto Battle Castle Simulator

---

## 1. PROJECT SETTINGS

```text
Engine: Godot 4.5
Resolution: 1280x720
Main Scene: res://scenes/main/Main.tscn
Input: khong dung player input trong gameplay prototype
```

Autoloads:

```text
res://scripts/autoloads/GameConfig.gd -> GameConfig
res://scripts/autoloads/GameState.gd  -> GameState
res://scripts/autoloads/EventBus.gd   -> EventBus
```

---

## 2. FILE TREE MUC TIEU

```text
AutoBattleTD/
|-- project.godot
|-- scenes/
|   |-- main/
|   |   |-- Main.tscn
|   |   |-- TestUnits.tscn
|   |   |-- TestMapPath.tscn
|   |   |-- TestBallPanel.tscn
|   |   +-- TestCastleQueue.tscn
|   |-- map/
|   |   +-- GameMap.tscn
|   |-- players/
|   |   +-- PlayerBase.tscn
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
|       +-- NeutralTower.tscn        # optional mode
|-- scripts/
|   |-- autoloads/
|   |   |-- GameConfig.gd
|   |   |-- GameState.gd
|   |   +-- EventBus.gd
|   |-- map/
|   |   +-- GameMap.gd
|   |-- players/
|   |   |-- PlayerBase.gd
|   |   +-- AIController.gd
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
|       +-- NeutralTower.gd          # optional mode
+-- docs/
```

`ResourceManager.gd` neu con trong repo thi de legacy/optional economy, khong can trong base mode.

---

## 3. MAIN.TSCN MUC TIEU

```text
Main (Node2D)
|-- GameMap (instance: scenes/map/GameMap.tscn)
|-- Players (Node2D)
|   |-- Player_0
|   |   |-- PlayerBase (player_id=0)
|   |   +-- AIController (player_id=0, strategy=AGGRESSIVE)
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

Base mode khong co `Towers` node active.

---

## 4. GAMEMAP.TSCN

```text
GameMap (Node2D) [script: GameMap.gd]
|-- Background
|-- PathVisual
|   |-- PathLine_P0
|   |-- PathLine_P1
|   |-- PathLine_P2
|   +-- PathLine_P3
|-- BaseMarkers / Castles
|   |-- CastleMarker_P0
|   |-- CastleMarker_P1
|   |-- CastleMarker_P2
|   +-- CastleMarker_P3
+-- SpawnedUnits
```

Neu can luu marker tower cho optional mode, dat ten ro:

```text
OptionalTowerMarkers (Node2D) [hidden or editor-only]
```

Khong instance `NeutralTower` trong scene base mode.

---

## 5. UI BALL PANEL SCENES

### BallPanel.tscn

```text
BallPanel (Node2D or Control) [script: BallPanel.gd]
|-- Background
|-- BallSpawnPoint
|-- BallContainer
|-- RewardSlots
|   |-- Slot_Scout
|   |-- Slot_Soldier
|   |-- Slot_Tank
|   |-- Slot_Mage
|   +-- Slot_X2
+-- CounterLabels
```

Exports:

```gdscript
@export var player_id: int = 0
@export var panel_rect: Rect2
@export var ball_scene: PackedScene
```

### PanelBall.tscn

```text
PanelBall (Area2D or CharacterBody2D) [script: PanelBall.gd]
|-- Body (Polygon2D or ColorRect primitive)
+-- CollisionShape2D
```

### RewardSlot.tscn

```text
RewardSlot (Area2D) [script: RewardSlot.gd]
|-- Background (ColorRect/Polygon2D)
|-- Label
+-- CollisionShape2D
```

---

## 6. PLAYERBASE / CASTLE SCENE

```text
PlayerBase (Area2D) [script: PlayerBase.gd]
|-- Body
|-- CollisionShape2D
|-- SpawnPoint
|-- HPBar
+-- QueueLabel
```

Vai tro:
- HP castle.
- Queue reward/unit.
- Spawn unit theo cooldown.
- Goi AI de lay route.

Ten `PlayerBase` co the giu de tranh doi file nhieu, nhung tai lieu coi no la castle.

---

## 7. UNIT SCENES

```text
Unit (CharacterBody2D) [script: Unit.gd]
|-- Body (Polygon2D)
|-- LeftEye (Polygon2D)
|-- RightEye (Polygon2D)
|-- CollisionShape2D
|-- DetectionArea
|-- HPBar
+-- Label
```

Unit variants:

```text
Scout.tscn
Soldier.tscn
Tank.tscn
Mage.tscn
```

Tat ca van dung Jelly Blob primitive trong prototype.

---

## 8. MAP COORDINATE REFERENCE

```text
Map area: x=192..1088, y=0..720
Map size: 896x720

P0 castle: Vector2(304, 134)
P1 castle: Vector2(976, 134)
P2 castle: Vector2(304, 586)
P3 castle: Vector2(976, 586)
Center:    Vector2(640, 360)
```

Side panels:

```text
Left panel width: 192
Right panel starts: x=1088
```

---

## 9. PHYSICS LAYERS

```text
Layer 1: world
Layer 2: units
Layer 3: unit_detection
Layer 4: castles
Layer 5: panel_balls
Layer 6: reward_slots
Layer 7: optional_towers
```

`optional_towers` chi dung khi bat Neutral Tower mode.

---

## 10. TEST SCENES

```text
TestUnits.tscn       -> unit movement/combat visual
TestMapPath.tscn     -> map positions/path visual
TestBallPanel.tscn   -> ball hits reward slots
TestCastleQueue.tscn -> reward queue -> castle spawn
Main.tscn            -> integrated base mode
```

Moi phase nen co mini test rieng truoc khi noi vao `Main.tscn`.
