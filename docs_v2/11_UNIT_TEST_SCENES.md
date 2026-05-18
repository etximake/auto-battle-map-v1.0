# 11 - Unit Test Scenes Guide

## Tổng Quan

Tài liệu này mô tả các test scene riêng cho Unit Phase 7-9, giúp verify unit behavior trong open_field mode.

## Danh Sách Test Scenes

### 1. TestUnitOpenFieldSpawn.tscn

**Mục đích:** Verify unit spawn open_field mode không cần path_points

**Test case:**
- Spawn 4 units ở 4 vị trí khác nhau
- Unit không biến mất sau khi spawn
- Unit có thể di chuyển tự do

**Expected result:**
- 4 units alive sau 10 giây
- Units không bị despawn
- Units có velocity hoặc đã di chuyển

**Cách chạy:**
```
Mở scene: scenes/main/TestUnitOpenFieldSpawn.tscn
Run scene (F6)
Xem console output để kiểm tra kết quả
```

### 2. TestUnitTargetEnemy.tscn

**Mục đích:** Verify unit chọn enemy unit làm target và đánh

**Test case:**
- Spawn 2 units khác team gần nhau
- Unit phải tự động chọn enemy làm target
- Unit phải đánh enemy

**Expected result:**
- Cả 2 units đều có target
- Target của mỗi unit là enemy (khác team)
- Units engage combat

**Cách chạy:**
```
Mở scene: scenes/main/TestUnitTargetEnemy.tscn
Run scene (F6)
Quan sát 2 units có đánh nhau không
```

### 3. TestUnitCastleAttack.tscn

**Mục đích:** Verify unit đánh castle khi không có enemy unit

**Test case:**
- Spawn 1 unit và 1 enemy castle
- Không có enemy unit
- Unit phải tiến tới castle và gây damage

**Expected result:**
- Unit chọn castle làm target
- Castle HP giảm dần
- Damage được gây lên castle

**Cách chạy:**
```
Mở scene: scenes/main/TestUnitCastleAttack.tscn
Run scene (F6)
Xem castle HP có giảm không
```

### 4. TestUnitRetargetOnDeath.tscn

**Mục đích:** Verify unit retarget khi target chết

**Test case:**
- Spawn 1 Gunner vs 2 enemy units (Scout + Tank)
- Scout có HP thấp, sẽ chết trước
- Gunner phải retarget sang Tank sau khi Scout chết

**Expected result:**
- Scout chết trước (HP thấp)
- Gunner retarget sang Tank
- Gunner tiếp tục combat với Tank

**Cách chạy:**
```
Mở scene: scenes/main/TestUnitRetargetOnDeath.tscn
Run scene (F6)
Quan sát Gunner có đổi target sau khi Scout chết không
```

### 5. TestUnitRoleProfiles.tscn

**Mục đích:** Verify behavior khác biệt giữa Scout/Tank/Archer

**Test case:**
- Spawn Scout, Tank, Archer (Team 0)
- Spawn 3 enemy units (Team 1)
- Verify behavior profile khác nhau

**Expected result:**
- Scout retarget_interval < Tank retarget_interval
- Archer hold_distance > 0
- Archer giữ khoảng cách với target

**Cách chạy:**
```
Mở scene: scenes/main/TestUnitRoleProfiles.tscn
Run scene (F6)
Xem console output để kiểm tra behavior metrics
```

### 6. TestUnit8Roles.tscn

**Mục đích:** Verify tất cả 8 unit types có behavior khác biệt rõ ràng

**Test case:**
- Spawn tất cả 8 unit types (Melee, Soldier, Tank, Scout, Archer, Gunner, Hammer, Mage)
- Spawn 8 enemy targets với HP khác nhau
- Monitor behavior của từng unit type

**Expected result:**
- Mỗi unit có role, attack_style, target_priority riêng
- Scout retarget nhanh nhất
- Ranged units (Archer/Gunner/Mage) giữ khoảng cách
- Melee units (Melee/Tank/Hammer) lao vào gần
- Gunner có cooldown nhanh nhất
- Hammer/Mage có damage cao nhất
- Scout có speed nhanh nhất

