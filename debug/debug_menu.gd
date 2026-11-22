class_name DebugMenu extends CanvasLayer
## Debug-build overlay: right-side column of collapsible sections for set-up situations.
## Created by Main in debug builds only. Calls only the public API of the injected refs.

const ENEMY_DIR: String = "res://entities/enemies/"
const PANEL_WIDTH: float = 200.0
const FONT_SIZE: int = 14
const TOP_MARGIN_RATIO: float = 0.25
const BOTTOM_MARGIN: float = 32.0
const BUDGET_SCALES: Array[float] = [0.5, 1.0, 2.0, 4.0, 8.0]
const TIME_SCALES: Array[float] = [0.1, 0.25, 0.5, 1.0, 2.0, 4.0]
const HP_RATIOS: Array[float] = [1.0, 0.75, 0.5, 0.25, 0.1]
const POLL_INTERVAL_MS: int = 200
## Spawn delay (s) used by the "Spawn delay" toggle instead of the wave's own delay.
const FAST_SPAWN_DELAY: float = 0.05
## Width and height of the DBG tab on the sidebar's left edge (touch-sized).
const TAB_SIZE: Vector2 = Vector2(44.0, 64.0)
## Seconds the sidebar takes to slide in or out (real time, ignores the time scale).
const SLIDE_TIME: float = 0.2

# Kept across reload_current_scene() (F1 / restart).
static var god_mode: bool = false
static var budget_scale: float = 1.0
static var countdown_held: bool = false
static var fast_spawn: bool = false
static var freeze_enemies: bool = false
static var invulnerable_enemies: bool = false
static var hold_fire: bool = false
static var time_scale: float = 1.0
static var open_sections: Dictionary[String, bool] = {}
static var enemy_name: String = ""
static var enemy_count: int = 1
static var spawn_location: int = 0
static var wave_number: int = 1

var level: Level
var building_manager: BuildingManager
var tower_menu: TowerMenu
var vfx: VfxManager
var camera: PanningCamera

var _panel: PanelContainer
var _toggle_button: Button
## Tab + panel; slides so only the tab shows while closed.
var _drawer: HBoxContainer
var _slide_tween: Tween
var _open: bool = false
var _enemy_scenes: Array[PackedScene] = []
var _enemy_option: OptionButton
var _location_option: OptionButton
var _count_spin: SpinBox
var _wave_spin: SpinBox
var _budget_button: Button
var _tower_label: Label
var _tower_level_buttons: Array[Button] = []
var _major_option: OptionButton
var _shown_tower: Tower
var _time_buttons: Dictionary[float, Button] = {}
var _pause_button: Button
var _step_button: Button
var _step_10_button: Button
var _stepping: bool = false
var _last_poll_ms: int = 0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	building_manager.tower_upgraded.connect(_on_building_manager_tower_upgraded)
	_apply_saved_state()
	_set_menu_visible(false, false)


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


func _apply_saved_state() -> void:
	level.set_god_mode(god_mode)
	level.set_budget_scale(budget_scale)
	level.set_countdown_held(countdown_held)
	level.set_spawn_delay_override(FAST_SPAWN_DELAY if fast_spawn else 0.0)
	building_manager.set_hold_fire(hold_fire)
	Engine.time_scale = time_scale


# --- UI construction ---

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

	_panel = PanelContainer.new()
	_panel.theme = theme
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.custom_minimum_size.x = PANEL_WIDTH
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_drawer.add_child(_panel)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)

	_build_game_section(_add_section(column, "Game"))
	_build_waves_section(_add_section(column, "Waves"))
	_build_enemies_section(_add_section(column, "Enemies"))
	_build_towers_section(_add_section(column, "Towers"))
	_build_time_section(_add_section(column, "Time"))
	_build_vfx_section(_add_section(column, "VFX"))


