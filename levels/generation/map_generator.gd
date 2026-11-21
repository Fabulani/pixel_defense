class_name MapGenerator extends RefCounted

## Atlas coords of the decoration tiles.
const DIRT_DOT: Vector2i = Vector2i(3, 9)
const FARMLAND: Vector2i = Vector2i(1, 9)
const ISLAND_TILES: Array[Vector2i] = [Vector2i(4, 5), Vector2i(5, 5), Vector2i(10, 5), Vector2i(11, 5)]

const _CLEANUP_MAX_ITERATIONS: int = 60
const _MIN_LAKE_CELLS: int = 4
const _BASE_TRIES: int = 30
const _SPAWNER_TRIES: int = 100
const _FALLBACK_MAX_TRIES: int = 1000
const _SETTLE_MAX_ROUNDS: int = 4

const _SIDE_BITS: Array[int] = [MapData.N, MapData.E, MapData.S, MapData.W]
const _SIDE_DIRS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const _CORNER_BITS: Array[int] = [MapData.NW, MapData.NE, MapData.SE, MapData.SW]
const _CORNER_DIRS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]
## Side bits adjacent to each corner (same order as _CORNER_BITS).
const _CORNER_SIDES: Array[int] = [MapData.N | MapData.W, MapData.N | MapData.E, MapData.E | MapData.S, MapData.S | MapData.W]
const _DIRS_4: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]


## Generates a map. The same config and seed always give the same result.
static func generate(config: MapGenConfig, map_seed: int) -> MapData:
	for attempt: int in range(1, config.max_attempts + 1):
		var data: MapData = _try_generate(config, map_seed, attempt)
		if data != null:
			data.attempts = attempt
			return data
	return _fallback(config, map_seed)


static func _try_generate(config: MapGenConfig, map_seed: int, attempt: int) -> MapData:
	var rng: RandomNumberGenerator = _make_rng(map_seed, attempt)
	var data: MapData = _new_data(config, map_seed)
	if not _shape_land(data, config, rng):
		return null
	var coast: PackedInt32Array = _coast_distance(data)
	if not _place_markers(data, config, rng, config.min_spawner_base_distance, config.min_spawner_separation, coast):
		return null
	var keep: PackedByteArray = _build_keep_out(data, config)
	var marker_keep: PackedByteArray = keep.duplicate()
	_place_lakes(data, config, rng, keep, coast)
	var protect: PackedByteArray = keep.duplicate()
	if not _cleanup(data, protect):
		return null
	var paths: Array[Array] = []
	if not _place_roads(data, config, rng, keep, protect, paths):
		return null
	# Roads only turn grass with water mask 0 into road, so the coast stays valid and no second `_cleanup` is needed.
	_place_trees(data, config, rng, keep)
	_place_lamps(data, config, rng, marker_keep, paths)
	var flooded: PackedByteArray = _flood(data, data.base_cell)
	if not _all_spawners_reached(data, flooded):
		return null
	_fill_pockets(data, flooded)
	_place_decor(data, config, rng, keep)
	return data


## Last resort: a square island (land everywhere inside a 1-cell water ring), no lakes, trees, decoration or lamps; markers and roads only.
static func _fallback(config: MapGenConfig, map_seed: int) -> MapData:
	var min_base: int = config.min_spawner_base_distance
	var sep: int = config.min_spawner_separation
	var data: MapData = _new_square_data(config, map_seed)
	var coast: PackedInt32Array = _coast_distance(data)
	for k: int in _FALLBACK_MAX_TRIES:
		var rng: RandomNumberGenerator = _make_rng(map_seed, config.max_attempts + 1 + k)
		if _place_markers(data, config, rng, min_base, sep, coast):
			break
		if k % 5 == 4:
			min_base >>= 1
			sep >>= 1
		if k == _FALLBACK_MAX_TRIES - 1:
			_place_last_resort(data, config)
	_place_fallback_roads(data, config, map_seed)
	data.attempts = config.max_attempts
	data.used_fallback = true
	return data


