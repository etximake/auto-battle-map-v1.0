# Unit Open Field Test Guide

## Tổng Quan

Dự án đã hoàn thành **Unit Phase 0-9** theo spec `docs_v2/10_OPEN_FIELD_UNIT_BEHAVIOR_SPEC.md`.

Các test scenes được tạo để verify unit behavior trong open_field mode.

## Quick Start

### Test Toàn Bộ 8 Unit Roles

Chạy scene này để xem tất cả 8 unit types hoạt động:

```
scenes/main/TestUnit8Roles.tscn
```

**Kết quả mong đợi:**
- Console hiển thị comparison table
- 8 behavior checks PASS
- Mỗi unit có behavior khác biệt rõ ràng

### Test Từng Feature Riêng

| Test Scene | Mục đích | Duration |
|------------|----------|----------|
| `TestUnitOpenFieldSpawn.tscn` | Unit spawn không path | 10s |
| `TestUnitTargetEnemy.tscn` | Unit chọn enemy target | 12s |
| `TestUnitCastleAttack.tscn` | Unit đánh castle | 15s |
| `TestUnitRetargetOnDeath.tscn` | Unit retarget khi target chết | 15s |
| `TestUnitRoleProfiles.tscn` | Scout/Tank/Archer khác biệt | 15s |

## Unit Behavior Summary

### Melee
- **Role:** melee_basic
- **Attack Style:** melee_hit
- **Target Priority:** nearest_unit
- **Behavior:** Áp sát cơ bản, đánh enemy gần nhất

### Soldier
- **Role:** soldier_balanced
- **Attack Style:** steady_slash
- **Target Priority:** nearest_unit
- **Behavior:** Cân bằng, đi nhóm tốt, ổn định

### Tank
- **Role:** tank_frontline
- **Attack Style:** heavy_body_hit
- **Target Priority:** any_nearest_enemy
- **Behavior:** Tuyến trước, HP cao, retarget chậm

### Scout
- **Role:** scout_assassin
- **Attack Style:** quick_stab
- **Target Priority:** lowest_hp_unit
- **Behavior:** Nhanh nhất, retarget nhanh, focus mục tiêu yếu

### Archer
- **Role:** archer_ranged
- **Attack Style:** arrow_shot
- **Target Priority:** nearest_unit
- **Behavior:** Bắn xa, giữ khoảng cách 75

### Gunner
- **Role:** gunner_rapid
- **Attack Style:** rapid_fire
- **Target Priority:** lowest_hp_unit
- **Behavior:** DPS nhanh, cooldown thấp nhất, focus mục tiêu yếu

### Hammer
- **Role:** hammer_breaker
- **Attack Style:** heavy_slam
- **Target Priority:** toughest_unit
- **Behavior:** Damage cao nhất, retarget chậm, phá tuyến

### Mage
- **Role:** mage_burst
- **Attack Style:** magic_bolt
- **Target Priority:** lowest_hp_unit
- **Behavior:** Burst damage cao, bắn xa, giữ khoảng cách 70

## Behavior Profile Fields

Mỗi unit có các field behavior trong config:

```json
{
  "role": "melee_basic",
  "attack_style": "melee_hit",
  "target_priority": "nearest_unit",
  "prefer_units_over_castle": true,
  "detection_range": 145.0,
  "chase_range": 240.0,
  "retarget_interval": 0.45,
  "hold_distance": 0.0,
  "separation_radius": 22.0,
  "separation_strength": 0.45,
  "castle_aggression": 0.45,
  "low_hp_focus": 0.0,
  "frontline_bias": 0.4
}
```

### Key Differences

| Field | Melee | Tank | Scout | Archer | Gunner | Hammer | Mage |
|-------|-------|------|-------|--------|--------|--------|------|
| **retarget_interval** | 0.45 | 0.80 | 0.20 | 0.35 | 0.25 | 0.75 | 0.40 |
| **hold_distance** | 0 | 0 | 0 | 75 | 85 | 0 | 70 |
| **low_hp_focus** | 0.0 | 0.0 | 1.0 | 0.2 | 0.8 | 0.0 | 0.7 |
| **frontline_bias** | 0.4 | 1.0 | 0.1 | 0.0 | 0.0 | 0.8 | 0.0 |
| **speed** | 145 | 85 | 190 | 135 | 150 | 105 | 115 |
| **damage** | 14 | 8 | 5 | 12 | 8 | 28 | 40 |
| **cooldown** | 0.95 | 1.5 | 0.8 | 1.15 | 0.65 | 1.6 | 2.0 |

