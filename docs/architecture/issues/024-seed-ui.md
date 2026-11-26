# Seed UI: enter a seed, replay a map, Web URL parameter

- **Type:** feature
- **Priority:** medium
- **Area:** UI, map generation

Seeds can only be set with `godot -- --seed=N`, which a Web build can't take. Add:
- a seed field in the start menu,
- "replay this map" on the end screen (it already shows `%SeedLabel`),
- a `?seed=N` URL parameter for the Web build (via `JavaScriptBridge`).

`GameData.requested_seed` already survives reloads, so all three only need to set it and reload.
