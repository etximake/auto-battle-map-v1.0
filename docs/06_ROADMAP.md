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
- `ResourceManager` vẫn giữ cho optional/legacy, nhưng base mode không còn dùng AI mua unit bằng gold.
- `SpawnManager` nhận spawn request từ castle queue và có thể nhận route từ AI.
- `AIController` đã chuyển sang chọn target/route cho unit sau khi castle spawn.
- `NeutralTower` đã có và đã được bỏ khỏi base gameplay; file vẫn giữ cho optional mode.
- `EventBus` đã có reward/castle signals để chuẩn bị Ball Panel Prototype.
- `BallPanel`, `PanelBall`, `RewardSlot` prototype đã có và emit được `reward_generated`.
- JSON config foundation đã được implement trong `GameConfig`; `BallPanel` đã đọc tham số từ config.
- Reward từ `BallPanel` đã đi vào castle queue và castle đã spawn unit qua `SpawnManager`.

Cần sửa hướng:
- Tắt/remove neutral towers khỏi `GameMap` base mode. [x]
- Thêm `BallPanel`, `RewardSlot`, `CastleQueue`. [x]
- Refactor `AIController` để chọn route/target, không trực tiếp mua unit. [x]
- Refactor `SpawnManager` để spawn từ castle queue/reward. [x]

---

## 2. Roadmap Mới

| Phase | Tên | Mục tiêu | Trạng thái |
|---|---|---|---|
| 0 | Foundation | Project, autoload, primitive unit | Hoàn thành |
| 1 | Map Base | Map/castle/path theo SVG, không tower core | Hoàn thành |
| 2 | Ball Panel Prototype | Panel màu, ball rơi, reward slot | Hoàn thành |
| 3 | JSON Config Foundation | Load/validate config cho tham số gameplay | Hoàn thành |
| 4 | Castle Queue & Spawn | Reward vào castle, castle spawn unit | Hoàn thành |
| 5 | AI Route Decision | AI chọn route/target cho unit | Hoàn thành |
| 5.5 | Unit Scale & Anti-Clog | Unit nho hon, body collision prototype off | Hoan thanh |
| 6 | Auto Battle Loop | Combat, castle damage, scoring co ban | Hoan thanh |
| 7 | Round & UI | Timer, score, panels, reset loop | Hoan thanh |
| 8 | Optional Modes | Neutral tower/capture/hazard variants | Chưa làm |
| 9 | Polish | Balance, visual clarity, YouTube ready | Chưa làm |

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

## 5. Phase 3 - JSON Config Foundation

Mục tiêu: các tham số gameplay chính có thể chỉnh bằng JSON config trước khi mở rộng castle/reward/AI.

Files dự kiến:
- `configs/default_game_config.json`
- `configs/presets/`
- Refactor `scripts/autoloads/GameConfig.gd`

Checklist:
- [x] Tạo `configs/default_game_config.json` theo `docs/07_CONFIG_SCHEMA.md`.
- [x] `GameConfig.gd` có safe defaults.
- [x] Load default JSON từ `res://configs/default_game_config.json`.
- [x] Load override từ `user://game_config_override.json` nếu có.
- [x] Validate/clamp player count, round, ball panel, unit, castle, limits.
- [x] BallPanel đọc tham số từ `GameConfig` thay vì hardcode toàn bộ.
- [x] JSON lỗi không crash game.
- [x] Mini test: `TestBallPanel.tscn` chạy qua config và vẫn emit reward event.

Deliverable:
Config foundation sẵn sàng để người dùng/content creator chỉnh tham số mà không sửa code.

Implementation notes:
- Tạo `configs/default_game_config.json`.
- Tạo `configs/presets/` để chứa preset về sau.
- Refactor `scripts/autoloads/GameConfig.gd` thành JSON loader có safe defaults, merge config và validation.
- `BallPanel.gd` đọc `spawn_interval`, `ball_speed`, `max_live_balls`, anchor settings, reward order và player colors từ `GameConfig`.
- Verify Godot 4.5 headless: `TestBallPanel.tscn` và `Main.tscn` load không lỗi.

---

## 6. Phase 4 - Castle Queue & Spawn

Mục tiêu: reward từ panel đi vào castle, castle spawn unit ra map.

Files dự kiến:
- Refactor `PlayerBase.gd` thành castle role hoặc tạo `PlayerCastle.gd`.
- `scripts/systems/RewardManager.gd`
- Refactor `SpawnManager.gd`.

Checklist:
- [x] Castle có queue unit/item.
- [x] `RewardManager` nhận signal từ BallPanel.
- [x] Reward unit được đưa vào castle queue.
- [x] Castle spawn theo cooldown.
- [x] SpawnManager chỉ spawn khi castle/reward yêu cầu trong base mode.
- [x] Tắt hoặc bỏ vai trò "AI mua unit bằng gold" trong base mode.
- [x] Mini test: ball hit Scout slot -> castle queue -> Scout spawn.

Deliverable:
Nguồn sinh quân đúng game mục tiêu.

Implementation notes:
- Tạo `scripts/systems/RewardManager.gd`.
- Refactor `PlayerBase.gd` thành castle queue tạm thời với `queue_reward()`, `reward_queue`, `spawn_cooldown`, `queue_limit`.
- `PlayerBase` đọc `castle_max_hp`, `castle_spawn_cooldown`, `castle_queue_limit` từ `GameConfig`.
- `SpawnManager` vào group `spawn_managers` và đọc `max_units_per_player` từ `GameConfig`.
- `Main.tscn` có `RewardManager`, 4 `BallPanel`, và AI gold-buy cũ đã `active=false`.
- Tạo `TestCastleQueue.tscn` và `CastleQueueTestMonitor.gd`.
- Verify Godot 4.5 headless: log có `reward_queued`, `castle_spawn_requested`, `unit_spawned`.

