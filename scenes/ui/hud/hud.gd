class_name HUD extends CanvasLayer

@onready var coin_amount_label: Label = $PanelContainer/MarginContainer/GridContainer/CoinAmountLabel

func _ready() -> void:
	CurrencyManager.currency_changed.connect(set_coin_amount)
	set_coin_amount(CurrencyManager.coins)

func set_coin_amount(amount: int) -> void:
	coin_amount_label.text = str(amount)
