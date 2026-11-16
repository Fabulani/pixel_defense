class_name Main extends Node2D

@onready var current_level: Level = $Level
@onready var building_manager: BuildingManager = $BuildingManager
@onready var input_controller: InputController = $InputController
@onready var tower_preview: TowerPreview = $TowerPreview
@onready var hud: HUD = $HUD
@onready var build_bar: BuildBar = $BuildBar
@onready var camera: PanningCamera = $PanningCamera
@onready var game_end_screen: GameEndScreen = $GameEndScreen
@onready var start_menu: StartMenu = $StartMenu
@onready var highlight_tile: HighlightTile = $HighlightTile
@onready var tower_menu: TowerMenu = $TowerMenu
@onready var vfx: VfxManager = $VfxManager


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
	current_level.wave_started.connect(hud.show_wave_banner)
	current_level.bullet_fired.connect(_on_level_bullet_fired)
	current_level.bullet_hit.connect(_on_level_bullet_hit)
	current_level.enemy_died.connect(_on_level_enemy_died)
	current_level.enemy_count_changed.connect(hud.set_enemy_count)
	building_manager.tower_built.connect(current_level.register_tower)
	building_manager.tower_built.connect(_on_building_manager_tower_built)
	building_manager.tower_placement_denied.connect(highlight_tile.flash_denied)
	input_controller.placement_invalid.connect(_on_input_controller_placement_invalid)
	input_controller.build_requested.connect(building_manager.place_tower)
	game_end_screen.restart_requested.connect(_on_game_end_screen_restart_requested)
	start_menu.start_requested.connect(_on_start_menu_start_requested)

	# Tower selection and upgrades
	input_controller.tower_selected.connect(_on_input_controller_tower_selected)
	input_controller.tower_deselected.connect(_on_input_controller_tower_deselected)
	tower_menu.upgrade_requested.connect(building_manager.upgrade_tower)
	tower_menu.major_requested.connect(building_manager.apply_major_upgrade)
	tower_menu.sell_requested.connect(building_manager.sell_tower)
	building_manager.tower_upgraded.connect(_on_building_manager_tower_upgraded)
	building_manager.tower_sold.connect(_on_building_manager_tower_sold)
	building_manager.upgrade_denied.connect(highlight_tile.flash_denied)

	# Build bar
	build_bar.set_tower_types(building_manager.tower_types)
	build_bar.tower_type_selected.connect(_on_build_bar_tower_type_selected)
	build_bar.tower_type_deselected.connect(_on_build_bar_tower_type_deselected)

	hud.set_wave(current_level.waves_survived)
	hud.set_enemy_count(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("f1"):
		get_tree().reload_current_scene()


func _on_level_lost() -> void:
	camera.shake(0.7)
	_close_tower_ui()
	game_end_screen.show_defeat(current_level.waves_survived, CurrencyManager.coins)


func _on_level_bullet_fired(data: ProjectileData) -> void:
	vfx.play_muzzle(data.origin, data.angle, data.color)


func _on_level_bullet_hit(hit_position: Vector2, direction: Vector2, data: ProjectileData) -> void:
	vfx.play_impact(hit_position, direction, data.color)


func _on_level_enemy_died(death_position: Vector2, coins: int, color: Color) -> void:
	vfx.play_death(death_position, color)
	vfx.play_coin_popup(death_position, coins)


func _on_level_won() -> void:
	_close_tower_ui()
	game_end_screen.show_victory(current_level.waves_survived, CurrencyManager.coins)


func _on_game_end_screen_restart_requested() -> void:
	get_tree().reload_current_scene()


func _on_start_menu_start_requested() -> void:
	current_level.start()


func _on_building_manager_tower_built(tower: Tower, _cell: Vector2i) -> void:
	tower.play_placed()
	vfx.play_tower_built(tower.global_position)
	input_controller.cancel_preview()


func _on_input_controller_placement_invalid(_cell: Vector2i) -> void:
	highlight_tile.flash_denied()


func _on_input_controller_tower_selected(tower: Tower) -> void:
	# InputController hides the build ghost before emitting, so the ring is shown last.
	tower_menu.show_for(tower)
	tower_preview.show_range(tower.global_position, tower.get_range())


func _on_input_controller_tower_deselected() -> void:
	# The build ghost shares TowerPreview: only hide it when a tower ring is showing.
	if tower_menu.get_tower() == null:
		return
	tower_menu.hide_menu()
	tower_preview.hide_preview()


func _on_build_bar_tower_type_selected(type: TowerType) -> void:
	# Closing the tower UI also hides the ring; cancel_preview in set_build_type hides the ghost.
	if tower_menu.get_tower() != null:
		tower_menu.hide_menu()
		tower_preview.hide_preview()
	input_controller.set_build_type(type)


func _on_build_bar_tower_type_deselected() -> void:
	input_controller.set_build_type(null)


func _on_building_manager_tower_upgraded(tower: Tower) -> void:
	vfx.play_tower_upgraded(tower.global_position)
	if tower_menu.get_tower() != tower:
		return
	tower_menu.refresh()
	tower_preview.show_range(tower.global_position, tower.get_range())


func _on_building_manager_tower_sold(tower: Tower, cell_position: Vector2i) -> void:
	current_level.unregister_tower(tower, cell_position)
	tower_menu.hide_menu()
	tower_preview.hide_preview()


func _close_tower_ui() -> void:
	tower_menu.hide_menu()
	input_controller.cancel_preview()
	build_bar.deselect()