---

## 7. Phase 5 - AI Route Decision

Mục tiêu: AI quyết định hướng đi sau khi castle spawn unit.

Checklist:
- [x] Refactor `AIController`: không còn `_buy_unit()`.
- [x] AI nhận câu hỏi từ castle/spawn: unit này nên đi route nào?
- [x] `GameMap` hỗ trợ nhiều route/target, không chỉ fixed opposite path.
- [x] Strategy:
  - AGGRESSIVE: route ngắn/tấn công nhiều.
  - BALANCED: chia quân theo áp lực.
  - ECONOMY: giữ item/burst nếu có.
  - ADAPTIVE: đọc map state và đổi route.
- [x] Mini test: cùng một castle có thể spawn unit đi các hướng khác nhau.

Deliverable:
AI điều khiển hướng chiến thuật, không điều khiển mua unit trực tiếp.

Implementation notes:
- `AIController.gd` chuyển thành service chọn target/route, không tự mua unit bằng gold.
- `GameMap.gd` thêm `get_route(from_player_id, target_player_id)` và `get_target_player_ids()`.
- `PlayerBase.gd` hỏi AI route trước khi gọi `SpawnManager.spawn_unit()`.
- `SpawnManager.gd` nhận route tùy chọn từ castle/AI, vẫn fallback về march path cũ nếu cần.
- `TestCastleQueue.tscn` có 4 AI controller để test route decision.
- Verify Godot 4.5 headless: `TestCastleQueue.tscn` log có `route_end`, `Main.tscn` load không lỗi.

---

## 7.5. Phase 5.5 - Unit Scale & Anti-Clog

Muc tieu: giam tac duong prototype truoc khi test combat dong quan.

Checklist:
- [x] Unit doc stats/size tu JSON config.
- [x] Giam visual radius va collision radius cua Scout/Soldier/Tank/Mage.
- [x] Tat body collision giua unit trong base prototype de unit khong day/chan nhau tren duong hep.
- [x] Waypoint reach distance dua vao JSON config.
- [x] Mini test: `TestCastleQueue.tscn` va `Main.tscn` load khong loi.

Deliverable:
Unit nho hon so voi duong line, khong bi body collision lam ket hang truoc khi vao Phase 6 combat.

Implementation notes:
- `default_game_config.json` them `visual_radius`, `collision_radius` cho tung unit.
- `default_game_config.json` them `unit_behavior.body_collision_enabled=false` va `waypoint_distance=7.0`.
- `Unit.gd` dung config cho stats/size/collision thay vi chi dung scene export.

---

## 8. Phase 6 - Auto Battle Loop

Muc tieu: hoan thien combat/castle damage/scoring cho base mode.

Da co:
- Unit movement/combat co ban.
- PlayerBase nhan castle damage.
- SpawnManager pool co ban.
- ScoreManager tinh diem co ban.

Checklist:
- [x] Kiem tra lai combat khi unit dong.
- [x] Unit vao castle dich gay score/damage ro rang.
- [x] ScoreManager tinh diem tu unit kill, castle damage, castle destroy.
- [x] Dieu chinh unit stats/size qua JSON config de de xem hon.
- [x] Mini test castle spawn, auto battle, score/damage event.

Deliverable:
Loop auto battle xem duoc du UI con don gian.

Implementation notes:
- `Unit.gd` emit `unit_reached_castle` khi unit di het route.
- `PlayerBase.gd` dung castle signal moi, emit `castle_damaged`/`castle_destroyed`, va tranh destroy lap.
- `ScoreManager.gd` tinh score tu unit kill, castle damage, castle destroy.
- `default_game_config.json` them nhom `auto_battle` de tune damage/score.
- `Main.tscn` co `ScoreManager`.
- `TestAutoBattleLoop.tscn` xac thuc score/damage loop.
- Verify Godot 4.5 headless: `TestAutoBattleLoop.tscn`, `TestCastleQueue.tscn`, `Main.tscn` khong loi.

---

## 9. Phase 7 - Round & UI

Muc tieu: simulation chay lien tuc de quay video.

Checklist:
- [x] RoundManager timer/reset.
- [x] HUD timer/round.
- [x] HUD hien score va castle HP co ban.
- [x] Round result overlay toi thieu.
- [x] Auto restart.

Deliverable:
Game tu chay nhieu round, co UI du hieu.

Implementation notes:
- `RoundManager.gd` tu start round, dem nguoc, end round, restart theo config.
- `RoundHud.gd` hien round timer, score, castle HP, va winner khi round end.
- `Main.tscn` da gan `RoundManager` va `RoundHud`.
- `TestRoundLoop.tscn` dung round duration ngan de test reset/restart.
- Verify Godot 4.5 headless: `TestRoundLoop.tscn`, `Main.tscn`, `TestAutoBattleLoop.tscn` khong loi.

---

## 10. Phase 8 - Optional Modes

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

## 11. Backlog Ưu Tiên Gần Nhất

1. Bat dau chuan bi/thay asset that cho base mode: map, castle, unit, panel.
2. Phase 8 neu muon them optional modes: neutral tower/capture outpost.
3. Phase 9 polish: readability, VFX, SFX, YouTube-ready tuning.

---

## 12. Quy Tắc Thiết Kế

- Base mode phải bám loop ball-panel/castle-spawn.
- Không dùng player input.
- Không dùng asset thật khi còn prototype.
- Neutral tower chỉ là optional mode.
- Không mở rộng hệ gold-buy thành core gameplay.
- Tham số gameplay mới nên đưa vào JSON config nếu có khả năng cần tune/user settings.
- Mỗi bước phải có mini test scene hoặc test path rõ ràng.
- GDScript file nên dưới 200 dòng.
