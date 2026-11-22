extends VBoxContainer
## Base of a debug menu section: a collapsible header and a content box filled by [method build].

const State = preload("res://debug/debug_state.gd")
const Context = preload("res://debug/debug_context.gd")
const Ui = preload("res://debug/debug_ui.gd")

## Box the subclass fills in [method build].
var content: VBoxContainer
var _title: String = ""


## Builds the header and content, calls [method build] and [method apply_state].
func setup(title: String, ctx: Context) -> void:
	_title = title
	var header: Button = Button.new()
	header.focus_mode = Control.FOCUS_NONE
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(header)
	content = VBoxContainer.new()
	add_child(content)
	var update: Callable = func(open: bool) -> void:
		header.text = "%s %s" % ["▾" if open else "▸", _title]
		content.visible = open
	header.pressed.connect(func() -> void:
		var open: bool = not content.visible
		State.open_sections[_title] = open
		update.call(open)
		if open:
			refresh())
	update.call(State.open_sections.get(_title, false))
	build(ctx)
	apply_state()


## Virtual: add this section's controls to [member content].
func build(_ctx: Context) -> void:
	pass


## Virtual: update labels and button states from the game; called while the menu is open.
func refresh() -> void:
	pass


## Virtual: re-apply the saved toggles to the (possibly reloaded) game.
func apply_state() -> void:
	pass
