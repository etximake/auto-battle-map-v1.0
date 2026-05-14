# ROADMAP - Lộ Trình Phát Triển
## Auto Battle TD Simulator - Godot 4.5

---

## 0. Pivot Thiết Kế

Project đã pivot sang loop mục tiêu mới:

```text
Ball Panel -> Reward Slot -> Castle Queue -> Castle Spawn -> AI Route -> Auto Battle
```

Quyết định quan trọng:
- Base mode không dùng neutral tower bắn quân.
- `NeutralTower.gd` và `NeutralTower.tscn` được giữ lại cho optional mode sau.
- Không xóa code đã có nếu còn tái dùng được.
- Không tiếp tục mở rộng gold-buy loop như core gameplay.
- Phase tiếp theo phải refactor từ `AI mua unit bằng gold` sang `ball panel tạo reward`.

---

## 1. Trạng Thái Hiện Tại

Đã có:
- Project Godot 4.5, resolution `1280x720`.
- `GameConfig`, `GameState`, `EventBus`.
- Jelly Blob unit placeholder và 4 unit scenes: Scout, Soldier, Tank, Mage.
- `GameMap` scale theo SVG mục tiêu về 1280x720.
- `Unit` có movement/combat cơ bản.
- `PlayerBase` đang đóng vai castle tạm thời.
- `ResourceManager`, `SpawnManager`, `AIController` đang theo logic cũ: AI mua unit bằng gold.
- `NeutralTower` đã có và đã được bỏ khỏi base gameplay; file vẫn giữ cho optional mode.
- `EventBus` đã có reward/castle signals để chuẩn bị Ball Panel Prototype.
- `BallPanel`, `PanelBall`, `RewardSlot` prototype đã có và emit được `reward_generated`.

Cần sửa hướng:
- Tắt/remove neutral towers khỏi `GameMap` base mode. [x]
- Thêm `BallPanel`, `RewardSlot`, `CastleQueue`. [BallPanel/RewardSlot done, CastleQueue pending]
- Refactor `AIController` để chọn route/target, không trực tiếp mua unit.
- Refactor `SpawnManager` để spawn từ castle queue/reward.

---

## 2. Roadmap Mới

| Phase | Tên | Mục tiêu | Trạng thái |
|---|---|---|---|
| 0 | Foundation | Project, autoload, primitive unit | Hoàn thành |
| 1 | Map Base | Map/castle/path theo SVG, không tower core | Hoàn thành |
| 2 | Ball Panel Prototype | Panel màu, ball rơi, reward slot | Hoàn thành |
| 3 | Castle Queue & Spawn | Reward vào castle, castle spawn unit | Chưa làm |
| 4 | AI Route Decision | AI chọn route/target cho unit | Chưa làm |
| 5 | Auto Battle Loop | Combat, castle damage, scoring cơ bản | Một phần đã có |
| 6 | Round & UI | Timer, score, panels, reset loop | Chưa làm |
| 7 | Optional Modes | Neutral tower/capture/hazard variants | Chưa làm |
| 8 | Polish | Balance, visual clarity, YouTube ready | Chưa làm |

---

## 3. Phase 1 - Map Base Reconciliation

Mục tiêu: map base mode không có tower trung lập active.

Checklist:
- [x] Remove hoặc disable `Towers` trong `GameMap.tscn` cho base mode.
- [x] Giữ `NeutralTower.tscn` và `NeutralTower.gd` trong project.
- [x] Đổi tower positions thành `optional_tower_positions` hoặc marker/reference.
- [x] Đảm bảo `Main.tscn` chạy không có tower bắn unit.
- [x] `GameMap` vẫn có castle/base positions:
  - P0: `Vector2(304, 134)`
  - P1: `Vector2(976, 134)`
  - P2: `Vector2(304, 586)`
  - P3: `Vector2(976, 586)`
- [x] Mini test: units spawn từ castle và đi path, không bị neutral tower bắn.

Deliverable:
Base map đúng hướng game mục tiêu, chưa có ball panel nhưng không còn tower core sai loop.

Implementation notes:
- `GameMap.tscn` không còn node `Towers` và không còn instance `NeutralTower`.
- Các vị trí T được giữ dưới dạng `OptionalTowerMarkers` ẩn.
- `GameMap.gd` đổi `TOWER_POSITIONS` thành `OPTIONAL_TOWER_POSITIONS`.
- `NeutralTower.gd` và `NeutralTower.tscn` vẫn nằm trong project cho optional mode.
- Godot 4.5 headless chạy `Main.tscn` thành công với log-file `.godot/phase1-map-base.log`.

---

## 4. Phase 2 - Ball Panel Prototype

Mục tiêu: tạo cơ chế panel màu hai bên sinh reward.

Files dự kiến:
- `scenes/ui/BallPanel.tscn`
- `scripts/ui/BallPanel.gd`
- `scenes/ui/RewardSlot.tscn`
- `scripts/ui/RewardSlot.gd`
- `scenes/ui/PanelBall.tscn`
- `scripts/ui/PanelBall.gd`

