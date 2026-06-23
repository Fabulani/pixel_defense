class_name HighlightTile extends Node2D

const _TILE_SIZE: int = 16

@onready var _sprite: Sprite2D = $Sprite2D

var _tween: Tween


func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		# Position still tracks via emulated mouse (= touch position).
		# Sprite is hidden; only visible during a flash.
		_sprite.visible = false


func _process(_delta: float) -> void:
	follow_mouse_position()


func follow_mouse_position() -> void:
	var mouse_position: Vector2i = get_global_mouse_position() / _TILE_SIZE
	position = mouse_position * _TILE_SIZE


func flash_denied() -> void:
	if _tween:
		_tween.kill()
	_sprite.visible = true
	_sprite.modulate = Color(1, 0, 0, 0.7)
	_tween = create_tween()
	_tween.tween_property(_sprite, "modulate", Color(1, 1, 1, 0.5), 0.4)
	if DisplayServer.is_touchscreen_available():
		_tween.tween_callback(func() -> void: _sprite.visible = false)
