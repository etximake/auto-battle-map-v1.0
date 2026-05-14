# ROADMAP - Lộ Trình Phát Triển
## Auto Battle TD Simulator - Godot 4.5

---

## 0. Trạng Thái Hiện Tại

Cập nhật theo project hiện tại:

- Project Godot 4.5 đã tồn tại và mở được.
- Cây thư mục chính đã có: `scenes/`, `scripts/`, `resources/`, `docs/`.
- Các thư mục con đã có: `scenes/main`, `scenes/units`, `scripts/units`, `scripts/systems`, `scripts/autoloads`, `scripts/map`.
- Đã có prototype visual `Jelly Blob placeholder` bằng primitive nodes, không dùng sprite/image asset.
- Đã có scene test `scenes/main/TestUnits.tscn`.
- Đã có `scripts/systems/UnitTestSpawner.gd` để spawn 4 unit test.
- Đã verify `TestUnits.tscn` bằng Godot 4.5 headless: scene load không lỗi console.
- `GameConfig.gd`, `GameState.gd`, `EventBus.gd` đang là file rỗng, chưa phải autoload hoạt động.
- Chưa có `Main.tscn`, `GameMap.tscn`, `RoundManager`, `SpawnManager`, `ResourceManager`, `AIController`, `PlayerBase`, `NeutralTower`, UI.

### Lệch Thiết Kế Cần Điều Chỉnh

1. Roadmap cũ đặt Phase 2 là `AI & Economy`, nhưng tiến độ thực tế đã bắt đầu Phase 2 theo hướng `Assets & Style`.
   - Điều chỉnh: Phase 2 mới là `Assets & Style - Jelly Blob Placeholder`.
   - `AI & Economy` dời sang Phase 4, sau khi map/path và spawn flow ổn định.

2. Prototype `TestUnits.tscn` đang dùng tọa độ 1920x1080:
   - Center: `Vector2(960, 540)`
   - Góc: `Vector2(192,108)`, `Vector2(1728,108)`, `Vector2(192,972)`, `Vector2(1728,972)`
   - Thiết kế GDD ban đầu dùng 1280x720 với center `Vector2(640, 360)`.
   - Điều chỉnh: chuẩn chính thức của project là 1280x720 theo GDD. Giữ `TestUnits.tscn` như scene test visual độc lập cho prototype, không dùng nó làm chuẩn tọa độ gameplay.

3. `Unit.gd` hiện tại là placeholder movement/visual, chưa phải Unit gameplay cuối cùng.
   - Chưa có UnitState `MARCHING/ATTACKING/DEAD`.
   - Chưa có combat, detection area, HP bar, EventBus signal, object pool reset.
   - Điều chỉnh: không coi Phase Core Combat đã hoàn thành. File hiện tại sẽ được mở rộng hoặc tách vai trò khi sang gameplay core.

---

## 0.1. Quyết Định Thiết Kế Hiện Tại

- Resolution chính thức: `1280x720`.
- Center gameplay chính thức: `Vector2(640, 360)`.
- Map area chính thức: `x=200..1080`, `y=0..720`.
- Style unit placeholder chính thức: `Jelly Blob` bằng Godot primitive nodes.
- Không dùng sprite/image asset trong giai đoạn placeholder.
- Không dùng player input trong bất kỳ gameplay/system nào.
- `TestUnits.tscn` là scene kiểm tra visual/movement, không phải main scene cuối.

---

## 1. Overview Roadmap Mới

| Phase | Tên | Mục tiêu | Trạng thái |
|---|---|---|---|
| 0 | Project Setup | Project, folder, autoload shell | Đang làm |
| 1 | Core Foundation | Autoloads, GameState, EventBus, config chuẩn | Chưa làm |
| 2 | Assets & Style | Jelly Blob placeholder, unit primitive visual | Đã bắt đầu |
| 3 | Map & Path | GameMap 1280x720, path visual, waypoint provider | Chưa làm |
| 4 | Spawn, Economy & AI | ResourceManager, SpawnManager, AIController | Chưa làm |
| 5 | Combat, Bases & Towers | Unit combat, PlayerBase, NeutralTower | Chưa làm |
| 6 | Round, Score & UI | Round loop, score, HUD, player panels | Chưa làm |
| 7 | Documentation Sync | Đồng bộ docs theo roadmap/style/resolution | Chưa làm |
| 8 | Polish & YouTube Ready | Balance, clarity, long-run stability | Chưa làm |

---

## 2. Definition of Done Chung

Một phase chỉ được coi là xong khi đạt các tiêu chí sau:

