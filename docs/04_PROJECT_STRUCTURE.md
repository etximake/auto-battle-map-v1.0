# PROJECT STRUCTURE — Godot 4.5
## Auto Battle TD Simulator — File & Scene Setup Guide

---

## 1. KHỞI TẠO PROJECT

### Bước 1: Tạo project mới
```
Godot 4.5 → New Project
Name: AutoBattleTD
Renderer: Forward+ (hoặc Compatibility nếu máy yếu)
Resolution: 1280 × 720
```

### Bước 2: Project Settings
```
Display → Window:
  - Width: 1280
  - Height: 720
  - Resizable: false (fixed cho quay video)

Application → Run:
  - Main Scene: res://scenes/main/Main.tscn
```

### Bước 3: Autoloads (Project → Project Settings → Autoload)
```
Path                              Name
res://scripts/autoloads/GameConfig.gd   → GameConfig
res://scripts/autoloads/GameState.gd    → GameState
res://scripts/autoloads/EventBus.gd     → EventBus
```

---

## 2. CÂY FILE ĐẦY ĐỦ

```
AutoBattleTD/
│
├── project.godot
│
├── scenes/
│   ├── main/
│   │   └── Main.tscn
│   │
│   ├── map/
│   │   └── GameMap.tscn
│   │
│   ├── players/
│   │   ├── PlayerBase.tscn
│   │   └── PlayerPanel.tscn
│   │
│   ├── units/
│   │   ├── Unit.tscn          ← Base scene (không dùng trực tiếp)
│   │   ├── Scout.tscn
│   │   ├── Soldier.tscn
│   │   ├── Tank.tscn
│   │   └── Mage.tscn
│   │
│   ├── towers/
│   │   └── NeutralTower.tscn
│   │
│   └── ui/
│       ├── HUD.tscn
│       └── RoundResult.tscn
│
├── scripts/
│   ├── autoloads/
│   │   ├── GameConfig.gd
│   │   ├── GameState.gd
│   │   └── EventBus.gd
│   │
│   ├── map/
│   │   └── GameMap.gd
│   │
│   ├── players/
│   │   ├── PlayerBase.gd
│   │   ├── PlayerPanel.gd
│   │   └── AIController.gd
│   │
│   ├── units/
│   │   ├── Unit.gd
│   │   └── UnitData.gd        ← Resource class
│   │
│   ├── towers/
│   │   └── NeutralTower.gd
│   │
│   └── systems/
│       ├── RoundManager.gd
│       ├── SpawnManager.gd
│       ├── ResourceManager.gd
│       └── ScoreManager.gd
│
└── resources/
    └── unit_configs/
        ├── scout_data.tres
        ├── soldier_data.tres
        ├── tank_data.tres
        └── mage_data.tres
```

---

## 3. SCENE SETUP CHI TIẾT

### Main.tscn
```
Main (Node2D) [script: none]
├── GameMap (Node2D) [script: GameMap.gd] [scene: GameMap.tscn]
├── Players (Node2D)
│   ├── Player_0 (Node2D)
│   │   ├── PlayerBase (Area2D) [script: PlayerBase.gd]
│   │   │   ├── CollisionShape2D (CircleShape r=40)
│   │   │   ├── SpawnPoint (Marker2D) ← spawn units ở đây
│   │   │   └── HPBar (ProgressBar)
│   │   └── AIController (Node) [script: AIController.gd]
│   │       └── [export] player_id = 0
│   │       └── [export] strategy = "AGGRESSIVE"
│   ├── Player_1 ... (tương tự)
│   ├── Player_2 ...
│   └── Player_3 ...
│
├── Systems (Node)
│   ├── RoundManager (Node) [script: RoundManager.gd]
│   │   └── RoundTimer (Timer) [wait_time=75, one_shot=true]
│   ├── SpawnManager (Node) [script: SpawnManager.gd]
│   ├── ResourceManager (Node) [script: ResourceManager.gd]
│   └── ScoreManager (Node) [script: ScoreManager.gd]
│
└── UI (CanvasLayer)
    ├── HUD (Control) [script: HUD.gd] [scene: HUD.tscn]
    ├── Panel_P0 (Control) [scene: PlayerPanel.tscn] [anchor: top-left]
    ├── Panel_P1 (Control) [scene: PlayerPanel.tscn] [anchor: top-right]
    ├── Panel_P2 (Control) [scene: PlayerPanel.tscn] [anchor: bottom-left]
    └── Panel_P3 (Control) [scene: PlayerPanel.tscn] [anchor: bottom-right]
```

