# ASSET PRODUCTION PLAN - COMPLETE

> File này dùng để đưa vào AI khác (GPT Image 2) phân tích và tạo assets.
> Game mục tiêu quay video, không phải game hoàn chỉnh phát hành.

---

## 1. Game Overview

**Tên:** Configurable Ball-Drop Auto Battler Tower Defense Battle Simulation

**Thể loại:** Auto Battler + Tower Defense + Ball-Drop Reward

**Đối tượng:** Trẻ em 6-14 tuổi xem video game simulation

**Gameplay tóm tắt:**
- Màn hình chia 3 phần: BallPanel trái | Map giữa | BallPanel phải
- Ball rơi qua pegs, chạm RewardSlot -> spawn unit
- Unit tự chiến đấu trên map (open field, không theo đường)
- 4-6 team cùng lúc, mỗi team có castle riêng
- Unit đánh unit địch hoặc đánh castle địch
- Castle HP = 0 thì team bị loại
- Team cuối cùng sống sót thắng

**Góc nhìn:** Top-down 2D

**Resolution:** 1920x1080 (Full HD cho video)

**Engine:** Godot 4.5

---

## 2. Art Style Direction

**Style:** Cozy hand-drawn cartoon

**Tham khảo:** Kingdom Rush art style

**Đặc điểm:**
- Nét vẽ tay mềm mại, không quá sắc cạnh
- Màu sắc tươi sáng, bão hòa cao
- Thân thiện với trẻ em, không bạo lực
- Dễ phân biệt các unit type ở kích thước nhỏ

**Thiết kế unit - đơn giản hóa:**
- Body: Grayscale base, tô màu team bằng modulate → người xem phân biệt team qua màu
- Weapon: Phân biệt unit type → người xem phân biệt loại unit qua vũ khí
- ~~Hat~~: Bỏ hoàn toàn - màn hình nhỏ, trẻ 6-14 không cần chi tiết thừa