- Scene hoặc script của phase load được trong Godot 4.5 không lỗi console.
- Nếu phase có scene test, scene đó chạy được trực tiếp bằng Run Current Scene.
- Không dùng `Input.*`.
- Không thêm sprite/image asset khi phase vẫn thuộc placeholder style.
- File GDScript mới nên dưới 200 dòng; nếu vượt, cần tách trách nhiệm rõ hơn.
- Tên node, path file, signal và exported variables khớp với docs hiện hành.
- Các event gameplay chính dùng `EventBus` khi hệ thống đó đã bước vào gameplay core.
- Roadmap và docs liên quan được cập nhật nếu có thay đổi thiết kế.

---

## PHASE 0 - PROJECT SETUP

### Mục tiêu
Project có cấu trúc đúng, chạy được trong Godot, các file nền tảng sẵn sàng để implement.

### Checklist
- [x] Tạo project Godot 4.5.
- [x] Tạo cây thư mục: `scenes/`, `scripts/`, `resources/`, `docs/`.
- [x] Tạo các thư mục con theo thiết kế.
- [x] Có file shell cho `GameConfig.gd`, `GameState.gd`, `EventBus.gd`.
- [ ] Implement nội dung cho 3 autoload.
- [ ] Đăng ký autoload trong `project.godot`.
- [ ] Set main scene chính thức: `res://scenes/main/Main.tscn`.
- [ ] Set resolution chuẩn 1280x720 trong `project.godot`.

### Deliverable
Project chạy được với autoload thật, không lỗi khi mở scene chính.

---

## PHASE 1 - CORE FOUNDATION

### Mục tiêu
Tạo nền tảng code dùng chung trước khi build gameplay loop.

### Step 1.1 - GameConfig
- [ ] Implement `scripts/autoloads/GameConfig.gd`.
- [ ] Config player count, colors, round duration, gold, strategies, time scale.
- [ ] Dùng màu player đồng bộ với Jelly Blob:
  - Player 0: `#E74C3C`
  - Player 1: `#3498DB`
  - Player 2: `#2ECC71`
  - Player 3: `#F1C40F`
- [ ] Giữ config mở rộng được lên 6 players.

### Step 1.2 - GameState
- [ ] Implement `scripts/autoloads/GameState.gd`.
- [ ] State enum: `IDLE`, `ROUND_ACTIVE`, `ROUND_END`, `SESSION_END`.
- [ ] Signals: `state_changed`, `round_started`, `round_ended`.

### Step 1.3 - EventBus
- [ ] Implement `scripts/autoloads/EventBus.gd`.
- [ ] Khai báo signals trung tâm:
  - `unit_spawned`
  - `unit_died`
  - `unit_reached_base`
  - `base_damaged`
  - `base_destroyed`
  - `gold_changed`
  - `round_reset_requested`
  - `tower_attacked`

### Step 1.4 - Verify Foundation
- [ ] Register 3 autoloads trong `project.godot`.
- [ ] Chạy Godot headless, không lỗi parse/autoload.

### Deliverable
Autoload foundation hoàn chỉnh, các hệ thống sau có thể gọi `GameConfig`, `GameState`, `EventBus`.

---

## PHASE 2 - ASSETS & STYLE: JELLY BLOB PLACEHOLDER

### Mục tiêu
Chốt style placeholder bằng Godot primitive node để test gameplay nhanh, không tạo asset thật.

### Đã hoàn thành
- [x] Tạo `scenes/units/Unit.tscn`.
- [x] Root `CharacterBody2D` tên `Unit`.
- [x] Child nodes:
  - `Polygon2D` tên `Body`
  - `Polygon2D` tên `LeftEye`
  - `Polygon2D` tên `RightEye`
  - `CollisionShape2D` tên `CollisionShape2D`
  - `Label` tên `Label`
- [x] Gắn script `scripts/units/Unit.gd`.
- [x] Body là blob tròn/mềm bằng `Polygon2D`.
- [x] Có 2 mắt trắng nhỏ.
- [x] Label hiện `unit_type`.
- [x] Màu theo `player_id`.
- [x] Collision dùng `CircleShape2D` radius 24.
- [x] Unit tự follow `path_points`.
- [x] Waypoint threshold 8px.
- [x] Unit xoay theo hướng di chuyển.
- [x] Dùng `move_and_slide()`.
- [x] Tạo `scripts/systems/UnitTestSpawner.gd`.
- [x] Tạo `scenes/main/TestUnits.tscn`.
- [x] Test scene spawn 4 blob và chạy về center.
- [x] Không dùng `Input.*`.
- [x] Không dùng sprite/image asset.

