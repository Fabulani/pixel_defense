extends RefCounted
## Static helpers that build the debug menu's controls (focus-less, so nothing steals game input).


static func add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


static func add_toggle(parent: Control, text: String, initial: bool, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.button_pressed = initial
	button.toggled.connect(callback)
	parent.add_child(button)
	return button


static func add_flow(parent: Control) -> HFlowContainer:
	var flow: HFlowContainer = HFlowContainer.new()
	parent.add_child(flow)
	return flow


static func add_spin(parent: Control, min_value: int, max_value: int, value: int) -> SpinBox:
	var spin: SpinBox = SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = 1
	spin.value = clampi(value, min_value, max_value)
	spin.focus_mode = Control.FOCUS_NONE
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(spin)
	return spin


static func add_option(parent: Control) -> OptionButton:
	var option: OptionButton = OptionButton.new()
	option.focus_mode = Control.FOCUS_NONE
	option.fit_to_longest_item = false
	option.clip_text = true
	parent.add_child(option)
	return option
