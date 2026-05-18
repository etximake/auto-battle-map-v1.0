# 10 - Đặc Tả Hành Vi Unit Open Field

## 1. Mục Tiêu

Tài liệu này định nghĩa rõ **unit sẽ suy nghĩ, di chuyển và chiến đấu như thế nào** trước khi refactor sang `movement_mode = "open_field"`.

Điểm quan trọng: không nên chỉ làm tất cả unit dùng cùng một hành vi rồi khác nhau bằng máu/sát thương/tốc độ. Người xem cần nhận ra:

```text
Tank khác Scout.
Archer khác Melee.
Mage khác Gunner.
Hammer khác Soldier.
```

Vì vậy kiến trúc nên là:

```text
Một AI lõi chung
+ nhiều profile hành vi theo từng loại unit
```

AI lõi giống nhau để code dễ bảo trì. Nhưng profile hành vi khác nhau để gameplay dễ xem, dễ hiểu, và có bản sắc.

## 2. Nguyên Tắc Thiết Kế

Unit không nhận player input.

Unit không đi theo line/path trong `open_field`.

Unit không được đứng im vô hạn nếu vẫn còn enemy alive.

Unit không hardcode số team. Mọi danh sách team phải lấy từ:

```text
GameConfig.get_player_count()
GameMap.get_target_player_ids(player_id)
group "units"
group "castles"
```

Unit behavior nên chia thành 2 lớp:

```text
Lớp 1: AI lõi
- scan target
- chọn target
- di chuyển
- attack
- retarget
- chết / return pool

Lớp 2: Unit behavior profile
- thích đánh unit hay castle
- giữ khoảng cách hay lao vào
- đổi target nhanh hay chậm
- ưu tiên máu thấp hay gần nhất
- có tránh đông địch hay không
- có giữ đội hình với đồng đội hay không
```

## 3. AI Lõi Chung

Mọi unit đều có state machine giống nhau:

```text
SPAWNING
SEEKING
CHASING
ATTACKING
DEAD
```

### SPAWNING

Khi SpawnManager tạo unit:

```text
- Gán player_id.
- Gán unit_type.
- Gán vị trí spawn.
- Đọc chỉ số từ GameConfig.
- Reset HP, attack cooldown, current_target.
- Chuyển sang SEEKING.
```

### SEEKING

Unit tìm việc để làm:

```text
- Tìm enemy unit trong detection_range.
- Nếu không có enemy unit phù hợp, tìm enemy castle còn sống.
- Nếu vẫn không có target nhưng còn enemy alive, đi về objective fallback.
- Nếu không còn enemy alive, dừng an toàn.
```

### CHASING

Unit đã có target và di chuyển tới target:

```text
- Nếu target là unit: đi tới vị trí unit đó.
- Nếu target là castle: đi tới vị trí castle.
- Áp dụng separation nhẹ để không chồng lên đồng đội.
- Không vượt ra ngoài map_rect.
- Nếu vào attack_range thì chuyển sang ATTACKING.
```

### ATTACKING

Unit đang trong tầm đánh:

```text
- Dừng lại hoặc chỉ dịch nhẹ vì separation.
- Khi attack_timer <= 0 thì gây damage.
- Reset attack_timer = attack_cooldown.
```

Nếu target là enemy unit:

```text
target.take_damage(damage, player_id)
```

Nếu target là enemy castle:

```text
castle.take_damage(damage * castle_unit_damage_multiplier, player_id)
```

### DEAD

Khi unit chết:

```text
- is_dead = true.
- velocity = Vector2.ZERO.
- set_physics_process(false).
- Emit EventBus.unit_died.
- SpawnManager return unit về pool.
```

## 4. Vì Sao Cần Behavior Profile

Nếu tất cả unit đều làm cùng một việc:

```text
spawn -> chạy tới enemy gần nhất -> đánh -> retarget
```

thì game nhìn sẽ phẳng. Dù chỉ số khác nhau, người xem vẫn thấy các unit giống nhau.