### Cần làm tiếp trong Phase 2
- [ ] Chạy visual test trong Godot editor để kiểm tra framing thực tế.
- [ ] Đổi hoặc tạo thêm test path 1280x720 để khớp chuẩn chính thức.
- [ ] Cập nhật docs để Jelly Blob là style placeholder chính thức.
- [ ] Chuẩn bị biến thể visual cho Scout/Soldier/Tank/Mage bằng primitive nodes, chưa cần combat.

### Deliverable
Một style placeholder rõ ràng, chạy được ngay, đủ dùng để test movement/spawn trước khi có asset thật.

---

## PHASE 3 - MAP & PATH

### Mục tiêu
Tạo map thật theo GDD, chuẩn 1280x720, có path visual và API path cho unit.

### Step 3.1 - GameMap Scene
- [ ] Tạo `scenes/map/GameMap.tscn`.
- [ ] Root `Node2D` tên `GameMap`.
- [ ] Background bằng `ColorRect`, không dùng TileMap phức tạp.
- [ ] Tạo `Paths`, `PathVisual`, `SpawnedUnits`.
- [ ] Vẽ 4 nhánh path bằng `Line2D`.

### Step 3.2 - GameMap Script
- [ ] Tạo `scripts/map/GameMap.gd`.
- [ ] Hardcode base positions theo GDD:
  - Player 0: `Vector2(280, 80)`
  - Player 1: `Vector2(1000, 80)`
  - Player 2: `Vector2(280, 640)`
  - Player 3: `Vector2(1000, 640)`
  - Center: `Vector2(640, 360)`
- [ ] Implement `get_march_path(player_id) -> Array[Vector2]`.
- [ ] Opponent mapping: `0 <-> 3`, `1 <-> 2`.
- [ ] Có `_load_paths_from_nodes()` để đọc `Path2D` nếu scene có path nodes.

### Step 3.3 - Integrate Unit Placeholder
- [ ] Tạo test scene map hoặc `Main.tscn` tối thiểu.
- [ ] Spawn Jelly Blob từ base theo path thật.
- [ ] Bỏ dần hardcoded 1920x1080 path khỏi test spawner, hoặc giữ riêng như test phụ.

### Deliverable
Unit có thể march trên map thật, path nhìn rõ, coordinate thống nhất.

---

## PHASE 4 - SPAWN, ECONOMY & AI

### Mục tiêu
4 AI player tự tích gold và mua unit.

### Step 4.1 - ResourceManager
- [ ] Tạo `scripts/systems/ResourceManager.gd`.
- [ ] Gold tăng theo `GameConfig.gold_per_second`.
- [ ] Clamp theo `GameConfig.gold_max`.
- [ ] Emit `EventBus.gold_changed`.
- [ ] Reset khi `round_reset_requested`.

### Step 4.2 - SpawnManager
- [ ] Tạo `scripts/systems/SpawnManager.gd`.
- [ ] Spawn unit theo `player_id`, `unit_type`.
- [ ] Dùng `GameMap.get_march_path(player_id)`.
- [ ] Add unit vào `SpawnedUnits`.
- [ ] Cap max units/player.
- [ ] Chuẩn bị object pool, nhưng có thể implement đơn giản trước nếu cần kiểm tra gameplay nhanh.

### Step 4.3 - AIController
- [ ] Tạo `scripts/players/AIController.gd`.
- [ ] Think interval 0.5s.
- [ ] Implement strategy theo thứ tự:
  1. `AGGRESSIVE`
  2. `BALANCED`
  3. `ECONOMY`
  4. `ADAPTIVE`
- [ ] AI gọi `ResourceManager.spend_gold()` và `SpawnManager.spawn_unit()`.

### Deliverable
4 player tự mua Jelly Blob units, units xuất hiện và march trên map.

---

## PHASE 5 - COMBAT, BASES & TOWERS

### Mục tiêu
Biến placeholder movement thành gameplay unit đầy đủ.

### Step 5.1 - Upgrade Unit Gameplay
- [ ] Thêm stats: `damage`, `attack_range`, `attack_cooldown`.
- [ ] Thêm state machine: `MARCHING`, `ATTACKING`, `DEAD`.
- [ ] Thêm `DetectionArea` nếu cần combat detection.
- [ ] Thêm HP bar primitive/control đơn giản.
- [ ] Thêm `initialize()` và `reset()` để hợp object pool.
- [ ] Khi chết: emit `EventBus.unit_died`.
- [ ] Khi đến base: emit `EventBus.unit_reached_base`.

### Step 5.2 - PlayerBase
- [ ] Tạo `scenes/players/PlayerBase.tscn`.
- [ ] Tạo `scripts/players/PlayerBase.gd`.
- [ ] Base HP mặc định 100.
- [ ] Detect unit vào base.
- [ ] Nhận damage, emit `base_damaged`, `base_destroyed`.

