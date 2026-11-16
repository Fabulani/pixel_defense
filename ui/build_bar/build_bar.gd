class_name BuildBar extends CanvasLayer

signal tower_type_selected(type: TowerType)
signal tower_type_deselected()

const _SLOT_SIZE: Vector2 = Vector2(64, 64)
const _ICON_SCALE: float = 3.0
const _SELECTED_SCALE: float = 0.9
const _CORNER_RADIUS: int = 8
const _BORDER_WIDTH: int = 2
const _BORDER_WIDTH_SELECTED: int = 4
const _CAPTION_FONT_SIZE: int = 12
const _CAPTION_OUTLINE_SIZE: int = 4
const _CAPTION_INSET: float = 8.0
const _UNAFFORDABLE_MODULATE: Color = Color(1, 1, 1, 0.4)
const _BACKGROUND: Color = Color(0, 0, 0, 0.5)
const _OUTLINE: Color = Color(1, 1, 1)
const _STATES: PackedStringArray = ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]

var _selected: TowerType = null
var _style_normal: StyleBoxFlat = _make_style(false)
var _style_selected: StyleBoxFlat = _make_style(true)
## Button of every type, in the order of the types.
var _buttons: Dictionary[TowerType, Button] = {}

@onready var _row: HBoxContainer = %Row


func _ready() -> void:
	CurrencyManager.currency_changed.connect(_on_currency_manager_currency_changed)


## Build one button per type (replaces the old ones; a selected type is deselected first).
func set_tower_types(types: Array[TowerType]) -> void:
	deselect()
	_buttons.clear()
	for child: Node in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	for type: TowerType in types:
		if type == null or type.stats == null:
			continue
		if _buttons.has(type):
			push_warning("BuildBar: duplicate tower type '%s' skipped" % type.id)
			continue
		var slot: Control = _make_slot(type)
		_row.add_child(slot)
	_refresh()


## Clear the selection. Emits [signal tower_type_deselected] only if something was selected.
func deselect() -> void:
	if _selected == null:
		return
	_selected = null
	_refresh()
	tower_type_deselected.emit()


## Selected tower type, or null.
func get_selected_type() -> TowerType:
	return _selected


## Fixed-size slot so the container never touches the scale of the button inside it.
func _make_slot(type: TowerType) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = _SLOT_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var button := Button.new()
	button.size = _SLOT_SIZE
	button.tooltip_text = type.display_name
	button.pivot_offset = _SLOT_SIZE * 0.5
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.pressed.connect(_on_type_button_pressed.bind(type))
	slot.add_child(button)

	button.add_child(_make_icon(type.base_texture, 1.0))
	button.add_child(_make_icon(type.turret_texture, type.turret_scale))
	button.add_child(_make_caption(str(type.stats.cost)))
	_buttons[type] = button
	return slot


func _make_icon(texture: Texture2D, extra_scale: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if texture != null:
		icon.size = texture.get_size() * _ICON_SCALE * extra_scale
	icon.position = (_SLOT_SIZE - icon.size) * 0.5
	return icon


func _make_caption(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", _CAPTION_FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", _CAPTION_OUTLINE_SIZE)
	# Zero-size rect at the bottom-left corner that grows up and to the right (same as the tower menu captions).
	label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	label.offset_left = _CAPTION_INSET
	label.offset_right = _CAPTION_INSET
	label.offset_top = -_CAPTION_INSET
	label.offset_bottom = -_CAPTION_INSET
	return label


func _make_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _BACKGROUND
	style.border_color = _OUTLINE
	# Children are placed by hand against the button rect, so the border width never moves icon or caption.
	style.set_border_width_all(_BORDER_WIDTH_SELECTED if selected else _BORDER_WIDTH)
	style.set_corner_radius_all(_CORNER_RADIUS)
	return style


## Update look of every button: style, scale and affordability dimming.
func _refresh() -> void:
	for type: TowerType in _buttons:
		var button: Button = _buttons[type]
		var is_selected: bool = type == _selected
		var style: StyleBoxFlat = _style_selected if is_selected else _style_normal
		for state: String in _STATES:
			button.add_theme_stylebox_override(state, style)
		button.scale = Vector2.ONE * (_SELECTED_SCALE if is_selected else 1.0)
		button.modulate = Color.WHITE if CurrencyManager.can_afford(type.stats.cost) else _UNAFFORDABLE_MODULATE


func _on_type_button_pressed(type: TowerType) -> void:
	if _selected == type:
		deselect()
		return
	_selected = type
	_refresh()
	tower_type_selected.emit(type)


func _on_currency_manager_currency_changed(_new_amount: int) -> void:
	_refresh()
