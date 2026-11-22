class_name HighlightTile extends Node2D

@onready var _sprite: Sprite2D = $Sprite2D

var _tween: Tween
## True while the last real pointer input was a touch; the crosshair is then hidden.
var _using_touch: bool = false
var _flashing: bool = false


func _ready() -> void:
	# Follows the pointer and flashes while paused too (building and selecting work while paused).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_using_touch = DisplayServer.is_touchscreen_available()
	_sprite.visible = not _using_touch


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_using_touch = true
		if not _flashing:
			_sprite.visible = false
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		_using_touch = false
		_sprite.visible = true


func _process(_delta: float) -> void:
	follow_mouse_position()


## Snaps the highlight to the tile under the (possibly touch-emulated) pointer.
func follow_mouse_position() -> void:
	var cell_size: Vector2i = GameData.grid_cell_size
	if cell_size.x <= 0 or cell_size.y <= 0:
		return
	var cell: Vector2i = Vector2i((get_global_mouse_position() / Vector2(cell_size)).floor())
	position = Vector2(cell * cell_size)


func flash_denied() -> void:
	if _tween:
		_tween.kill()
	_flashing = true
	_sprite.visible = true
	_sprite.modulate = Color(1, 0, 0, 0.7)
	_tween = create_tween()
	_tween.tween_property(_sprite, "modulate", Color(1, 1, 1, 0.5), 0.4)
	_tween.tween_callback(_on_flash_finished)


func _on_flash_finished() -> void:
	_flashing = false
	if _using_touch:
		_sprite.visible = false
