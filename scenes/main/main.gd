class_name Main extends Node2D


@onready var highlight_tile: HighlightTile = $HighlightTile


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		print("click")
		# TODO: tower building. Come back after tileset has custom data eg 'buildable'
	
