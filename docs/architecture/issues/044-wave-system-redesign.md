# Wave system: discuss and redesign pacing and early calls

- **Type:** design / discussion
- **Priority:** medium
- **Area:** waves

This is a discussion issue, not a fix. Collects the author's notes from the 2026-11-26 code review.

## 1. Spawn interval scales with the spawner count

Today open spawner *k* spawns every `d × n × template.spawn_delay_multiplier`, with a first delay of `d × (k + 1)` (`WaveManager.start_next_wave()`). The map as a whole spawns one enemy per `d`, alternating between spawners.

With many spawners the gap at each spawner becomes very long: on wave 1 with 4 spawners, each one spawns every 4 s (tank: 4.8 s). Each lane trickles.

Proposal:
- Every spawner uses the same delay, independent of how many are open.
- Waves may be sent in **bursts** (groups of enemies close together, then a pause), not a steady stream.

Things to decide: does the budget per spawner still split evenly (more spawners = same threat, more lanes), or does each spawner get its own budget? Does a template still change the delay?

## 2. Early call and the countdown model

The countdown starts only when spawning of the current wave completes, and calling early pays `floor(time_left × 0.5)` (max 6 per wave, about 95 to 114 coins over a run). Early-calling therefore gives a lot of coins for a difficulty increase that lasts only the current wave (see issue 028).

Idea: a **wave queue that never stops** (as in Dungeon Warfare). Upcoming waves are shown in a queue sliding toward "now" on a fixed clock; calling early slides the queue forward (pulls the next wave in now) and pays for the skipped time. The clock keeps running whatever the player does, so pressure keeps building instead of resetting after every wave.

This would also make the next-wave preview natural: the plans already exist ahead of time (`WaveManager` plans the next wave when the countdown starts).

## Related

- 028 call-early has no cap
- 041 `spawning_complete` one interval late
- 043 player-started first wave
- 027 balance pass
