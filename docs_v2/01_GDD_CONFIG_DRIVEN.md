# 01 — GDD Config-Driven

## 1. Overview

Game là mô phỏng chiến đấu tự động top-down 2D trong Godot 4.5.

- Engine: Godot 4.5
- View: 2D top-down
- Resolution target: 1280×720
- Control: không có player input trong gameplay
- Team count: config-driven, ví dụ 2–6
- Core: Ball-Drop + Auto Battler + Tower Defense + Battle Simulation

## 2. Team count

Số team lấy từ:

```json
{
  "players": {
    "count": 4
  }
}
```

Code phải dùng:

```gdscript
for player_id in range(GameConfig.players_count):
    ...
```

Không viết logic kiểu:

```gdscript
if player_count == 4:
    ...
if player_count == 6:
    ...
```

Có thể dùng `MAX_PLAYERS = 6` làm giới hạn prototype, nhưng runtime phải tạo team theo `players.count`.

## 3. Screen layout

Màn hình gồm 3 vùng:

```text
Left Ball Panels | Battlefield | Right Ball Panels
```

Layout panel sinh động theo số team:

```text
team_id chẵn  → bên trái
team_id lẻ    → bên phải
```

Ví dụ:

```text
2 team:
Left: P0
Right: P1

4 team:
Left: P0, P2
Right: P1, P3

6 team:
Left: P0, P2, P4
Right: P1, P3, P5
```

## 4. Battlefield

Battlefield chứa:

- tower/castle của mỗi team
- spawn point của mỗi team
- route/path giữa tower các team
- unit active
- projectile active
- optional markers nếu cần

Team tower phải là core gameplay. NeutralTower chỉ là optional mode.

## 5. Ball panel

Mỗi team có một BallPanel riêng.

BallPanel có:

- background theo màu team
- ball spawn point
- peg anchors
- reward slots
- queue/count labels
- defeated overlay nếu team thua

Ball tự rơi/bounce. Khi chạm reward slot, reward được gửi tới team tương ứng.

## 6. Rewards

Prototype reward:

| Reward | Effect |
|---|---|
| Scout / Melee | Queue +1 unit nhanh |
| Soldier | Queue +1 unit cân bằng |
| Archer / Mage | Queue +1 ranged unit |
| Tank | Queue +1 unit nhiều HP |
| Hammer | Queue +1 melee heavy |
| Gunner | Queue +1 ranged fast |
| x2 | Nhân đôi reward tiếp theo hoặc spawn burst |
| Heal | Hồi HP tower |
| Shield | Giảm damage tạm thời |

Không cần implement tất cả cùng lúc. Core cần ít nhất 4 unit reward và x2.

## 7. Team tower / castle

Mỗi team tower có 3 vai trò:

1. **Spawn base**
   - nhận reward
   - giữ reward queue
   - spawn unit theo cooldown

2. **Defense tower**
   - có HP
   - có shoot_range
   - tự bắn unit địch trong range
   - tạo projectile

3. **Defeat condition**
   - HP về 0 thì team defeated
   - panel hiển thị defeated
   - team ngừng nhận/spawn reward hoặc xử lý theo config

## 8. Unit behavior

Unit spawn từ tower/castle của team.

State cơ bản:

```text
SPAWN → MOVE → ATTACK → MOVE → REACH_CASTLE hoặc DIE
```

Target priority:

```text
1. Enemy unit trong attack range/detection range
2. Enemy tower ở cuối route
3. Nếu target chết thì chọn target mới hoặc tiếp tục route
```

## 9. Win condition

Round kết thúc khi:

```text
- chỉ còn 1 team alive
hoặc
- hết round timer
```

Timeout winner:

```text
Ưu tiên HP tower cao nhất.
Nếu bằng HP, dùng score.
Nếu vẫn bằng, chọn theo rule deterministic để tránh lỗi.
```

## 10. Out of scope trước assets chuẩn

Chưa cần:

- menu chính
- settings UI
- multiplayer
- player input
- sound/music hoàn chỉnh
- animation phức tạp
- NeutralTower active trong base mode
