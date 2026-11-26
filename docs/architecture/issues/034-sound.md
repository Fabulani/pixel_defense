# Add sound

- **Type:** feature
- **Priority:** medium
- **Area:** audio

The game has no sound. The game-feel hooks (`bullet_fired`, `bullet_hit`, `enemy_died`, `armor_deflected`, `tower_built`, `tower_upgraded`, `wave_started`, base hit, lost/won) are already relayed to `Main`, so an `SfxManager` can connect next to `VfxManager`. It needs volume settings and Web audio-unlock handling.