## Roads for the fallback map: the same `_place_roads` as the real generator, no lamps. If a road cannot be routed, a straight corridor is
## carved first (a no-op on the all-grass square, but it keeps the call safe for odd marker positions); if it still fails the map has no roads.
static func _place_fallback_roads(data: MapData, config: MapGenConfig, map_seed: int) -> void:
	var rng: RandomNumberGenerator = _make_rng(map_seed, config.max_attempts + 1 + _FALLBACK_MAX_TRIES)
	var keep: PackedByteArray = _build_keep_out(data, config)
	var protect: PackedByteArray = keep.duplicate()
	var paths: Array[Array] = []
	if _place_roads(data, config, rng, keep, protect, paths):
		return
	for spawner: Vector2i in data.spawner_cells:
		_carve(data, spawner, data.base_cell, protect)
	paths.clear()
	_place_roads(data, config, rng, keep, protect, paths)


## Deterministic placement that cannot fail, for degenerate configs.
static func _place_last_resort(data: MapData, config: MapGenConfig) -> void:
	data.base_cell = data.size / 2
	data.spawner_cells.clear()
	data.spawner_first_waves.clear()
	for i: int in maxi(config.spawner_count_min, 1):
		data.spawner_cells.append(Vector2i(2, mini(2 + i * 3, data.size.y - 3)))
		data.spawner_first_waves.append(_first_wave_for(config, i))


