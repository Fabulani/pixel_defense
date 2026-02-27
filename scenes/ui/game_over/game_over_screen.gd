class_name GameOverScreen extends CanvasLayer

signal restart_requested

@onready var wave_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/WaveLabel
@onready var coins_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/CoinsLabel
@onready var restart_button: Button = $PanelContainer/MarginContainer/VBoxContainer/RestartButton

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_button_pressed)
	hide()

func show_game_over(wave_reached: int, coins_saved: int) -> void:
	wave_label.text = "wave %d" % wave_reached
	coins_label.text = str(coins_saved)
	show()
	get_tree().paused = true

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	restart_requested.emit()
