# Game Design Document (GDD)
## Project: Auto Battle TD Simulator
### Version 1.0 — Godot 4.5 | YouTube Simulation Build

---

## 1. TỔNG QUAN DỰ ÁN

| Thuộc tính | Giá trị |
|---|---|
| Engine | Godot 4.5 |
| Mục tiêu | Auto Simulation để quay video YouTube |
| Thể loại | Competitive Tower Defense Auto-Battler |
| Số player | Linh hoạt (config: 2–6 AI players) |
| Điều khiển | 100% AI, không cần input người chơi |
| Góc nhìn | Top-down 2D |
| Thời gian/round | Config được (mặc định 75 giây) |

---

## 2. THỂ LOẠI & ĐỊNH NGHĨA

**Competitive Tower Defense Auto-Battler** — kết hợp 3 thể loại:

- **Tower Defense**: Đường path cố định, quân đi từ base ra
- **Auto-Battler**: Quân tự spawn, tự di chuyển, tự combat
- **Competitive PvP (giả lập)**: Nhiều AI cùng lúc, đấu real-time trên 1 map

### Core Fantasy (cho video YouTube):
> *"Xem các đội quân tự động giao chiến, tranh giành lãnh thổ trên bản đồ chia 4 góc — không cần người chơi can thiệp."*

---

## 3. GAME LOOP CHÍNH

```
┌─────────────────────────────────────────────────┐
│                  SIMULATION LOOP                │
│                                                 │
│  [Round Start]                                  │
│       ↓                                         │
│  [Mỗi AI Player tích Resource theo thời gian]   │
│       ↓                                         │
│  [AI quyết định mua Unit type nào]              │
│       ↓                                         │
│  [Unit spawn tại base, march theo Path]         │
│       ↓                                         │
│  [Unit gặp Unit địch → Auto Combat]             │
│       ↓                                         │
│  [Unit sống sót → tiếp tục march đến base địch]│
│       ↓                                         │
│  [Gây damage cho base địch]                     │
│       ↓                                         │
│  [Round kết thúc theo timer / base bị phá]      │
│       ↓                                         │
│  [Tính điểm, reset, Round mới]                  │
└─────────────────────────────────────────────────┘
```

---

## 4. BỐ CỤC MÀN HÌNH (SIMULATION VIEW)

```
┌──────────┬────────────────────────┬──────────┐
│ PLAYER 1 │                        │ PLAYER 2 │
│  Panel   │      MAP TRUNG TÂM     │  Panel   │
│          │   (Top-down, Path)     │          │
├──────────┤                        ├──────────┤
│ PLAYER 3 │                        │ PLAYER 4 │
│  Panel   │                        │  Panel   │
└──────────┴────────────────────────┴──────────┘
```

- **Map trung tâm**: ~70% chiều rộng màn hình
- **4 Panel góc**: Hiển thị stats AI player (resource, unit count, score)
- **Timer overlay**: Góc trên trái (thời gian round hiện tại / tổng)

---

## 5. MAP & PATH DESIGN

### Cấu trúc Path:
- Map có dạng **cross/spider** — 4 nhánh path từ 4 góc hội tụ về trung tâm
- Mỗi player có **1 base** ở góc tương ứng
- Path nối **base A → trung tâm → base B** (mỗi cặp đối diện)
- Unit đi từ base mình → hướng về base đối thủ gần nhất

### Path Nodes (Waypoints):
```
Base[Player1] → WP1 → WP2 → CENTER → WP3 → WP4 → Base[Player2]
Base[Player3] → WP5 → WP6 → CENTER → WP7 → WP8 → Base[Player4]
```

### Towers dọc path:
- Có các **neutral tower** cố định dọc đường
- Tower tự động bắn vào unit đi qua trong range
- Tower có thể bị **chiếm** bởi team đã đẩy quân qua đó (optional, Phase 2)

---

## 6. PLAYERS & AI CONFIG

### Player Config (GameConfig.gd):
```gdscript
var player_count: int = 4          # 2-6
var player_colors: Array = [
    Color.RED, Color.BLUE, 
    Color.GREEN, Color.YELLOW,
    Color.CYAN, Color.PURPLE
]
var round_duration: float = 75.0   # giây
var rounds_per_session: int = 10   # số round trước khi restart
```

