# The fallback map is not validated and breaks the edge margin

- **Type:** robustness
- **Priority:** low
- **Area:** map generation

## Description
`MapGenerator._fallback()` is used after `max_attempts` failed attempts. It is a square island with a 1-cell water ring, so land sits closer to the edge than the "≥ 2 cells" rule. It skips the flood-fill check that every spawner reaches the base, and `_place_last_resort` puts spawners 3 cells apart at x = 2. A 500-seed run never reached it through `generate()`.

## Fix
Run `_flood` / `_all_spawners_reached` on the fallback (and carve corridors if it fails). Use a 2-cell ring. Add a unit-style headless check that calls `_fallback()` for a few seeds.
