class_name InputController extends Node

signal build_requested(cell_position: Vector2i)
signal placement_invalid(cell_position: Vector2i)

@export var tile_map_layer: TileMapLayer
@export var touch_controls: TouchControls
@export var kbm_controls: KBMControls
@export var tower_preview: TowerPreview
@export var building_manager: BuildingManager

var _preview_cell: Vector2i = Vector2i(-1, -1)


func setup() -> void:
	if touch_controls == null or kbm_controls == null:
		return
	if DisplayServer.is_touchscreen_available():
		touch_controls.tapped.connect(_on_tapped)
	else:
		kbm_controls.clicked.connect(_on_clicked)


func _on_tapped(position: Vector2) -> void:
	_handle_cell_input(_get_cell_at_screen_pos(position))


func _on_clicked(position: Vector2) -> void:
	_handle_cell_input(_get_cell_at_screen_pos(position))


func _handle_cell_input(cell: Vector2i) -> void:
	if _preview_cell == cell:
		build_requested.emit(cell)
		# Ghost stays until build is confirmed or until user taps a different tile.
		return

	if not building_manager.check_valid_tower_placement(cell):
		cancel_preview()
		placement_invalid.emit(cell)
		return

	_preview_cell = cell
	tower_preview.show_at(cell)


func cancel_preview() -> void:
	_preview_cell = Vector2i(-1, -1)
	tower_preview.hide_preview()


## Convert viewport/screen position to TileMapLayer cell coordinates.
func _get_cell_at_screen_pos(screen_pos: Vector2) -> Vector2i:
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var local_pos: Vector2 = tile_map_layer.to_local(world_pos)
	return tile_map_layer.local_to_map(local_pos)
