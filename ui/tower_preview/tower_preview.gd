class_name TowerPreview extends Node2D

@export var tile_map_layer: TileMapLayer

const _TOWER_STATS: TowerStats = preload("res://entities/towers/stats/tower_stats.tres")


func _ready() -> void:
	visible = false


func _draw() -> void:
	draw_arc(Vector2.ZERO, _TOWER_STATS.detection_range, 0.0, TAU, 64, Color(1, 1, 0, 0.3), 2.0)


func show_at(cell: Vector2i) -> void:
	global_position = tile_map_layer.to_global(tile_map_layer.map_to_local(cell))
	visible = true
	queue_redraw()


func hide_preview() -> void:
	visible = false
