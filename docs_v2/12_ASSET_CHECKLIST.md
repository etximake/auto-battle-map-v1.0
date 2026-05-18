# 12 - Asset Production Checklist

## Tổng Quan

Tài liệu này liệt kê tất cả assets cần tạo cho **Configurable Ball-Drop Auto Battler Tower Defense Battle Simulation**, được tối ưu hóa cho đối tượng **6-14 tuổi**.

**Mục tiêu:** Tạo visuals rõ ràng, dễ phân biệt, và hấp dẫn cho trẻ em mà không làm mất đi tính chiến thuật của gameplay.

## Art Direction Guidelines

### Style Recommendations

**Recommended Style:** **Cartoon/Stylized 2D**

**Lý do:**
- ✅ Phù hợp với độ tuổi 6-14
- ✅ Dễ phân biệt unit types
- ✅ Không cần animation phức tạp
- ✅ Dễ scale và maintain

**Color Palette:**
- **Bright & Saturated:** Dễ nhìn, thu hút trẻ em
- **High Contrast:** Dễ phân biệt trên background
- **Team Colors:** Sử dụng màu từ config (Red, Blue, Purple, Yellow, Green, Cyan)

**Technical Specs:**
- **Resolution:** 64x64 đến 128x128 pixels per unit
- **Format:** PNG với alpha channel
- **Frame Rate:** 8-12 FPS cho animations (không cần 60fps)
- **Color Depth:** 32-bit RGBA

### Visual Hierarchy

**Priority 1 - Critical (Must Have):**
- Unit sprites với silhouette rõ ràng
- Attack effects cơ bản
- Team color indicators

**Priority 2 - Important (Should Have):**
- Idle animations
- Attack animations
- UI icons

**Priority 3 - Nice to Have (Could Have):**
- Death animations
- Particle effects phức tạp
- Background details

---

## 📋 Asset Checklist

### 1. Unit Sprites (8 Types)

Mỗi unit cần có silhouette và visual identity rõ ràng theo role.

#### 1.1 Melee

**Role:** Quân áp sát cơ bản

**Visual Identity:**
- [ ] **Silhouette:** Nhỏ-gọn, cân đối
- [ ] **Weapon:** Kiếm ngắn hoặc dao găm
- [ ] **Size:** Medium (64x64px base)
- [ ] **Color Accent:** Xám/bạc (weapon)

**Sprites Needed:**
- [ ] Idle (1-2 frames)
- [ ] Walk/Run (2-4 frames)
- [ ] Attack (2-3 frames)
- [ ] Death (1-2 frames, optional)

**Animation Notes:**
- Attack: Chém nhanh, arc motion
- Movement: Tốc độ trung bình

---

#### 1.2 Soldier

**Role:** Quân cân bằng, ổn định

**Visual Identity:**
- [ ] **Silhouette:** Vuông vức, có khiên nhỏ
- [ ] **Weapon:** Kiếm + khiên hoặc giáo ngắn
- [ ] **Size:** Medium (64x64px base)
- [ ] **Color Accent:** Xanh dương/thép (armor)

**Sprites Needed:**
- [ ] Idle (1-2 frames)
- [ ] Walk/Run (2-4 frames)
- [ ] Attack (2-3 frames)
- [ ] Death (1-2 frames, optional)

**Animation Notes:**
- Attack: Đâm thẳng hoặc chém ổn định
- Movement: Đều đặn, có cảm giác đội hình

---

#### 1.3 Tank

**Role:** Tuyến trước, hút sát thương

**Visual Identity:**
- [ ] **Silhouette:** To lớn, rộng, khiên lớn
- [ ] **Weapon:** Khiên lớn + vũ khí nặng
- [ ] **Size:** Large (96x96px base)
- [ ] **Color Accent:** Nâu/đồng (heavy armor)

**Sprites Needed:**
- [ ] Idle (1-2 frames)
- [ ] Walk/Run (2-4 frames)
- [ ] Attack (2-3 frames)
- [ ] Death (1-2 frames, optional)

**Animation Notes:**
- Attack: Đánh chậm, nặng nề
- Movement: Chậm, có cảm giác trọng lượng
- Idle: Ít động, vững chãi

---

#### 1.4 Scout

**Role:** Quân nhanh, quấy rối