### GameMap.tscn
```
GameMap (Node2D) [script: GameMap.gd]
├── Background (ColorRect) [color: #5a8f3c, size: 1280×720]
├── Paths (Node2D)
│   ├── Path_P0 (Path2D)   ← vẽ path từ góc top-left → center
│   ├── Path_P1 (Path2D)   ← vẽ path từ góc top-right → center
│   ├── Path_P2 (Path2D)   ← vẽ path từ góc bottom-left → center
│   └── Path_P3 (Path2D)   ← vẽ path từ góc bottom-right → center
├── PathVisual (Node2D)    ← vẽ path bằng Line2D (màu vàng/be)
│   ├── PathLine_P0 (Line2D) [width=40, color=#e8d08a]
│   ├── PathLine_P1 (Line2D)
│   ├── PathLine_P2 (Line2D)
│   └── PathLine_P3 (Line2D)
├── Towers (Node2D)
│   ├── Tower_01 (NeutralTower) [position: trên path P0]
│   ├── Tower_02 (NeutralTower) [position: trên path P0]
│   ├── Tower_03 (NeutralTower) [position: trên path P1]
│   ├── Tower_04 (NeutralTower) [position: trên path P1]
│   ├── Tower_05 (NeutralTower) [position: trên path P2]
│   ├── Tower_06 (NeutralTower) [position: trên path P2]
│   ├── Tower_07 (NeutralTower) [position: trên path P3]
│   └── Tower_08 (NeutralTower) [position: trên path P3]
└── SpawnedUnits (Node2D)  ← container runtime cho units
```

### Unit.tscn (base, không dùng trực tiếp)
```
Unit (CharacterBody2D) [script: Unit.gd]
├── Sprite (ColorRect) [size: 16×16, color: white]
├── CollisionShape2D (CapsuleShape h=16, r=6)
├── HPBar (ProgressBar) [size: 20×4, position: above unit]
├── DetectionArea (Area2D)
│   └── CollisionShape2D (CircleShape r=30) ← attack range
└── RangeIndicator (Node2D) [visible=false, debug only]
```

### Scout.tscn (inherits Unit.tscn)
```
Scout (Unit) [extends Unit.tscn]
[script override các stats:]
  max_hp = 20
  damage = 5
  move_speed = 120    ← nhanh nhất
  attack_range = 25
  attack_cooldown = 0.8
  unit_type = "Scout"
```

### Soldier.tscn
```
Soldier (Unit)
  max_hp = 50
  damage = 15
  move_speed = 80
  attack_range = 30
  attack_cooldown = 1.0
  unit_type = "Soldier"
```

### Tank.tscn
```
Tank (Unit)
  max_hp = 150
  damage = 8
  move_speed = 50     ← chậm nhất
  attack_range = 25
  attack_cooldown = 1.5
  unit_type = "Tank"
```

### Mage.tscn
```
Mage (Unit)
  max_hp = 30
  damage = 40         ← damage cao nhất
  move_speed = 70
  attack_range = 80   ← range xa nhất
  attack_cooldown = 2.0
  unit_type = "Mage"
```

### NeutralTower.tscn
```
NeutralTower (StaticBody2D) [script: NeutralTower.gd]
├── Sprite (ColorRect) [size: 24×24, color: #888888]
├── CollisionShape2D (RectShape 24×24)
├── RangeArea (Area2D)
│   └── CollisionShape2D (CircleShape r=100)
└── HPBar (ProgressBar) [size: 30×4]
```

### PlayerPanel.tscn
```
PlayerPanel (PanelContainer) [size: 200×240]
├── VBoxContainer
│   ├── ScoreLabel (Label) ← số lớn (score/wave)
│   ├── GoldBar (ProgressBar) [max=50] ← visualize gold
│   ├── GoldLabel (Label) ← "Gold: XX/50"
│   └── UnitCountContainer (HBoxContainer)
│       ├── Scout_Count (Label) ← "S: X/30"
│       ├── Soldier_Count (Label)
│       ├── Tank_Count (Label)
│       └── Mage_Count (Label)
└── [script: PlayerPanel.gd]
    └── [export] player_id: int
```

### HUD.tscn
```
HUD (Control) [anchor: full rect]
├── TimerContainer (HBoxContainer) [position: top-left]
│   ├── TimerLabel (Label) ← "00:08 / 01:15"
│   └── RoundLabel (Label) ← "Round 3"
└── [script: HUD.gd]
```

---

## 4. MAP COORDINATE REFERENCE

Với resolution 1280×720, map chiếm phần giữa (trừ 200px hai bên cho panels):

```
Map area: x=200 to x=1080, y=0 to y=720
Map size: 880 × 720

Base positions (approximate):
  Player 0 (top-left):     Vector2(280, 80)
  Player 1 (top-right):    Vector2(1000, 80)
  Player 2 (bottom-left):  Vector2(280, 640)
  Player 3 (bottom-right): Vector2(1000, 640)

Center:                    Vector2(640, 360)

Path waypoints P0 (top-left → center):
  [Vector2(280,80), Vector2(320,150), Vector2(400,200), 
   Vector2(480,280), Vector2(560,320), Vector2(640,360)]

Path waypoints P1 (top-right → center):
  [Vector2(1000,80), Vector2(960,150), Vector2(880,200),
   Vector2(800,280), Vector2(720,320), Vector2(640,360)]

(P2, P3 tương tự nhưng từ dưới lên)
```

---

## 5. PHYSICS LAYERS SETUP

Project Settings → Layer Names → 2D Physics:
```
Layer 1: world
Layer 2: units
Layer 3: unit_detection
Layer 4: bases
Layer 5: towers
```

Unit CollisionShape:
- Layer: 2 (units)
- Mask: 2 (va chạm với units khác)

Unit DetectionArea:
- Layer: 3
- Mask: 2 (detect units)

PlayerBase:
- Layer: 4
- Mask: 2 (detect units entering)

Tower RangeArea:
- Layer: 5
- Mask: 2 (detect units in range)