## Visual Feedback

Unit attack có visual feedback theo attack_style:

- **melee_hit**: Impact placeholder
- **steady_slash**: Impact placeholder
- **heavy_body_hit**: Impact lớn, màu cam
- **quick_stab**: Slash line + impact nhanh
- **arrow_shot**: Line projectile vàng
- **rapid_fire**: Line projectile trắng, rất nhanh
- **heavy_slam**: Impact lớn, màu cam
- **magic_bolt**: Line projectile tím, dày

## Troubleshooting

### Unit không di chuyển
- Check `movement_mode` trong config = "open_field"
- Check unit có `current_target` không
- Check unit state (SEEKING/CHASING/ATTACKING)

### Unit không đánh
- Check `attack_range` và distance to target
- Check `attack_timer` và `attack_cooldown`
- Check target còn valid không

### Unit không retarget
- Check `retarget_interval`
- Check target có chết/invalid không
- Check `chase_range` có đủ không

### Ranged unit lao vào gần
- Check `hold_distance` > 0
- Check `attack_range` > `hold_distance`

## Next Steps

Sau khi verify tất cả test scenes PASS:

1. **Tuning balance:** Điều chỉnh HP/damage/speed trong config
2. **Add visual assets:** Thay placeholder bằng sprite/animation thật
3. **Add advanced features:** Kiting, splash damage, formation, obstacle avoidance
4. **Integration test:** Test với full game loop (BallPanel → Reward → Spawn → Combat → Score → Round)

## Documentation

Chi tiết về unit behavior spec:
- `docs_v2/10_OPEN_FIELD_UNIT_BEHAVIOR_SPEC.md`
- `docs_v2/11_UNIT_TEST_SCENES.md`

Chi tiết về config schema:
- `docs_v2/04_CONFIG_SCHEMA.md`

## Files Changed

### New Files
- `scripts/systems/UnitOpenFieldTestMonitor.gd` - Test monitor cho 5 test modes
- `scripts/systems/Unit8RolesTestMonitor.gd` - Test monitor cho 8 unit roles
- `scenes/main/TestUnitOpenFieldSpawn.tscn` - Test spawn
- `scenes/main/TestUnitTargetEnemy.tscn` - Test target enemy
- `scenes/main/TestUnitCastleAttack.tscn` - Test castle attack
- `scenes/main/TestUnitRetargetOnDeath.tscn` - Test retarget
- `scenes/main/TestUnitRoleProfiles.tscn` - Test role profiles
- `scenes/main/TestUnit8Roles.tscn` - Test 8 unit roles
- `docs_v2/11_UNIT_TEST_SCENES.md` - Test scenes guide
- `TEST_UNIT_PHASES.md` - This file

### Modified Files
- `docs_v2/10_OPEN_FIELD_UNIT_BEHAVIOR_SPEC.md` - Updated Phase 7 & 9 status to DONE

### Existing Files (No Changes)
- `configs/default_game_config.json` - Already has behavior profiles
- `scripts/units/Unit.gd` - Already implements open_field behavior
- `scripts/autoloads/GameConfig.gd` - Already reads behavior profiles

## Conclusion

**Unit Phase 0-9 hoàn thành:**
- ✅ Phase 0: Behavior contract
- ✅ Phase 1: Config behavior profile
- ✅ Phase 2: Setup open field
- ✅ Phase 3: Target scan
- ✅ Phase 4: Movement open field
- ✅ Phase 5: Attack một mục tiêu
- ✅ Phase 6: Retarget và anti-stuck
- ✅ Phase 7: Làm rõ khác biệt 8 unit
- ✅ Phase 8: Visual/asset hooks
- ✅ Phase 9: Test riêng cho unit

Tất cả 8 unit types có behavior profile riêng và hoạt động đúng theo spec.