Auto battler / battle simulation cần unit có vai trò rõ:

```text
- Tank tạo tuyến trước.
- Scout quấy rối và đổi target nhanh.
- Archer giữ khoảng cách.
- Gunner bắn nhanh nhưng mềm.
- Hammer lao vào mục tiêu cứng.
- Mage đánh mục tiêu giá trị cao.
- Soldier là quân cân bằng.
- Melee là quân áp sát cơ bản.
```

Điểm nên nhớ:

```text
Không cần viết 8 AI riêng.
Chỉ cần một AI lõi, sau đó dùng tham số để tạo 8 phong cách.
```

## 5. Đề Xuất Vai Trò Từng Unit

### Melee

Vai trò:

```text
Quân áp sát cơ bản.
```

Hành vi:

```text
- Ưu tiên enemy unit gần nhất.
- Nếu không có enemy unit thì tiến tới castle.
- Ít đổi target.
- Không giữ khoảng cách.
```

Cảm giác người xem:

```text
Đơn giản, dễ hiểu, luôn lao vào giao tranh gần nhất.
```

Phương thức tiêu diệt:

```text
- Áp sát.
- Đánh một mục tiêu.
- Damage đều, nhịp đánh trung bình.
- Không có hiệu ứng đặc biệt.
```

Gợi ý asset:

```text
- Vũ khí ngắn hoặc nắm đấm.
- Animation chém/đấm ngắn.
- Silhouette nhỏ-gọn, dễ đọc là quân cận chiến.
```

### Soldier

Vai trò:

```text
Quân cân bằng, ổn định.
```

Hành vi:

```text
- Ưu tiên enemy unit gần nhất.
- Có thể chuyển sang castle nếu đường trống.
- Retarget vừa phải.
- Đi thành nhóm tốt hơn Melee nhờ separation ổn định.
```

Cảm giác người xem:

```text
Đội hình chính, không quá nhanh, không quá mỏng.
```

Phương thức tiêu diệt:

```text
- Áp sát như Melee nhưng ổn định hơn.
- Đánh một mục tiêu.
- Damage và tốc độ đánh cân bằng.
- Có thể phối hợp tốt khi đi nhiều unit cùng lúc.
```

Gợi ý asset:

```text
- Khiên nhỏ, kiếm/ngọn giáo ngắn, hoặc giáp nhẹ.
- Animation gọn, chắc, không quá hoang dã.
- Nhìn như quân chủ lực phổ thông.
```

### Tank

Vai trò:

```text
Tuyến trước, hút sát thương.
```

Hành vi:

```text
- Ưu tiên target gần nhất phía trước.
- Không đổi target quá thường xuyên.
- Chấp nhận đi thẳng vào vùng đông địch.
- Có thể ưu tiên castle nếu không bị unit chặn.
- Separation thấp hơn để tank đứng chắn đường.
```

Cảm giác người xem:

```text
Chậm, lì, tạo điểm va chạm lớn trên chiến trường.
```

Phương thức tiêu diệt:

```text
- Không phải nguồn kill chính.
- Giết đối thủ bằng damage chậm nhưng bền.
- Giữ chân enemy để đồng đội phía sau gây damage.
- Có thể đánh castle nếu không bị chặn.
```

Gợi ý asset:

```text
- Thân to, giáp dày, khiên lớn.
- Animation đánh chậm, nặng.
- Hit reaction ít, tạo cảm giác khó bị đẩy lùi.
```

### Scout

Vai trò:

```text
Quân nhanh, quấy rối, bắt mục tiêu yếu.
```

Hành vi:

```text
- Detection_range cao hơn.
- Retarget nhanh hơn.
- Ưu tiên enemy unit máu thấp.
- Nếu không có unit yếu thì chạy tới castle gần nhất.
- Có thể né vùng quá đông enemy nếu thêm logic sau.
```

Cảm giác người xem:

```text
Nhanh, hay đổi hướng, tạo cảm giác thông minh và khó đoán.
```

Phương thức tiêu diệt:

```text
- Lao nhanh vào mục tiêu yếu.
- Ưu tiên enemy unit máu thấp.
- Đánh nhanh, damage mỗi hit thấp hoặc trung bình.
- Đổi target nhanh để kết liễu nhiều mục tiêu.
```

Gợi ý asset:

```text
- Nhỏ, nhẹ, dáng chạy nhanh.
- Dao găm, móng vuốt, hoặc vũ khí ngắn.
- Animation dash/chém nhanh để người xem nhận ra tốc độ.
```

### Archer

Vai trò:

```text
Đánh xa ổn định.
```

Hành vi:

```text
- Ưu tiên giữ khoảng cách với target.
- Không cần lao sát vào enemy.
- Nếu enemy tiến lại quá gần, có thể lùi nhẹ nếu thêm kiting sau.
- Ưu tiên enemy unit trong tầm bắn.
- Chỉ đánh castle khi không có enemy unit gần.
```

Cảm giác người xem:

```text
Đứng sau tuyến trước và bắn đều.
```

Phương thức tiêu diệt:

```text
- Bắn xa từng phát.
- Giữ khoảng cách thay vì lao sát.
- Ưu tiên enemy unit trong tầm bắn.
- Damage mỗi phát rõ ràng, cooldown trung bình.
```

Gợi ý asset:

```text
- Cung/nỏ hoặc projectile mũi tên.
- Animation kéo dây/bắn rõ.
- Nên có projectile nhìn thấy để phân biệt với Gunner/Mage.
```

### Gunner

Vai trò:

```text
DPS nhanh, mềm, bắn liên tục.
```

Hành vi:

```text
- Ưu tiên target gần nhất trong range.
- Retarget nhanh hơn Archer.
- Cooldown thấp.
- Không nên lao quá sâu nếu có target trong range.
- Có thể focus unit máu thấp để tạo kill nhanh.
```

Cảm giác người xem:

```text
Bắn nhanh, đổi mục tiêu nhanh, tạo nhiều event damage.
```

Phương thức tiêu diệt:

```text
- Bắn nhanh nhiều phát nhỏ.
- Hạ mục tiêu bằng DPS liên tục.
- Retarget nhanh sang mục tiêu gần chết.
- Mềm hơn Soldier/Tank nên không đứng tuyến đầu.
```

Gợi ý asset:

```text
- Súng nhỏ, nòng sáng, hoặc hiệu ứng đạn nhanh.
- Animation giật nhẹ/liên thanh.
- Projectile nhỏ, nhanh, nhiều hơn Archer.
```

### Hammer

Vai trò:

```text
Quân phá tuyến, đánh chậm nhưng đau.
```

Hành vi:

```text
- Ưu tiên target có HP cao hoặc castle.
- Ít bị phân tâm bởi unit máu thấp.
- Retarget chậm.
- Đi thẳng vào mục tiêu cứng.
- Attack cooldown dài nhưng damage cao.
```

Cảm giác người xem:

```text
Mỗi cú đánh có trọng lượng, chuyên phá Tank/castle.
```

Phương thức tiêu diệt:

```text
- Đánh chậm nhưng damage rất cao.
- Ưu tiên unit HP cao, Tank, hoặc castle.
- Ít bị phân tâm bởi mục tiêu yếu.
- Mỗi cú đánh nên tạo cảm giác phá tuyến.
```

Gợi ý asset:

```text
- Búa lớn, chùy, hoặc vũ khí nặng.
- Animation vung chậm, impact rõ.
- Có thể thêm hiệu ứng rung/flash nhỏ khi đánh trúng.
```

### Mage

Vai trò:

```text
Quân sát thương cao, chọn mục tiêu giá trị.
```

Hành vi:

```text
- Ưu tiên enemy unit máu thấp hoặc target nguy hiểm.
- Retarget vừa phải.
- Tầm đánh xa.
- Không nên đứng tuyến đầu.
- Có thể ưu tiên nhóm đông nếu sau này có splash/AOE.
```

Cảm giác người xem:

