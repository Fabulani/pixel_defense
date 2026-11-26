# `spawning_complete` fires one interval after the last spawn

- **Type:** polish / timing
- **Priority:** low
- **Area:** waves, spawners

## What happens

`EnemySpawner._on_spawn_timer_timeout()` calls `spawn_next()` and then restarts the timer while `_is_spawning` is true. On the tick that spawns the last enemy, the queue index has reached the end but `_is_spawning` is still true, so the timer runs once more. Only the following tick finds the queue empty and emits `spawning_complete`.

So the countdown to the next wave (and the spawn-delay step) starts one full spawner interval (`d × n × template multiplier`) after the last enemy appeared. On banner wave 6 (3 spawners open, `d` = 0.5) a spawner with the tank template finishes 0.5 × 3 × 1.2 = 1.8 s late; the wave ends when its slowest spawner does.

## Where

`entities/spawners/enemy_spawner.gd`: `spawn_next()` and `_on_spawn_timer_timeout()`.

## Ideas

- In `spawn_next()`, finish right after spawning the last enemy (check the index after incrementing).
- Or decide it is wanted (a breather before the countdown) and document it.

Note: changing it shifts the timing of every run, but not the wave contents.
