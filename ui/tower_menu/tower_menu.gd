class_name TowerMenu extends CanvasLayer

signal upgrade_requested(tower: Tower)
signal major_requested(tower: Tower, major: MajorUpgrade)
signal sell_requested(tower: Tower)

const _UPGRADE_ICON: Texture2D = preload("res://ui/tower_menu/upgrade.png")
const _SELL_ICON: Texture2D = preload("res://ui/tower_menu/sell.png")
const _BUTTON_SIZE: Vector2 = Vector2(56, 56)
const _CAPTION_FONT_SIZE: int = 12
const _CAPTION_OUTLINE_SIZE: int = 4
const _CAPTION_INSET: float = 2.0
const _DISABLED_MODULATE: Color = Color(1, 1, 1, 0.4)
const _SCREEN_MARGIN: float = 4.0
## Button presses are ignored this long after the row was (re)built, so a double press
## cannot hit whatever button moved under the finger.
const _PRESS_GUARD_MSEC: int = 300

var _tower: Tower
var _built_at_msec: int = 0

@onready var _panel: PanelContainer = %Panel
@onready var _buttons: HBoxContainer = %Buttons


func _ready() -> void:
	# Usable while paused: follows the camera and takes button presses.
	process_mode = Node.PROCESS_MODE_ALWAYS
	CurrencyManager.currency_changed.connect(_on_currency_manager_currency_changed)
	visible = false


func _process(_delta: float) -> void:
	if _tower == null:
		return
	if not is_instance_valid(_tower):
		hide_menu()
		return
	_update_position()


## Show the menu for the tower (replaces any previous one).
func show_for(tower: Tower) -> void:
	_tower = tower
	refresh()
	visible = true
	_update_position()


## Rebuild the buttons for the current tower (call after an upgrade).
func refresh() -> void:
	_built_at_msec = Time.get_ticks_msec()
	for child: Node in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	if _tower == null or not is_instance_valid(_tower):
		return

	var affordable: bool = CurrencyManager.can_afford(_tower.next_upgrade_cost())
	if _tower.needs_major():
		for major: MajorUpgrade in _tower.major_upgrades:
			var major_button: TextureButton = _make_button(major.icon, major.caption, affordable)
			major_button.material = MajorUpgrade.make_tint_material(major.icon_tint)
			major_button.pressed.connect(_on_major_button_pressed.bind(major))
			_buttons.add_child(major_button)
	elif not _tower.is_max_level():
		var upgrade_button: TextureButton = _make_button(_UPGRADE_ICON, "lvl+", affordable)
		upgrade_button.pressed.connect(_on_upgrade_button_pressed)
		_buttons.add_child(upgrade_button)

	var sell_button: TextureButton = _make_button(_SELL_ICON, "sell", true)
	sell_button.pressed.connect(_on_sell_button_pressed)
	_buttons.add_child(sell_button)

	_panel.reset_size()
	if _tower != null:
		_update_position()


## Hide the menu and forget the tower.
func hide_menu() -> void:
	# Forget the tower first: hiding releases a held button, which emits `pressed`.
	_tower = null
	visible = false


## Tower the menu is currently shown for, or null.
func get_tower() -> Tower:
	if _tower != null and not is_instance_valid(_tower):
		return null
	return _tower


## True when the menu is visible and [param screen_position] lies inside its panel.
func contains_screen_point(screen_position: Vector2) -> bool:
	return visible and _panel.get_global_rect().has_point(screen_position)


func _make_button(icon: Texture2D, caption: String, enabled: bool) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = icon
	button.custom_minimum_size = _BUTTON_SIZE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not enabled
	button.modulate = Color.WHITE if enabled else _DISABLED_MODULATE

	# Child of the button: dims with its modulate; the major tint material is not inherited.
	var label := Label.new()
	label.text = caption
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", _CAPTION_FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", _CAPTION_OUTLINE_SIZE)
	button.add_child(label)
	# Zero-size rect at the bottom-left corner, 2 px inside; it grows to its minimum size up and to the right.
	# (set_anchors_and_offsets_preset would measure the label before it is in the tree, with the wrong font size.)
	label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	label.offset_left = _CAPTION_INSET
	label.offset_right = _CAPTION_INSET
	label.offset_top = -_CAPTION_INSET
	label.offset_bottom = -_CAPTION_INSET
	return button


func _update_position() -> void:
	var tower_transform: Transform2D = _tower.get_global_transform_with_canvas()
	var screen_position: Vector2 = tower_transform.origin
	var zoom: float = tower_transform.get_scale().y
	var panel_size: Vector2 = _panel.size
	var target := Vector2(
		screen_position.x - panel_size.x * 0.5,
		screen_position.y - (8.0 * zoom + 6.0) - panel_size.y,
	)
	var bounds: Rect2 = get_viewport().get_visible_rect()
	var min_pos: Vector2 = bounds.position + Vector2(_SCREEN_MARGIN, _SCREEN_MARGIN)
	var max_pos: Vector2 = bounds.end - Vector2(_SCREEN_MARGIN, _SCREEN_MARGIN) - panel_size
	target.x = clampf(target.x, min_pos.x, maxf(min_pos.x, max_pos.x))
	target.y = clampf(target.y, min_pos.y, maxf(min_pos.y, max_pos.y))
	_panel.position = target


func _on_currency_manager_currency_changed(_new_amount: int) -> void:
	if _tower == null or not is_instance_valid(_tower):
		return
	var affordable: bool = CurrencyManager.can_afford(_tower.next_upgrade_cost())
	# The sell button is always last; every button before it is an upgrade/major button.
	var count: int = _buttons.get_child_count()
	for i: int in range(count - 1):
		var button: TextureButton = _buttons.get_child(i) as TextureButton
		button.disabled = not affordable
		button.modulate = Color.WHITE if affordable else _DISABLED_MODULATE


func _is_press_guarded() -> bool:
	return Time.get_ticks_msec() - _built_at_msec < _PRESS_GUARD_MSEC


func _on_upgrade_button_pressed() -> void:
	if _tower != null and not _is_press_guarded():
		upgrade_requested.emit(_tower)


func _on_major_button_pressed(major: MajorUpgrade) -> void:
	if _tower != null and not _is_press_guarded():
		major_requested.emit(_tower, major)


func _on_sell_button_pressed() -> void:
	if _tower != null and not _is_press_guarded():
		sell_requested.emit(_tower)