### AI Strategy Types:
| Strategy | Mô tả | Hành vi |
|---|---|---|
| `AGGRESSIVE` | Spam unit nhiều nhất có thể | Mua ngay khi đủ tiền, ưu tiên unit rẻ |
| `BALANCED` | Cân bằng số lượng & chất lượng | Mix nhiều loại unit |
| `ECONOMY` | Tích tiền mua unit mạnh | Chờ đủ tiền mua unit đắt |
| `ADAPTIVE` | Phản ứng theo tình hình | Đọc số unit địch để điều chỉnh |

---

## 7. RESOURCE SYSTEM

### Resource Panel (mỗi player):
- **Gold**: Tăng tự động theo thời gian (passive income)
- **Gold rate**: Config được, mặc định +5 gold/giây
- **Max gold**: 50 (thấy trong video: x/50)
- **Spend**: Trừ gold khi mua unit

### Hiển thị panel (quan sát từ video):
```
[Score/Wave Number] ← số lớn ở góc panel
[Dot Grid]          ← visualize gold pool (dots sáng = gold đang có)
[Unit1: x/max] [Unit2: x/max] [Unit3: x/max] [Unit4: x/max]
[x2 multiplier button]
```

---

## 8. UNIT SYSTEM

### Unit Types (4 loại cơ bản mỗi player):

| Slot | Tên gọi | Cost | HP | DMG | Speed | Role |
|---|---|---|---|---|---|---|
| 1 | Scout | 5 | 20 | 5 | Fast | Nhử địch |
| 2 | Soldier | 10 | 50 | 15 | Normal | DPS chính |
| 3 | Tank | 20 | 150 | 8 | Slow | Absorb damage |
| 4 | Mage | 15 | 30 | 40 | Normal | Burst damage |

### Placeholder Visual Style:
- Style chính trong giai đoạn prototype: **Jelly Blob**.
- Unit được vẽ bằng Godot primitive nodes: `Polygon2D`, `CollisionShape2D`, `Label`.
- Không dùng sprite/image asset ở giai đoạn placeholder.
- Màu unit lấy theo `player_id`; biến thể Scout/Soldier/Tank/Mage khác nhau bằng kích thước, tốc độ và label.

### Unit Behavior (Auto):
1. Spawn tại base
2. Follow path waypoints
3. Nếu gặp unit địch trong range → dừng, attack
4. Nếu unit địch chết → tiếp tục march
5. Nếu đến base địch → deal damage, despawn

### Combat:
- **Melee**: Attack khi trong range 30px
- **Ranged** (Mage): Attack khi trong range 80px
- Attack cooldown: 1.0 giây mặc định

---

## 9. TOWER SYSTEM

### Neutral Towers:
- Đặt sẵn dọc path (không phải player đặt)
- Auto-attack unit đi qua trong range 100px
- HP: 200, DMG: 20/shot, Rate: 1.5s

### Tower Placement:
- 2 towers mỗi nhánh path = 8 towers tổng (4 player map)
- Position cố định, define trong scene

---

## 10. WIN CONDITIONS & SCORING

### Round Win:
- **Timer hết**: Player nào còn nhiều unit trên đường nhất → thắng round
- **Base bị phá**: Base HP về 0 → player đó thua round

### Session Score:
- Thắng round: +3 điểm
- Unit vào được base địch: +1 điểm/unit
- Dùng để hiển thị leaderboard trên video

---

## 11. SIMULATION SETTINGS (cho YouTube)

### Auto-restart:
- Sau mỗi session (N rounds), tự động reset và chạy lại
- Không cần input người dùng
- Log kết quả ra console để track

### Speed control:
- `Engine.time_scale` config được: 1.0x, 1.5x, 2.0x
- Cho phép quay video ở tốc độ bình thường nhưng test nhanh hơn

### Camera:
- Fixed top-down, không pan/zoom
- Toàn bộ map vừa trong 1 màn hình

---

## 12. KHÔNG CẦN (do mục tiêu YouTube simulation)

- ❌ Menu chính / UI đẹp
- ❌ Sound effects / Music
- ❌ Player input / Controls
- ❌ Save/Load game
- ❌ Animations phức tạp (placeholder shapes OK)
- ❌ Networking / Multiplayer thật
- ❌ Mobile support
