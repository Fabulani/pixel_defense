# Spawner-open tell: show the player when a new spawner opens

- **Type:** feature
- **Priority:** medium
- **Area:** UI, waves

Nothing tells the player that a spawner has opened, besides its flag fading from alpha 0.35 to full. Roadmap idea: an arrow or exclamation mark at the screen edge pointing to a newly opened spawner. It slides along the edge to follow the spawner's direction as the camera moves, and disappears once the spawner is on screen.

Wiring: emit a signal when `EnemySpawner.set_active()` goes from false to true (it is called every wave), relay it through `Level`, and connect it in `Main` to the HUD.
