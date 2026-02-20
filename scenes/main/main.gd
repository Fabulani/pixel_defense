class_name Main extends Node2D

@export var tower_packed_scene : PackedScene = null
@onready var highlight_tile: HighlightTile = $HighlightTile


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		# TODO: tower building. Come back after tileset has custom data eg 'buildable'
		var test_pos := Vector2i(3, 3) 
		place_tower(test_pos)
		
		
func place_tower(cell_position : Vector2i) -> void:
	var new_tower : Node2D = tower_packed_scene.instantiate()
	new_tower.position = cell_position * 16 + Vector2i(8, 8)
	add_child(new_tower)
	# TODO: tower is drawing on top of highlight