```text
Mỏng nhưng nguy hiểm, tạo khoảnh khắc burst damage.
```

Phương thức tiêu diệt:

```text
- Bắn phép damage cao.
- Ưu tiên mục tiêu giá trị hoặc máu thấp.
- Cooldown dài hơn Gunner/Archer.
- Phase sau có thể thêm splash/AOE, nhưng phase đầu nên dùng magic bolt đơn mục tiêu.
```

Gợi ý asset:

```text
- Gậy phép, orb, hoặc hiệu ứng tay phát sáng.
- Projectile phép khác màu với đạn/mũi tên.
- Animation cast có thời gian chuẩn bị ngắn để tạo cảm giác burst.
```

## 6. Bảng Tóm Tắt Phương Thức Tiêu Diệt

| Unit | Phương thức chính | Target ưu tiên | Nhịp đánh | Dấu hiệu hình ảnh nên có |
|---|---|---|---|---|
| Melee | Áp sát đánh đơn mục tiêu | Unit gần nhất | Trung bình | Vũ khí ngắn, chém/đấm gần |
| Soldier | Áp sát ổn định theo nhóm | Unit gần nhất | Trung bình | Giáp nhẹ, khiên/kiếm |
| Tank | Giữ chân, damage chậm | Mục tiêu phía trước | Chậm | Thân to, khiên lớn |
| Scout | Kết liễu mục tiêu yếu | Unit máu thấp | Nhanh | Dáng nhỏ, dash/chém nhanh |
| Archer | Bắn xa từng phát | Unit trong tầm | Trung bình | Cung/nỏ, mũi tên |
| Gunner | DPS nhanh nhiều phát | Unit gần chết/gần nhất | Rất nhanh | Súng/đạn nhỏ liên tục |
| Hammer | Cú đánh nặng phá tuyến | Tank/castle/HP cao | Chậm | Búa lớn, impact mạnh |
| Mage | Burst phép đơn mục tiêu | Unit giá trị/máu thấp | Chậm-vừa | Projectile phép, cast effect |

## 7. Attack Style Đề Xuất Cho Config

Nên tách `attack_style` khỏi `role`.

```text
role:
- mô tả vai trò chiến thuật của unit.

attack_style:
- mô tả cách unit gây damage.
```

Các `attack_style` tối thiểu:

```text
melee_hit
steady_slash
heavy_body_hit
quick_stab
arrow_shot
rapid_fire
heavy_slam
magic_bolt
```

Mapping đề xuất:

```text
Melee  -> melee_hit
Soldier -> steady_slash
Tank -> heavy_body_hit
Scout -> quick_stab
Archer -> arrow_shot
Gunner -> rapid_fire
Hammer -> heavy_slam
Mage -> magic_bolt
```

Phase đầu có thể để tất cả attack style dùng cùng hàm damage đơn mục tiêu. Khác biệt trước mắt đến từ:

```text
- range
- cooldown
- damage
- target_priority
- retarget_interval
- hold_distance
- projectile visual nếu là ranged
```

Phase sau mới cần mở rộng:

```text
- Mage splash/AOE.
- Hammer cleave hoặc knockback.
- Scout dash strike.
- Tank taunt/body block.
- Archer/Gunner projectile pooling riêng.
```

## 8. Behavior Profile Nên Đưa Vào Config

Hiện config unit mới có chỉ số:

```text
hp
damage
speed
range
cooldown
visual_radius
collision_radius
```

Nên thêm behavior profile theo từng unit:

```json
"Melee": {
  "hp": 45,
  "damage": 14,
  "speed": 145,
  "range": 32,
  "cooldown": 0.95,
  "role": "melee_basic",
  "attack_style": "melee_hit",
  "target_priority": "nearest_unit",
  "prefer_units_over_castle": true,
  "retarget_interval": 0.45,
  "hold_distance": 0.0
}
```

Các field đề xuất:

```text
role
attack_style
target_priority
prefer_units_over_castle
detection_range
chase_range
retarget_interval
hold_distance
separation_radius
separation_strength
castle_aggression
low_hp_focus
frontline_bias
```

