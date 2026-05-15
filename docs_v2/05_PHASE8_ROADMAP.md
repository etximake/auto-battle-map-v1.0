# 05 — Phase 8 Roadmap

## Current state assumption

Phase 0–7 đã hoàn thành:

```text
BallPanel → RewardSlot → RewardManager → CastleQueue → CastleSpawn → AIRoute → AutoBattle → Score → RoundReset
```

Phase 8 không nên làm assets trước. Nên hoàn thiện gameplay target trước.

## Phase 8A — CastleShooter

Goal: thêm lớp Tower Defense thật.

Tasks:

```text
- Thêm config castle.shoot_range, shoot_damage, shoot_cooldown, projectile_speed
- Tạo Projectile.tscn / Projectile.gd
- Thêm ShootDetectionArea vào PlayerBase hoặc CastleShooter child
- Castle tự chọn enemy unit trong range
- Castle spawn projectile
- Projectile gây damage khi tới target
- Không bắn unit cùng team
```

Acceptance:

```text
Unit địch vào range tower → tower bắn projectile → unit mất HP/chết.
```

## Phase 8B — Config-driven player count audit

Goal: không còn hard-code 4 hoặc 6 trong gameplay.

Check:

```text
Main.gd / Main.tscn
GameMap.gd
BallPanel layout
AIController target list
RewardManager find castle
SpawnManager limits
ScoreManager scores
RoundHud HP bars
RoundManager alive teams
```

Acceptance:

```text
players.count=2 chạy.
players.count=4 chạy.
players.count=6 chạy.
Không sửa scene thủ công giữa các lần test.
```

## Phase 8C — BallPanel peg bounce improvement

Goal: ball panel nhìn giống pachinko hơn.

Tasks:

```text
- Anchor pegs có vị trí rõ
- Ball reflect khi gặp peg
- Ball reflect ở border
- Spawn angle random nhẹ
- Giữ scripted movement, chưa cần RigidBody2D
```

Acceptance:

```text
Ball không đi cùng đường lặp lại quá rõ.
Ball không thoát khỏi panel.
Reward vẫn emit đúng player.
```

## Phase 8D — Unit roster refinement

Goal: chuẩn hóa unit cho game mục tiêu.

Minimum:

```text
Scout / Soldier / Tank / Mage
```

Optional target roster:

```text
Melee
Archer
Gunner
Hammer
Tank
Mage/Special
```

Acceptance:

```text
Reward slot nào spawn đúng unit đó.
Unit stats đọc từ config.
```

## Phase 8E — HUD config-driven

Goal: HUD hiển thị đủ N team.

Tasks:

```text
- HP bar theo range(players_count)
- Score theo range(players_count)
- Defeated overlay theo team
- Winner overlay
```

Acceptance:

```text
players.count thay đổi thì HUD tự thay đổi.
```

## Phase 8F — Placeholder asset swap

Chỉ làm sau khi 8A–8E ổn.

Tasks:

```text
- Castle sprite/modulate theo team
- Unit sprite/modulate theo team
- Projectile visual rõ
- Reward slot icon đơn giản
```

Rule:

```text
Không thay gameplay logic khi swap asset.
```

## Recommended order

```text
8A CastleShooter
8B Config-driven count audit
8C PegBoard improvement
8E HUD config-driven
8D Unit roster refinement
8F Asset swap
```