func _add_section(parent: Control, title: String) -> VBoxContainer:
	var header: Button = Button.new()
	header.focus_mode = Control.FOCUS_NONE
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	parent.add_child(header)
	var content: VBoxContainer = VBoxContainer.new()
	parent.add_child(content)
	var update: Callable = func(open: bool) -> void:
		header.text = "%s %s" % ["▾" if open else "▸", title]
		content.visible = open
	header.pressed.connect(func() -> void:
		var open: bool = not content.visible
		open_sections[title] = open
		update.call(open)
		if open:
			_refresh())
	update.call(open_sections.get(title, false))
	return content


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _add_toggle(parent: Control, text: String, initial: bool, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.button_pressed = initial
	button.toggled.connect(callback)
	parent.add_child(button)
	return button


func _add_flow(parent: Control) -> HFlowContainer:
	var flow: HFlowContainer = HFlowContainer.new()
	parent.add_child(flow)
	return flow


func _add_spin(parent: Control, min_value: int, max_value: int, value: int) -> SpinBox:
	var spin: SpinBox = SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = 1
	spin.value = clampi(value, min_value, max_value)
	spin.focus_mode = Control.FOCUS_NONE
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(spin)
	return spin


func _add_option(parent: Control) -> OptionButton:
	var option: OptionButton = OptionButton.new()
	option.focus_mode = Control.FOCUS_NONE
	option.fit_to_longest_item = false
	option.clip_text = true
	parent.add_child(option)
	return option


func _build_game_section(box: VBoxContainer) -> void:
	_add_toggle(box, "God mode", god_mode, _on_god_mode_toggled)
	_add_button(box, "+9999 coins", _on_coins_pressed)


func _build_waves_section(box: VBoxContainer) -> void:
	var max_waves: int = level.get_max_waves()
	_wave_spin = _add_spin(box, 1, max_waves, wave_number)
	_wave_spin.value_changed.connect(_on_wave_spin_value_changed)
	_add_button(box, "Spawn wave", _on_spawn_wave_pressed)
	_add_button(box, "Jump to wave", _on_jump_wave_pressed)
	_budget_button = _add_button(box, "", _on_budget_pressed)
	_update_budget_text()
	_add_toggle(box, "Hold countdown", countdown_held, _on_hold_countdown_toggled)
	_add_toggle(box, "Spawn delay %s" % FAST_SPAWN_DELAY, fast_spawn, _on_fast_spawn_toggled)
	_add_button(box, "Clear enemies", _on_kill_all_pressed)


func _build_enemies_section(box: VBoxContainer) -> void:
	_enemy_option = _add_option(box)
	var names: Array[String] = []
	_scan_enemy_scenes(names)
	for i: int in _enemy_scenes.size():
		_enemy_option.add_item(names[i])
	var selected: int = maxi(names.find(enemy_name), 0)
	if not names.is_empty():
		_enemy_option.select(selected)
	_enemy_option.item_selected.connect(_on_enemy_option_item_selected)

	_count_spin = _add_spin(box, 1, 50, enemy_count)
	_count_spin.value_changed.connect(_on_count_spin_value_changed)

	_location_option = _add_option(box)
	for i: int in level.get_spawner_count():
		_location_option.add_item("Spawner %d" % (i + 1))
	_location_option.add_item("View centre")
	_location_option.select(clampi(spawn_location, 0, _location_option.item_count - 1))
	_location_option.item_selected.connect(_on_location_option_item_selected)

	_add_button(box, "Spawn", _on_spawn_pressed)
	_add_toggle(box, "Freeze", freeze_enemies, _on_freeze_toggled)
	_add_toggle(box, "Invulnerable", invulnerable_enemies, _on_invulnerable_toggled)
	var hp_flow: HFlowContainer = _add_flow(box)
	for ratio: float in HP_RATIOS:
		_add_button(hp_flow, "HP %d%%" % roundi(ratio * 100.0), _on_hp_pressed.bind(ratio))
	var action_flow: HFlowContainer = _add_flow(box)
	_add_button(action_flow, "Hit 1", _on_hit_pressed)
	_add_button(action_flow, "Kill all", _on_kill_all_pressed)
	var attach_flow: HFlowContainer = _add_flow(box)
	_add_button(attach_flow, "Smoke", _on_attach_pressed.bind(DamageSmoke))
	_add_button(attach_flow, "Regen", _on_attach_pressed.bind(Regeneration))
	_add_button(attach_flow, "Dash", _on_attach_pressed.bind(Dash))


func _build_towers_section(box: VBoxContainer) -> void:
	_tower_label = Label.new()
	_tower_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tower_label.custom_minimum_size.x = PANEL_WIDTH - 24.0
	box.add_child(_tower_label)
	var flow: HFlowContainer = _add_flow(box)
	for i: int in TowerStats.MAX_LEVEL + 1:
		_tower_level_buttons.append(_add_button(flow, "L%d" % i, _on_tower_level_pressed.bind(i)))
	_major_option = _add_option(box)
	_add_toggle(box, "Hold fire", hold_fire, _on_hold_fire_toggled)


func _build_time_section(box: VBoxContainer) -> void:
	var flow: HFlowContainer = _add_flow(box)
	for factor: float in TIME_SCALES:
		var button: Button = _add_button(flow, "%s" % factor, _on_time_scale_pressed.bind(factor))
		button.toggle_mode = true
		_time_buttons[factor] = button
	_pause_button = _add_toggle(box, "Pause", get_tree().paused, _on_pause_toggled)
	var step_row: HFlowContainer = _add_flow(box)
	_step_button = _add_button(step_row, "Step 1", _on_step_pressed.bind(1))
	_step_10_button = _add_button(step_row, "Step 10", _on_step_pressed.bind(10))


func _build_vfx_section(box: VBoxContainer) -> void:
	var flow: HFlowContainer = _add_flow(box)
	_add_button(flow, "Muzzle", _on_vfx_pressed.bind(&"muzzle"))
	_add_button(flow, "Impact", _on_vfx_pressed.bind(&"impact"))
	_add_button(flow, "Death", _on_vfx_pressed.bind(&"death"))
	_add_button(flow, "Deflect", _on_vfx_pressed.bind(&"deflect"))
	_add_button(flow, "Coins +5", _on_vfx_pressed.bind(&"coins"))
	_add_button(flow, "Built", _on_vfx_pressed.bind(&"built"))
	_add_button(flow, "Upgraded", _on_vfx_pressed.bind(&"upgraded"))
	_add_button(flow, "Shake", _on_vfx_pressed.bind(&"shake"))


## Fill [member _enemy_scenes] and [param names] (parallel, sorted by name) from the enemy folders.
func _scan_enemy_scenes(names: Array[String]) -> void:
	var found: Dictionary[String, PackedScene] = {}
	for entry: String in ResourceLoader.list_directory(ENEMY_DIR):
		if not entry.ends_with("/") or entry == "components/":
			continue
		var folder: String = ENEMY_DIR + entry
		for file: String in ResourceLoader.list_directory(folder):
			if file.ends_with("/"):
				continue
			var file_name: String = file.trim_suffix(".remap")
			if not file_name.ends_with(".tscn"):
				continue
			var scene: PackedScene = load(folder + file_name) as PackedScene
			if scene == null:
				continue
			var probe: Node = scene.instantiate()
			var is_enemy: bool = probe is Enemy
			probe.free()
			if is_enemy:
				found[entry.trim_suffix("/")] = scene
	var keys: Array[String] = found.keys()
	keys.sort()
	for key: String in keys:
		names.append(key)
		_enemy_scenes.append(found[key])


# --- Visibility and refresh ---

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
	_refresh_towers()
	_refresh_time()


func _refresh_towers() -> void:
	var tower: Tower = tower_menu.get_tower()
	if tower != _shown_tower:
		_shown_tower = tower
		_major_option.clear()
		if tower != null:
			for major: MajorUpgrade in tower.major_upgrades:
				_major_option.add_item(major.caption)
	if tower == null:
		_tower_label.text = "Select a tower"
	else:
		var caption: String = "" if tower.major == null else " [%s]" % tower.major.caption
		_tower_label.text = "Selected: lvl %d%s" % [tower.level, caption]
	for button: Button in _tower_level_buttons:
		button.disabled = tower == null
	_major_option.disabled = tower == null or _major_option.item_count == 0


func _refresh_time() -> void:
	for factor: float in _time_buttons:
		_time_buttons[factor].set_pressed_no_signal(is_equal_approx(factor, Engine.time_scale))
	var paused: bool = get_tree().paused
	_pause_button.set_pressed_no_signal(paused)
	_step_button.disabled = not paused and not _stepping
	_step_10_button.disabled = _step_button.disabled


func _update_budget_text() -> void:
	_budget_button.text = "Budget x%s" % budget_scale


# --- Helpers ---

func _selected_major() -> MajorUpgrade:
	if _shown_tower == null or _major_option.selected < 0:
		return null
	if _major_option.selected >= _shown_tower.major_upgrades.size():
		return null
	return _shown_tower.major_upgrades[_major_option.selected]


func _apply_flags(enemy: Enemy) -> void:
	enemy.debug_invulnerable = invulnerable_enemies
	if freeze_enemies:
		enemy.set_speed_factor(&"debug", 0.0)


func _view_centre() -> Vector2:
	return camera.get_screen_center_position()


# --- Handlers ---

func _on_toggle_button_pressed() -> void:
	_set_menu_visible(not _open)


func _on_building_manager_tower_upgraded(_tower: Tower) -> void:
	if _open:
		_refresh()


func _on_god_mode_toggled(on: bool) -> void:
	god_mode = on
	level.set_god_mode(on)


func _on_coins_pressed() -> void:
	CurrencyManager.earn(9999)


func _on_wave_spin_value_changed(value: float) -> void:
	wave_number = int(value)


func _on_spawn_wave_pressed() -> void:
	level.debug_spawn_wave(wave_number - 1)


func _on_jump_wave_pressed() -> void:
	level.debug_jump_to_wave(wave_number - 1)


func _on_budget_pressed() -> void:
	var next: int = (BUDGET_SCALES.find(budget_scale) + 1) % BUDGET_SCALES.size()
	budget_scale = BUDGET_SCALES[next]
	level.set_budget_scale(budget_scale)
	_update_budget_text()


func _on_hold_countdown_toggled(on: bool) -> void:
	countdown_held = on
	level.set_countdown_held(on)


func _on_enemy_option_item_selected(index: int) -> void:
	enemy_name = _enemy_option.get_item_text(index)


func _on_count_spin_value_changed(value: float) -> void:
	enemy_count = int(value)


func _on_location_option_item_selected(index: int) -> void:
	spawn_location = index


func _on_spawn_pressed() -> void:
	var index: int = _enemy_option.selected
	if index < 0 or index >= _enemy_scenes.size():
		return
	var spawned: Array[Enemy]
	if spawn_location >= level.get_spawner_count():
		spawned = level.debug_spawn_enemies_at(_enemy_scenes[index], enemy_count, _view_centre())
	else:
		spawned = level.debug_spawn_enemies(_enemy_scenes[index], enemy_count, spawn_location)
	for enemy: Enemy in spawned:
		_apply_flags(enemy)


func _on_freeze_toggled(on: bool) -> void:
	freeze_enemies = on
	for enemy: Enemy in level.get_enemies():
		if on:
			enemy.set_speed_factor(&"debug", 0.0)
		else:
			enemy.clear_speed_factor(&"debug")


func _on_invulnerable_toggled(on: bool) -> void:
	invulnerable_enemies = on
	for enemy: Enemy in level.get_enemies():
		enemy.debug_invulnerable = on


func _on_hp_pressed(ratio: float) -> void:
	for enemy: Enemy in level.get_enemies():
		enemy.set_health_ratio(ratio)


func _on_hit_pressed() -> void:
	for enemy: Enemy in level.get_enemies():
		enemy.take_damage(1.0)


func _on_kill_all_pressed() -> void:
	for enemy: Enemy in level.get_enemies():
		enemy.die()


func _on_attach_pressed(component: GDScript) -> void:
	for enemy: Enemy in level.get_enemies():
		var present: bool = false
		for child: Node in enemy.get_children():
			if is_instance_of(child, component):
				present = true
				break
		if not present:
			enemy.add_child(component.new() as Node)


func _on_tower_level_pressed(tower_level: int) -> void:
	# Read the selection now: the 0.2 s poll may still show the previous tower.
	var tower: Tower = tower_menu.get_tower()
	if tower == null or not is_instance_valid(tower):
		return
	if tower != _shown_tower:
		_refresh_towers()
	var major: MajorUpgrade = _selected_major() if tower_level >= TowerStats.MAX_LEVEL else null
	building_manager.debug_set_level(tower, tower_level, major)


func _on_hold_fire_toggled(on: bool) -> void:
	hold_fire = on
	building_manager.set_hold_fire(on)


func _on_time_scale_pressed(factor: float) -> void:
	time_scale = factor
	Engine.time_scale = factor
	_refresh_time()


func _on_fast_spawn_toggled(on: bool) -> void:
	fast_spawn = on
	level.set_spawn_delay_override(FAST_SPAWN_DELAY if on else 0.0)


func _on_pause_toggled(on: bool) -> void:
	get_tree().paused = on
	_refresh_time()


## Runs [param frames] physics steps, then pauses again. [signal SceneTree.physics_frame] fires
## before the nodes' physics step, so waiting for frames + 1 of them lets exactly [param frames]
## steps (and the idle frames between them) run.
func _on_step_pressed(frames: int) -> void:
	if _stepping or not get_tree().paused:
		return
	_stepping = true
	get_tree().paused = false
	for i: int in range(frames + 1):
		await get_tree().physics_frame
	if is_inside_tree():
		get_tree().paused = true
		_stepping = false
		_refresh_time()


func _on_vfx_pressed(kind: StringName) -> void:
	var at: Vector2 = _view_centre()
	match kind:
		&"muzzle":
			vfx.play_muzzle(at, -PI / 2.0, Color.WHITE)
		&"impact":
			vfx.play_impact(at, Vector2.UP, Color.WHITE)
		&"death":
			vfx.play_death(at, Color.WHITE)
		&"deflect":
			vfx.play_deflect(at)
		&"coins":
			vfx.play_coin_popup(at, 5)
		&"built":
			vfx.play_tower_built(at)
		&"upgraded":
			vfx.play_tower_upgraded(at)
		&"shake":
			camera.shake(0.7)
