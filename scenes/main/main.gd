class_name Main extends Node2D

@export var building_manager : BuildingManager
@onready var tile_map_layer: TileMapLayer = $Level/TileMapLayer

var tower_packed_scene := preload("res://scenes/towers/tower_basic.tscn")

@onready var current_level := $Level
@onready var hud: HUD = $HUD
@onready var game_over_screen: GameOverScreen = $GameOverScreen
@onready var start_menu: StartMenu = $StartMenu

func _ready() -> void:
	current_level.get_node("PlayerBase").game_over.connect(_on_game_over)
	current_level.wave_manager.all_waves_done.connect(_on_game_win)
	building_manager.new_tower_built.connect(current_level._on_building_manager_new_tower_built)
	game_over_screen.restart_requested.connect(_on_restart)
	start_menu.start_requested.connect(_on_start)
	
	# TODO: refactor this to avoid coupling. Signal bus or something?
	var wave_manager: WaveManager = current_level.wave_manager
	wave_manager.wave_started.connect(hud.set_wave)
	hud.set_wave(wave_manager.wave_index)
	
	# TODO: refactor this to avoid coupling
	var enemy_spawner: EnemySpawner = current_level.enemy_spawner
	enemy_spawner.enemy_count_changed.connect(hud.set_enemy_count)
	hud.set_enemy_count(0)

func _on_game_over() -> void:
	var waves_survived: int = current_level.wave_manager.wave_index
	game_over_screen.show_game_over(waves_survived, CurrencyManager.coins)

func _on_game_win() -> void:
	var waves_survived: int = current_level.wave_manager.wave_index
	game_over_screen.show_win(waves_survived, CurrencyManager.coins)

func _on_restart() -> void:
	get_tree().reload_current_scene()

func _on_start() -> void:
	current_level.wave_manager.start_next_wave()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		var cell_position : Vector2i = tile_map_layer.local_to_map(tile_map_layer.get_local_mouse_position())
		building_manager.place_tower(cell_position, tower_packed_scene)
	if event.is_action_pressed("f1"):
		print_debug("Restart")
		get_tree().reload_current_scene()
