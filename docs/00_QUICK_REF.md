# QUICK REFERENCE CARD
## Auto Battle TD Simulator — Godot 4.5

---

## THỨ TỰ BUILD (5 phases, đọc ROADMAP.md để chi tiết)

```
Phase 0: Setup (30 phút)
  → Tạo project, 3 autoloads (GameConfig, GameState, EventBus)

Phase 1: Core Loop (2-3 giờ)
  → GameMap + paths, Unit march + combat, 4 unit types

Phase 2: AI & Economy (2-3 giờ)
  → ResourceManager, SpawnManager (pool), AIController (4 strategies)

Phase 3: Round System (1-2 giờ)
  → RoundManager timer, PlayerBase HP, ScoreManager

Phase 4: Towers (1-2 giờ)
  → NeutralTower auto-attack, base destruction condition

Phase 5: UI + Polish (2-4 giờ)
  → HUD timer, Player panels, balancing, quay thử
```

---

## UNIT STATS NHANH

| Unit    | HP  | DMG | SPD | RNG | CD  | Cost |
|---------|-----|-----|-----|-----|-----|------|
| Scout   | 20  | 5   | 120 | 25  | 0.8 | 5    |
| Soldier | 50  | 15  | 80  | 30  | 1.0 | 10   |
| Tank    | 150 | 8   | 50  | 25  | 1.5 | 20   |
| Mage    | 30  | 40  | 70  | 80  | 2.0 | 15   |

---

## AI STRATEGY CHEATSHEET

| Strategy   | Mua gì               | Khi nào mua |
|------------|----------------------|-------------|
| AGGRESSIVE | Scout (5g)           | Ngay khi đủ |
| BALANCED   | Mix theo thời gian   | Theo phase  |
| ECONOMY    | Tank/Mage (20/15g)   | Tích đủ     |
| ADAPTIVE   | Tùy map state        | Mỗi 0.5s   |

---

## KEY CONFIGS (GameConfig.gd)

```gdscript
player_count = 4          # 2-6
round_duration = 75.0     # giây
gold_per_second = 5.0
gold_max = 50
starting_gold = 10
auto_restart = true
```

---

## BASE POSITIONS (1280×720)

```
P0 top-left:     Vector2(280, 80)
P1 top-right:    Vector2(1000, 80)
P2 bottom-left:  Vector2(280, 640)
P3 bottom-right: Vector2(1000, 640)
Center:          Vector2(640, 360)
Opponents: 0↔3, 1↔2
```

---

## COLLISION LAYERS

```
1=world  2=units  3=unit_detect  4=bases  5=towers
Unit body: Layer=2, Mask=2
Unit area: Layer=3, Mask=2
Base:      Layer=4, Mask=2
Tower:     Layer=5, Mask=2
```

---

## GROUP NAMES

```
"units"   → tất cả Unit nodes đang active
"bases"   → tất cả PlayerBase nodes
"towers"  → tất cả NeutralTower nodes
```

---

## FILE CODEX PROMPTS → xem 05_CODEX_PROMPT.md

Dán MASTER PROMPT trước, rồi từng Task Prompt theo thứ tự.
