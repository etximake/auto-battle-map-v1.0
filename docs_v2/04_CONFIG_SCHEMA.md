# 04 — Config Schema

## 1. Purpose

Game phải cho phép người dùng chỉnh simulation bằng JSON mà không sửa code.

Load order:

```text
GameConfig.gd safe defaults
→ res://configs/default_game_config.json
→ user://game_config_override.json
→ validate/clamp
→ systems read from GameConfig
```

## 2. Example default config

```json
{
  "version": 2,
  "game_mode": "base",
  "players": {
    "count": 4,
    "max_count": 6,
    "colors": ["#E74C3C", "#3498DB", "#9B59B6", "#F1C40F", "#2ECC71", "#1ABC9C"],
    "ai_strategies": ["BALANCED", "AGGRESSIVE", "ADAPTIVE", "ECONOMY", "BALANCED", "AGGRESSIVE"],
    "panel_layout": "split_even_odd",
    "position_preset": "side_castles_6_slots"
  },
  "round": {
    "duration": 75.0,
    "rounds_per_session": 10,
    "auto_restart": true,
    "restart_delay": 3.0,
    "time_scale": 1.0
  },
  "layout": {
    "resolution": [1280, 720],
    "left_panel_width": 192,
    "right_panel_x": 1088,
    "map_rect": [192, 0, 896, 720],
    "position_variant": "default",
    "castle_positions": [[304,134], [976,134], [304,360], [976,360], [304,586], [976,586]],
    "spawn_offsets": [[28,18], [-28,18], [28,0], [-28,0], [28,-18], [-28,-18]]
  },
  "ball_panel": {
    "spawn_interval": 0.7,
    "ball_speed": 165.0,
    "max_live_balls": 8,
    "anchor_count": 6,
    "anchor_radius": 11.0,
    "anchor_min_y": 56.0,
    "anchor_reward_gap": 112.0,
    "spawn_angle_random_degrees": 15.0
  },
  "rewards": {
    "slot_order": ["Scout", "Soldier", "Tank", "Mage", "x2"],
    "x2_mode": "next_reward",
    "unknown_reward_policy": "ignore"
  },
  "castle": {
    "max_hp": 500,
    "spawn_cooldown": 1.0,
    "queue_limit": 40,
    "shoot_range": 120.0,
    "shoot_damage": 10.0,
    "shoot_cooldown": 1.5,
    "projectile_speed": 300.0,
    "target_priority": "nearest"
  },
  "auto_battle": {
    "castle_unit_damage_multiplier": 1.0,
    "unit_kill_score": 5,
    "castle_damage_score_per_point": 0.1,
    "castle_destroy_score": 50
  },
  "units": {
    "Scout": {"hp": 20, "damage": 5, "speed": 190, "range": 28, "cooldown": 0.8, "visual_radius": 12, "collision_radius": 7},
    "Soldier": {"hp": 50, "damage": 15, "speed": 140, "range": 34, "cooldown": 1.0, "visual_radius": 15, "collision_radius": 9},
    "Tank": {"hp": 150, "damage": 8, "speed": 85, "range": 32, "cooldown": 1.5, "visual_radius": 18, "collision_radius": 11},
    "Mage": {"hp": 30, "damage": 40, "speed": 115, "range": 85, "cooldown": 2.0, "visual_radius": 14, "collision_radius": 8}
  },
  "unit_behavior": {
    "body_collision_enabled": false,
    "waypoint_distance": 7.0,
    "target_scan_interval": 0.25
  },
  "limits": {
    "max_units_per_player": 30,
    "max_total_units": 180,
    "max_projectiles": 80
  },
  "optional_modes": {
    "neutral_towers_enabled": false,
    "capture_outposts_enabled": false
  }
}
```

## 3. Validation rules

```text
players.count: clamp 2..players.max_count
players.max_count: clamp 2..12, prototype recommended 6
round.duration: min 10
round.time_scale: clamp 0.25..4
ball_panel.spawn_interval: min 0.1
ball_panel.max_live_balls: clamp 1..50
castle.max_hp: min 1
castle.shoot_range: min 0
castle.shoot_cooldown: min 0.1
castle.queue_limit: clamp 1..200
limits.max_units_per_player: clamp 1..200
limits.max_total_units: clamp 1..500
unit stats missing: fallback safe defaults
invalid color: fallback #AAAAAA
unknown reward: ignore + warning
```

