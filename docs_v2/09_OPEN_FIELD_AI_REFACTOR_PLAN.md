# 09 - Open Field AI Refactor Plan

## 1. Problem Summary

Project hien tai van dang dung thiet ke lane/path:

```text
Castle queue
-> PlayerBase hoi AIController chon target/route
-> SpawnManager spawn unit voi route_points
-> Unit di theo path_points/waypoint
-> Het route thi emit unit_reached_castle
-> PlayerBase nhan castle damage
```

Thiet ke moi cua base mode khong con dung duong line/path co dinh. Unit can tu danh gia battlefield, tu chon target, tu di chuyen trong map mo, tu giao tranh, retarget, va tan cong castle dich.

Refactor nay khong rewrite toan bo project. Muc tieu la thay doi nho nhat de base mode chay bang open-field AI, trong khi van giu lane/path code cu nhu legacy/optional mode.

## 2. Design Goals

Core goals:

```text
- Base mode mac dinh dung movement_mode = "open_field".
- Unit spawn duoc ma khong can path_points.
- Unit tu tim enemy unit hoac enemy castle.
- Unit co retarget khi target chet, ra khoi chase range, hoac castle bi pha.
- Unit khong dung im neu van con enemy alive.
- Castle damage khong phu thuoc vao unit_reached_castle.
- Khong hardcode 4 hoac 6 team.
- NeutralTower khong tro thanh core gameplay.
- ResourceManager/gold-buy khong tro thanh core loop.
```

Compatibility goals:

```text
- Giu BallPanel -> RewardSlot -> RewardManager -> PlayerBase queue.
- Giu PlayerBase spawn cooldown va queue.
- Giu SpawnManager pooling/limit.
- Giu CastleShooter, ScoreManager, RoundManager, EventBus.
- Giu lane/path code cu duoi movement_mode = "lane_path".
```

## 3. Current Path Dependencies

Files can phai audit khi refactor:

```text
scripts/units/Unit.gd
scripts/players/AIController.gd
scripts/players/PlayerBase.gd
scripts/systems/SpawnManager.gd
scripts/map/GameMap.gd
scripts/autoloads/GameConfig.gd
scripts/autoloads/EventBus.gd
scripts/systems/CastleQueueTestMonitor.gd
scripts/systems/UnitTestSpawner.gd
scenes/main/TestCastleQueue.tscn
scenes/main/TestAutoBattleLoop.tscn
scenes/main/TestRoundLoop.tscn
scenes/main/TestPhase4AI.tscn
scenes/main/TestMapPath.tscn
```

Important current dependencies:

```text
Unit.gd:
- path_points
- path_index
- UnitState.MARCHING
- setup_unit(..., new_path_points)
- _follow_path()
- _reach_base()

AIController.gd:
- choose_route()
- GameMap.get_route()
- GameMap.get_march_path()

PlayerBase.gd:
- _get_route_for_unit()
- spawn_manager.spawn_unit(player_id, unit_type, route)
- _on_unit_reached_castle()

SpawnManager.gd:
- spawn_unit(..., route_points)
- fallback _get_path_for_player()
- error if no march path

GameMap.gd:
- path_waypoints
- _setup_default_paths()
- _draw_path_lines()
- get_march_path()
- get_route()
```

## 4. Target Architecture

Before implementing this architecture, Unit behavior must be defined clearly in:

```text
docs_v2/10_OPEN_FIELD_UNIT_BEHAVIOR_SPEC.md
```

That spec is the behavior contract for `Unit.gd`. If a future implementation conflicts with it, update the spec first, then update code.

### Movement Modes

Add config:

```json
"unit_behavior": {
  "movement_mode": "open_field"
}
```

Supported values:

```text
open_field - base mode moi, unit tu chon target va di chuyen tren map mo.
lane_path  - legacy mode, unit di theo route/path_points nhu hien tai.
```

### Open Field Unit State

Recommended state machine:

```text
SPAWNING
SEEKING
CHASING
ATTACKING
DEAD
```

Behavior:

```text
SEEKING:
- Tim enemy unit trong detection_range.
- Neu khong co enemy unit, tim enemy castle alive.
- Neu khong tim thay target nhung van con enemy alive, di ve fallback objective.

CHASING:
- Di ve current_target.
- Neu vao attack_range thi chuyen ATTACKING.
- Neu target invalid hoac ra khoi chase_range thi retarget.

ATTACKING:
- Dung lai hoac micro-move nhe.
- Danh theo attack_cooldown.
- Neu target chet/invalid/ra range thi retarget.

DEAD:
- Emit unit_died.
- Return to pool qua SpawnManager.
```

### Target Types

Unit target can be:

```text
- Unit enemy
- Castle/PlayerBase enemy
```

Open-field unit should not need fixed target player forever. It can store optional objective_player_id, but must be able to change when battlefield changes.

### Castle Damage

In open_field:

```text
Unit reaches attack_range of enemy castle
-> Unit calls castle.take_damage(damage * castle_unit_damage_multiplier, player_id)
-> ScoreManager receives castle_damaged
```

Do not use `unit_reached_castle` for open_field castle damage.

### AIController Role

AIController should become policy provider, not route owner:

```gdscript
func choose_objective_player(unit_type: String) -> int
func get_unit_ai_policy(unit_type: String) -> Dictionary
```

Legacy APIs can remain:

```gdscript
func choose_target_player(unit_type: String) -> int
func choose_route(unit_type: String, target_player_id: int) -> Array[Vector2]
```

In `open_field`, PlayerBase/SpawnManager should not require `choose_route()`.

## 5. Config Additions

Add to `configs/default_game_config.json` under `unit_behavior`:

```json
{
  "movement_mode": "open_field",
  "detection_range": 180.0,
  "chase_range": 280.0,
  "retarget_interval": 0.35,
  "prefer_units_over_castle": true,
  "target_priority": "nearest",
  "objective_fallback": "nearest_castle",
  "separation_radius": 22.0,
  "separation_strength": 0.45,
  "map_bounds_padding": 10.0
}
```

Validation rules:

```text
movement_mode: "open_field" or "lane_path"
detection_range: 0..1000, default 180
chase_range: >= detection_range, default 280
retarget_interval: 0.05..5.0
target_priority: "nearest", "lowest_hp", "castle_first", "unit_first"
objective_fallback: "nearest_castle", "center", "ai_objective"
separation_radius: 0..96
separation_strength: 0..2
```

Keep existing:

```text
body_collision_enabled
waypoint_distance
```

But `waypoint_distance` is only meaningful in `lane_path`.

## 6. Phase Plan

## Phase 0 - Unit Behavior Contract

Goal:

```text
Define exactly how Unit behaves before changing gameplay code.
```

Tasks:

```text
- Create and review docs_v2/10_OPEN_FIELD_UNIT_BEHAVIOR_SPEC.md.
- Define Unit states: SPAWNING, SEEKING, CHASING, ATTACKING, DEAD.
- Define target priority rules.
- Define retarget rules.
- Define castle attack rules.
- Define anti-stuck rules.
- Define lane_path legacy behavior.
```

Acceptance:

```text
- Unit behavior is clear before touching Unit.gd.
- Open-field behavior and lane_path legacy behavior are separated.
- No code behavior changes yet.
```

Risk:

```text
Low. Documentation only.
```

## Phase 1 - Safety Baseline And Dependency Audit

Goal:

```text
Record current path dependencies and create a safe migration path.
```

Tasks:

```text
- Note all path-dependent files.
- Confirm base mode should not depend on NeutralTower or ResourceManager.
- Confirm default movement_mode target: open_field.
- Confirm lane/path becomes legacy optional mode.
```

Acceptance:

```text
- Team agrees that lane/path becomes legacy optional mode.
- All known path dependency points are listed.
- No code behavior changes yet.
```

Risk:

```text
Low. Documentation only.
```

## Phase 2 - Add Config Surface

Goal:

```text
GameConfig can read open-field AI parameters.
```

Files:

```text
configs/default_game_config.json
scripts/autoloads/GameConfig.gd
docs_v2/04_CONFIG_SCHEMA.md
```

Tasks:

```text
- Add unit_behavior.movement_mode.
- Add detection_range, chase_range, retarget_interval.
- Add prefer_units_over_castle, target_priority.
- Add separation_radius, separation_strength.
- Add objective_fallback, map_bounds_padding.
- Validate values in GameConfig._validate_config().
- Keep waypoint_distance for lane_path only.
```

Acceptance:

```text
- GameConfig loads default config without errors.
- movement_mode defaults to open_field.
- Invalid movement_mode falls back to open_field.
- Existing configs without new fields still work.
```

Risk:

```text
Low. Mostly config and defaults.
```

## Phase 3 - Spawn Without Required Path

Goal:

```text
SpawnManager can spawn units in open_field without route_points.
```

Files:

```text
scripts/systems/SpawnManager.gd
scripts/players/PlayerBase.gd
scripts/map/GameMap.gd
```

Tasks:

```text
- In SpawnManager.spawn_unit(), branch by GameConfig.unit_movement_mode.
- For open_field, use GameMap.get_spawn_position(player_id).
- Do not error when route_points is empty in open_field.
- Add open-field activation path, for example _activate_unit_open_field().
- Keep old _activate_unit(..., unit_path) for lane_path.
- In PlayerBase._spawn_next_reward(), do not call _get_route_for_unit() when open_field.
```

