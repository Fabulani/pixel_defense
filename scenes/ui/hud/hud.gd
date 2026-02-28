class_name HUD extends CanvasLayer

signal zoom_in_btn_pressed
signal zoom_out_btn_pressed

@onready var coin_amount_label: Label = $PanelContainer/MarginContainer/VBoxContainer/CoinContainer/CoinAmountLabel
@onready var wave_index_label: Label = $PanelContainer/MarginContainer/VBoxContainer/WaveContainer/WaveIndexLabel
@onready var enemy_count_label: Label = $PanelContainer/MarginContainer/VBoxContainer/EnemyCountContainer/EnemyCount

func _ready() -> void:
	CurrencyManager.currency_changed.connect(set_coin_amount)
	set_coin_amount(CurrencyManager.coins)

func set_coin_amount(amount: int) -> void:
	coin_amount_label.text = str(amount)

func set_wave(wave_index: int) -> void:
	wave_index_label.text = str(wave_index)

func set_enemy_count(count: int) -> void:
	enemy_count_label.text = str(count)


func _on_zoom_in_button_pressed() -> void:
	zoom_in_btn_pressed.emit()


func _on_zoom_out_button_pressed() -> void:
	zoom_out_btn_pressed.emit()