Không bắt buộc thêm toàn bộ ngay. Phase đầu chỉ cần vài field quan trọng:

```text
role
attack_style
target_priority
detection_range
chase_range
retarget_interval
hold_distance
```

## 9. Target Priority Dễ Hiểu

Nên dùng tên rõ nghĩa:

```text
nearest_unit
lowest_hp_unit
nearest_castle
objective_castle
toughest_unit
any_nearest_enemy
```

Ý nghĩa:

```text
nearest_unit:
- Đánh enemy unit gần nhất.

lowest_hp_unit:
- Ưu tiên kết liễu enemy unit máu thấp.

nearest_castle:
- Nếu không bị chặn, tiến tới castle gần nhất.

objective_castle:
- Đi theo objective_player_id do AIController chọn.

toughest_unit:
- Ưu tiên unit HP cao, hợp với Hammer.

any_nearest_enemy:
- Enemy unit hoặc castle, cái nào gần hơn thì đánh.
```

## 10. Giữ Khoảng Cách

Không phải unit nào cũng nên lao vào sát target.

Field:

```text
hold_distance
```

Ý nghĩa:

```text
Melee/Tank/Hammer:
- hold_distance = 0
- Lao tới attack_range.

Archer/Gunner/Mage:
- hold_distance > 0
- Dừng ở khoảng cách bắn hợp lý.
```

Ví dụ:

```text
Archer range = 95
hold_distance = 75

Archer sẽ cố giữ khoảng cách quanh 75-95 thay vì lao sát vào enemy.
```

Phase đầu có thể làm đơn giản:

```text
Nếu distance <= attack_range thì đứng bắn.
```

Kiting/lùi lại có thể để phase sau.

## 11. Retarget Khác Nhau Theo Vai Trò

Không phải unit nào cũng đổi mục tiêu giống nhau.

```text
Tank:
- retarget chậm
- bám mục tiêu lâu

Scout:
- retarget nhanh
- dễ đổi sang mục tiêu yếu hơn

Gunner:
- retarget nhanh
- focus mục tiêu dễ giết

Hammer:
- retarget chậm
- không bị phân tâm bởi unit yếu

Mage:
- retarget vừa phải
- ưu tiên mục tiêu giá trị
```

Điều này giúp người xem cảm thấy unit có cá tính mà không cần AI quá phức tạp.

## 12. Castle Attack

Trong `open_field`, unit đánh castle như một target thật:

```text
Unit tiến tới enemy castle
-> vào attack_range
-> đánh theo cooldown
-> castle.take_damage(...)
```

Unit không biến mất sau khi đánh castle.

`unit_reached_castle` chỉ dùng cho `lane_path` legacy.

## 13. Tránh Unit Đứng Im

Unit phải luôn có fallback:

```text
1. Có enemy unit phù hợp -> đánh unit.
2. Không có enemy unit -> đi tới enemy castle.
3. Castle objective chết -> chọn castle khác.
4. Không tìm được castle nhưng còn enemy alive -> đi về center/map objective.
5. Không còn enemy alive -> dừng.
```

Nếu bị kẹt:

```text
- Retarget.
- Tăng separation tạm thời.
- Đi về fallback objective.
```

Phase đầu có thể chưa cần stuck detector riêng nếu retarget và fallback hoạt động tốt.

## 14. Legacy Lane Path

Khi `movement_mode = "lane_path"`:

```text
- Unit dùng path_points.
- Unit đi waypoint.
- Gặp enemy trong range thì dừng đánh.
- Enemy chết hoặc rời range thì đi tiếp path.
- Hết path thì emit unit_reached_castle.
```

Không trộn open-field chase logic vào lane_path nếu chưa cần.

## 15. Phase Triển Khai Unit

Phần này chỉ nói về triển khai Unit. Các hệ thống khác như BallPanel, RewardManager, RoundManager không nằm trong phạm vi phase này, trừ khi cần kết nối tối thiểu.