Acceptance:

```text
- PlayerBase can consume reward and spawn unit with no route.
- Unit appears at configured spawn position.
- lane_path still uses route_points.
```

Risk:

```text
Medium. SpawnManager currently assumes path is required.
```

## Phase 4 - Unit Open-Field Movement

Goal:

```text
Unit can move and attack without path_points.
```

Files:

```text
scripts/units/Unit.gd
```

Tasks:

```text
- Add movement_mode awareness.
- Keep setup_unit(player_id, unit_type, path_points) for compatibility.
- Add setup_open_field(player_id, unit_type, spawn_position, objective_player_id = -1), or make setup_unit accept empty path in open_field.
- Add current_target: Node, not only Unit.
- Add target scan timer using retarget_interval.
- Add _find_enemy_unit_target().
- Add _find_enemy_castle_target().
- Add _is_valid_target().
- Add _move_toward_target().
- Add _attack_current_target().
- Add _apply_separation().
- Add _clamp_to_map_rect().
```

Acceptance:

```text
- With no path, unit does not immediately call _reach_base().
- Unit moves toward enemy unit when detected.
- Unit attacks enemy unit in range.
- If no enemy unit exists, unit moves toward enemy castle.
- Unit attacks castle directly in attack_range.
- Unit retargets after current target dies.
```

Risk:

```text
High. This is the core behavior change.
```

## Phase 5 - Castle Damage And Events Cleanup

Goal:

```text
Castle damage works in open_field without unit_reached_castle.
```

Files:

```text
scripts/units/Unit.gd
scripts/players/PlayerBase.gd
scripts/autoloads/EventBus.gd
scripts/systems/ScoreManager.gd
scripts/systems/RoundManager.gd
```

Tasks:

```text
- In open_field, Unit attacks castle with PlayerBase.take_damage().
- Keep EventBus.unit_reached_castle only for lane_path.
- Ensure ScoreManager still scores castle_damaged and castle_destroyed.
- Ensure RoundManager still ends round when only one castle alive.
- Ensure PlayerBase ignores damage after is_destroyed.
```

Acceptance:

```text
- Unit damaging castle emits castle_damaged.
- Destroying castle emits castle_destroyed.
- ScoreManager awards castle damage and destroy score.
- RoundManager ends round when one team remains.
```

Risk:

```text
Medium. Event flow changes from reach-signal to direct damage call.
```

## Phase 6 - GameMap Path Visualization As Legacy Only

Status:

```text
DONE - GameMap.gd gates _setup_default_paths() and _draw_path_lines() behind
GameConfig.is_open_field_movement(). PathVisual is hidden in open_field.
```

Goal:

```text
Open-field map no longer shows or depends on lane lines.
```

Files:

```text
scripts/map/GameMap.gd
scenes/map/GameMap.tscn
```

Tasks:

```text
- Only call _setup_default_paths() and _draw_path_lines() if movement_mode == lane_path.
- Hide or clear PathVisual in open_field.
- Keep get_route() and get_march_path() for lane_path.
- Keep get_base_position(), get_spawn_position(), get_target_player_ids(), get_map_rect() for both modes.
```

Acceptance:

```text
- open_field scene does not draw lane/path lines.
- lane_path scene still draws path lines.
- GameMap still creates bases based on GameConfig.get_player_count().
```

Risk:

```text
Low to medium. Visual behavior changes only in map setup.
```

## Phase 7 - AIController Policy Refactor

Status:

```text
DONE - AIController.choose_objective_player() and get_unit_ai_policy() added.
PlayerBase passes objective_player_id into SpawnManager.spawn_unit() in
open_field. SpawnManager forwards it to Unit.setup_open_field().
```

Goal:

```text
AIController supports open-field objective and target policy.
```

Files:

```text
scripts/players/AIController.gd
scripts/players/PlayerBase.gd
scripts/systems/SpawnManager.gd
```

Tasks:

```text
- Add choose_objective_player(unit_type).
- Optionally add get_unit_ai_policy(unit_type).
- Reuse existing choose_target_player logic for objective selection.
- Keep choose_route() for lane_path.
- In open_field, PlayerBase/SpawnManager may pass objective_player_id to Unit.
```

Acceptance:

```text
- AGGRESSIVE can prefer nearest/weak target.
- BALANCED can rotate objective.
- ADAPTIVE can use low-pressure or low-unit-count target.
- No code assumes exactly 4 teams.
```

Risk:

```text
Medium. Existing AI is route-oriented but can be reused for objective selection.
```

