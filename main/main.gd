class_name Main extends Node2D

@onready var current_level: Level = $Level
@onready var building_manager: BuildingManager = $BuildingManager
@onready var input_controller: InputController = $InputController
@onready var tower_preview: TowerPreview = $TowerPreview
@onready var hud: HUD = $HUD
@onready var camera: PanningCamera = $PanningCamera
@onready var game_end_screen: GameEndScreen = $GameEndScreen
@onready var start_menu: StartMenu = $StartMenu
@onready var highlight_tile: HighlightTile = $HighlightTile


func _ready() -> void:
	# Wire cross-scene dependencies explicitly
	building_manager.level = current_level
	input_controller.tile_map_layer = current_level.tile_map_layer
	input_controller.touch_controls = camera.touch_controls
	input_controller.kbm_controls = camera.kbm_controls
	input_controller.tower_preview = tower_preview
	input_controller.building_manager = building_manager
	input_controller.setup()
	tower_preview.tile_map_layer = current_level.tile_map_layer

	# Game signals
	current_level.lost.connect(_on_level_lost)
	current_level.won.connect(_on_level_won)
	current_level.wave_started.connect(hud.set_wave)
	current_level.enemy_count_changed.connect(hud.set_enemy_count)
	building_manager.tower_built.connect(current_level.register_tower)
	building_manager.tower_built.connect(_on_building_manager_tower_built)
	building_manager.tower_placement_denied.connect(highlight_tile.flash_denied)
	input_controller.placement_invalid.connect(_on_input_controller_placement_invalid)
	input_controller.build_requested.connect(building_manager.place_tower)
	game_end_screen.restart_requested.connect(_on_game_end_screen_restart_requested)
	start_menu.start_requested.connect(_on_start_menu_start_requested)

	hud.set_wave(current_level.waves_survived)
	hud.set_enemy_count(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("f1"):
		get_tree().reload_current_scene()


func _on_level_lost() -> void:
	game_end_screen.show_defeat(current_level.waves_survived, CurrencyManager.coins)


func _on_level_won() -> void:
	game_end_screen.show_victory(current_level.waves_survived, CurrencyManager.coins)


func _on_game_end_screen_restart_requested() -> void:
	get_tree().reload_current_scene()


func _on_start_menu_start_requested() -> void:
	current_level.start()


func _on_building_manager_tower_built(_tower: Tower, _cell: Vector2i) -> void:
	input_controller.cancel_preview()


func _on_input_controller_placement_invalid(_cell: Vector2i) -> void:
	highlight_tile.flash_denied()
