# Calling the next wave early has no cap

- **Type:** design / balance
- **Priority:** medium
- **Area:** waves

`call_next_wave()` pays `floori(time_left × 0.5)`. Calling at 12 s gives +6 coins every wave, and waves may overlap with no limit. Decide whether this is intended. Options: a cap on overlapping waves, a decaying bonus, or a bonus that depends on how many enemies are still alive.

The countdown, call-early and the banner have not been playtested by a human, nor on a phone or Web, and `wave_delay`, the button size and `banner_hold_special` are placeholders.
