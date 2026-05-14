# SYSTEMS - Chi Tiet He Thong
## Ball-Drop Auto Battle Castle Simulator

---

## 1. BALL PANEL SYSTEM

### Files

- `scenes/ui/BallPanel.tscn`
- `scripts/ui/BallPanel.gd`
- `scenes/ui/PanelBall.tscn`
- `scripts/ui/PanelBall.gd`
- `scenes/ui/RewardSlot.tscn`
- `scripts/ui/RewardSlot.gd`

### Trach nhiem

Moi player co mot panel mau o bien man hinh. Panel tu spawn ball, ball roi/chay trong panel va cham vao reward slot.

Prototype duoc phep dung scripted movement truoc, chua can physics phuc tap.

Thong so BallPanel sau nay lay tu `GameConfig`:
- `spawn_interval`
- `ball_speed`
- `max_live_balls`
- `anchor_count`
- `anchor_radius`
- `anchor_reward_gap`
- `reward slot_order`

### Flow

```text
BallPanel timer
  -> spawn PanelBall
  -> PanelBall di chuyen trong vung panel
  -> PanelBall cham RewardSlot
  -> RewardSlot emit reward_generated(player_id, reward_type)
  -> PanelBall despawn/reset
```

### Mini test

Mo scene test panel, quan sat ball cham slot va log dung:

```text
reward_generated P0 Scout
reward_generated P1 Tank
```

---

## 2. REWARD SLOT SYSTEM

Reward slot la diem bien ket qua ball thanh reward.

Reward dau tien:

| Slot | Reward |
|---|---|
| Scout | queue Scout |
| Soldier | queue Soldier |
| Tank | queue Tank |
| Mage | queue Mage |
| x2 | modifier cho reward tiep theo hoac burst |

Giai doan dau uu tien unit reward. Item nhu heal, shield, speed boost de sau.

Signal chinh:

```gdscript
signal reward_generated(player_id: int, reward_type: String)
```

---

## 3. REWARD MANAGER SYSTEM

### File

`scripts/systems/RewardManager.gd`

### Trach nhiem

- Lang nghe `EventBus.reward_generated`.
- Tim castle cua player.
- Dua reward vao queue cua castle.
- Xu ly modifier don gian nhu `x2` khi duoc them.

### Pseudocode

```gdscript
func _ready() -> void:
    EventBus.reward_generated.connect(_on_reward_generated)

func _on_reward_generated(player_id: int, reward_type: String) -> void:
    var castle = _find_castle(player_id)
    if castle == null:
        return
    castle.queue_reward(reward_type)
    EventBus.reward_queued.emit(player_id, reward_type)
```

RewardManager khong spawn unit truc tiep. Castle moi la noi quyet dinh thoi diem spawn.

---

## 4. CASTLE / PLAYERBASE SYSTEM

### File

`scripts/players/PlayerBase.gd`

Co the giu ten file `PlayerBase.gd`, nhung vai tro gameplay la castle.

### Trach nhiem

- Luu `player_id`.
- Luu HP castle.
- Luu queue reward/unit.
- Spawn unit theo cooldown.
- Nhan damage khi unit dich cham vao.

### Data goi y

```gdscript
var reward_queue: Array[String] = []
var spawn_cooldown: float = 1.0
var spawn_timer: float = 0.0
```

### Flow spawn

```text
queue_reward("Scout")
  -> reward_queue.push_back("Scout")
_process(delta)
  -> neu spawn_timer het va queue khong rong
  -> pop reward
  -> neu reward la unit: hoi AI chon route
  -> SpawnManager.spawn_unit(player_id, unit_type, route_points)
```

### Mini test

Goi `queue_reward("Scout")` bang code test, castle phai spawn Scout sau cooldown.

---

## 5. SPAWN MANAGER SYSTEM

### File

`scripts/systems/SpawnManager.gd`

### Trach nhiem

- Spawn unit tu yeu cau cua castle.
- Giu object pool neu can performance.
- Gan `player_id`, `unit_type`, `spawn_position`, `path_points`.
- Emit `unit_spawned`.

### API muc tieu

```gdscript
func spawn_unit(player_id: int, unit_type: String, path_points: Array[Vector2]) -> Unit:
    pass
```

Khong tu quyet dinh mua unit. Khong phu thuoc ResourceManager trong base mode.

---

