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
	if not _place_markers(data, config, rng, config.min_spawner_base_distance, config.min_spawner_separation):
		return null
	var keep: PackedByteArray = _build_keep_out(data, config)
	_place_lakes(data, config, rng, keep)
	var protect: PackedByteArray = keep.duplicate()
	if not _cleanup(data, protect):
		return null
	_place_trees(data, config, rng, keep)
	var reached: PackedByteArray = _flood(data, data.base_cell)
	if not _all_spawners_reached(data, reached):
		for spawner: Vector2i in data.spawner_cells:
			if reached[_index(data, spawner)] == 0:
				_carve(data, spawner, data.base_cell, protect)
		if not _cleanup(data, protect):
			return null
		_demote_shore_trees(data)
		reached = _flood(data, data.base_cell)
		if not _all_spawners_reached(data, reached):
			return null
	_fill_pockets(data, reached)
	_place_decor(data, config, rng, keep)
	return data


static func _fallback(config: MapGenConfig, map_seed: int) -> MapData:
	var min_base: int = config.min_spawner_base_distance
	var sep: int = config.min_spawner_separation
	var data: MapData = _new_data(config, map_seed)
	for k: int in _FALLBACK_MAX_TRIES:
		var rng: RandomNumberGenerator = _make_rng(map_seed, config.max_attempts + 1 + k)
		if _place_markers(data, config, rng, min_base, sep):
			break
		if k % 5 == 4:
			min_base >>= 1
			sep >>= 1
		if k == _FALLBACK_MAX_TRIES - 1:
			_place_last_resort(data, config)
	data.attempts = config.max_attempts
	data.used_fallback = true
	return data


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


## Step 1: all grass with a water ring.
static func _new_data(config: MapGenConfig, map_seed: int) -> MapData:
	var data: MapData = MapData.new()
	data.map_seed = map_seed
	data.size = config.size
	data.cells.resize(config.size.x * config.size.y)
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


## Step 2: base and spawners. Returns false if no valid placement was found.
static func _place_markers(data: MapData, config: MapGenConfig, rng: RandomNumberGenerator, min_base: int, sep: int) -> bool:
	var count: int = rng.randi_range(config.spawner_count_min, maxi(config.spawner_count_min, config.spawner_count_max))
	var margin: int = config.base_margin
	for _b: int in _BASE_TRIES:
		var base: Vector2i = Vector2i(
			rng.randi_range(margin, data.size.x - 1 - margin),
			rng.randi_range(margin, data.size.y - 1 - margin))
		var spawners: Array[Vector2i] = []
		for _i: int in count:
			var spawner: Vector2i = _find_spawner_cell(data, config, rng, base, spawners, min_base, sep)
			if spawner.x < 0:
				break
			spawners.append(spawner)
		if spawners.size() == count:
			data.base_cell = base
			data.spawner_cells = spawners
			data.spawner_first_waves.clear()
			for i: int in count:
				data.spawner_first_waves.append(_first_wave_for(config, i))
			return true
	return false


## Returns a valid spawner cell, or (-1, -1) if none was found.
static func _find_spawner_cell(data: MapData, config: MapGenConfig, rng: RandomNumberGenerator, base: Vector2i, others: Array[Vector2i], min_base: int, sep: int) -> Vector2i:
	for _t: int in _SPAWNER_TRIES:
		var cell: Vector2i = _random_edge_cell(data, config, rng)
		if cell == base or (cell - base).length_squared() < min_base * min_base:
			continue
		var ok: bool = true
		for other: Vector2i in others:
			if cell == other or (cell - other).length_squared() < sep * sep:
				ok = false
				break
		if ok:
			return cell
	return Vector2i(-1, -1)


static func _random_edge_cell(data: MapData, config: MapGenConfig, rng: RandomNumberGenerator) -> Vector2i:
	var side: int = rng.randi_range(0, 3)
	var depth: int = rng.randi_range(2, 2 + maxi(config.spawner_edge_band, 1) - 1)
	match side:
		0:
			return Vector2i(depth, rng.randi_range(2, data.size.y - 3))
		1:
			return Vector2i(data.size.x - 1 - depth, rng.randi_range(2, data.size.y - 3))
		2:
			return Vector2i(rng.randi_range(2, data.size.x - 3), depth)
	return Vector2i(rng.randi_range(2, data.size.x - 3), data.size.y - 1 - depth)


