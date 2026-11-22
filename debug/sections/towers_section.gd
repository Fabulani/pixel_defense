extends "res://debug/sections/debug_section.gd"
## Towers: set the selected tower's level and major, hold fire.

const PANEL_WIDTH: float = 200.0

var _ctx: Context
var _tower_label: Label
var _tower_level_buttons: Array[Button] = []
var _major_option: OptionButton
var _shown_tower: Tower


func build(ctx: Context) -> void:
	_ctx = ctx
	_tower_label = Label.new()
	_tower_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tower_label.custom_minimum_size.x = PANEL_WIDTH - 24.0
	content.add_child(_tower_label)
	var flow: HFlowContainer = Ui.add_flow(content)
	for i: int in TowerStats.MAX_LEVEL + 1:
		_tower_level_buttons.append(Ui.add_button(flow, "L%d" % i, _on_tower_level_pressed.bind(i)))
	_major_option = Ui.add_option(content)
	Ui.add_toggle(content, "Hold fire", State.hold_fire, _on_hold_fire_toggled)
	ctx.building_manager.tower_built.connect(_on_building_manager_tower_built)


func apply_state() -> void:
	_apply_hold_fire()


func refresh() -> void:
	var tower: Tower = _ctx.tower_menu.get_tower()
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


func _selected_major() -> MajorUpgrade:
	if _shown_tower == null or _major_option.selected < 0:
		return null
	if _major_option.selected >= _shown_tower.major_upgrades.size():
		return null
	return _shown_tower.major_upgrades[_major_option.selected]


## Applies the hold-fire flag to every existing tower.
func _apply_hold_fire() -> void:
	for node: Node in get_tree().get_nodes_in_group("towers"):
		var tower: Tower = node as Tower
		if tower != null:
			tower.set_firing_enabled(not State.hold_fire)


func _on_tower_level_pressed(tower_level: int) -> void:
	# Read the selection now: the 0.2 s poll may still show the previous tower.
	var tower: Tower = _ctx.tower_menu.get_tower()
	if tower == null or not is_instance_valid(tower):
		return
	if tower != _shown_tower:
		refresh()
	var major: MajorUpgrade = _selected_major() if tower_level >= TowerStats.MAX_LEVEL else null
	_ctx.building_manager.set_tower_level(tower, tower_level, major)


func _on_hold_fire_toggled(on: bool) -> void:
	State.hold_fire = on
	_apply_hold_fire()


func _on_building_manager_tower_built(tower: Tower, _cell_position: Vector2i) -> void:
	if State.hold_fire:
		tower.set_firing_enabled(false)