Mục tiêu là làm từng bước nhỏ để luôn kiểm tra được:

```text
Unit spawn được.
Unit không đứng im.
Unit chọn target đúng.
Unit đánh đúng.
Unit khác nhau rõ theo vai trò.
```

### Unit Phase 0 - Khóa Behavior Contract

Trạng thái:

```text
DONE - Behavior contract đã được mô tả trong tài liệu này.
```

Mục tiêu:

```text
Chốt rõ hành vi trước khi sửa Unit.gd.
```

Việc cần làm:

```text
- Chốt state machine: SPAWNING, SEEKING, CHASING, ATTACKING, DEAD.
- Chốt 8 vai trò unit.
- Chốt phương thức tiêu diệt của từng unit.
- Chốt attack_style tối thiểu.
- Chốt target_priority tối thiểu.
```

Kết quả cần đạt:

```text
Developer đọc spec là biết Unit.gd cần làm gì.
Không bắt đầu code khi hành vi còn mơ hồ.
```

### Unit Phase 1 - Thêm Config Behavior Profile

Trạng thái:

```text
DONE - default_game_config.json và GameConfig.gd đã có behavior profile.
```

Mục tiêu:

```text
Mỗi unit có profile hành vi riêng trong config.
```

File chính:

```text
configs/default_game_config.json
scripts/autoloads/GameConfig.gd
docs_v2/04_CONFIG_SCHEMA.md
```

Việc cần làm:

```text
- Thêm role.
- Thêm attack_style.
- Thêm target_priority.
- Thêm detection_range.
- Thêm chase_range.
- Thêm retarget_interval.
- Thêm hold_distance.
- Thêm separation_radius/separation_strength nếu cần override theo unit.
```

Kết quả cần đạt:

```text
GameConfig đọc được behavior profile cho từng unit.
Nếu field thiếu thì dùng default an toàn.
Không hardcode behavior theo unit_type trực tiếp trong Unit.gd nếu có thể tránh.
```

### Unit Phase 2 - Tách Setup Open Field Khỏi Lane Path

Trạng thái:

```text
DONE - Unit.gd có setup_open_field(), SpawnManager branch theo movement_mode.
```

Mục tiêu:

```text
Unit có thể spawn mà không cần path_points.
```

File chính:

```text
scripts/units/Unit.gd
scripts/systems/SpawnManager.gd
```

Việc cần làm:

```text
- Giữ setup_unit(player_id, unit_type, path_points) cho lane_path.
- Thêm setup_open_field(player_id, unit_type, spawn_position, objective_player_id = -1).
- Reset current_target, attack_timer, retarget_timer, state.
- Không gọi _reach_base() khi không có path trong open_field.
```

Kết quả cần đạt:

```text
Unit xuất hiện tại spawn_position.
Unit không biến mất ngay khi path rỗng.
Lane_path legacy vẫn chạy như cũ.
```

### Unit Phase 3 - Target Scan Cơ Bản

Trạng thái:

```text
DONE - Unit.gd đã có target scan cho enemy unit và enemy castle.
```

Mục tiêu:

```text
Unit biết tìm enemy unit hoặc enemy castle.
```

File chính:

```text
scripts/units/Unit.gd
```

Việc cần làm:

```text
- Thêm _find_enemy_unit_target().
- Thêm _find_enemy_castle_target().
- Thêm _is_valid_enemy_unit().
- Thêm _is_valid_enemy_castle().
- Thêm _select_target_by_priority().
```

Target priority tối thiểu:

```text
nearest_unit
lowest_hp_unit
nearest_castle
objective_castle
toughest_unit
any_nearest_enemy
```

Kết quả cần đạt:

```text
Unit không chọn đồng đội.
Unit không chọn castle cùng team.
Unit bỏ qua unit đã chết.
Unit bỏ qua castle đã destroyed.
```

### Unit Phase 4 - Movement Open Field

Trạng thái:

```text
DONE - Unit.gd đã có _process_open_field(), chase target, hold_distance, separation và bounds force cơ bản.
```