### Step 5.3 - NeutralTower
- [ ] Tạo `scenes/towers/NeutralTower.tscn`.
- [ ] Tạo `scripts/towers/NeutralTower.gd`.
- [ ] Tower auto-attack units trong range.
- [ ] Đặt 8 tower dọc path.

### Deliverable
Units đánh nhau, chết, vào base gây damage, tower bắn unit.

---

## PHASE 6 - ROUND, SCORE & UI

### Mục tiêu
Simulation loop đầy đủ để chạy tự động nhiều round.

### Step 6.1 - RoundManager
- [ ] Tạo `scripts/systems/RoundManager.gd`.
- [ ] Timer round mặc định 75s.
- [ ] `start_round()`, `end_round()`, reset, next round.
- [ ] End round khi timeout hoặc base destroyed.

### Step 6.2 - ScoreManager
- [ ] Tạo `scripts/systems/ScoreManager.gd`.
- [ ] Tính điểm theo unit reached base và round winner.
- [ ] Lưu session score.
- [ ] Print summary cuối session.

### Step 6.3 - UI
- [ ] Tạo `scenes/ui/HUD.tscn`.
- [ ] Tạo `scenes/players/PlayerPanel.tscn`.
- [ ] Hiển thị timer, round, gold, unit count, score.
- [ ] UI dùng để quay video, ưu tiên rõ và ít nhiễu.

### Step 6.4 - Main Bootstrap
- [ ] Tạo `scenes/main/Main.tscn`.
- [ ] Tạo `scripts/main/Main.gd` nếu cần bootstrap wiring.
- [ ] Gắn GameMap, Players, Systems, UI.
- [ ] Start simulation tự động sau 1 frame.
- [ ] Không dùng player input.

### Deliverable
Game tự chạy round mới liên tục, có điểm và UI đủ xem.

---

## PHASE 7 - DOCUMENTATION SYNC

### Mục tiêu
Đồng bộ lại toàn bộ docs để các lần implement sau không bị kéo về thiết kế cũ.

### Checklist
- [ ] Cập nhật `docs/01_GDD.md` để ghi rõ style placeholder là Jelly Blob primitive.
- [ ] Cập nhật `docs/03_SYSTEMS.md` để mô tả đúng `Unit.gd` hiện tại và hướng nâng cấp combat.
- [ ] Cập nhật `docs/04_PROJECT_STRUCTURE.md` để `Unit.tscn` không còn mô tả `ColorRect` làm visual chính.
- [ ] Cập nhật `docs/05_CODEX_PROMPT.md` để prompt theo phase không mâu thuẫn với roadmap mới.
- [ ] Ghi rõ `TestUnits.tscn` là scene prototype, không phải main gameplay scene.
- [ ] Rà toàn bộ docs để tọa độ chính thức là 1280x720.

### Deliverable
Docs khớp với roadmap, style, resolution và cấu trúc file thực tế.

---

## PHASE 8 - POLISH & YOUTUBE READY

### Mục tiêu
Ổn định để quay video dài.

### Checklist
- [ ] Test long run 30-60 phút không crash.
- [ ] Test 100 rounds để cân bằng AI.
- [ ] Tune unit stats và gold income.
- [ ] Kiểm tra unit cap để giữ FPS ổn định.
- [ ] Visual clarity: unit đủ lớn, path rõ, màu player phân biệt tốt.
- [ ] Kiểm tra OBS/video compression.
- [ ] Nếu sau này đổi sang 1920x1080, cập nhật toàn bộ coordinate docs, scenes và project settings trong cùng một phase riêng.

### Deliverable
Project chạy tự động, nhìn rõ trên video, đủ ổn định để quay nội dung YouTube.

---

## Backlog Ưu Tiên Gần Nhất

1. Implement 3 autoload thật: `GameConfig`, `GameState`, `EventBus`.
2. Đăng ký autoloads trong `project.godot`.
3. Set project resolution chính thức 1280x720.
4. Tạo `GameMap.tscn` và `GameMap.gd`.
5. Tích hợp Jelly Blob unit vào map/path thật.
6. Đồng bộ docs đang mô tả unit kiểu `ColorRect` sang Jelly Blob.
7. Sau đó mới làm `ResourceManager`, `SpawnManager`, `AIController`.

---

## Quy Tắc Giữ Thiết Kế

- Game là simulation tự động, không dùng `Input.*`.
- Không tạo asset thật trong giai đoạn placeholder.
- Dùng primitive nodes cho visual sớm.
- GDScript 4.x, Godot 4.5.
- Mỗi file script nên dưới 200 dòng nếu có thể.
- Tất cả event gameplay chính đi qua `EventBus` khi bước vào core systems.
- Ưu tiên chạy được ngay trong Godot sau mỗi phase.