static func _make_rng(map_seed: int, attempt: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([map_seed, attempt])
	return rng


static func _make_noise(rng: RandomNumberGenerator, frequency: float) -> FastNoiseLite:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = frequency
	return noise


## Step 1: an all-water map; `_shape_land` raises the island.
static func _new_data(config: MapGenConfig, map_seed: int) -> MapData:
	var data: MapData = MapData.new()
	data.map_seed = map_seed
	data.size = config.size
	data.cells.resize(config.size.x * config.size.y)
	data.cells.fill(MapData.Cell.WATER)
	return data


## All grass with a 1-cell water ring (the fallback map).
static func _new_square_data(config: MapGenConfig, map_seed: int) -> MapData:
	var data: MapData = _new_data(config, map_seed)
	data.cells.fill(MapData.Cell.GRASS)
	for x: int in config.size.x:
		data.set_cell(Vector2i(x, 0), MapData.Cell.WATER)
		data.set_cell(Vector2i(x, config.size.y - 1), MapData.Cell.WATER)
	for y: int in config.size.y:
		data.set_cell(Vector2i(0, y), MapData.Cell.WATER)
		data.set_cell(Vector2i(config.size.x - 1, y), MapData.Cell.WATER)
	return data


static func _index(data: MapData, cell: Vector2i) -> int:
	return cell.y * data.size.x + cell.x


static func _is_ring(data: MapData, cell: Vector2i) -> bool:
	return cell.x == 0 or cell.y == 0 or cell.x == data.size.x - 1 or cell.y == data.size.y - 1


static func _first_wave_for(config: MapGenConfig, index: int) -> int:
	if config.spawner_first_waves.is_empty():
		return 0
	return config.spawner_first_waves[mini(index, config.spawner_first_waves.size() - 1)]


## Effective keep-out radius: `MapGenConfig.keep_out_radius`, but at least 2 (a radius-1 circle leaves the diagonal neighbours free, so a corner could be water and the cell a shore tile).
static func _keep_out_radius(config: MapGenConfig) -> int:
	return maxi(2, config.keep_out_radius)


## Step 2: base and spawners. `coast` is the coast distance field of the island. Returns false if no valid placement was found.
## If the requested spawner count does not fit, it is retried with one spawner less, down to `spawner_count_min`.
static func _place_markers(data: MapData, config: MapGenConfig, rng: RandomNumberGenerator, min_base: int, sep: int, coast: PackedInt32Array) -> bool:
	var lowest: int = maxi(config.spawner_count_min, 0)
	var count: int = rng.randi_range(lowest, maxi(lowest, config.spawner_count_max))
	var best: int = 0
	for value: int in coast:
		best = maxi(best, value)
	var base_floor: int = mini(best, config.base_margin)
	var base_candidates: Array[Vector2i] = []
	var spawner_candidates: Array[Vector2i] = []
	for idx: int in coast.size():
		var cell: Vector2i = Vector2i(idx % data.size.x, idx / data.size.x)
		# Markers sit on road tiles, which need grass on all 8 sides.
		if coast[idx] == 0 or data.get_water_mask(cell) != 0:
			continue
		if coast[idx] >= base_floor:
			base_candidates.append(cell)
		if coast[idx] >= 2 and coast[idx] <= 1 + maxi(config.spawner_edge_band, 1):
			spawner_candidates.append(cell)
	if base_candidates.is_empty():
		return false
	for wanted: int in range(count, lowest - 1, -1):
		for _b: int in _BASE_TRIES:
			var base: Vector2i = base_candidates[rng.randi_range(0, base_candidates.size() - 1)]
			var spawners: Array[Vector2i] = _pick_spawners(rng, spawner_candidates, base, wanted, min_base, sep)
			if spawners.size() == wanted:
				data.base_cell = base
				data.spawner_cells = spawners
				data.spawner_first_waves.clear()
				for i: int in wanted:
					data.spawner_first_waves.append(_first_wave_for(config, i))
				return true
	return false


## Greedily picks up to `wanted` random spawner cells that keep `min_base` from the base and `sep` from each other.
static func _pick_spawners(rng: RandomNumberGenerator, candidates: Array[Vector2i], base: Vector2i, wanted: int, min_base: int, sep: int) -> Array[Vector2i]:
	var pool: Array[Vector2i] = []
	for cell: Vector2i in candidates:
		if cell != base and (cell - base).length_squared() >= min_base * min_base:
			pool.append(cell)
	var picked: Array[Vector2i] = []
	while picked.size() < wanted and not pool.is_empty():
		var chosen: Vector2i = pool[rng.randi_range(0, pool.size() - 1)]
		picked.append(chosen)
		var rest: Array[Vector2i] = []
		for cell: Vector2i in pool:
			if cell != chosen and (cell - chosen).length_squared() >= sep * sep:
				rest.append(cell)
		pool = rest
	return picked


## Marks the circles around base and spawners (interior cells only; the water ring is never kept out).
static func _build_keep_out(data: MapData, config: MapGenConfig) -> PackedByteArray:
	var keep: PackedByteArray = PackedByteArray()
	keep.resize(data.cells.size())
	var centers: Array[Vector2i] = [data.base_cell]
	centers.append_array(data.spawner_cells)
	var r: int = _keep_out_radius(config)
	for center: Vector2i in centers:
		for dy: int in range(-r, r + 1):
			for dx: int in range(-r, r + 1):
				var cell: Vector2i = center + Vector2i(dx, dy)
				if dx * dx + dy * dy <= r * r and data.is_in_bounds(cell) and not _is_ring(data, cell):
					keep[_index(data, cell)] = 1
	return keep


## Returns the first `count` of `candidates` ranked by noise value (highest first, index breaks ties).
static func _top_by_noise(data: MapData, candidates: Array[int], noise: FastNoiseLite, count: int) -> Array[int]:
	var values: Dictionary[int, float] = {}
	for idx: int in candidates:
		values[idx] = noise.get_noise_2d(idx % data.size.x, idx / data.size.x)
	var sorted: Array[int] = candidates.duplicate()
	sorted.sort_custom(func(a: int, b: int) -> bool:
		if values[a] != values[b]:
			return values[a] > values[b]
		return a < b)
	return sorted.slice(0, maxi(count, 0))


## Step 3: lakes from the top noise values, only on cells at least 3 steps from the coast.
static func _place_lakes(data: MapData, config: MapGenConfig, rng: RandomNumberGenerator, keep: PackedByteArray, coast: PackedInt32Array) -> void:
	var noise: FastNoiseLite = _make_noise(rng, config.lake_noise_frequency)
	var candidates: Array[int] = []
	var land_count: int = 0
	for idx: int in coast.size():
		if coast[idx] > 0:
			land_count += 1
		if coast[idx] >= 3 and keep[idx] == 0:
			candidates.append(idx)
	var count: int = roundi(config.lake_coverage * land_count)
	for idx: int in _top_by_noise(data, candidates, noise, count):
		data.cells[idx] = MapData.Cell.WATER


## Step 4: fixes invalid shore cells and removes tiny lakes until stable. Returns false if it did not converge.
static func _cleanup(data: MapData, protect: PackedByteArray) -> bool:
	for _i: int in _CLEANUP_MAX_ITERATIONS:
		var changed: bool = false
		for y: int in range(1, data.size.y - 1):
			for x: int in range(1, data.size.x - 1):
				var cell: Vector2i = Vector2i(x, y)
				if data.get_cell(cell) == MapData.Cell.WATER:
					continue
				var mask: int = data.get_water_mask(cell)
				if MapData.is_valid_shore_mask(mask):
					continue
				changed = true
				_fix_cell(data, cell, mask, protect[_index(data, cell)] != 0)
		if _remove_small_lakes(data):
			changed = true
		if not changed:
			return true
	return false


static func _fix_cell(data: MapData, cell: Vector2i, mask: int, is_protected: bool) -> void:
	var sides: int = mask & 15
	var opposite: bool = (sides & (MapData.N | MapData.S)) == (MapData.N | MapData.S) \
			or (sides & (MapData.E | MapData.W)) == (MapData.E | MapData.W)
	if opposite:
		if not is_protected:
			data.set_cell(cell, MapData.Cell.WATER)
			return
		for i: int in 4:
			if sides & _SIDE_BITS[i] != 0:
				_make_grass(data, cell + _SIDE_DIRS[i])
		return
	# Diagonal pinch or stray corner: drop the water corners that no side explains.
	for i: int in 4:
		if mask & _CORNER_BITS[i] != 0 and sides & _CORNER_SIDES[i] == 0:
			_make_grass(data, cell + _CORNER_DIRS[i])


static func _make_grass(data: MapData, cell: Vector2i) -> void:
	if data.get_cell(cell) == MapData.Cell.WATER and not _is_ring(data, cell):
		data.set_cell(cell, MapData.Cell.GRASS)


## Turns lakes (8-connected water not touching the ring) of fewer than 4 cells into grass.
static func _remove_small_lakes(data: MapData) -> bool:
	var visited: PackedByteArray = PackedByteArray()
	visited.resize(data.cells.size())
	var changed: bool = false
	for start_y: int in range(1, data.size.y - 1):
		for start_x: int in range(1, data.size.x - 1):
			var start: Vector2i = Vector2i(start_x, start_y)
			if data.get_cell(start) != MapData.Cell.WATER or visited[_index(data, start)] != 0:
				continue
			var component: Array[Vector2i] = [start]
			visited[_index(data, start)] = 1
			var touches_ring: bool = false
			var head: int = 0
			while head < component.size():
				var cur: Vector2i = component[head]
				head += 1
				for dy: int in range(-1, 2):
					for dx: int in range(-1, 2):
						var nb: Vector2i = cur + Vector2i(dx, dy)
						if not data.is_in_bounds(nb) or data.get_cell(nb) != MapData.Cell.WATER:
							continue
						if _is_ring(data, nb):
							touches_ring = true
							continue
						if visited[_index(data, nb)] == 0:
							visited[_index(data, nb)] = 1
							component.append(nb)
			if not touches_ring and component.size() < _MIN_LAKE_CELLS:
				for cell: Vector2i in component:
					data.set_cell(cell, MapData.Cell.GRASS)
				changed = true
	return changed


## Step 5: trees on plain grass, partly clustered by noise, partly scattered.
static func _place_trees(data: MapData, config: MapGenConfig, rng: RandomNumberGenerator, keep: PackedByteArray) -> void:
	var candidates: Array[int] = _plain_grass_candidates(data, keep)
	var total: int = roundi(config.tree_coverage * _count_land(data))
	var clustered: int = roundi(total * config.tree_cluster_share)
	var noise: FastNoiseLite = _make_noise(rng, config.lake_noise_frequency * 2.0)
	var chosen: Array[int] = _top_by_noise(data, candidates, noise, clustered)
	for idx: int in chosen:
		data.cells[idx] = MapData.Cell.TREE
	var remaining: Array[int] = []
	for idx: int in candidates:
		if data.cells[idx] == MapData.Cell.GRASS:
			remaining.append(idx)
	for _i: int in mini(total - chosen.size(), remaining.size()):
		var pick: int = rng.randi_range(0, remaining.size() - 1)
		data.cells[remaining[pick]] = MapData.Cell.TREE
		remaining[pick] = remaining[remaining.size() - 1]
		remaining.remove_at(remaining.size() - 1)


## Row-major indices of GRASS cells with water mask 0 outside the keep-outs.
static func _plain_grass_candidates(data: MapData, keep: PackedByteArray) -> Array[int]:
	var result: Array[int] = []
	for y: int in range(1, data.size.y - 1):
		for x: int in range(1, data.size.x - 1):
			var cell: Vector2i = Vector2i(x, y)
			var idx: int = y * data.size.x + x
			if keep[idx] == 0 and data.get_cell(cell) == MapData.Cell.GRASS \
					and data.get_water_mask(cell) == 0 and not data.decor.has(cell):
				result.append(idx)
	return result


## 4-neighbour flood fill over walkable cells. Returns a mask of reached cells.
static func _flood(data: MapData, from: Vector2i) -> PackedByteArray:
	var reached: PackedByteArray = PackedByteArray()
	reached.resize(data.cells.size())
	var stack: Array[Vector2i] = [from]
	reached[_index(data, from)] = 1
	while not stack.is_empty():
		var cur: Vector2i = stack.pop_back()
		for dir: Vector2i in _DIRS_4:
			var nb: Vector2i = cur + dir
			if data.is_walkable(nb) and reached[_index(data, nb)] == 0:
				reached[_index(data, nb)] = 1
				stack.append(nb)
	return reached


static func _all_spawners_reached(data: MapData, reached: PackedByteArray) -> bool:
	for spawner: Vector2i in data.spawner_cells:
		if reached[_index(data, spawner)] == 0:
			return false
	return true


## Carves a 4-connected straight corridor and protects it from the shore cleanup.
static func _carve(data: MapData, from: Vector2i, to: Vector2i, protect: PackedByteArray) -> void:
	var delta: Vector2i = to - from
	var nx: int = absi(delta.x)
	var ny: int = absi(delta.y)
	var step: Vector2i = Vector2i(signi(delta.x), signi(delta.y))
	var pos: Vector2i = from
	var ix: int = 0
	var iy: int = 0
	_carve_cell(data, pos, protect)
	while ix < nx or iy < ny:
		if (1 + 2 * ix) * ny < (1 + 2 * iy) * nx:
			pos.x += step.x
			ix += 1
		else:
			pos.y += step.y
			iy += 1
		_carve_cell(data, pos, protect)


static func _carve_cell(data: MapData, cell: Vector2i, protect: PackedByteArray) -> void:
	if _is_ring(data, cell) or not data.is_in_bounds(cell):
		return
	data.set_cell(cell, MapData.Cell.GRASS)
	protect[_index(data, cell)] = 1


## Cut-off grass pockets with no water nearby become trees.
static func _fill_pockets(data: MapData, reached: PackedByteArray) -> void:
	for y: int in range(1, data.size.y - 1):
		for x: int in range(1, data.size.x - 1):
			var cell: Vector2i = Vector2i(x, y)
			if data.get_cell(cell) == MapData.Cell.GRASS and reached[_index(data, cell)] == 0 \
					and data.get_water_mask(cell) == 0:
				data.set_cell(cell, MapData.Cell.TREE)


## Step 7: farmland patches, small islands and dirt dots.
static func _place_decor(data: MapData, config: MapGenConfig, rng: RandomNumberGenerator, keep: PackedByteArray) -> void:
	var total: int = roundi(config.decoration_density * data.size.x * data.size.y)
	_place_farmland(data, config, rng, keep, maxi(roundi(total / 10.0 * config.farmland_multiplier), 1))
	_place_islands(data, rng, roundi(total * 0.2), _ocean_mask(data))
	var candidates: Array[int] = _plain_grass_candidates(data, keep)
	# Density per land cell stays that of the old full-square map.
	var dots: int = roundi(total * 0.6 * _count_land(data) / float((data.size.x - 2) * (data.size.y - 2)))
	for _i: int in mini(dots, candidates.size()):
		var pick: int = rng.randi_range(0, candidates.size() - 1)
		var idx: int = candidates[pick]
		data.decor[Vector2i(idx % data.size.x, idx / data.size.x)] = DIRT_DOT
		candidates[pick] = candidates[candidates.size() - 1]
		candidates.remove_at(candidates.size() - 1)


static func _is_plain_free(data: MapData, cell: Vector2i, keep: PackedByteArray) -> bool:
	return data.is_in_bounds(cell) and keep[_index(data, cell)] == 0 \
			and data.get_cell(cell) == MapData.Cell.GRASS and data.get_water_mask(cell) == 0 \
			and not data.decor.has(cell)


## Farmland patches of 3..5 cells, clumped near the base. The first patch centre is the nearest of a few random tries within `r + 3` of the base (outside the keep-out circle);
## later patches prefer a cell 4-adjacent to existing farmland and fall back to that near-base search.
static func _place_farmland(data: MapData, config: MapGenConfig, rng: RandomNumberGenerator, keep: PackedByteArray, patches: int) -> void:
	var r: int = _keep_out_radius(config)
	var farm: Array[Vector2i] = []
	for _p: int in patches:
		var center: Vector2i = Vector2i(-1, -1)
		if not farm.is_empty():
			for _t: int in 12:
				var cand: Vector2i = farm[rng.randi_range(0, farm.size() - 1)] + _DIRS_4[rng.randi_range(0, 3)]
				if _is_plain_free(data, cand, keep):
					center = cand
					break
		if center.x < 0:
			var best: int = 1 << 30
			for _t: int in 12:
				var cand: Vector2i = data.base_cell + Vector2i(rng.randi_range(-(r + 3), r + 3), rng.randi_range(-(r + 3), r + 3))
				var d2: int = (cand - data.base_cell).length_squared()
				if d2 > r * r and d2 < best and _is_plain_free(data, cand, keep):
					best = d2
					center = cand
		if center.x < 0:
			continue
		var patch: Array[Vector2i] = [center]
		var wanted: int = rng.randi_range(3, 5)
		for _g: int in 20:
			if patch.size() >= wanted:
				break
			var nb: Vector2i = patch[rng.randi_range(0, patch.size() - 1)] + _DIRS_4[rng.randi_range(0, 3)]
			if not patch.has(nb) and _is_plain_free(data, nb, keep):
				patch.append(nb)
		for cell: Vector2i in patch:
			data.decor[cell] = FARMLAND
			farm.append(cell)


## Small islands in lakes (never in the ocean).
static func _place_islands(data: MapData, rng: RandomNumberGenerator, count: int, ocean: PackedByteArray) -> void:
	var candidates: Array[Vector2i] = []
	for y: int in range(1, data.size.y - 1):
		for x: int in range(1, data.size.x - 1):
			var cell: Vector2i = Vector2i(x, y)
			if data.get_cell(cell) == MapData.Cell.WATER and data.get_water_mask(cell) == 255 \
					and ocean[_index(data, cell)] == 0 and not data.decor.has(cell):
				candidates.append(cell)
	for _i: int in mini(count, candidates.size()):
		var pick: int = rng.randi_range(0, candidates.size() - 1)
		data.decor[candidates[pick]] = ISLAND_TILES[rng.randi_range(0, ISLAND_TILES.size() - 1)]
		candidates[pick] = candidates[candidates.size() - 1]
		candidates.remove_at(candidates.size() - 1)


## Water cells connected (8-neighbour) to the map edge ring: 1 = ocean, 0 = land or lake.
static func _ocean_mask(data: MapData) -> PackedByteArray:
	var ocean: PackedByteArray = PackedByteArray()
	ocean.resize(data.cells.size())
	var stack: Array[Vector2i] = []
	for y: int in data.size.y:
		for x: int in data.size.x:
			var cell: Vector2i = Vector2i(x, y)
			if _is_ring(data, cell) and data.get_cell(cell) == MapData.Cell.WATER:
				ocean[_index(data, cell)] = 1
				stack.append(cell)
	while not stack.is_empty():
		var cur: Vector2i = stack.pop_back()
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				var nb: Vector2i = cur + Vector2i(dx, dy)
				if data.is_in_bounds(nb) and data.get_cell(nb) == MapData.Cell.WATER and ocean[_index(data, nb)] == 0:
					ocean[_index(data, nb)] = 1
					stack.append(nb)
	return ocean


## Step 1b: raises the island: an irregular ellipse (random stretch 0.8..1.2 per axis and rotation, coast noise), never within 2 cells of the map edge.
## Only the largest 4-connected land piece stays and the coast is cleaned. Returns false if less than `min_land_share` of the interior is land.
static func _shape_land(data: MapData, config: MapGenConfig, rng: RandomNumberGenerator) -> bool:
	var noise: FastNoiseLite = _make_noise(rng, config.coast_noise_frequency)
	var stretch: Vector2 = Vector2(rng.randf_range(0.8, 1.2), rng.randf_range(0.8, 1.2))
	var angle: float = rng.randf_range(0.0, TAU)
	var cos_a: float = cos(angle)
	var sin_a: float = sin(angle)
	var center: Vector2 = Vector2(data.size - Vector2i.ONE) * 0.5
	var radius: Vector2 = Vector2(data.size) * maxf(config.land_radius, 0.01) * stretch
	for y: int in range(2, data.size.y - 2):
		for x: int in range(2, data.size.x - 2):
			var offset: Vector2 = Vector2(x, y) - center
			var u: float = offset.x * cos_a + offset.y * sin_a
			var v: float = -offset.x * sin_a + offset.y * cos_a
			var dist: float = Vector2(u / radius.x, v / radius.y).length()
			if dist + noise.get_noise_2d(x, y) * config.coast_noise_amplitude < 1.0:
				data.set_cell(Vector2i(x, y), MapData.Cell.GRASS)
	_keep_largest_land(data)
	var none: PackedByteArray = PackedByteArray()
	none.resize(data.cells.size())
	var stable: bool = false
	for _i: int in _SETTLE_MAX_ROUNDS:
		if not _cleanup(data, none):
			return false
		if not _keep_largest_land(data):
			stable = true
			break
	if not stable:
		return false
	return _count_land(data) >= roundi(config.min_land_share * (data.size.x - 2) * (data.size.y - 2))


static func _count_land(data: MapData) -> int:
	var count: int = 0
	for value: int in data.cells:
		if value != MapData.Cell.WATER:
			count += 1
	return count


## Turns all land except the largest 4-connected piece into water. Returns true if anything changed.
static func _keep_largest_land(data: MapData) -> bool:
	var components: Array[Array] = _land_components(data)
	if components.size() <= 1:
		return false
	var largest: int = 0
	for i: int in components.size():
		if components[i].size() > components[largest].size():
			largest = i
	for i: int in components.size():
		if i != largest:
			for cell: Vector2i in components[i]:
				data.set_cell(cell, MapData.Cell.WATER)
	return true


## All 4-connected pieces of non-water cells, in row-major order of their first cell.
static func _land_components(data: MapData) -> Array[Array]:
	var seen: PackedByteArray = PackedByteArray()
	seen.resize(data.cells.size())
	var result: Array[Array] = []
	for y: int in data.size.y:
		for x: int in data.size.x:
			var start: Vector2i = Vector2i(x, y)
			if data.get_cell(start) == MapData.Cell.WATER or seen[_index(data, start)] != 0:
				continue
			var piece: Array[Vector2i] = [start]
			seen[_index(data, start)] = 1
			var head: int = 0
			while head < piece.size():
				var cur: Vector2i = piece[head]
				head += 1
				for dir: Vector2i in _DIRS_4:
					var nb: Vector2i = cur + dir
					if data.is_in_bounds(nb) and data.get_cell(nb) != MapData.Cell.WATER and seen[_index(data, nb)] == 0:
						seen[_index(data, nb)] = 1
						piece.append(nb)
			result.append(piece)
	return result


## Step 3a: steps to the nearest water over land. 0 = water, 1 = next to water.
static func _coast_distance(data: MapData) -> PackedInt32Array:
	var dist: PackedInt32Array = PackedInt32Array()
	dist.resize(data.cells.size())
	var queue: Array[Vector2i] = []
	for y: int in data.size.y:
		for x: int in data.size.x:
			var cell: Vector2i = Vector2i(x, y)
			if data.get_cell(cell) == MapData.Cell.WATER:
				continue
			for dir: Vector2i in _DIRS_4:
				if data.get_cell(cell + dir) == MapData.Cell.WATER:
					dist[_index(data, cell)] = 1
					queue.append(cell)
					break
	var head: int = 0
	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		for dir: Vector2i in _DIRS_4:
			var nb: Vector2i = cur + dir
			if data.is_in_bounds(nb) and data.get_cell(nb) != MapData.Cell.WATER and dist[_index(data, nb)] == 0:
				dist[_index(data, nb)] = dist[_index(data, cur)] + 1
				queue.append(nb)
	return dist


static func _road_passable(data: MapData, cell: Vector2i) -> bool:
	return data.is_in_bounds(cell) and data.get_cell(cell) == MapData.Cell.GRASS \
			and data.get_water_mask(cell) == 0


## Step 4b: a dirt road from every spawner to the base. A* over grass with water mask 0 (the road tiles have grass on all sides),
## weights `1 + road_wiggle * noise` so roads bend, +4 next to an existing road so runs do not go side by side. Spawners are routed in order and
## each path is cut at the first cell that is already road (or the base), so the roads form a tree. Base and spawner cells become road.
## `paths` receives the ordered cells of each road, spawner first (the merge cell is the last one). Nothing is changed and false is returned
## if a spawner has no route. Road cells are added to `keep` and `protect`.
static func _place_roads(data: MapData, config: MapGenConfig, rng: RandomNumberGenerator, keep: PackedByteArray, protect: PackedByteArray, paths: Array[Array]) -> bool:
	var noise: FastNoiseLite = _make_noise(rng, 0.12)
	var grid: AStarGrid2D = AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, data.size)
	grid.cell_size = Vector2.ONE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var base_weights: PackedFloat32Array = PackedFloat32Array()
	base_weights.resize(data.cells.size())
	for y: int in data.size.y:
		for x: int in data.size.x:
			var cell: Vector2i = Vector2i(x, y)
			var passable: bool = _road_passable(data, cell)
			grid.set_point_solid(cell, not passable)
			base_weights[_index(data, cell)] = 1.0 + maxf(config.road_wiggle, 0.0) * (noise.get_noise_2d(x, y) * 0.5 + 0.5)
	var road: PackedByteArray = PackedByteArray()
	road.resize(data.cells.size())
	var penalised: PackedByteArray = PackedByteArray()
	penalised.resize(data.cells.size())
	for idx: int in base_weights.size():
		grid.set_point_weight_scale(Vector2i(idx % data.size.x, idx / data.size.x), base_weights[idx])
	_mark_road_cell(data, grid, road, penalised, base_weights, data.base_cell)
	var routed: Array[Array] = []
	for spawner: Vector2i in data.spawner_cells:
		var path: Array[Vector2i] = []
		if road[_index(data, spawner)] != 0:
			path.append(spawner)
		else:
			var full: Array[Vector2i] = grid.get_id_path(spawner, data.base_cell)
			if full.is_empty():
				return false
			for cell: Vector2i in full:
				path.append(cell)
				if road[_index(data, cell)] != 0:
					break
		for cell: Vector2i in path:
			_mark_road_cell(data, grid, road, penalised, base_weights, cell)
		routed.append(path)
	for idx: int in road.size():
		if road[idx] != 0:
			data.cells[idx] = MapData.Cell.ROAD
			keep[idx] = 1
			protect[idx] = 1
	paths.append_array(routed)
	return true