**Team Colors (6 teams):**
- Team 1: Đỏ (#E74C3C)
- Team 2: Xanh dương (#3498DB)
- Team 3: Tím (#9B59B6)
- Team 4: Vàng (#F1C40F)
- Team 5: Xanh lá (#2ECC71)
- Team 6: Cyan (#1ABC9C)

**Format output:** PNG 24-bit với alpha channel (nền trong suốt)

---

## 3. Unit Assets (8 Types)

> **Nguyên tắc đơn giản hóa:** Bỏ hat. Chỉ cần Body (màu team) + Weapon (phân biệt loại unit).
> Màn hình nhỏ, đối tượng 6-14 tuổi → màu sắc + vũ khí là đủ để nhận dạng.

Mỗi unit cần: **1 body grayscale** + **1 weapon sprite**.
Body dùng chung 1 sprite, Godot modulate màu team runtime.

### 3.1 Melee
- **Weapon:** Kiếm ngắn / dao găm
- **Kích thước unit:** 64x64px
- **Nhận dạng:** Vũ khí ngắn, cận chiến rõ ràng

### 3.2 Soldier
- **Weapon:** Kiếm + khiên nhỏ
- **Kích thước unit:** 64x64px
- **Nhận dạng:** Có khiên - khác Melee ở điểm này

### 3.3 Tank
- **Weapon:** Khiên lớn che nửa người
- **Kích thước unit:** 96x96px (to hơn rõ rệt)
- **Nhận dạng:** To + khiên lớn = dễ nhận ra nhất

### 3.4 Scout
- **Weapon:** Dao găm đôi / móng vuốt nhỏ
- **Kích thước unit:** 48x48px (nhỏ hơn rõ rệt)
- **Nhận dạng:** Nhỏ + 2 vũ khí nhỏ

### 3.5 Archer
- **Weapon:** Cung
- **Kích thước unit:** 64x64px
- **Nhận dạng:** Cung là silhouette đặc trưng nhất

### 3.6 Gunner
- **Weapon:** Súng nhỏ / pistol
- **Kích thước unit:** 64x64px
- **Nhận dạng:** Súng khác cung rõ ràng

### 3.7 Hammer
- **Weapon:** Búa chiến lớn (to hơn thân)
- **Kích thước unit:** 96x96px (to như Tank)
- **Nhận dạng:** Búa khổng lồ = không thể nhầm

### 3.8 Mage
- **Weapon:** Gậy phép có orb phát sáng
- **Kích thước unit:** 64x64px
- **Nhận dạng:** Orb sáng trên gậy = magic rõ ràng

---

## 4. Projectile & Attack FX (CODE-BASED, không cần asset)

> Đạn, tên, phép đều mô phỏng bằng Godot built-in FX - không cần sprite.

### Render bằng code:
- **Arrow (Archer):** Line2D vàng mỏng, fade out nhanh
- **Bullet (Gunner):** draw_circle nhỏ trắng/vàng, tốc độ cao
- **Magic Bolt (Mage):** draw_circle tím có glow (CanvasItem modulate)
- **Castle Projectile:** draw_circle xám, size trung bình

### Godot FX có thể dùng:
- `Line2D` - trail đạn/tên
- `CPUParticles2D` - spark khi trúng đích
- `Tween` scale + alpha - impact flash
- `draw_circle` trong `_draw()` - projectile đơn giản

### Lợi ích:
- 0 texture cần load
- Smooth ở mọi resolution
- Dễ chỉnh màu theo team/unit type
- Performance tốt hơn sprite

---

## 5. BallPanel (CODE-BASED, không cần asset)

> Tham khảo đối thủ: BallPanel render hoàn toàn bằng code, nhẹ và mượt hơn dùng sprite.

### Render bằng Godot code:
- **Panel background:** `ColorRect` với team color đậm (dùng colors từ config)
- **Pegs:** `draw_circle()` màu trắng/xám nhạt, radius 6-8px
- **Ball:** `draw_circle()` màu sáng hơn team color, radius 8-10px
- **Reward slots:** `ColorRect` nhỏ ở dưới panel + unit icon bên trong
- **x2 badge:** Label text "x2" với font bold
- **DEFEATED overlay:** Label text lớn khi team thua

### Reward Slot Icons (vẫn cần asset nhỏ)
Mỗi icon là weapon silhouette đơn giản, dùng trong reward slot:

- **Melee:** Hình kiếm ngắn
- **Soldier:** Hình khiên + kiếm
- **Tank:** Hình khiên lớn
- **Scout:** Hình dao găm đôi
- **Archer:** Hình cung
- **Gunner:** Hình súng
- **Hammer:** Hình búa
- **Mage:** Hình gậy phép
- **x2:** Text "x2" (không cần asset)

**Kích thước icon:** 24x24px
**Style:** White silhouette trên nền team color, high contrast

### Lợi ích code-based:
- Không load texture -> game nhẹ hơn
- Pegs/balls scale mượt ở mọi resolution
- Đổi team color instant qua config
- Ít file asset cần quản lý

---

## 6. Castle & Base Assets

> **4 loại castle khác nhau về hình dạng, cùng 1 style.**
> Godot modulate màu team runtime → 1 castle sprite dùng cho nhiều màu khác nhau.

### 6.1 Castle Type A - Tháp tròn
- **Hình dạng:** Tháp tròn đơn, có cửa sổ nhỏ
- **Kích thước:** 96x96px
- **Grayscale base** → modulate team color

### 6.2 Castle Type B - Pháo đài vuông
- **Hình dạng:** Tường vuông, có lỗ châu mai
- **Kích thước:** 96x96px
- **Grayscale base** → modulate team color

### 6.3 Castle Type C - Tháp nhọn
- **Hình dạng:** Tháp cao nhọn kiểu gothic
- **Kích thước:** 96x96px
- **Grayscale base** → modulate team color

### 6.4 Castle Type D - Lâu đài nhỏ
- **Hình dạng:** Lâu đài 2 tháp nhỏ hai bên
- **Kích thước:** 96x96px
- **Grayscale base** → modulate team color

### Ghi chú:
- Mỗi trận đấu chọn 1 trong 4 loại castle, hoặc mix
- Màu sắc thay đổi theo team color config
- Cờ/banner nhỏ trên đỉnh tháp có thể tô màu team

---

## 7. Map Background & Props

### 7.1 Ground Texture
- **Hình dạng:** Cỏ xanh cartoon, tileable (lặp liền mạch)
- **Kích thước:** 128x128px (tile lặp lại phủ map)
- **Màu:** Xanh lá tươi, có variation nhẹ (đốm sáng/tối)
- **Style:** Cozy hand-drawn, giống cỏ trong Kingdom Rush
- **Ghi chú:** Không quá chi tiết, unit phải nổi bật trên nền

### 7.2 Map Props (trang trí, không có collision)

> Props đặt ngẫu nhiên hoặc cố định trên map để tránh cảm giác trống rỗng.
> Không cần nhiều loại - 5-6 props đủ để map trông đa dạng.

| Props | Kích thước | Ghi chú |
|---|---|---|
| Cây lớn (tán tròn) | 64x64px | Đặt rìa map, không chặn đường |
| Cây nhỏ / bụi cây | 32x32px | Rải rác giữa map |
| Đá lớn | 48x48px | 1-2 cái giữa map |
| Đá nhỏ (cụm) | 32x32px | Rải rác |
| Hàng rào gỗ (đoạn) | 48x16px | Đặt theo hàng ngang/dọc |
| Bụi cỏ cao | 24x24px | Fill khoảng trống nhỏ |

**Style chung:** Grayscale hoặc màu cố định (không cần modulate)
**Ghi chú quan trọng:**
- Props chỉ là visual, **không có collision** với unit
- Đặt ở vùng rìa hoặc khoảng trống để không che unit đang chiến đấu
- Có thể dùng `z_index` thấp hơn unit để unit luôn hiện trên props

### 7.3 Map Border (optional)
- **Hình dạng:** Viền đá/gỗ bao quanh vùng chiến đấu
- **Kích thước:** 32px width, tileable
- **Màu:** Nâu đá / xám

---

## 8. GPT Image 2 Prompts

> **Workflow:** GPT Image tạo ảnh lớn → import Godot → scale nhỏ trong scene.
> Luôn yêu cầu transparent background + object centered.
> **Bỏ hat, bỏ projectile** - không cần asset cho 2 thứ này.

### Style Reference chung (đặt đầu mỗi prompt):
```
Cozy hand-drawn 2D game sprite, cartoon style inspired by Kingdom Rush,
bright saturated colors, clean outlines, transparent background PNG,
top-down perspective, kid-friendly, no violence, centered object
```

### 8.1 Unit Body (Grayscale - dùng chung cho tất cả 8 unit)
```
A simple chibi warrior body in grayscale only (no color), top-down view,
round head, small stocky body, cozy hand-drawn cartoon style,
no weapon, no hat, no accessories, transparent background, centered
```

### 8.2 Weapons (8 loại - tạo riêng từng cái)
```
[Melee] Short sword or dagger, simple cartoon weapon,
transparent background, centered, hand-drawn style

[Soldier] Sword with small round shield, cartoon style,
transparent background, centered

[Tank] Very large round shield, bigger than character body,
cartoon style, transparent background, centered

[Scout] Two small daggers side by side, cartoon style,
transparent background, centered

[Archer] Wooden bow, cartoon style,
transparent background, centered

[Gunner] Small cartoon pistol, simple design,
transparent background, centered

[Hammer] Oversized war hammer, head bigger than handle,
cartoon style, transparent background, centered

[Mage] Magic staff with glowing orb on top, cartoon style,
transparent background, centered
```

### 8.3 Castle Types (4 loại - grayscale để modulate màu team)
```
[Type A] Round stone tower, single tower, small windows,
grayscale only, top-down view, cartoon hand-drawn style,
transparent background, centered

[Type B] Square fortress with battlements,
grayscale only, top-down view, cartoon hand-drawn style,
transparent background, centered

[Type C] Tall pointed gothic tower,
grayscale only, top-down view, cartoon hand-drawn style,
transparent background, centered

[Type D] Small castle with two side towers,
grayscale only, top-down view, cartoon hand-drawn style,
transparent background, centered
```

### 8.4 Reward Slot Icons (8 weapon silhouettes)
```
Set of 8 minimal weapon silhouette icons, white on transparent background:
short sword, sword+shield, large shield, dual daggers,
bow, pistol, war hammer, magic staff.
Each icon simple and readable at small size, game UI style
```

### 8.5 Map Ground Texture
```
Green grass ground texture, seamless tileable pattern,
cartoon hand-drawn style inspired by Kingdom Rush,
bright green with subtle grass variation, top-down view,
128x128 pixels, game ground tile, no characters, no objects
```

### 8.6 Map Props (tạo 1 lần nhiều items)
```
Top-down view map decoration props sprite sheet, cartoon hand-drawn style,
Kingdom Rush inspired, transparent background, 6 items arranged in 2 rows:
1. Large round tree with full canopy (64x64px)
2. Small bush/shrub (32x32px)
3. Large rock/boulder (48x48px)
4. Small rock cluster (32x32px)
5. Wooden fence segment horizontal (48x16px)
6. Tall grass tuft (24x24px)
Bright colors, clean outlines, kid-friendly, no shadows needed
```

---

## 9. Production Priority & Phases

### Phase 1 - Minimum (đủ để quay video)
1. Body grayscale (1 sprite dùng chung)
2. 8 weapons (phân biệt unit type)
3. 1 Castle sprite (chọn 1 trong 4 type)
4. Ground texture (1 tile cỏ)
5. Map props (1 lần tạo 6 props cùng lúc)

**Tổng: ~16 sprites** (10 unit/castle + 1 ground + 6 props)
**BallPanel: code-based (0 sprites)**
**Projectile: code FX (0 sprites)**

### Phase 2 - Polish (video đẹp hơn)
1. 3 Castle types còn lại
2. 8 reward slot icons (weapon silhouettes)
3. Map border tile

**Tổng thêm: ~12 sprites**

### Ghi chú import Godot:
- Tất cả PNG transparent background
- Import ảnh lớn từ GPT → scale nhỏ trong scene (không cần resize thủ công)
- Body grayscale → Godot `modulate` team color runtime
- Weapon đặt làm child Sprite2D của body node
- Castle grayscale → Godot `modulate` team color runtime

---

*File version: 2.0*
*Cập nhật: Bỏ hat, projectile dùng code FX, 4 castle types grayscale*
*Mục đích: Đưa vào GPT Image 2 để tạo assets*
