class_name MapData extends RefCounted

enum Cell { WATER, GRASS, TREE, ROAD, LAMP }

## Bits of the water mask (neighbours that are water).
const N: int = 1
const E: int = 2
const S: int = 4
const W: int = 8
const NW: int = 16
const NE: int = 32
const SE: int = 64
const SW: int = 128

## The 13 normalised masks the tileset can draw for a grass cell.
const _VALID_MASKS: Array[int] = [
	0,
	NW, NE, SE, SW,
	N | NW | NE, E | NE | SE, S | SE | SW, W | SW | NW,
	N | E | NW | NE | SE, E | S | NE | SE | SW, S | W | SE | SW | NW, W | N | SW | NW | NE,
]

var map_seed: int
var size: Vector2i
## Row-major terrain, index = y * size.x + x.
var cells: PackedByteArray
## Cell -> atlas coords of a decoration tile drawn instead of the terrain tile.
var decor: Dictionary[Vector2i, Vector2i] = {}
var base_cell: Vector2i
var spawner_cells: Array[Vector2i] = []
var spawner_first_waves: Array[int] = []
## Attempts generation needed (1-based).
var attempts: int = 1
var used_fallback: bool = false


## Returns true if the cell lies inside the map.
func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


## Returns the terrain of a cell; out of bounds counts as water.
func get_cell(cell: Vector2i) -> Cell:
	if not is_in_bounds(cell):
		return Cell.WATER
	return cells[cell.y * size.x + cell.x] as Cell


## Sets the terrain of a cell (ignored out of bounds).
func set_cell(cell: Vector2i, value: Cell) -> void:
	if is_in_bounds(cell):
		cells[cell.y * size.x + cell.x] = value


## Grass and road cells are walkable; all grass decoration tiles are walkable too. Trees and lamps are not.
func is_walkable(cell: Vector2i) -> bool:
	var value: Cell = get_cell(cell)
	return value == Cell.GRASS or value == Cell.ROAD


## Returns the 4-bit road mask of a cell: N, E, S, W are set where that side neighbour is a road.
func get_road_mask(cell: Vector2i) -> int:
	var mask: int = 0
	if get_cell(cell + Vector2i(0, -1)) == Cell.ROAD:
		mask |= N
	if get_cell(cell + Vector2i(1, 0)) == Cell.ROAD:
		mask |= E
	if get_cell(cell + Vector2i(0, 1)) == Cell.ROAD:
		mask |= S
	if get_cell(cell + Vector2i(-1, 0)) == Cell.ROAD:
		mask |= W
	return mask


## Returns the normalised 8-bit water mask of a cell: a water side also sets its two corners.
func get_water_mask(cell: Vector2i) -> int:
	var mask: int = 0
	if get_cell(cell + Vector2i(0, -1)) == Cell.WATER:
		mask |= N | NW | NE
	if get_cell(cell + Vector2i(1, 0)) == Cell.WATER:
		mask |= E | NE | SE
	if get_cell(cell + Vector2i(0, 1)) == Cell.WATER:
		mask |= S | SE | SW
	if get_cell(cell + Vector2i(-1, 0)) == Cell.WATER:
		mask |= W | SW | NW
	if get_cell(cell + Vector2i(-1, -1)) == Cell.WATER:
		mask |= NW
	if get_cell(cell + Vector2i(1, -1)) == Cell.WATER:
		mask |= NE
	if get_cell(cell + Vector2i(1, 1)) == Cell.WATER:
		mask |= SE
	if get_cell(cell + Vector2i(-1, 1)) == Cell.WATER:
		mask |= SW
	return mask


## Returns true if the normalised mask is one of the 13 shore cases the tileset can draw.
static func is_valid_shore_mask(mask: int) -> bool:
	return mask in _VALID_MASKS
