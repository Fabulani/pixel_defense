# Dying enemies freeze mid-fade behind the win/loss screen

- **Type:** polish
- **Priority:** low
- **Area:** enemies, UI

`GameEndScreen` pauses the tree, so enemies in their 0.25 s death fade freeze half-transparent behind it (only `VfxManager`, `CameraShake` and the wave banner keep running). Options: let the death tween run with `set_pause_mode(TWEEN_PAUSE_PROCESS)`, or delay the end screen by the fade duration.
