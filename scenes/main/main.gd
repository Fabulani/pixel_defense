class_name Main extends Node2D

@export var building_manager : BuildingManager = null
@export var tower_packed_scene : PackedScene = null
@onready var tile_map_layer: TileMapLayer = $Level/TileMapLayer

@onready var current_level := $Level

func _ready() -> void:
	current_level.get_node("PlayerBase").game_over.connect(_on_game_over)

func _on_game_over() -> void:
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		var cell_position : Vector2i = tile_map_layer.local_to_map(tile_map_layer.get_local_mouse_position())
		building_manager.place_tower(cell_position, tower_packed_scene)
	if event.is_action_pressed("f1"):
		print_debug("Restart")
		get_tree().reload_current_scene()