**Cách chạy:**
```
Mở scene: scenes/main/TestUnit8Roles.tscn
Run scene (F6)
Xem console output để kiểm tra comparison table
```

**Console output mẫu:**
```
Unit       | Role               | Attack Style    | Target Priority    | Retarget | Hold | Moved | Attacks
----------------------------------------------------------------------------------------------------------------------------------
Melee      | melee_basic        | melee_hit       | nearest_unit       | 0.45s    |    0 |   250 | 12
Soldier    | soldier_balanced   | steady_slash    | nearest_unit       | 0.40s    |    0 |   280 | 14
Tank       | tank_frontline     | heavy_body_hit  | any_nearest_enemy  | 0.80s    |    0 |   180 | 8
Scout      | scout_assassin     | quick_stab      | lowest_hp_unit     | 0.20s    |    0 |   420 | 22
Archer     | archer_ranged      | arrow_shot      | nearest_unit       | 0.35s    |   75 |   150 | 10
Gunner     | gunner_rapid       | rapid_fire      | lowest_hp_unit     | 0.25s    |   85 |   160 | 28
Hammer     | hammer_breaker     | heavy_slam      | toughest_unit      | 0.75s    |    0 |   200 | 6
Mage       | mage_burst         | magic_bolt      | lowest_hp_unit     | 0.40s    |   70 |   140 | 7

=== Behavior Verification ===
  • Scout retarget (0.20s) < Tank (0.80s): PASS
  • Ranged units keep distance: Archer=75, Gunner=85, Mage=70: PASS
  • Melee units rush in: Melee=0, Tank=0, Hammer=0: PASS
  • Scout/Gunner focus low HP: Scout=1.0, Gunner=0.8: PASS
  • Tank/Hammer frontline: Tank=1.0, Hammer=0.8: PASS
  • Gunner fastest cooldown: Gunner=0.65s < Archer=1.15s: PASS
  • Hammer/Mage high damage: Hammer=28, Mage=40: PASS
  • Scout fastest speed: Scout=190 > Tank=85: PASS
```

## Test Monitor Scripts

### UnitOpenFieldTestMonitor.gd

Script chính cho test scenes 1-5. Hỗ trợ 5 test modes:
- `spawn_basic`: Test spawn cơ bản
- `target_enemy`: Test chọn enemy target
- `castle_attack`: Test đánh castle
- `retarget_death`: Test retarget khi target chết
- `role_profiles`: Test khác biệt behavior profiles

**Cách dùng:**
```gdscript
@export var test_mode: String = "spawn_basic"
@export var auto_start: bool = true
@export var test_duration: float = 15.0
@export var unit_scene: PackedScene
@export var castle_scene: PackedScene
```

### Unit8RolesTestMonitor.gd

Script riêng cho test scene 6 (TestUnit8Roles). Tự động:
- Spawn tất cả 8 unit types
- Monitor behavior metrics
- Print comparison table
- Verify behavior differences

**Metrics tracked:**
- role, attack_style, target_priority
- retarget_interval, hold_distance
- detection_range, chase_range
- max_distance_moved
- retarget_count
- attack_count

## Cách Thêm Test Mới

Nếu cần thêm test case mới:

1. **Tạo test scene mới:**
```
scenes/main/TestUnitNewFeature.tscn
```

2. **Thêm test mode vào UnitOpenFieldTestMonitor.gd:**
```gdscript
match test_mode:
    "new_feature":
        _setup_new_feature_test()

func _setup_new_feature_test() -> void:
    # Setup logic
    pass

func _monitor_new_feature() -> void:
    # Monitor logic
    pass
```

3. **Hoặc tạo monitor script riêng:**
```gdscript
extends Node

@export var unit_scene: PackedScene
var test_results: Dictionary = {}

func _ready() -> void:
    start_test()

func start_test() -> void:
    # Test logic
    pass
```

## Kết Luận

Các test scenes này giúp:
- Verify unit behavior đúng theo spec
- Phát hiện bug sớm
- Đảm bảo 8 unit types có behavior khác biệt rõ ràng
- Dễ dàng test từng feature riêng lẻ

Khi thêm feature mới cho unit, nên tạo test scene tương ứng để verify behavior.
