# 07 — Test Plan

## 1. Config load test

Scene/headless:

```text
Main.tscn hoặc TestConfig.tscn
```

Check:

```text
GameConfig load không crash
players.count được clamp đúng
invalid color fallback
unknown reward warning nhưng không crash
```

## 2. Player count test

Run 3 lần với config:

```json
{"players": {"count": 2}}
{"players": {"count": 4}}
{"players": {"count": 6}}
```

Expected:

```text
Đúng số team
Đúng số panel
Đúng số castle
Đúng số score/HP bars
Không hard-code lỗi index
```

## 3. BallPanel test

Scene:

```text
TestBallPanel.tscn
```

Expected:

```text
Ball spawn tự động
Ball bounce trong panel
Ball chạm reward slot
Log reward_generated đúng player_id và reward_type
Ball despawn/reset
```

## 4. Castle queue test

Scene:

```text
TestCastleQueue.tscn
```

Expected:

```text
reward_generated
→ reward_queued
→ castle_spawn_requested
→ unit_spawned
```

## 5. AI route test

Expected:

```text
AI chọn target không phải self
Target là active/alive team
Route có ít nhất 2 waypoint
Unit đi đến đúng target castle
```

## 6. Auto battle test

Scene:

```text
TestAutoBattleLoop.tscn
```

Expected:

```text
Unit hai team gặp nhau
Unit dừng lại đánh
HP giảm
unit_died emit
Score tăng
```

## 7. Castle shooter test

Scene:

```text
TestCastleShooter.tscn
```

Expected:

```text
Enemy unit vào shoot_range
Castle bắn projectile
EventBus.castle_shot_fired emit
Projectile bay tới target
Target take_damage
Projectile queue_free
Castle không bắn unit cùng team
```

## 8. Round loop test

Scene:

```text
TestRoundLoop.tscn
```

Expected:

```text
Round start
Timer chạy
Castle destroyed hoặc timeout
Winner xác định
Round ended overlay
Auto restart
```

## 9. Performance sanity

Config stress:

```json
{
  "players": {"count": 6},
  "limits": {
    "max_units_per_player": 30,
    "max_total_units": 180,
    "max_projectiles": 80
  }
}
```

Expected:

```text
Không tụt FPS nghiêm trọng trong prototype
Không crash do quá nhiều unit/projectile
Unit không tắc đường nếu body_collision_enabled=false
```