## Marks a cell as road in the router's state: it costs its plain weight again and its free side neighbours get the +4 side-by-side penalty (once).
static func _mark_road_cell(data: MapData, grid: AStarGrid2D, road: PackedByteArray, penalised: PackedByteArray, base_weights: PackedFloat32Array, cell: Vector2i) -> void:
	var idx: int = _index(data, cell)
	road[idx] = 1
	grid.set_point_weight_scale(cell, base_weights[idx])
	for dir: Vector2i in _DIRS_4:
		var nb: Vector2i = cell + dir
		if not data.is_in_bounds(nb):
			continue
		var nb_idx: int = _index(data, nb)
		if road[nb_idx] == 0 and penalised[nb_idx] == 0:
			penalised[nb_idx] = 1
			grid.set_point_weight_scale(nb, base_weights[nb_idx] + 4.0)


## Step 6: lamp posts beside the roads. Walking each road from its spawner, the first cell after every `lamp_spacing` steps that has a free
## side neighbour (perpendicular to the travel direction, side order random) gets a LAMP. A lamp sits on plain grass with water
## mask 0 outside the marker keep-outs and has the road cell it stands beside as its only road neighbour.
static func _place_lamps(data: MapData, config: MapGenConfig, rng: RandomNumberGenerator, marker_keep: PackedByteArray, paths: Array[Array]) -> void:
	var spacing: int = maxi(config.lamp_spacing, 1)
	for path: Array in paths:
		var next: int = spacing
		for i: int in range(1, path.size()):
			if i < next:
				continue
			var cell: Vector2i = path[i]
			var dir: Vector2i = cell - (path[i - 1] as Vector2i)
			var side: Vector2i = Vector2i(dir.y, dir.x)
			var first_negative: bool = rng.randf() < 0.5
			var sides: Array[Vector2i] = []
			sides.append_array([-side, side] if first_negative else [side, -side])
			for candidate_side: Vector2i in sides:
				var lamp: Vector2i = cell + candidate_side
				if _lamp_fits(data, lamp, marker_keep):
					data.set_cell(lamp, MapData.Cell.LAMP)
					next = i + spacing
					break


static func _lamp_fits(data: MapData, lamp: Vector2i, marker_keep: PackedByteArray) -> bool:
	if not data.is_in_bounds(lamp) or marker_keep[_index(data, lamp)] != 0:
		return false
	if data.get_cell(lamp) != MapData.Cell.GRASS or data.get_water_mask(lamp) != 0 or data.decor.has(lamp):
		return false
	return _count_road_neighbours(data, lamp) == 1


static func _count_road_neighbours(data: MapData, cell: Vector2i) -> int:
	var count: int = 0
	for dir: Vector2i in _DIRS_4:
		if data.get_cell(cell + dir) == MapData.Cell.ROAD:
			count += 1
	return count
