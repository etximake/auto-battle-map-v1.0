# QUICK REFERENCE CARD
## Ball-Drop Auto Battle Castle Simulator - Godot 4.5

---

## CORE LOOP MOI

```text
Ball Panel
  -> Reward Slot
  -> RewardManager
  -> Castle Queue
  -> Castle Spawn
  -> AI Route Decision
  -> Unit Auto Battle
  -> Castle Damage / Score
```

Base mode khong dung neutral tower. Tower da co trong project duoc giu lai cho optional mode sau.

---

## THU TU BUILD GAN NHAT

```text
Phase 1: Map Base Reconciliation
  -> Tat/remove Towers trong GameMap base mode
  -> Giu NeutralTower.gd/.tscn cho optional mode

Phase 2: Ball Panel Prototype
  -> BallPanel, PanelBall, RewardSlot
  -> Ball roi/cham slot tao reward event

Phase 3: Castle Queue & Spawn
  -> Reward vao castle queue
  -> Castle spawn unit theo cooldown

Phase 4: AI Route Decision
  -> AI chon route/target
  -> Khong mua unit bang gold trong base mode

Phase 5: Auto Battle Loop
  -> Unit combat, castle damage, score

Phase 6: Round & UI
  -> Timer, panels, score, auto restart
```

---

## PLAYER / CASTLE POSITIONS

Resolution: `1280x720`

```text
Map area: x=192..1088, y=0..720
Center:   Vector2(640, 360)

P0 castle: Vector2(304, 134)   top-left
P1 castle: Vector2(976, 134)   top-right
P2 castle: Vector2(304, 586)   bottom-left
P3 castle: Vector2(976, 586)   bottom-right
```

Side panels:
- Left side: P0 top, P2 bottom.
- Right side: P1 top, P3 bottom.

---

## PLAYER COLORS

```text
P0 = #E74C3C red
P1 = #3498DB blue
P2 = #2ECC71 green
P3 = #F1C40F yellow
Other = #AAAAAA gray
```

---

## UNIT STATS PROTOTYPE

| Unit | HP | DMG | Speed | Range | Role |
|---|---:|---:|---:|---:|---|
| Scout | 20 | 5 | Fast | 28 | So luong, di nhanh |
| Soldier | 50 | 15 | Normal | 34 | DPS co ban |
| Tank | 150 | 8 | Slow | 32 | Chan sat thuong |
| Mage | 30 | 40 | Medium | 85 | Ranged burst |

---

## REWARD TYPES DAU TIEN

```text
Scout   -> castle queue +1 Scout
Soldier -> castle queue +1 Soldier
Tank    -> castle queue +1 Tank
Mage    -> castle queue +1 Mage
x2      -> nhan reward tiep theo hoac spawn burst
```

Prototype uu tien 4 unit reward truoc. Item/boost de phase sau.

---

## EVENTBUS SIGNALS CAN CO

```gdscript
signal reward_generated(player_id: int, reward_type: String)
signal reward_queued(player_id: int, reward_type: String)
signal castle_spawn_requested(player_id: int, unit_type: String)
signal unit_spawned(unit: Node, player_id: int)
signal unit_died(unit: Node, killer_player_id: int)
signal unit_reached_castle(unit: Node, target_castle: Node)
signal castle_damaged(castle: Node, amount: float, attacker_player: int)
signal castle_destroyed(castle: Node)
signal round_reset_requested()
```

Signals cu nhu `gold_changed` va `tower_attacked` chi dung neu bat optional/legacy mode.

---

## GROUP NAMES

```text
"units"       -> tat ca Unit dang active
"castles"     -> tat ca PlayerCastle/PlayerBase nodes
"ball_panels" -> tat ca BallPanel nodes
"reward_slots"-> reward slots trong side panels
"towers"      -> chi dung trong optional Neutral Tower mode
```

---

## COLLISION LAYERS GOI Y

```text
1 = world
2 = units
3 = unit_detection
4 = castles
5 = panel_balls
6 = reward_slots
7 = optional_towers
```

Base mode can `units`, `castles`, `panel_balls`, `reward_slots`.

---

## QUY TAC KHONG DUOC LECH

- Khong dung player input.
- Khong dung asset that trong prototype.
- Khong coi neutral tower la core gameplay.
- Khong mo rong gold-buy AI thanh base loop.
- Moi phase can co mini test de xem duoc ngay trong Godot.
- Moi file GDScript nen duoi 200 dong.