## 4. GameConfig helpers

Recommended API:

```gdscript
var players_count: int

func get_player_count() -> int
func get_player_color(player_id: int) -> Color
func get_ai_strategy(player_id: int) -> String
func get_unit_config(unit_type: String) -> Dictionary
func get_unit_behavior_config(unit_type: String) -> Dictionary
func get_unit_stat(unit_type: String, stat_name: String, default_value: float = 0.0) -> float
func get_castle_config() -> Dictionary
func get_castle_position(player_id: int) -> Vector2
func get_spawn_position(player_id: int) -> Vector2
func get_reward_slot_order() -> Array[String]
```

## 5. Player count layouts

Use `layout.player_count_layouts` when the map needs different positions for
different team counts.

```json
{
  "layout": {
    "position_variant": "default",
    "player_count_layouts": {
      "2": {
        "variants": {
          "default": {"castle_positions": [[304,360], [976,360]], "spawn_offsets": [[28,0], [-28,0]]},
          "vertical": {"castle_positions": [[640,150], [640,570]]},
          "diagonal": {"castle_positions": [[304,170], [976,550]]},
          "close_center": {"castle_positions": [[424,360], [856,360]]}
        }
      },
      "4": {
        "variants": {
          "default": {"castle_positions": [[304,220], [976,220], [304,500], [976,500]]},
          "corners": {"castle_positions": [[304,140], [976,140], [304,580], [976,580]]},
          "diamond": {"castle_positions": [[640,128], [980,360], [640,592], [300,360]]},
          "staggered": {"castle_positions": [[304,165], [976,270], [304,555], [976,450]]}
        }
      },
      "6": {"castle_positions": [[304,134], [976,134], [304,360], [976,360], [304,586], [976,586]]}
    }
  }
}
```

Full ASCII maps are in `docs_v2/08_MAP_POSITION_PRESETS.md`.

## 6. Unit behavior profile

Each unit can define a behavior profile in the same object as its stats.

Example:

```json
{
  "units": {
    "Scout": {
      "hp": 20,
      "damage": 5,
      "speed": 190,
      "range": 28,
      "cooldown": 0.8,
      "visual_radius": 12,
      "collision_radius": 7,
      "role": "scout_assassin",
      "attack_style": "quick_stab",
      "target_priority": "lowest_hp_unit",
      "prefer_units_over_castle": true,
      "detection_range": 210,
      "chase_range": 330,
      "retarget_interval": 0.2,
      "hold_distance": 0,
      "separation_radius": 18,
      "separation_strength": 0.5,
      "castle_aggression": 0.35,
      "low_hp_focus": 1.0,
      "frontline_bias": 0.1
    }
  }
}
```

Allowed `role` values:

```text
melee_basic
soldier_balanced
tank_frontline
scout_assassin
archer_ranged
gunner_rapid
hammer_breaker
mage_burst
```

Allowed `attack_style` values:

```text
melee_hit
steady_slash
heavy_body_hit
quick_stab
arrow_shot
rapid_fire
heavy_slam
magic_bolt
```

Allowed `target_priority` values:

```text
nearest_unit
lowest_hp_unit
nearest_castle
objective_castle
toughest_unit
any_nearest_enemy
```

Validation rules:

```text
invalid role: fallback melee_basic
invalid attack_style: fallback melee_hit
invalid target_priority: fallback nearest_unit
detection_range: clamp 0..1000
chase_range: clamp detection_range..1500
retarget_interval: clamp 0.05..5.0
hold_distance: clamp 0..unit.range
separation_radius: clamp 0..96
separation_strength: clamp 0..2
castle_aggression: clamp 0..1
low_hp_focus: clamp 0..1
frontline_bias: clamp 0..1
```

Design note:

```text
Phase 1 only exposes and validates these fields.
Unit.gd should consume them in later Unit phases.
```
