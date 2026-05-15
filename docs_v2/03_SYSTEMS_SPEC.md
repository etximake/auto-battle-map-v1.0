# 03 — Systems Spec

## 1. BallPanel System

Files:

```text
scenes/ui/BallPanel.tscn
scripts/ui/BallPanel.gd
scenes/ui/PanelBall.tscn
scripts/ui/PanelBall.gd
scenes/ui/RewardSlot.tscn
scripts/ui/RewardSlot.gd
```

Responsibilities:

- create ball automatically
- keep ball inside panel bounds
- bounce ball from pegs/borders
- detect reward slot hit
- emit reward event with correct player_id

Config:

```text
ball_panel.spawn_interval
ball_panel.ball_speed
ball_panel.max_live_balls
ball_panel.anchor_count
ball_panel.anchor_radius
ball_panel.anchor_min_y
ball_panel.anchor_reward_gap
rewards.slot_order
```

## 2. RewardSlot System

RewardSlot exports:

```gdscript
@export var player_id: int = 0
@export var reward_type: String = "Scout"
```

On ball hit:

```gdscript
EventBus.reward_generated.emit(player_id, reward_type)
ball.despawn()
```

## 3. RewardManager

Responsibilities:

- listen to `reward_generated`
- find castle by player_id
- apply x2/boost rules if any
- queue reward into castle
- emit `reward_queued`

Pseudocode:

```gdscript
func _on_reward_generated(player_id: int, reward_type: String) -> void:
    var castle := find_castle(player_id)
    if castle == null:
        push_warning("No castle for player %s" % player_id)
        return

    if reward_type == "x2":
        castle.add_modifier("x2")
        return

    castle.queue_reward(reward_type)
    EventBus.reward_queued.emit(player_id, reward_type)
```

## 4. PlayerBase / TeamTower

Responsibilities:

- team id
- HP
- alive/defeated state
- reward queue
- spawn unit
- route request through AIController
- tower shooting through CastleShooter
- damage/destroy events

Recommended methods:

```gdscript
func setup(player_id: int, ai_controller: Node) -> void
func queue_reward(reward_type: String) -> void
func take_damage(amount: float, attacker_player_id: int) -> void
func is_alive() -> bool
func reset_for_round() -> void
```

## 5. CastleShooter

Can be implemented inside PlayerBase or as a child node `CastleShooter.gd`.

Responsibilities:

- maintain enemy target list in range
- ignore same-team units
- choose target
- spawn projectile
- apply cooldown

Config:

```text
castle.shoot_range
castle.shoot_damage
castle.shoot_cooldown
castle.projectile_speed
castle.target_priority
```

Target priority options:

```text
nearest
lowest_hp
first_entered
```

## 6. Projectile System

File:

```text
scripts/units/Projectile.gd
scenes/units/Projectile.tscn
```

Behavior:

```text
spawn at tower position
→ move toward target
→ if target invalid, delete self
→ if close enough, target.take_damage(damage)
→ delete self
```

## 7. AIController

AI does not buy units.

Responsibilities:

- choose target player
- choose route/lane
- adapt target according to strategy

API:

```gdscript
func choose_target_player(unit_type: String) -> int
func choose_route(unit_type: String, target_player_id: int) -> Array[Vector2]
```

Target list must come from active alive players, excluding self.

## 8. GameMap

Responsibilities:

- provide tower/castle positions
- provide spawn positions
- provide route between teams
- draw/debug paths if needed

API:

```gdscript
func get_castle_position(player_id: int) -> Vector2
func get_spawn_position(player_id: int) -> Vector2
func get_route(from_id: int, target_id: int, route_id: String = "main") -> Array[Vector2]
func get_active_player_ids() -> Array[int]
func get_target_player_ids(from_id: int) -> Array[int]
```

Positions should come from config or preset arrays, not hard-coded gameplay logic.

## 9. SpawnManager

Responsibilities:

- spawn unit instance or use pool
- assign player_id and unit_type
- assign route/path_points
- enforce max unit limits
- emit unit_spawned
- return unit to pool or queue_free on death/reach

## 10. Unit System

Unit states:

```text
SPAWN
MOVE
ATTACK
REACH_CASTLE
DIE
```

Unit data from config:

```text
hp
damage
speed
range
cooldown
visual_radius
collision_radius
```

Must support:

```gdscript
func setup(player_id: int, unit_type: String, path_points: Array[Vector2]) -> void
func take_damage(amount: float, attacker_player_id: int = -1) -> void
```

## 11. ScoreManager

Score source:

```text
unit kill
castle damage
castle destroyed
optional reward bonus
```

Scores initialized with:

```gdscript
for player_id in range(GameConfig.players_count):
    scores[player_id] = 0.0
```

## 12. RoundManager

Responsibilities:

- start/reset round
- reset castle HP, queues, panels, units, projectiles, score if needed
- count timer
- listen to castle_destroyed
- detect winner
- auto restart