**Visual Identity:**
- [ ] **Silhouette:** Nhỏ, mảnh, năng động
- [ ] **Weapon:** Dao găm đôi hoặc móng vuốt
- [ ] **Size:** Small (48x48px base)
- [ ] **Color Accent:** Xanh lá/đen (stealth)

**Sprites Needed:**
- [ ] Idle (1-2 frames)
- [ ] Walk/Run (3-4 frames, nhanh)
- [ ] Attack (2-3 frames, nhanh)
- [ ] Dash effect (optional)
- [ ] Death (1-2 frames, optional)

**Animation Notes:**
- Attack: Chém nhanh liên tục
- Movement: Rất nhanh, có thể có blur effect
- Idle: Động nhiều, không đứng yên

---

#### 1.5 Archer

**Role:** Đánh xa ổn định

**Visual Identity:**
- [ ] **Silhouette:** Cao, mảnh, có cung
- [ ] **Weapon:** Cung hoặc nỏ
- [ ] **Size:** Medium (64x64px base)
- [ ] **Color Accent:** Xanh lá/nâu (wood)

**Sprites Needed:**
- [ ] Idle (1-2 frames)
- [ ] Walk/Run (2-4 frames)
- [ ] Attack - Draw bow (2-3 frames)
- [ ] Attack - Release (1 frame)
- [ ] Death (1-2 frames, optional)

**Projectile:**
- [ ] Arrow sprite (16x4px)
- [ ] Arrow trail effect (optional)

**Animation Notes:**
- Attack: Kéo cung → bắn → recoil
- Movement: Tốc độ trung bình
- Projectile: Visible arrow flying

---

#### 1.6 Gunner

**Role:** DPS nhanh, bắn liên tục

**Visual Identity:**
- [ ] **Silhouette:** Nhỏ gọn, có súng
- [ ] **Weapon:** Súng nhỏ/pistol
- [ ] **Size:** Medium (64x64px base)
- [ ] **Color Accent:** Xám/đen (metal)

**Sprites Needed:**
- [ ] Idle (1-2 frames)
- [ ] Walk/Run (2-4 frames)
- [ ] Attack - Shoot (2 frames, rapid)
- [ ] Muzzle flash (1 frame)
- [ ] Death (1-2 frames, optional)

**Projectile:**
- [ ] Bullet sprite (8x2px, small)
- [ ] Muzzle flash effect

**Animation Notes:**
- Attack: Bắn nhanh, giật nhẹ
- Movement: Nhanh, linh hoạt
- Projectile: Rất nhanh, nhỏ

---

#### 1.7 Hammer

**Role:** Phá tuyến, đánh chậm nhưng đau

**Visual Identity:**
- [ ] **Silhouette:** To, rộng vai, búa lớn
- [ ] **Weapon:** Búa chiến hoặc chùy
- [ ] **Size:** Large (96x96px base)
- [ ] **Color Accent:** Đỏ/cam (power)

**Sprites Needed:**
- [ ] Idle (1-2 frames)
- [ ] Walk/Run (2-4 frames)
- [ ] Attack - Windup (1-2 frames)
- [ ] Attack - Slam (1 frame)
- [ ] Attack - Recovery (1 frame)
- [ ] Death (1-2 frames, optional)

**Animation Notes:**
- Attack: Vung chậm → slam mạnh → recovery
- Movement: Chậm nhưng có momentum
- Impact: Cần effect rung/shockwave

---

#### 1.8 Mage

**Role:** Sát thương cao, burst damage

**Visual Identity:**
- [ ] **Silhouette:** Mảnh, có gậy phép/orb
- [ ] **Weapon:** Staff hoặc wand
- [ ] **Size:** Medium (64x64px base)
- [ ] **Color Accent:** Tím/xanh dương (magic)

**Sprites Needed:**
- [ ] Idle (1-2 frames, có glow effect)
- [ ] Walk/Run (2-4 frames)
- [ ] Attack - Cast (2-3 frames)
- [ ] Attack - Release (1 frame)
- [ ] Death (1-2 frames, optional)

**Projectile:**
- [ ] Magic bolt sprite (24x24px)
- [ ] Magic trail effect
- [ ] Cast glow effect

**Animation Notes:**
- Attack: Cast animation → projectile release
- Movement: Float/hover effect (optional)
- Projectile: Glowing, có trail