Mục tiêu:

```text
Unit di chuyển tới target trên map mở.
```

File chính:

```text
scripts/units/Unit.gd
scripts/map/GameMap.gd
```

Việc cần làm:

```text
- Thêm _process_open_field(delta).
- Thêm _move_toward_target(delta).
- Dùng move_speed từ config.
- Dùng hold_distance cho ranged unit.
- Dùng GameMap.get_map_rect() để tránh ra khỏi map.
- Thêm separation cơ bản với unit cùng team.
```

Kết quả cần đạt:

```text
Melee/Tank/Hammer lao vào gần.
Archer/Gunner/Mage không cần lao sát nếu đã trong range.
Scout di chuyển nhanh và đổi hướng rõ hơn.
Unit không đứng im khi còn enemy alive.
```

### Unit Phase 5 - Attack Một Mục Tiêu

Trạng thái:

```text
DONE - Unit có thể damage enemy Unit hoặc PlayerBase/Castle trực tiếp trong open_field.
```

Mục tiêu:

```text
Tất cả unit có thể gây damage bằng attack_style riêng, nhưng dùng damage đơn mục tiêu trước.
```

File chính:

```text
scripts/units/Unit.gd
scripts/players/PlayerBase.gd
```

Việc cần làm:

```text
- Thêm _attack_current_target().
- Nếu target là Unit: target.take_damage(damage, player_id).
- Nếu target là Castle: castle.take_damage(damage * castle_unit_damage_multiplier, player_id).
- Tôn trọng attack_cooldown.
- Tôn trọng attack_range.
```

Kết quả cần đạt:

```text
Unit giết được enemy unit.
Unit damage được castle.
Castle damage không cần unit_reached_castle trong open_field.
ScoreManager vẫn nhận castle_damaged qua PlayerBase.take_damage().
```

### Unit Phase 6 - Retarget Và Anti-Stuck Cơ Bản

Trạng thái:

```text
DONE - Retarget theo interval, target invalid, target chết, castle destroyed, chase_range.
```

Mục tiêu:

```text
Unit không bị kẹt vào target chết hoặc target không hợp lệ.
```

File chính:

```text
scripts/units/Unit.gd
```

Việc cần làm:

```text
- Retarget khi target null.
- Retarget khi target chết.
- Retarget khi castle destroyed.
- Retarget khi target ra khỏi chase_range.
- Retarget theo retarget_interval.
- Nếu không có unit target thì fallback sang castle target.
- Nếu objective castle destroyed thì chọn castle khác.
```

Kết quả cần đạt:

```text
Target chết giữa đường -> unit chọn target mới.
Castle bị phá -> unit đổi sang castle/team khác.
Không có enemy unit -> unit tiến tới castle.
Không còn enemy alive -> unit dừng an toàn.
```

### Unit Phase 7 - Làm Rõ Khác Biệt 8 Unit

Trạng thái:

```text
DONE - Behavior profile đã được Unit.gd đọc và dùng đầy đủ. Test scene TestUnit8Roles.tscn verify 8 unit types có behavior khác biệt rõ ràng theo role, attack_style, target_priority, retarget_interval, hold_distance.
```

Mục tiêu:

```text
Người xem nhìn battle có thể nhận ra unit nào đang làm vai trò gì.
```

Việc cần làm:

```text
- Melee: nearest_unit, áp sát cơ bản.
- Soldier: nearest_unit, ổn định, đi nhóm tốt.
- Tank: retarget chậm, HP cao, tuyến trước.
- Scout: lowest_hp_unit, retarget nhanh, speed cao.
- Archer: arrow_shot, hold_distance cao.
- Gunner: rapid_fire, cooldown thấp, retarget nhanh.
- Hammer: toughest_unit/objective_castle, damage cao, cooldown dài.
- Mage: magic_bolt, damage cao, ưu tiên mục tiêu giá trị hoặc máu thấp.
```

Kết quả cần đạt:

```text
Không chỉ khác chỉ số.
Khác cả nhịp đánh, khoảng cách, target ưu tiên, và cách tham gia giao tranh.
```

