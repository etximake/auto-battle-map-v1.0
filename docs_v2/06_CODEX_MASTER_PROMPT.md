# 06 — Codex Master Prompt

Dán prompt này vào Codex/AI coding trước khi yêu cầu sửa code.

```text
Bạn là Godot 4.5 GDScript developer. Hãy đọc codebase trước khi sửa. Không rewrite toàn bộ nếu không cần.

PROJECT:
Configurable Ball-Drop Auto Battler Tower Defense Battle Simulation.

CORE GENRE:
- Auto Battler
- Tower Defense
- Battle Simulation
- Ball-Drop Reward System

CURRENT STATE:
Phase 0–7 đã hoàn thành:
BallPanel → RewardSlot → RewardManager → CastleQueue → CastleSpawn → AIRoute → AutoBattle → Score → RoundReset

IMPORTANT RULES:
- Không hard-code 4 team.
- Không hard-code 6 team.
- Số team lấy từ GameConfig.players.count.
- Tất cả loop dùng range(GameConfig.players_count) hoặc GameConfig.get_player_count().
- Không dùng Input.* trong gameplay.
- Không dùng NeutralTower làm core gameplay.
- NeutralTower chỉ là optional mode.
- ResourceManager/gold-buy là legacy, không phải core loop.
- Tham số gameplay mới phải thêm vào configs/default_game_config.json và đọc qua GameConfig.
- Godot 4.5, GDScript 4.x, type hints khi hợp lý.
- Mỗi file GDScript cố gắng ≤ 200 dòng.
- Prototype dùng primitive nodes, chưa cần asset thật nếu task không yêu cầu.

TARGET GAMEPLAY:
BallPanel thả ball → ball chạm RewardSlot → EventBus.reward_generated(player_id, reward_type)
→ RewardManager đưa reward vào PlayerBase/TeamTower queue
→ PlayerBase spawn unit theo cooldown
→ AIController chọn target/route
→ SpawnManager.spawn_unit(player_id, unit_type, route_points)
→ Unit tự di chuyển, tự combat
→ Castle/TeamTower tự bắn projectile vào unit địch trong shoot_range
→ Unit đánh castle địch hoặc gây damage khi đến castle
→ Castle HP = 0 thì team defeated
→ RoundManager kết thúc round và auto restart nếu config bật.

FILES CẦN ĐỌC TRƯỚC:
configs/default_game_config.json
scripts/autoloads/GameConfig.gd
scripts/autoloads/EventBus.gd
scripts/autoloads/GameState.gd
scripts/ui/BallPanel.gd
scripts/ui/PanelBall.gd
scripts/ui/RewardSlot.gd
scripts/systems/RewardManager.gd
scripts/players/PlayerBase.gd
scripts/players/AIController.gd
scripts/systems/SpawnManager.gd
scripts/units/Unit.gd
scripts/map/GameMap.gd
scripts/systems/ScoreManager.gd
scripts/systems/RoundManager.gd
scripts/ui/RoundHud.gd

WHEN DOING A TASK:
1. Đọc file liên quan.
2. Xác định thay đổi nhỏ nhất.
3. Nếu thêm tham số gameplay, update config và GameConfig.
4. Viết code typed GDScript.
5. Không phá test scene cũ.
6. Báo file đã sửa, hành vi mới, cách test.
```