## Phase 8 - Test Scene And Monitor Updates

Status:

```text
PARTIAL - Unit-level tests done in earlier phases. Integration:
- scenes/main/TestOpenFieldBattle.tscn (dynamic AI per GameConfig.player_count).
- scripts/systems/OpenFieldBattleTestMonitor.gd (movement, deaths, castle damage).
TODO:
- TestOpenFieldRetarget.tscn (battle-level retarget).
- TestOpenFieldCastleAttack.tscn (battle-level castle pressure).
- TestLanePathLegacy.tscn (legacy mode regression).
```

Goal:

```text
Tests verify open-field behavior and no hardcoded 4-team dependency.
```

Files:

```text
scripts/systems/CastleQueueTestMonitor.gd
scripts/systems/AutoBattleLoopTestMonitor.gd
scripts/systems/UnitTestSpawner.gd
scenes/main/TestOpenFieldBattle.tscn
scenes/main/TestOpenFieldRetarget.tscn
scenes/main/TestOpenFieldCastleAttack.tscn
scenes/main/TestLanePathLegacy.tscn
```

Tasks:

```text
- Stop requiring path_points in open-field monitors.
- Add a monitor that checks unit movement distance after spawn.
- Add a monitor that checks unit damage/death events.
- Add a monitor that checks castle_damaged without unit_reached_castle.
- Add dynamic AI creation in test scenes or use Main.gd style setup.
- Keep TestMapPath for lane_path legacy only.
```

Acceptance:

```text
- 2-team open_field test: units spawn, move, fight.
- 4-team open_field test: all teams can spawn from config.
- 6-team open_field test: no hardcoded AI_0..AI_3 blocker.
- Retarget test: unit switches target after target dies.
- Castle attack test: unit damages castle when no enemy unit blocks it.
- lane_path legacy test still passes.
```

Risk:

```text
Medium. Some existing scenes have fixed AI_0..AI_3 nodes.
```

## Phase 9 - Regression And Cleanup

Goal:

```text
Remove accidental base-mode dependence on lane/path while preserving legacy mode.
```

Tasks:

```text
- rg audit for get_route, get_march_path, path_points, unit_reached_castle.
- Confirm each reference is either legacy lane_path or test-specific.
- Update docs_v2/03_SYSTEMS_SPEC.md to describe open_field as base mode.
- Update docs_v2/07_TEST_PLAN.md with open-field tests.
- Update docs_v2/00_README_TARGET.md if it still says AI route is core.
```

Acceptance:

```text
- Base mode docs no longer describe fixed line/path as required.
- Code has clear branch for lane_path legacy.
- Tests cover both movement modes.
```

Risk:

```text
Low. Cleanup and documentation.
```

## 7. Implementation Order

Recommended order:

```text
1. Phase 0 - Unit Behavior Contract
2. Phase 1 - Safety Baseline And Dependency Audit
3. Phase 2 - Add Config Surface
4. Phase 3 - Spawn Without Required Path
5. Phase 4 - Unit Open-Field Movement
6. Phase 5 - Castle Damage And Events Cleanup
7. Phase 6 - GameMap Path Visualization As Legacy Only
8. Phase 7 - AIController Policy Refactor
9. Phase 8 - Test Scene And Monitor Updates
10. Phase 9 - Regression And Cleanup
```

Do not start with visual/assets work. The first milestone is a plain prototype where units spawn without path and still fight correctly.

## 8. Minimal First Milestone

The smallest useful implementation slice:

```text
- Add movement_mode config.
- SpawnManager allows open_field spawn without route.
- Unit has open_field seeking/chasing/attacking.
- Unit can attack castle directly.
- GameMap hides path lines in open_field.
- One 2-team open-field test passes.
```

This milestone proves the new architecture without touching BallPanel, RewardManager, ScoreManager, RoundManager, or CastleShooter beyond required event compatibility.

## 9. Do Not Do

Avoid these changes during this refactor:

```text
- Do not rewrite the whole project.
- Do not add player input.
- Do not hardcode 4 or 6 teams.
- Do not make NeutralTower core gameplay.
- Do not restore ResourceManager/gold-buy as core loop.
- Do not remove lane_path code until open_field is stable.
- Do not mix asset replacement with AI refactor.
```

## 10. Final Target Loop

Expected base-mode loop after this refactor:

```text
BallPanel
-> RewardSlot
-> RewardManager
-> PlayerBase queue
-> PlayerBase spawn cooldown
-> SpawnManager spawn open-field unit
-> Unit selects target from battlefield
-> Unit moves/chases/attacks
-> Unit retargets when target invalid
-> Unit or CastleShooter deals damage
-> Castle destroyed
-> RoundManager ends/resets round
```
