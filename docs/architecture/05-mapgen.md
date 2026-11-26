# 5. Map generation

`Level._generate_map()` runs these steps in order: `_pick_seed()` → `MapGenerator.generate(config, seed)` → `tile_map_layer.clear()` → `MapPainter.paint()` → move `PlayerBase` → replace the spawners. `MapGenerator` and `MapData` are pure data. They use no nodes, no autoloads and no global random.

## Generator pipeline (`levels/generation/map_generator.gd`)

```mermaid
flowchart TD
  G["generate(config, seed) :25"] --> loop{"attempt 1..max_attempts (20)"}
  loop --> rng["_make_rng :108  hash([seed, attempt])"]
  rng --> nd["_new_data :122  all water"]
  nd --> shape["_shape_land :531  rotated/stretched ellipse + coast noise<br/>_keep_largest_land :571, ≤ 4 rounds of cleanup"]
  shape -- "land < min_land_share / no convergence" --> rej((reject))
  shape --> cd["_coast_distance :612  BFS from water"]
  cd --> mk["_place_markers :165  base (coast ≥ base_margin)<br/>spawners (coast 2..1+edge_band), water mask 0;<br/>count shrinks toward min if it does not fit"]
  mk -- nothing fits --> rej
  mk --> ko["_build_keep_out :218  circles around markers"]
  ko --> lk["_place_lakes :247  top noise cells, coast ≥ 3"]
  lk --> cl["_cleanup :262  only 13 valid shore masks;<br/>fix cells, drop lakes < 4 cells, ≤ 60 iterations"]
  cl -- no convergence --> rej
  cl --> rd["_place_roads :648  AStarGrid2D (no diagonals),<br/>weight 1 + wiggle × noise, +4 beside road;<br/>paths cut at first road cell, so they form a tree"]
  rd -- spawner has no route --> rej
  rd --> tr["_place_trees :341  clustered + scattered"]
  tr --> lm["_place_lamps :713  every lamp_spacing road cells,<br/>beside the road, exactly 1 road neighbour"]
  lm --> fl["_flood :374 / _all_spawners_reached :389"]
  fl -- spawner unreachable --> rej
  fl --> pk["_fill_pockets :424  unreached grass → trees"]
  pk --> dc["_place_decor :434  farmland near base, lake islands, dirt dots"]
  dc --> ok[return MapData]
  rej --> loop
  loop -- all attempts failed --> fb["_fallback :63  square island, markers + roads only"]
```

### Why the shore cleanup exists

The tileset has no tile for grass with water on two *opposite* sides, and none for a diagonal water pinch. A grass cell may therefore only have one of 13 water masks (`MapData.is_valid_shore_mask`). `_cleanup` turns offending cells into water or grass until the map is stable.

## Painter (`levels/generation/map_painter.gd`)

```mermaid
flowchart LR
  ts[tileset terrain peering bits] --> shore["shore lookup<br/>water mask → buildable grass tile"]
  ts --> road["road lookup<br/>4-side road mask → dirt tile (terrain 2)"]
  data[MapData cells + decor] --> paint
  shore --> paint
  road --> paint
  paint{"per cell, priority:"} --> r1["ROAD → road tile (mask 0 = 3,9)"]
  paint --> r2["LAMP → (0,9)  (not buildable, cost 255)"]
  paint --> r3["decor → decor tile"]
  paint --> r4["WATER → (6,3)"]
  paint --> r5["TREE → one of 3 (seeded RNG)"]
  paint --> r6["GRASS → shore lookup by mask"]
```

## Data types

- `MapGenConfig` (Resource, `default_map.tres`): every tunable. The `.tres` only overrides `spawner_count_max` 10, lakes, trees and decor density.
- `MapData` (RefCounted): `cells: PackedByteArray` of `Cell {WATER, GRASS, TREE, ROAD, LAMP}`, plus `decor`, `base_cell`, `spawner_cells`, `spawner_first_waves`, `attempts`, `used_fallback`.

After the level is ready, `Main` calls `PanningCamera.fit_rect(Level.get_map_rect())`. It centres the camera, zooms the map to fit, and lowers `min_zoom` to that zoom.
