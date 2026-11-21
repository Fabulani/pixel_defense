class_name MapPainter extends RefCounted

const TERRAIN_SET: int = 0
const TERRAIN_GRASS: int = 0
const TERRAIN_WATER: int = 1
const TERRAIN_DIRT: int = 2

const WATER_TILE: Vector2i = Vector2i(6, 3)
const TREE_TILES: Array[Vector2i] = [Vector2i(0, 3), Vector2i(0, 4), Vector2i(0, 5)]
const PLAIN_GRASS_TILE: Vector2i = Vector2i(2, 4)
const LAMP_TILE: Vector2i = Vector2i(0, 9)
## Road cell with no road neighbour (a dirt patch).
const ISOLATED_ROAD_TILE: Vector2i = Vector2i(3, 9)

const _CUSTOM_DATA_BUILDABLE: String = "buildable"
const _SIDES: Array[TileSet.CellNeighbor] = [
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
]
## Mask bit of each entry of _SIDES.
const _BITS: Array[int] = [
	MapData.N, MapData.E, MapData.S, MapData.W,
	MapData.NW, MapData.NE, MapData.SE, MapData.SW,
]


## Writes the whole map into the layer. The same map always looks the same.
static func paint(layer: TileMapLayer, data: MapData) -> void:
	var tile_set: TileSet = layer.tile_set
	var source_id: int = tile_set.get_source_id(0)
	var source: TileSetAtlasSource = tile_set.get_source(source_id) as TileSetAtlasSource
	var shore_tiles: Dictionary[int, Array] = _build_shore_lookup(source)
	var road_tiles: Dictionary[int, Vector2i] = _build_road_lookup(source)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = data.map_seed
	var reported: bool = false
	var road_reported: bool = false
	for y: int in data.size.y:
		for x: int in data.size.x:
			var cell: Vector2i = Vector2i(x, y)
			var atlas: Vector2i
			var kind: MapData.Cell = data.get_cell(cell)
			if kind == MapData.Cell.ROAD:
				var road_mask: int = data.get_road_mask(cell)
				if road_mask == 0:
					atlas = ISOLATED_ROAD_TILE
				elif road_tiles.has(road_mask):
					atlas = road_tiles[road_mask]
				else:
					if not road_reported:
						push_error("MapPainter: no road tile for mask %d at cell %s." % [road_mask, cell])
						road_reported = true
					atlas = ISOLATED_ROAD_TILE
			elif kind == MapData.Cell.LAMP:
				atlas = LAMP_TILE
			elif data.decor.has(cell):
				atlas = data.decor[cell]
			else:
				match kind:
					MapData.Cell.WATER:
						atlas = WATER_TILE
					MapData.Cell.TREE:
						atlas = TREE_TILES[rng.randi() % TREE_TILES.size()]
					_:
						var mask: int = data.get_water_mask(cell)
						if shore_tiles.has(mask):
							var options: Array = shore_tiles[mask]
							atlas = options[rng.randi() % options.size()]
						else:
							if not reported:
								push_error("MapPainter: no tile for mask %d at cell %s." % [mask, cell])
								reported = true
							atlas = PLAIN_GRASS_TILE
			layer.set_cell(cell, source_id, atlas)


## Maps each water mask to the buildable grass tiles that draw it.
static func _build_shore_lookup(source: TileSetAtlasSource) -> Dictionary[int, Array]:
	var lookup: Dictionary[int, Array] = {}
	for i: int in source.get_tiles_count():
		var coords: Vector2i = source.get_tile_id(i)
		var tile_data: TileData = source.get_tile_data(coords, 0)
		if tile_data.terrain_set != TERRAIN_SET or tile_data.terrain != TERRAIN_GRASS:
			continue
		if tile_data.get_custom_data(_CUSTOM_DATA_BUILDABLE) != true:
			continue
		var mask: int = 0
		var valid: bool = true
		for k: int in _SIDES.size():
			var terrain: int = tile_data.get_terrain_peering_bit(_SIDES[k])
			if terrain == TERRAIN_WATER:
				mask |= _BITS[k]
			elif terrain != TERRAIN_GRASS:
				valid = false
				break
		if not valid:
			continue
		if not lookup.has(mask):
			lookup[mask] = [] as Array[Vector2i]
		lookup[mask].append(coords)
	return lookup


## Maps each 4-bit road mask (N=1, E=2, S=4, W=8) to the dirt tile that draws it. Only the side peering bits count; mask 0 is not mapped.
static func _build_road_lookup(source: TileSetAtlasSource) -> Dictionary[int, Vector2i]:
	var lookup: Dictionary[int, Vector2i] = {}
	for i: int in source.get_tiles_count():
		var coords: Vector2i = source.get_tile_id(i)
		var tile_data: TileData = source.get_tile_data(coords, 0)
		if tile_data.terrain_set != TERRAIN_SET or tile_data.terrain != TERRAIN_DIRT:
			continue
		var mask: int = 0
		for k: int in 4:
			if tile_data.get_terrain_peering_bit(_SIDES[k]) == TERRAIN_DIRT:
				mask |= _BITS[k]
		if mask != 0 and not lookup.has(mask):
			lookup[mask] = coords
	return lookup
