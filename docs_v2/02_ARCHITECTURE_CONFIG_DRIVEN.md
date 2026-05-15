# 02 — Architecture Config-Driven

## 1. Architecture principle

Project không được build theo số lượng team cố định. Tất cả hệ thống phải đọc từ `GameConfig`.

```text
GameConfig
→ Main/RoundManager tạo teams
→ BallPanel được tạo theo teams
→ GameMap trả position/route theo teams
→ AI chọn target từ active teams
→ SpawnManager/ScoreManager/HUD dùng range(players_count)
```

## 2. Target project tree

```text
res://
  configs/
    default_game_config.json
    presets/
  scenes/
    main/
      Main.tscn
      TestBallPanel.tscn
      TestCastleQueue.tscn
      TestAutoBattleLoop.tscn
      TestRoundLoop.tscn
      TestCastleShooter.tscn
    map/
      GameMap.tscn
    players/
      PlayerBase.tscn
    units/
      Unit.tscn
      Projectile.tscn
    ui/
      BallPanel.tscn
      PanelBall.tscn
      RewardSlot.tscn
      RoundHud.tscn
    towers/
      NeutralTower.tscn
  scripts/
    autoloads/
      GameConfig.gd
      GameState.gd
      EventBus.gd
    map/
      GameMap.gd
    players/
      PlayerBase.gd
      AIController.gd
      CastleShooter.gd
    units/
      Unit.gd
      Projectile.gd
    ui/
      BallPanel.gd
      PanelBall.gd
      RewardSlot.gd
      RoundHud.gd
    systems/
      RewardManager.gd
      SpawnManager.gd
      ScoreManager.gd
      RoundManager.gd
    towers/
      NeutralTower.gd
```

## 3. Main scene dynamic hierarchy

```text
Main
├── GameMap
├── Teams
│   ├── Team_0
│   │   ├── PlayerBase
│   │   └── AIController
│   ├── Team_1
│   └── Team_N
├── Systems
│   ├── RewardManager
│   ├── SpawnManager
│   ├── ScoreManager
│   └── RoundManager
└── UI
    ├── LeftPanels
    │   └── BallPanel for even team ids
    ├── RightPanels
    │   └── BallPanel for odd team ids
    └── RoundHud
```

Không nên đặt sẵn cố định `Player_0..Player_5` rồi để code phụ thuộc scene đó. Có thể dùng scene markers trong editor, nhưng logic phải dynamic.

## 4. Data flow

```text
BallPanel
→ PanelBall hits RewardSlot
→ EventBus.reward_generated(player_id, reward_type)
→ RewardManager finds PlayerBase by player_id
→ PlayerBase.queue_reward(reward_type)
→ PlayerBase spawn cooldown pops queue
→ AIController chooses target/route
→ SpawnManager.spawn_unit(player_id, unit_type, route)
→ Unit follows route and fights
→ Unit reaches enemy PlayerBase
→ PlayerBase.take_damage()
→ CastleShooter fires at enemy units in range
→ ScoreManager listens to damage/kill/destroy
→ RoundManager checks alive teams/timer
```

## 5. Groups

```text
"teams"        → team root nodes
"castles"      → PlayerBase / TeamTower
"units"        → active units
"ball_panels"  → active BallPanel
"reward_slots" → RewardSlot
"projectiles"  → active projectiles
"towers"       → optional NeutralTower only
```

## 6. EventBus required signals

```gdscript
signal reward_generated(player_id: int, reward_type: String)
signal reward_queued(player_id: int, reward_type: String)

signal castle_spawn_requested(player_id: int, unit_type: String)
signal unit_spawned(unit: Node, player_id: int)
signal unit_died(unit: Node, killer_player_id: int)
signal unit_reached_castle(unit: Node, target_castle: Node)

signal castle_damaged(castle: Node, amount: float, attacker_player: int)
signal castle_destroyed(castle: Node)
signal castle_shot_fired(castle: Node, target: Node)

signal round_reset_requested()
signal round_started(round_number: int)
signal round_ended(winner_player_id: int)
```

## 7. Refactor rule

Tên file `PlayerBase.gd` có thể giữ để tránh sửa quá lớn, nhưng tài liệu và code comment nên ghi:

```text
PlayerBase = TeamTower/Castle role trong base mode.
```

`NeutralTower` là optional và không được instance active trong base mode.