Checklist:
- [x] Mỗi player có một panel màu.
- [x] Panel có ball spawn tự động.
- [x] Ball rơi/chạy trong panel mà không cần input.
- [x] Có 4 reward slots unit: Scout, Soldier, Tank, Mage.
- [x] Khi ball chạm slot, emit `reward_generated(player_id, reward_type)`.
- [x] Không cần physics phức tạp ở bản đầu; scripted motion được chấp nhận.
- [x] Mini test: ball tạo reward log/queue đúng player.

Deliverable:
Nhìn thấy ball panel hoạt động, reward được tạo tự động.

Implementation notes:
- Tạo `scenes/ui/BallPanel.tscn`, `PanelBall.tscn`, `RewardSlot.tscn`.
- Tạo `scripts/ui/BallPanel.gd`, `PanelBall.gd`, `RewardSlot.gd`.
- Tạo `scenes/main/TestBallPanel.tscn` để test 4 panel hai bên.
- Tạo `scripts/systems/BallPanelTestMonitor.gd` để log reward event.
- Godot 4.5 headless chạy `TestBallPanel.tscn` thành công, log có `reward_generated`.
- Không dùng sprite/image asset và không dùng `Input.*`.

---

## 5. Phase 3 - Castle Queue & Spawn

Mục tiêu: reward từ panel đi vào castle, castle spawn unit ra map.

Files dự kiến:
- Refactor `PlayerBase.gd` thành castle role hoặc tạo `PlayerCastle.gd`.
- `scripts/systems/RewardManager.gd`
- Refactor `SpawnManager.gd`.

Checklist:
- [ ] Castle có queue unit/item.
- [ ] `RewardManager` nhận signal từ BallPanel.
- [ ] Reward unit được đưa vào castle queue.
- [ ] Castle spawn theo cooldown.
- [ ] SpawnManager chỉ spawn khi castle/reward yêu cầu.
- [ ] Tắt hoặc bỏ vai trò "AI mua unit bằng gold" trong base mode.
- [ ] Mini test: ball hit Scout slot -> castle queue -> Scout spawn.

Deliverable:
Nguồn sinh quân đúng game mục tiêu.

---

## 6. Phase 4 - AI Route Decision

Mục tiêu: AI quyết định hướng đi sau khi castle spawn unit.

Checklist:
- [ ] Refactor `AIController`: không còn `_buy_unit()`.
- [ ] AI nhận câu hỏi từ castle/spawn: unit này nên đi route nào?
- [ ] `GameMap` hỗ trợ nhiều route/target, không chỉ fixed opposite path.
- [ ] Strategy:
  - AGGRESSIVE: route ngắn/tấn công nhiều.
  - BALANCED: chia quân theo áp lực.
  - ECONOMY: giữ item/burst nếu có.
  - ADAPTIVE: đọc map state và đổi route.
- [ ] Mini test: cùng một castle có thể spawn unit đi các hướng khác nhau.

Deliverable:
AI điều khiển hướng chiến thuật, không điều khiển mua unit trực tiếp.

---

## 7. Phase 5 - Auto Battle Loop

Mục tiêu: hoàn thiện combat/castle damage/scoring cho base mode.

Đã có một phần:
- Unit movement/combat cơ bản.
- PlayerBase nhận damage.
- SpawnManager pool cơ bản.

Cần làm:
- [ ] Kiểm tra lại combat khi unit đông.
- [ ] Unit vào castle địch gây score/damage rõ ràng.
- [ ] ScoreManager tính điểm từ castle damage/reach.
- [ ] Điều chỉnh unit stats cho video dễ xem.
- [ ] Mini test 4 castle tự spawn từ panel và giao chiến.

Deliverable:
Loop auto battle xem được dù UI còn đơn giản.

---

## 8. Phase 6 - Round & UI

Mục tiêu: simulation chạy liên tục để quay video.

Checklist:
- [ ] RoundManager timer/reset.
- [ ] HUD timer/round.
- [ ] PlayerPanel hiển thị ball count/reward/score/castle HP.
- [ ] Round result overlay tối thiểu.
- [ ] Auto restart.

Deliverable:
Game tự chạy nhiều round, có UI đủ hiểu.

---

## 9. Phase 7 - Optional Modes

Neutral tower chuyển sang mode phụ:

### Neutral Tower Mode
- [ ] Re-enable `NeutralTower`.
- [ ] Towers bắn mọi team hoặc có thể capture.
- [ ] Đây là game variant, không phải base mode.

### Capture Outpost Mode
- [ ] Các vị trí T trở thành outpost có thể chiếm.
- [ ] Outpost spawn unit hoặc buff team đã chiếm.

Deliverable:
Biến thể gameplay để tạo nhiều video khác nhau.

---

## 10. Backlog Ưu Tiên Gần Nhất

1. Tạo RewardManager/Castle queue.
2. Refactor SpawnManager để nhận spawn request từ castle queue.
3. Refactor AIController khỏi logic mua unit bằng gold.

---

## 11. Quy Tắc Thiết Kế

- Base mode phải bám loop ball-panel/castle-spawn.
- Không dùng player input.
- Không dùng asset thật khi còn prototype.
- Neutral tower chỉ là optional mode.
- Không mở rộng hệ gold-buy thành core gameplay.
- Mỗi bước phải có mini test scene hoặc test path rõ ràng.
- GDScript file nên dưới 200 dòng.