### Unit Phase 8 - Visual/Asset Hooks

Trạng thái:

```text
DONE - Unit.gd đã emit unit_attack_performed và tạo placeholder feedback theo attack_style.
```

Mục tiêu:

```text
Chuẩn bị điểm móc cho asset/animation sau này, chưa cần thay asset thật.
```

File chính:

```text
scripts/units/Unit.gd
scenes/units/*.tscn
```

Việc cần làm:

```text
- Expose attack_style để visual layer đọc được.
- Có chỗ emit hoặc gọi visual feedback khi attack.
- Phân biệt ranged attack và melee attack ở mức signal/data.
- Chưa cần làm sprite hoàn chỉnh.
```

Kết quả cần đạt:

```text
Sau này thiết kế asset biết Melee/Hammer/Tank/Mage/Gunner cần animation khác nhau.
Không phải sửa lại logic combat lớn khi thay visual.
```

Đã triển khai hiện tại:

```text
- EventBus.unit_attack_performed(unit, target, attack_style).
- melee_hit / steady_slash: impact placeholder.
- heavy_slam / heavy_body_hit: impact lớn hơn, cảm giác nặng hơn.
- quick_stab: slash line + impact ngắn.
- arrow_shot: line projectile placeholder màu vàng.
- rapid_fire: line projectile nhỏ, rất nhanh.
- magic_bolt: line projectile tím, dày hơn.
```

### Unit Phase 9 - Test Riêng Cho Unit

Trạng thái:

```text
DONE - Đã tạo 5 test scenes riêng cho unit behavior:
- TestUnitOpenFieldSpawn.tscn: Test spawn open_field không path
- TestUnitTargetEnemy.tscn: Test chọn và đánh enemy unit
- TestUnitCastleAttack.tscn: Test đánh castle khi không có enemy unit
- TestUnitRetargetOnDeath.tscn: Test retarget khi target chết
- TestUnitRoleProfiles.tscn: Test khác biệt Scout/Tank/Archer behavior
```

Mục tiêu:

```text
Xác nhận Unit behavior chạy đúng trước khi nối vào toàn bộ game loop.
```

Test đề xuất:

```text
TestUnitOpenFieldSpawn:
- Spawn unit không path_points.
- Unit không biến mất.

TestUnitTargetEnemy:
- 2 unit khác team gần nhau.
- Unit chọn và đánh enemy.

TestUnitCastleAttack:
- Không có enemy unit.
- Unit đi tới castle và gây damage.

TestUnitRetargetOnDeath:
- Target chết.
- Unit chọn target mới.

TestUnitRetargetOnCastleDestroyed:
- Castle target destroyed.
- Unit chọn castle khác hoặc dừng nếu không còn enemy.

TestUnitRoleProfiles:
- Scout retarget nhanh hơn Tank.
- Archer giữ khoảng cách hơn Melee.
- Hammer ưu tiên target cứng hơn Scout.
```

Kết quả cần đạt:

```text
Unit behavior ổn trước khi test full battle loop.
Bug nằm ở Unit thì phát hiện sớm, không lẫn với BallPanel/Reward/Round.
```

## 16. Kết Luận Thiết Kế

Khuyến nghị của developer:

```text
Không nên làm mỗi unit một AI script riêng ngay.
Nên làm một Unit.gd có AI lõi chung.
Mỗi unit lấy behavior profile từ config.
```

Cách này có lợi:

```text
- Dễ cân bằng.
- Dễ thêm unit mới.
- Dễ test.
- Người xem vẫn nhận ra khác biệt hành vi.
- Không làm project phình quá sớm.
```

Thứ tự nên làm:

```text
1. Làm AI lõi open-field chạy ổn.
2. Thêm behavior profile tối thiểu cho từng unit.
3. Tinh chỉnh từng unit để nhìn khác nhau rõ.
4. Sau đó mới thêm logic nâng cao như kiting, splash, formation, obstacle avoidance.
```
