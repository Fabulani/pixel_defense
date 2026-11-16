class_name TowerPreview extends Node2D

@export var tile_map_layer: TileMapLayer

var _radius: float = 0.0

@onready var _base_ghost: Sprite2D = %BaseGhost
@onready var _turret_ghost: Sprite2D = %TurretGhost


func _ready() -> void:
	visible = false


func _draw() -> void:
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, Color(1, 1, 0, 0.3), 2.0)


## Show the build ghost (base and cannon) of [param type] on the cell, with its range ring.
func show_at(cell: Vector2i, type: TowerType) -> void:
	global_position = tile_map_layer.to_global(tile_map_layer.map_to_local(cell))
	_radius = type.stats.detection_range
	_base_ghost.texture = type.base_texture
	_turret_ghost.texture = type.turret_texture
	_turret_ghost.scale = Vector2.ONE * type.turret_scale
	_base_ghost.visible = true
	_turret_ghost.visible = true
	visible = true
	queue_redraw()


## Show the range ring at a world position with an explicit radius (used for a selected tower).
func show_range(world_position: Vector2, radius: float) -> void:
	global_position = world_position
	_radius = radius
	_base_ghost.visible = false
	_turret_ghost.visible = false
	visible = true
	queue_redraw()


func hide_preview() -> void:
	visible = false