---

### 2. Attack Effects

Mỗi attack_style cần visual feedback rõ ràng.

#### 2.1 Melee Hit (melee_hit)

- [ ] Impact flash (16x16px, 2-3 frames)
- [ ] Slash line effect (optional)
- [ ] Hit spark particles (4-6 particles)

**Color:** Trắng/vàng nhạt

---

#### 2.2 Steady Slash (steady_slash)

- [ ] Slash arc sprite (32x32px)
- [ ] Impact flash (16x16px)
- [ ] Metal clang effect (optional)

**Color:** Xám/bạc

---

#### 2.3 Heavy Body Hit (heavy_body_hit)

- [ ] Large impact (32x32px, 3-4 frames)
- [ ] Shockwave ring (expanding circle)
- [ ] Dust particles (6-8 particles)

**Color:** Cam/nâu

---

#### 2.4 Quick Stab (quick_stab)

- [ ] Fast slash line (thin, 24x4px)
- [ ] Small impact (12x12px, 1-2 frames)
- [ ] Speed lines (optional)

**Color:** Xanh lá/trắng

---

#### 2.5 Arrow Shot (arrow_shot)

- [ ] Arrow projectile (16x4px)
- [ ] Arrow trail (line, fading)
- [ ] Hit impact (16x16px)
- [ ] Feather particles on hit (optional)

**Color:** Vàng/nâu

---

#### 2.6 Rapid Fire (rapid_fire)

- [ ] Bullet projectile (8x2px)
- [ ] Muzzle flash (12x12px, 1 frame)
- [ ] Bullet trail (thin line)
- [ ] Hit spark (8x8px)

**Color:** Trắng/vàng sáng

---

#### 2.7 Heavy Slam (heavy_slam)

- [ ] Slam impact (48x48px, 4-5 frames)
- [ ] Shockwave (expanding ring, 64x64px)
- [ ] Ground crack effect (optional)
- [ ] Debris particles (8-12 particles)

**Color:** Cam/đỏ

---

#### 2.8 Magic Bolt (magic_bolt)

- [ ] Magic projectile (24x24px, animated)
- [ ] Magic trail (glowing, fading)
- [ ] Magic impact (32x32px, 3-4 frames)
- [ ] Sparkle particles (8-12 particles)

**Color:** Tím/xanh dương

---

### 3. Castle/Base Sprites

#### 3.1 Castle Main Structure

- [ ] Castle base sprite (128x128px)
- [ ] Castle damaged state (optional, 2-3 variants)
- [ ] Castle destroyed sprite (rubble)
- [ ] Team color flag/banner

**Variants Needed:**
- [ ] Neutral/default
- [ ] Team colored (use shader/tint)

---

#### 3.2 Castle Shooter

- [ ] Turret/cannon sprite (32x32px)
- [ ] Turret rotation frames (8 directions, optional)
- [ ] Muzzle flash (16x16px)
- [ ] Projectile (16x16px)

---

### 4. UI Elements

#### 4.1 Unit Icons (for Reward Slots)

Mỗi unit cần icon 48x48px:

- [ ] Melee icon
- [ ] Soldier icon
- [ ] Tank icon
- [ ] Scout icon
- [ ] Archer icon
- [ ] Gunner icon
- [ ] Hammer icon
- [ ] Mage icon
- [ ] x2 multiplier icon

**Style:** Simplified, high contrast, easy to recognize

---

#### 4.2 HUD Elements

- [ ] HP bar frame (132x16px)
- [ ] HP bar fill (gradient, team colored)
- [ ] Score display background
- [ ] Team indicator badges (6 colors)
- [ ] DEFEATED overlay text
- [ ] WINNER overlay text

---

#### 4.3 Ball Panel UI

- [ ] Panel background (192x720px)
- [ ] Peg sprite (24x24px, circular)
- [ ] Ball sprite (20x20px, circular)
- [ ] Reward slot frame (48x48px)
- [ ] Reward slot glow effect (active state)

---

### 5. Map & Environment

#### 5.1 Background

- [ ] Ground texture (tileable, 128x128px)
- [ ] Map border/frame
- [ ] Center decoration (optional)

**Style:** Simple, không làm mất focus vào units

---

#### 5.2 Spawn Effects

