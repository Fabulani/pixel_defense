class_name StartMenu extends CanvasLayer

signal start_requested

@onready var start_button: Button = $CenterContainer/StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	get_tree().paused = true

func _on_start_button_pressed() -> void:
	get_tree().paused = false
	start_requested.emit()
	hide()
