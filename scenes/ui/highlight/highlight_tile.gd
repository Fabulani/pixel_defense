class_name HighlightTile extends Node2D

const _TILE_SIZE : int = 16

func _process(_delta: float) -> void:
	follow_mouse_position()

func follow_mouse_position() -> void:
	var mouse_position: Vector2i = get_global_mouse_position() / _TILE_SIZE
	
	self.position = mouse_position * _TILE_SIZE
	
