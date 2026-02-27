class_name HUD extends CanvasLayer

@onready var coin_amount_label: Label = $PanelContainer/MarginContainer/VBoxContainer/CoinContainer/CoinAmountLabel
@onready var wave_index_label: Label = $PanelContainer/MarginContainer/VBoxContainer/WaveContainer/WaveIndexLabel

func _ready() -> void:
	CurrencyManager.currency_changed.connect(set_coin_amount)
	set_coin_amount(CurrencyManager.coins)

func set_coin_amount(amount: int) -> void:
	coin_amount_label.text = str(amount)

func set_wave(wave_index: int) -> void:
	wave_index_label.text = str(wave_index)
