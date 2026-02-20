class_name Main extends Node2D

@export var tower_packed_scene : PackedScene = null
@onready var tile_map_layer: TileMapLayer = $Level/BG/TileMapLayer
@onready var highlight_tile: HighlightTile = $HighlightTile

const IS_BUILDABLE : String = "buildable"
const CELL_SIZE : int = 16

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		var cell_position : Vector2i = tile_map_layer.local_to_map(tile_map_layer.get_local_mouse_position())
		var cell_data = tile_map_layer.get_cell_tile_data(cell_position).get_custom_data(IS_BUILDABLE)

		if cell_data == true:
			place_tower(cell_position)
		
		
func place_tower(cell_position : Vector2i) -> void:
	var new_tower : Node2D = tower_packed_scene.instantiate()
	new_tower.position = cell_position * CELL_SIZE + Vector2i(CELL_SIZE/2, CELL_SIZE/2)
	add_child(new_tower)
