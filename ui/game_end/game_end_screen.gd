class_name GameEndScreen extends CanvasLayer

signal restart_requested

const _DEFEAT_TITLE: String = "YOU DIED"
const _DEFEAT_COLOR: Color = Color(1, 0, 0)
const _VICTORY_TITLE: String = "Pixel Defense Defeated"
const _VICTORY_COLOR: Color = Color(0, 0.5, 1)

@onready var _title_label: Label = %TitleLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _coins_label: Label = %CoinsLabel
@onready var _seed_label: Label = %SeedLabel
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	_restart_button.pressed.connect(_on_restart_button_pressed)
	hide()


## Show the defeat screen and pause the game.
func show_defeat(waves_survived: int, coins: int, map_seed: int) -> void:
	_show_end(_DEFEAT_TITLE, _DEFEAT_COLOR, waves_survived, coins, map_seed)


## Show the victory screen and pause the game.
func show_victory(waves_survived: int, coins: int, map_seed: int) -> void:
	_show_end(_VICTORY_TITLE, _VICTORY_COLOR, waves_survived, coins, map_seed)


func _show_end(title: String, color: Color, waves_survived: int, coins: int, map_seed: int) -> void:
	if not is_inside_tree():
		return
	_title_label.text = title
	_title_label.add_theme_color_override("font_color", color)
	_wave_label.text = "wave %d" % waves_survived
	_coins_label.text = str(coins)
	_seed_label.text = "seed %d" % map_seed
	_seed_label.visible = map_seed != 0
	show()
	get_tree().paused = true


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	restart_requested.emit()
