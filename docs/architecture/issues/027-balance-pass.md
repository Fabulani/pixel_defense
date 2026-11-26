# Balance pass: enemies, waves, towers, economy

- **Type:** tuning
- **Priority:** high (before content grows)
- **Area:** balance

All of these values are placeholders:
- Enemies: hp, speed, armor, coins, and wave cost / weight / `max_share` for every variant (armored, regenerator, splitter, mini, dasher; fast now pays 1 coin).
- Waves: the budget formula in `default_waves.tres` (wave 20 has about 60-70 enemies), `min_spawn_delay` 0.3, every template value, and the boss (a tank-weighted placeholder until wave rework phase 4).
- Towers: costs, +10 % per level, the major multipliers, turn speeds, `aim_tolerance`, `bullet_speed`, idle sweep.
- Economy: starting coins 5, `early_bonus_per_second` 0.5, `wave_delay` 12.

Early special waves (tank, rush before their enemies unlock) are mostly basic enemies. Use `tools/print_waves` and the debug menu while playtesting.