- [ ] Spawn portal/circle (32x32px, 4-6 frames)
- [ ] Spawn particles (8-12 particles)
- [ ] Spawn glow effect

---

#### 5.3 Death Effects

- [ ] Death poof (32x32px, 4-6 frames)
- [ ] Death particles (6-8 particles)
- [ ] Fade out effect

---

### 6. Particle Effects

#### 6.1 Generic Particles

- [ ] Dust particle (4x4px)
- [ ] Spark particle (4x4px)
- [ ] Smoke particle (8x8px)
- [ ] Magic sparkle (4x4px)
- [ ] Blood/hit particle (4x4px, optional)

---

#### 6.2 Trail Effects

- [ ] Speed trail (for Scout)
- [ ] Magic trail (for Mage)
- [ ] Arrow trail
- [ ] Bullet trail

---

### 7. Audio (Optional but Recommended)

#### 7.1 Unit Sounds

- [ ] Melee attack sound (sword swing)
- [ ] Soldier attack sound (shield bash)
- [ ] Tank attack sound (heavy hit)
- [ ] Scout attack sound (quick slash)
- [ ] Archer attack sound (bow release)
- [ ] Gunner attack sound (gunshot)
- [ ] Hammer attack sound (heavy slam)
- [ ] Mage attack sound (magic cast)

---

#### 7.2 Impact Sounds

- [ ] Hit impact (generic)
- [ ] Heavy impact (Tank/Hammer)
- [ ] Magic impact
- [ ] Arrow hit
- [ ] Bullet hit

---

#### 7.3 UI Sounds

- [ ] Ball drop sound
- [ ] Reward collect sound
- [ ] Unit spawn sound
- [ ] Castle damage sound
- [ ] Victory sound
- [ ] Defeat sound

---

#### 7.4 Background Music

- [ ] Main menu theme (optional)
- [ ] Battle theme (loopable, 1-2 minutes)
- [ ] Victory jingle (5-10 seconds)

---

## 📊 Asset Production Priority

### Phase 1: Minimum Viable Visuals (1-2 weeks)

**Goal:** Game trông "finished" enough để test với trẻ em

- ✅ 8 unit sprites (idle only)
- ✅ Basic attack effects (simple particles)
- ✅ Unit icons cho UI
- ✅ Team color indicators
- ✅ Castle sprites
- ✅ HP bars

**Estimated Cost:**
- DIY: 40-60 hours
- Asset packs: $200-300
- Commission: $500-800

---

### Phase 2: Animation & Polish (2-3 weeks)

**Goal:** Gameplay feedback rõ ràng, animations smooth

- ✅ Walk/run animations
- ✅ Attack animations
- ✅ Projectile sprites
- ✅ Impact effects
- ✅ Spawn/death effects
- ✅ UI polish

**Estimated Cost:**
- DIY: 60-80 hours
- Commission: $800-1200

---

### Phase 3: Full Production (4-6 weeks)

**Goal:** Production-ready, marketing-quality

- ✅ All animations polished
- ✅ Particle effects
- ✅ Background art
- ✅ Audio/SFX
- ✅ UI animations
- ✅ Special effects

**Estimated Cost:**
- DIY: 100-150 hours
- Commission: $2000-4000

---

## 🎨 Asset Sources & Tools

### Recommended Asset Packs (Quick Start)

