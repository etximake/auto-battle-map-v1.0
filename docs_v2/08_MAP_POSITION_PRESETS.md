# 08 - Map Position Presets

Tai lieu nay mo ta layout castle/spawn theo `players.count`.

Map chinh:

```text
screen: 1280 x 720
left BallPanel:  x 0..192
map_rect:        x 192..1088, y 0..720
right BallPanel: x 1088..1280
```

## players.count = 2

### variant: default

```text
           x=192                         x=1088
             |-----------------------------|
             |                             |
             |                             |
             |                             |
             |    P0 C/S ---> <--- S/C P1 |
             |             center          |
             |                             |
             |                             |
             |                             |
             |-----------------------------|
```

```text
P0 castle (304, 360), spawn (332, 360)
P1 castle (976, 360), spawn (948, 360)
```

### variant: vertical

```text
           x=192                         x=1088
             |-----------------------------|
             |             P0              |
             |             C/S             |
             |              |              |
             |            center           |
             |              |              |
             |             S/C             |
             |             P1              |
             |-----------------------------|
```

```text
P0 castle (640, 150), spawn (640, 182)
P1 castle (640, 570), spawn (640, 538)
```

### variant: diagonal

```text
           x=192                         x=1088
             |-----------------------------|
             |    P0 C/S                   |
             |        \                    |
             |         \                   |
             |          \ center           |
             |           \                 |
             |                    S/C P1   |
             |                             |
             |-----------------------------|
```

```text
P0 castle (304, 170), spawn (334, 188)
P1 castle (976, 550), spawn (946, 532)
```

### variant: close_center

```text
           x=192                         x=1088
             |-----------------------------|
             |                             |
             |                             |
             |        P0 C/S -> <- S/C P1 |
             |             center          |
             |                             |
             |                             |
             |                             |
             |-----------------------------|
```

```text
P0 castle (424, 360), spawn (454, 360)
P1 castle (856, 360), spawn (826, 360)
```

## players.count = 4

### variant: default

```text
           x=192                         x=1088
             |-----------------------------|
             |                             |
             |    P0 C/S ---> <--- S/C P1 |
             |                             |
             |             center          |
             |                             |
             |    P2 C/S ---> <--- S/C P3 |
             |                             |
             |-----------------------------|
```

```text
P0 castle (304, 220), spawn (332, 232)
P1 castle (976, 220), spawn (948, 232)
P2 castle (304, 500), spawn (332, 488)
P3 castle (976, 500), spawn (948, 488)
```

### variant: corners

```text
           x=192                         x=1088
             |-----------------------------|
             |    P0 C/S           S/C P1 |
             |                             |
             |                             |
             |            center           |
             |                             |
             |    P2 C/S           S/C P3 |
             |                             |
             |-----------------------------|
```

```text
P0 castle (304, 140), spawn (334, 162)
P1 castle (976, 140), spawn (946, 162)
P2 castle (304, 580), spawn (334, 558)
P3 castle (976, 580), spawn (946, 558)
```

### variant: diamond

```text
           x=192                         x=1088
             |-----------------------------|
             |             P0              |
             |             C/S             |
             |                             |
             | P3 C/S    center    S/C P1 |
             |                             |
             |             S/C             |
             |             P2              |
             |-----------------------------|
```

```text
P0 castle (640, 128), spawn (640, 162)
P1 castle (980, 360), spawn (946, 360)
P2 castle (640, 592), spawn (640, 558)
P3 castle (300, 360), spawn (334, 360)
```

### variant: staggered

```text
           x=192                         x=1088
             |-----------------------------|
             |    P0 C/S                   |
             |                       S/C P1|
             |                             |
             |            center           |
             |                       S/C P3|
             |    P2 C/S                   |
             |                             |
             |-----------------------------|
```

```text
P0 castle (304, 165), spawn (332, 183)
P1 castle (976, 270), spawn (948, 282)
P2 castle (304, 555), spawn (332, 537)
P3 castle (976, 450), spawn (948, 438)
```

## players.count = 6

```text
           x=192                         x=1088
             |-----------------------------|
             |    P0 C/S ---> <--- S/C P1 |
             |                             |
             |    P2 C/S ---> <--- S/C P3 |
             |             center          |
             |    P4 C/S ---> <--- S/C P5 |
             |                             |
             |-----------------------------|
```

```text
P0 castle (304, 134), spawn (332, 152)
P1 castle (976, 134), spawn (948, 152)
P2 castle (304, 360), spawn (332, 360)
P3 castle (976, 360), spawn (948, 360)
P4 castle (304, 586), spawn (332, 568)
P5 castle (976, 586), spawn (948, 568)
```

## Config source

The active preset is selected from:

```text
configs/default_game_config.json
layout.player_count_layouts[str(players.count)]
layout.position_variant
```

If a preset is missing, `GameConfig` falls back to `layout.castle_positions`,
then to generated side positions.

For 2-team and 4-team layouts, `layout.position_variant` can be:

```text
default
vertical
diagonal
close_center
corners
diamond
staggered
```
