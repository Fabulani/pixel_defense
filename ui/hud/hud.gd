class_name HUD extends CanvasLayer

@onready var coin_amount_label: Label = $PanelContainer/MarginContainer/VBoxContainer/CoinContainer/CoinAmountLabel
@onready var wave_index_label: Label = $PanelContainer/MarginContainer/VBoxContainer/WaveContainer/WaveIndexLabel
@onready var enemy_count_label: Label = $PanelContainer/MarginContainer/VBoxContainer/EnemyCountContainer/EnemyCount
@onready var _debug_coins_button: Button = %DebugCoinsButton
@onready var _wave_banner: Label = %WaveBanner

@export_group("Wave banner")
@export var banner_fade_in: float = 0.15
@export var banner_hold: float = 0.8
@export var banner_fade_out: float = 0.4

var _banner_tween: Tween

func _ready() -> void:
	_debug_coins_button.visible = OS.is_debug_build()
	_debug_coins_button.pressed.connect(_on_debug_coins_button_pressed)
	CurrencyManager.currency_changed.connect(set_coin_amount)
	set_coin_amount(CurrencyManager.coins)

func set_coin_amount(amount: int) -> void:
	coin_amount_label.text = str(amount)

func set_wave(wave_index: int) -> void:
	wave_index_label.text = str(wave_index)

## Show the "wave N" banner for [param wave_index].
func show_wave_banner(wave_index: int) -> void:
	if _banner_tween != null:
		_banner_tween.kill()
	_wave_banner.text = "Wave %d" % wave_index
	_wave_banner.modulate.a = 0.0
	_wave_banner.show()
	# The banner node is PROCESS_MODE_ALWAYS, so it finishes even if the tree gets paused.
	_banner_tween = _wave_banner.create_tween()
	_banner_tween.tween_property(_wave_banner, "modulate:a", 1.0, banner_fade_in)
	_banner_tween.tween_interval(banner_hold)
	_banner_tween.tween_property(_wave_banner, "modulate:a", 0.0, banner_fade_out)
	_banner_tween.tween_callback(_wave_banner.hide)

func set_enemy_count(count: int) -> void:
	enemy_count_label.text = str(count)

## Debug builds only: grant coins for testing.
func _on_debug_coins_button_pressed() -> void:
	CurrencyManager.earn(9999)