**For Units:**
- [Kenney.nl - Top Down Shooter Pack](https://kenney.nl/assets/topdown-shooter) - Free
- [Itch.io - Tiny RPG Characters](https://itch.io/game-assets/tag-characters) - $10-50
- [OpenGameArt.org](https://opengameart.org/) - Free

**For Effects:**
- [Kenney.nl - Particle Pack](https://kenney.nl/assets/particle-pack) - Free
- [Itch.io - VFX Packs](https://itch.io/game-assets/tag-vfx) - $5-30

**For UI:**
- [Kenney.nl - UI Pack](https://kenney.nl/assets/ui-pack) - Free
- [Game-icons.net](https://game-icons.net/) - Free icons

---

### Tools for Creating Assets

**Sprite Creation:**
- **Aseprite** ($20) - Best for pixel art
- **Krita** (Free) - Good for hand-drawn
- **Piskel** (Free, web-based) - Simple pixel art

**AI Generation:**
- **Midjourney** ($10/month) - High quality
- **DALL-E 3** (Pay per use) - Good for concepts
- **Stable Diffusion** (Free) - Local generation

**Animation:**
- **Aseprite** - Built-in animation
- **Spine** ($69-299) - Professional 2D animation
- **DragonBones** (Free) - Open source alternative

**Effects:**
- **Godot Particle System** (Built-in) - Free
- **Particle Designer** - Various tools

---

## 📐 Technical Specifications

### Sprite Sheets

**Format:**
```
unit_name_animation.png
Example: melee_idle.png, archer_attack.png
```

**Layout:**
- Horizontal strip (frames left to right)
- Power of 2 dimensions when possible
- Transparent background (PNG)

**Naming Convention:**
```
[unit_type]_[animation]_[frame].png
OR
[unit_type]_[animation].png (sprite sheet)
```

---

### Import Settings (Godot)

```gdscript
# For pixel art
Filter: Nearest
Mipmaps: Disabled
Repeat: Disabled

# For smooth art
Filter: Linear
Mipmaps: Enabled (for scaling)
Repeat: Disabled
```

---

### Animation Frame Rates

- **Idle:** 4-8 FPS (slow, subtle)
- **Walk:** 8-12 FPS (smooth)
- **Attack:** 12-16 FPS (snappy)
- **Effects:** 12-24 FPS (fast)

---

## ✅ Quality Checklist

Before considering assets "done", verify:

### Visual Clarity
- [ ] Mỗi unit type có silhouette unique
- [ ] Dễ phân biệt ở kích thước nhỏ (64px)
- [ ] Team colors rõ ràng
- [ ] Attack effects visible và clear

### Performance
- [ ] Sprite sheets optimized (power of 2)
- [ ] File sizes reasonable (<500KB per sheet)
- [ ] No unnecessary transparency
- [ ] Compressed appropriately

### Consistency
- [ ] Art style consistent across all units
- [ ] Color palette consistent
- [ ] Animation timing consistent
- [ ] Scale/proportions consistent

### Kid-Friendly
- [ ] Không có violence quá mức
- [ ] Colors bright và appealing
- [ ] Characters cute/cool (not scary)
- [ ] Easy to understand visually

---

## 🎯 Success Metrics

**Test với trẻ 6-14 tuổi:**

- [ ] 90%+ có thể phân biệt 8 unit types
- [ ] 80%+ hiểu unit nào đang attack
- [ ] 70%+ thích visual style
- [ ] 0% complain về visuals quá scary/violent

---

## 📝 Notes for Artists

### Do's ✅
- Keep silhouettes distinct
- Use bright, saturated colors
- Make animations snappy and clear
- Test at actual game size (64-96px)
- Use team colors consistently
- Make effects visible but not overwhelming

### Don'ts ❌
- Don't make units too similar
- Don't use muddy/dark colors
- Don't make animations too slow
- Don't add unnecessary detail
- Don't make effects too flashy (distraction)
- Don't use realistic violence

---

## 🔄 Iteration Plan

### After First Playtest:
1. Identify units that are hard to distinguish
2. Adjust silhouettes/colors
3. Improve unclear attack effects
4. Polish based on feedback

### After Second Playtest:
1. Fine-tune animations
2. Add missing feedback
3. Adjust colors if needed
4. Final polish

---

## 📞 Next Steps

1. **Choose approach:**
   - [ ] Asset packs (fastest)
   - [ ] AI + polish (medium)
   - [ ] Commission artist (best quality)

2. **Create style guide:**
   - [ ] Choose art style
   - [ ] Define color palette
   - [ ] Create reference images

3. **Start with Phase 1:**
   - [ ] 8 unit sprites (idle)
   - [ ] Basic effects
   - [ ] UI icons

4. **Test early:**
   - [ ] Show to kids
   - [ ] Get feedback
   - [ ] Iterate

---

## 📚 References

- [Kenney Assets](https://kenney.nl/assets)
- [OpenGameArt](https://opengameart.org/)
- [Itch.io Game Assets](https://itch.io/game-assets)
- [Game-icons.net](https://game-icons.net/)
- [Aseprite Tutorials](https://www.aseprite.org/docs/)
- [Godot Sprite Documentation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html)

---

**Last Updated:** 2024
**Version:** 1.0
**Status:** Ready for Production