## Marks the circles around base and spawners (interior cells only; the water ring is never kept out).
static func _build_keep_out(data: MapData, config: MapGenConfig) -> PackedByteArray:
	var keep: PackedByteArray = PackedByteArray()
	keep.resize(data.cells.size())
	var centers: Array[Vector2i] = [data.base_cell]
	centers.append_array(data.spawner_cells)
	var r: int = config.keep_out_radius
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


## Step 3: lakes from the top noise values.
static func _place_lakes(data: MapData, config: MapGenConfig, rng: RandomNumberGenerator, keep: PackedByteArray) -> void:
	var noise: FastNoiseLite = _make_noise(rng, config.lake_noise_frequency)
	var candidates: Array[int] = []
	for y: int in range(3, data.size.y - 3):
		for x: int in range(3, data.size.x - 3):
			var idx: int = y * data.size.x + x
			if keep[idx] == 0:
				candidates.append(idx)
	var count: int = roundi(config.lake_coverage * (data.size.x - 2) * (data.size.y - 2))
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
	var total: int = roundi(config.tree_coverage * (data.size.x - 2) * (data.size.y - 2))
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
			if keep[idx] == 0 and data.get_cell(cell) == MapData.Cell.GRASS and data.get_water_mask(cell) == 0 \
					and not data.decor.has(cell):
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


## Trees that ended up next to water become plain grass again.
static func _demote_shore_trees(data: MapData) -> void:
	for y: int in range(1, data.size.y - 1):
		for x: int in range(1, data.size.x - 1):
			var cell: Vector2i = Vector2i(x, y)
			if data.get_cell(cell) == MapData.Cell.TREE and data.get_water_mask(cell) != 0:
				data.set_cell(cell, MapData.Cell.GRASS)


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
	_place_farmland(data, config, rng, keep, maxi(total / 10, 1))
	_place_islands(data, rng, roundi(total * 0.2))
	var candidates: Array[int] = _plain_grass_candidates(data, keep)
	for _i: int in mini(roundi(total * 0.6), candidates.size()):
		var pick: int = rng.randi_range(0, candidates.size() - 1)
		var idx: int = candidates[pick]
		data.decor[Vector2i(idx % data.size.x, idx / data.size.x)] = DIRT_DOT
		candidates[pick] = candidates[candidates.size() - 1]
		candidates.remove_at(candidates.size() - 1)


static func _is_plain_free(data: MapData, cell: Vector2i, keep: PackedByteArray) -> bool:
	return data.is_in_bounds(cell) and keep[_index(data, cell)] == 0 \
			and data.get_cell(cell) == MapData.Cell.GRASS and data.get_water_mask(cell) == 0 \
			and not data.decor.has(cell)


static func _place_farmland(data: MapData, config: MapGenConfig, rng: RandomNumberGenerator, keep: PackedByteArray, patches: int) -> void:
	var r: int = config.keep_out_radius
	for _p: int in patches:
		var center: Vector2i = Vector2i(-1, -1)
		for _t: int in 30:
			var cand: Vector2i = data.base_cell + Vector2i(rng.randi_range(-(r + 4), r + 4), rng.randi_range(-(r + 4), r + 4))
			if (cand - data.base_cell).length_squared() > r * r and _is_plain_free(data, cand, keep):
				center = cand
				break
		if center.x < 0:
			continue
		var patch: Array[Vector2i] = [center]
		var wanted: int = rng.randi_range(2, 4)
		for _g: int in 20:
			if patch.size() >= wanted:
				break
			var nb: Vector2i = patch[rng.randi_range(0, patch.size() - 1)] + _DIRS_4[rng.randi_range(0, 3)]
			if not patch.has(nb) and _is_plain_free(data, nb, keep):
				patch.append(nb)
		for cell: Vector2i in patch:
			data.decor[cell] = FARMLAND


static func _place_islands(data: MapData, rng: RandomNumberGenerator, count: int) -> void:
	var candidates: Array[Vector2i] = []
	for y: int in range(1, data.size.y - 1):
		for x: int in range(1, data.size.x - 1):
			var cell: Vector2i = Vector2i(x, y)
			if data.get_cell(cell) == MapData.Cell.WATER and data.get_water_mask(cell) == 255 \
					and not data.decor.has(cell):
				candidates.append(cell)
	for _i: int in mini(count, candidates.size()):
		var pick: int = rng.randi_range(0, candidates.size() - 1)
		data.decor[candidates[pick]] = ISLAND_TILES[rng.randi_range(0, ISLAND_TILES.size() - 1)]
		candidates[pick] = candidates[candidates.size() - 1]
		candidates.remove_at(candidates.size() - 1)
