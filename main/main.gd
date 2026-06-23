class_name Main extends Node2D

@onready var current_level: Level = $Level
@onready var building_manager: BuildingManager = $BuildingManager
@onready var input_controller: InputController = $InputController
@onready var tower_preview: TowerPreview = $TowerPreview
@onready var hud: HUD = $HUD
@onready var camera: PanningCamera = $PanningCamera
@onready var game_over_screen: GameOverScreen = $GameOverScreen
@onready var start_menu: StartMenu = $StartMenu
@onready var highlight_tile: HighlightTile = $HighlightTile


func _ready() -> void:
	# Wire cross-scene dependencies explicitly
	building_manager.level_layer = current_level
	input_controller.tile_map_layer = current_level.tile_map_layer
	input_controller.touch_controls = camera.touch_controls
	input_controller.kbm_controls = camera.kbm_controls
	input_controller.tower_preview = tower_preview
	input_controller.building_manager = building_manager
	input_controller.setup()
	tower_preview.tile_map_layer = current_level.tile_map_layer

	# Game signals
	current_level.player_base.game_over.connect(_on_game_over)
	current_level.wave_manager.all_waves_done.connect(_on_game_win)
	building_manager.tower_built.connect(current_level._on_building_manager_tower_built)
	building_manager.tower_built.connect(_on_tower_built)
	building_manager.tower_placement_denied.connect(highlight_tile.flash_denied)
	input_controller.placement_invalid.connect(_on_placement_invalid)
	input_controller.build_requested.connect(building_manager.place_tower)
	game_over_screen.restart_requested.connect(_on_restart)
	start_menu.start_requested.connect(_on_start)

	# TODO: refactor this to avoid coupling. Signal bus or something?
	var wave_manager: WaveManager = current_level.wave_manager
	wave_manager.wave_started.connect(hud.set_wave)
	hud.set_wave(wave_manager.wave_index)

	# TODO: refactor this to avoid coupling
	var enemy_spawner: EnemySpawner = current_level.enemy_spawner
	enemy_spawner.alive_count_changed.connect(hud.set_enemy_count)
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


func _on_tower_built(_tower: Tower, _cell: Vector2i) -> void:
	input_controller.cancel_preview()


func _on_placement_invalid(_cell: Vector2i) -> void:
	highlight_tile.flash_denied()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("f1"):
		get_tree().reload_current_scene()
