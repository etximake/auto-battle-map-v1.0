# Game Design Document (GDD)
## Project: Auto Battle TD Simulator
### Version 1.1 - Godot 4.5 | YouTube Simulation Build

---

## 1. TỔNG QUAN DỰ ÁN

| Thuộc tính | Giá trị |
|---|---|
| Engine | Godot 4.5 |
| Mục tiêu | Auto simulation để quay video YouTube |
| Thể loại | Ball-Drop Auto Battle / Castle Spawn Simulator |
| Số player | 4 AI players, có thể mở rộng 2-6 |
| Điều khiển | 100% tự động, không cần player input |
| Góc nhìn | Top-down 2D |
| Resolution chính thức | 1280x720 |

Core fantasy:
> Các panel màu ở hai bên liên tục thả ball. Ball rơi trúng ô reward nào thì castle của team đó nhận unit/item tương ứng. Castle tự spawn quân vào map, AI chọn hướng đi, quân tự giao chiến để tạo một trận auto battle dễ xem cho YouTube.

---

## 2. GAME MODE CHÍNH

### Base Mode: Ball Panel Castle Battle

Đây là mode chính cần bám theo ảnh game mục tiêu.

Loop chính:
```text
Round Start
  -> Ball xuất hiện/rơi trong từng PlayerPanel
  -> Ball chạm reward slot
  -> Reward tạo unit/item cho castle tương ứng
  -> Castle đưa reward vào spawn queue
  -> Castle spawn unit ra map
  -> AI chọn route/target cho unit
  -> Unit tự di chuyển và combat
  -> Unit vào castle địch gây damage/score
  -> Round timeout hoặc castle bị phá
  -> Reset và round mới
```

### Optional Mode: Neutral Tower Variant

`NeutralTower` không thuộc base mode. Tower trung lập có thể dùng cho mode phụ sau này:
- Tower bắn tất cả unit đi ngang.
- Tower có thể là hazard mode, challenge mode hoặc capture mode.
- Code/scene tower được giữ lại để tái dùng, nhưng **không đặt active trong gameplay base**.

---

## 3. MÀN HÌNH & BỐ CỤC

```text
┌────────────┬────────────────────────┬────────────┐
│ Panel P0   │                        │ Panel P1   │
│ Ball board │                        │ Ball board │
├────────────┤      MAP / CASTLES     ├────────────┤
│ Panel P2   │      AUTO BATTLE       │ Panel P3   │
│ Ball board │                        │ Ball board │
└────────────┴────────────────────────┴────────────┘
```

- Map area chính thức: `x=192..1088`, `y=0..720`.
- Center: `Vector2(640, 360)`.
- Castle/base positions:
  - P0: `Vector2(304, 134)`
  - P1: `Vector2(976, 134)`
  - P2: `Vector2(304, 586)`
  - P3: `Vector2(976, 586)`
- Hai vùng biên trái/phải dành cho ball panels và UI.

---

## 4. BALL PANEL SYSTEM

Mỗi player có một panel màu.

Panel có:
- Ball spawn area.
- Ball rơi/tung tự động bằng physics hoặc scripted motion.
- Reward slots ở dưới panel.
- Score/stock number lớn.
- Unit/item counters.

Ball behavior:
1. Spawn ở đầu panel theo timer.
2. Rơi/bounce trong vùng panel.
3. Khi chạm reward slot, emit reward event.
4. Reward được gửi tới castle/team tương ứng.
5. Ball bị despawn hoặc reset.

Giai đoạn đầu có thể scripted đơn giản, chưa cần physics phức tạp.

---

## 5. REWARD & ITEM SYSTEM

Reward slot có thể tạo:
- Unit: Scout, Soldier, Tank, Mage.
- Item: speed boost, heal, shield, multiplier.
- Economy bonus: extra ball, x2 reward, fast spawn.

Trong prototype gần nhất, ưu tiên unit rewards trước:

| Reward | Kết quả |
|---|---|
| Scout slot | Castle queue thêm Scout |
| Soldier slot | Castle queue thêm Soldier |
| Tank slot | Castle queue thêm Tank |
| Mage slot | Castle queue thêm Mage |
| x2 slot | Nhân đôi reward tiếp theo hoặc tăng spawn burst |

---

## 6. CASTLE / BASE SYSTEM

Castle là nơi nhận reward và spawn unit.

Castle behavior:
1. Nhận reward từ `BallPanel`.
2. Đưa unit/item vào queue.
3. Spawn unit theo cooldown riêng.
4. Hỏi AI route/target để gán path cho unit.
5. Bị unit địch vào gây damage.

`PlayerBase` hiện có thể refactor thành `PlayerCastle`.

---

## 7. AI SYSTEM

AI không còn trực tiếp mua unit bằng gold trong base mode.

AI nên quyết định:
- Castle spawn unit đi lane/path nào.
- Ưu tiên tấn công castle nào.
- Khi có nhiều route, chọn route ít địch hơn hoặc route đang cần phòng thủ.
- Có dùng item ngay hay giữ trong queue không.

Strategy gợi ý:

| Strategy | Hành vi |
|---|---|
| AGGRESSIVE | Chọn route ngắn, đẩy quân liên tục |
| BALANCED | Chia quân giữa attack/defense |
| ECONOMY | Ưu tiên giữ item/x2/burst lâu hơn |
| ADAPTIVE | Đọc số unit địch và đổi route theo trạng thái map |

---

## 8. UNIT SYSTEM

Unit hiện dùng Jelly Blob placeholder bằng primitive nodes.

Unit behavior:
1. Spawn từ castle.
2. Nhận path/route do AI chọn.
3. Đi theo waypoint.
4. Gặp unit địch trong range thì dừng đánh.
5. Thắng combat thì tiếp tục đi.
6. Vào castle địch thì gây damage/score và despawn.

Unit stats prototype:

| Unit | HP | DMG | Speed | Range | Cooldown | Role |
|---|---:|---:|---:|---:|---:|---|
| Scout | 20 | 5 | Fast | 28 | 0.8 | Nhanh, số lượng |
| Soldier | 50 | 15 | Normal | 34 | 1.0 | DPS chính |
| Tank | 150 | 8 | Slow | 32 | 1.5 | Chịu đòn |
| Mage | 30 | 40 | Medium | 85 | 2.0 | Burst/ranged |

---

## 9. MAP & PATH

Base mode dùng map spider/cross có castle ở 4 vùng.

Yêu cầu path sắp tới:
- Không chỉ fixed opposite path.
- Cần route graph hoặc lane options.
- AI chọn route khi castle spawn unit.
- `GameMap.get_march_path(player_id)` hiện là tạm thời, cần refactor thành `get_route(player_id, route_id/target_id)`.

Neutral tower positions hiện tại chỉ giữ làm marker/design reference cho optional mode.

---

## 10. WIN CONDITIONS & SCORING

Round có thể kết thúc khi:
- Hết timer.
- Một castle bị phá.
- Một player đạt score threshold.

Score nguồn:
- Unit vào castle địch: +1 hoặc gây damage.
- Phá castle: bonus lớn.
- Ball panel có thể tạo score bonus riêng.

---

## 11. KHÔNG CẦN Ở GIAI ĐOẠN PROTOTYPE

- Không cần menu chính.
- Không cần player input.
- Không cần asset thật.
- Không cần animation phức tạp.
- Không cần sound/music.
- Không cần networking.
- Không cần tower trung lập trong base mode.
