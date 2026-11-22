extends CanvasLayer
## Debug-build overlay: right-side drawer with collapsible sections for set-up situations.
## Created by Main in debug builds only; Main calls [method setup] after add_child.

const Context = preload("res://debug/debug_context.gd")
const ExtraWaveSpawner = preload("res://debug/extra_wave_spawner.gd")
const Section = preload("res://debug/sections/debug_section.gd")
const GameSection = preload("res://debug/sections/game_section.gd")
const WavesSection = preload("res://debug/sections/waves_section.gd")
const EnemiesSection = preload("res://debug/sections/enemies_section.gd")
const TowersSection = preload("res://debug/sections/towers_section.gd")
const TimeSection = preload("res://debug/sections/time_section.gd")
const VfxSection = preload("res://debug/sections/vfx_section.gd")

const PANEL_WIDTH: float = 200.0
const FONT_SIZE: int = 14
const TOP_MARGIN_RATIO: float = 0.25
const BOTTOM_MARGIN: float = 32.0
const POLL_INTERVAL_MS: int = 200
## Width and height of the DBG tab on the sidebar's left edge (touch-sized).
const TAB_SIZE: Vector2 = Vector2(44.0, 64.0)
## Seconds the sidebar takes to slide in or out (real time, ignores the time scale).
const SLIDE_TIME: float = 0.2

var _context: Context
var _sections: Array[Section] = []
var _extra_wave_spawner: ExtraWaveSpawner
var _toggle_button: Button
## Tab + panel; slides so only the tab shows while closed.
var _drawer: HBoxContainer
var _slide_tween: Tween
var _open: bool = false
var _last_poll_ms: int = 0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if not _open:
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_poll_ms < POLL_INTERVAL_MS:
		return
	_last_poll_ms = now
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug>toggle"):
		_set_menu_visible(not _open)
		get_viewport().set_input_as_handled()


## Stores the game references, builds the UI and applies the saved toggles.
func setup(level: Level, building_manager: BuildingManager, tower_menu: TowerMenu, vfx: VfxManager, camera: PanningCamera) -> void:
	_context = Context.new()
	_context.level = level
	_context.building_manager = building_manager
	_context.tower_menu = tower_menu
	_context.vfx = vfx
	_context.camera = camera
	# The menu runs ALWAYS; PAUSABLE so extra waves pause with the game.
	_extra_wave_spawner = ExtraWaveSpawner.new()
	_extra_wave_spawner.process_mode = Node.PROCESS_MODE_PAUSABLE
	_extra_wave_spawner.setup(_context)
	add_child(_extra_wave_spawner)
	_context.extra_wave_spawner = _extra_wave_spawner
	_build_ui()
	building_manager.tower_upgraded.connect(_on_building_manager_tower_upgraded)
	_set_menu_visible(false, false)


func _build_ui() -> void:
	var theme: Theme = Theme.new()
	theme.default_font_size = FONT_SIZE

	# Drawer anchored to the right edge: [DBG tab][panel]. Closed, the panel sits off-screen.
	_drawer = HBoxContainer.new()
	_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drawer.add_theme_constant_override("separation", 0)
	_drawer.anchor_left = 1.0
	_drawer.anchor_right = 1.0
	_drawer.anchor_top = TOP_MARGIN_RATIO
	_drawer.anchor_bottom = 1.0
	_drawer.offset_top = 0.0
	_drawer.offset_bottom = -BOTTOM_MARGIN
	add_child(_drawer)

	_toggle_button = Button.new()
	_toggle_button.text = "DBG"
	_toggle_button.focus_mode = Control.FOCUS_NONE
	_toggle_button.theme = theme
	_toggle_button.custom_minimum_size = TAB_SIZE
	_toggle_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_toggle_button.pressed.connect(_on_toggle_button_pressed)
	_drawer.add_child(_toggle_button)

	var panel: PanelContainer = PanelContainer.new()
	panel.theme = theme
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size.x = PANEL_WIDTH
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_drawer.add_child(panel)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)

	_add_section(column, "Game", GameSection)
	_add_section(column, "Waves", WavesSection)
	_add_section(column, "Enemies", EnemiesSection)
	_add_section(column, "Towers", TowersSection)
	_add_section(column, "Time", TimeSection)
	_add_section(column, "VFX", VfxSection)


func _add_section(parent: Control, title: String, script: GDScript) -> void:
	var section: Section = script.new() as Section
	parent.add_child(section)
	section.setup(title, _context)
	_sections.append(section)


## Slides the sidebar open (tab on its left edge) or closed (only the tab at the screen's right edge).
func _set_menu_visible(shown: bool, animate: bool = true) -> void:
	_open = shown
	var left: float = -(TAB_SIZE.x + PANEL_WIDTH) if shown else -TAB_SIZE.x
	var right: float = 0.0 if shown else PANEL_WIDTH
	if _slide_tween != null:
		_slide_tween.kill()
	if animate:
		# Bound to this node (PROCESS_MODE_ALWAYS), so it also runs while the tree is paused.
		_slide_tween = create_tween().set_parallel(true).set_ignore_time_scale(true)
		_slide_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_slide_tween.tween_property(_drawer, "offset_left", left, SLIDE_TIME)
		_slide_tween.tween_property(_drawer, "offset_right", right, SLIDE_TIME)
	else:
		_drawer.offset_left = left
		_drawer.offset_right = right
	if shown:
		_refresh()


func _refresh() -> void:
	for section: Section in _sections:
		section.refresh()


func _on_toggle_button_pressed() -> void:
	_set_menu_visible(not _open)


func _on_building_manager_tower_upgraded(_tower: Tower) -> void:
	if _open:
		_refresh()