## 6. AI ROUTE DECISION SYSTEM

### File

`scripts/players/AIController.gd`

### Trach nhiem moi

AI khong mua unit bang gold trong base mode. AI chi quyet dinh route/target khi castle sap spawn unit.

### API goi y

```gdscript
func choose_target_player(unit_type: String) -> int:
    pass

func choose_route(unit_type: String, target_player_id: int) -> Array[Vector2]:
    pass
```

### Strategies

| Strategy | Hanh vi |
|---|---|
| AGGRESSIVE | Chon target gan/yeu, day quan lien tuc |
| BALANCED | Chia target, tranh don het vao mot lane |
| ECONOMY | Giu item/burst neu co, spawn unit nang dung luc |
| ADAPTIVE | Doc map state, doi target khi bi ap luc |

Gold-buy `_buy_unit()` la logic cu, can bo khoi base mode khi refactor.

---

## 7. UNIT SYSTEM

### File

`scripts/units/Unit.gd`

### Trang thai hien co

- Jelly Blob placeholder bang primitive node.
- Di theo `path_points`.
- Combat co ban.
- HP/death/event da co mot phan.

### Behavior muc tieu

```text
Spawn tu castle
  -> nhan path route
  -> di waypoint
  -> gap enemy thi dung danh
  -> target chet/ra range thi tiep tuc di
  -> den castle dich thi gay damage/score
```

### Yeu cau can giu

- Khong dung sprite/image asset trong prototype.
- Khong dung `Input.*`.
- File GDScript duoi 200 dong neu co the.

---

## 8. GAME MAP SYSTEM

### File

`scripts/map/GameMap.gd`

### Trach nhiem

- Luu castle positions.
- Luu route/waypoints.
- Ve path visual.
- Cung cap route cho AI/SpawnManager.

### API muc tieu

```gdscript
func get_castle_position(player_id: int) -> Vector2:
    pass

func get_route(from_player_id: int, target_player_id: int, route_id: String = "main") -> Array[Vector2]:
    pass
```

### Rule moi

`TOWER_POSITIONS` neu con dung thi doi thanh `OPTIONAL_TOWER_POSITIONS` hoac comment ro la optional mode. Base mode khong instance active NeutralTower.

---

## 9. ROUND MANAGER SYSTEM

### File

`scripts/systems/RoundManager.gd`

### Trach nhiem

- Start round.
- Reset ball panels, castles, units.
- Quan ly timer.
- End round khi timeout/castle destroyed.
- Auto restart de quay video lien tuc.

RoundManager khong quan ly reward logic truc tiep.

---

## 10. SCORE MANAGER SYSTEM

### File

`scripts/systems/ScoreManager.gd`

### Score source

- Unit vao castle dich.
- Damage gay len castle.
- Pha castle.
- Co the cong bonus tu reward slot dac biet trong phase sau.

ScoreManager chi lang nghe event, khong dieu khien spawn/combat.

---

## 11. LEGACY / OPTIONAL SYSTEMS

### ResourceManager

`ResourceManager.gd` thuoc prototype cu AI mua unit bang gold. Trong base mode moi:

- Khong la nguon sinh quan chinh.
- Khong duoc mo rong thanh core loop.
- Co the giu lai cho optional mode economy sau.

### NeutralTower

`NeutralTower.gd` va `NeutralTower.tscn` duoc giu lai cho:

- Neutral Tower Mode.
- Hazard Mode.
- Capture Outpost Mode.

Khong dat active trong `Main.tscn` base mode.

---

## 12. CONFIG SYSTEM

### Files

- `scripts/autoloads/GameConfig.gd`
- `configs/default_game_config.json`
- `configs/presets/*.json`
- `user://game_config_override.json`

### Trach nhiem

`GameConfig` la noi duy nhat load va validate JSON config.

Load order:

```text
safe defaults
  -> default_game_config.json
  -> user override
  -> validate/clamp
```

Systems khac chi doc config qua `GameConfig`, khong tu parse JSON.

Config groups:
- `players`
- `round`
- `ball_panel`
- `rewards`
- `units`
- `castle`
- `limits`
- `optional_modes`

Mini test sau khi implement:
- Chay Godot headless.
- Log config summary.
- Doi `ball_panel.spawn_interval` trong JSON va thay doi co tac dung voi `BallPanel`.
- JSON sai field khong crash game.
