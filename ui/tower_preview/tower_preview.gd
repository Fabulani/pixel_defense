class_name TowerPreview extends Node2D

@export var tile_map_layer: TileMapLayer

const _TOWER_STATS: TowerStats = preload("res://entities/towers/stats/tower_stats.tres")

var _radius: float = _TOWER_STATS.detection_range

@onready var _base_ghost: Sprite2D = %BaseGhost
@onready var _turret_ghost: Sprite2D = %TurretGhost


func _ready() -> void:
	visible = false


func _draw() -> void:
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, Color(1, 1, 0, 0.3), 2.0)


## Show the build ghost (base and cannon) on the cell, with its range ring.
func show_at(cell: Vector2i) -> void:
	global_position = tile_map_layer.to_global(tile_map_layer.map_to_local(cell))
	_radius = _TOWER_STATS.detection_range
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
