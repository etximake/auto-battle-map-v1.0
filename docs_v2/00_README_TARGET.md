# 00 — Target Redesign Brief

## Project identity

Game này là:

**Configurable Ball-Drop Auto Battler Tower Defense Battle Simulation**

Không mô tả game theo số team cố định. `4 team` hoặc `6 team` chỉ là preset/layout ví dụ. Số team thật phải đọc từ config.

## Genre pillars

1. **Auto Battler**  
   Unit tự spawn, tự di chuyển, tự tìm mục tiêu và tự đánh.

2. **Tower Defense**  
   Mỗi team có tower/castle chính. Tower có HP, có vùng phòng thủ, tự bắn unit địch khi unit vào range.

3. **Battle Simulation**  
   Toàn bộ trận chạy tự động theo luật simulation. Không có điều khiển trực tiếp trong gameplay.

4. **Ball-Drop Reward System**  
   Ball rơi trong panel, va vào reward slot, tạo unit/item cho team tương ứng.

## Core loop

```text
Round Start
→ GameConfig xác định số team
→ Mỗi team có panel + tower + spawn point + AI
→ BallPanel tự thả ball
→ Ball chạm RewardSlot
→ EventBus.reward_generated(player_id, reward_type)
→ RewardManager đưa reward vào queue của tower/castle
→ Tower/Castle spawn unit theo cooldown
→ AIController chọn target/route
→ Unit đi theo route, gặp enemy thì combat
→ Tower tự bắn enemy unit trong shoot_range
→ Unit đánh tower địch / gây damage khi đến tower
→ Tower HP = 0 → team defeated
→ Round kết thúc khi còn 1 team hoặc timeout
→ Auto restart nếu config bật
```

## Hard rules

```text
Không hard-code 4 team.
Không hard-code 6 team.
Không dùng player input trong gameplay.
Không dùng NeutralTower làm core.
Không dùng ResourceManager/gold-buy làm core.
Tham số gameplay mới phải đi qua GameConfig.
Assets chuẩn làm sau khi gameplay đúng.
```

## Terminology

| Term | Meaning |
|---|---|
| Team / Player | Một phe tham gia simulation |
| BallPanel | Khu vực thả ball của một team |
| RewardSlot | Ô nhận ball và sinh reward |
| Reward | Unit/item được gửi vào queue |
| PlayerBase / Castle / TeamTower | Công trình chính của team, vừa spawn unit vừa tự bắn phòng thủ |
| NeutralTower | Tower phụ optional, không thuộc base mode |
| Unit | Quân tự động chiến đấu |
| Projectile | Đạn tower bắn ra hoặc đạn của ranged unit |
