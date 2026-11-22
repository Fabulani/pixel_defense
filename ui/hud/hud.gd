class_name HUD extends CanvasLayer

## Emitted when the player presses the "next wave" button.
signal next_wave_requested

@onready var coin_amount_label: Label = $PanelContainer/MarginContainer/VBoxContainer/CoinContainer/CoinAmountLabel
@onready var wave_index_label: Label = $PanelContainer/MarginContainer/VBoxContainer/WaveContainer/WaveIndexLabel
@onready var enemy_count_label: Label = $PanelContainer/MarginContainer/VBoxContainer/EnemyCountContainer/EnemyCount
@onready var _debug_coins_button: Button = %DebugCoinsButton
@onready var _wave_banner: Label = %WaveBanner
@onready var _wave_banner_detail: Label = %WaveBannerDetail
@onready var _next_wave_button: Button = %NextWaveButton

@export_group("Wave banner")
@export var banner_fade_in: float = 0.15
@export var banner_hold: float = 0.8
## Hold time when the banner shows special-wave lines (placeholder).
@export var banner_hold_special: float = 2.0
@export var banner_fade_out: float = 0.4

var _banner_tween: Tween
var _plan: WavePlan

func _ready() -> void:
	_debug_coins_button.visible = OS.is_debug_build()
	_debug_coins_button.pressed.connect(_on_debug_coins_button_pressed)
	_next_wave_button.visible = false
	_next_wave_button.pressed.connect(_on_next_wave_button_pressed)
	CurrencyManager.currency_changed.connect(set_coin_amount)
	set_coin_amount(CurrencyManager.coins)

func set_coin_amount(amount: int) -> void:
	coin_amount_label.text = str(amount)

func set_wave(wave_index: int) -> void:
	wave_index_label.text = str(wave_index)

## Store the upcoming wave [param plan]; its special lines are shown by [method show_wave_banner]
## when that wave starts.
func show_wave_plan(plan: WavePlan) -> void:
	_plan = plan

## Show the "wave N" banner for [param wave_index] (1-based). Special lines are added
## if the stored plan is that wave.
func show_wave_banner(wave_index: int) -> void:
	if _banner_tween != null:
		_banner_tween.kill()
	var lines: PackedStringArray = []
	if _plan != null and _plan.index + 1 == wave_index:
		for spawner_plan: SpawnerPlan in _plan.spawners:
			var template: WaveTemplate = spawner_plan.template
			if template == null or not template.is_special:
				continue
			var line: String = "%s: %s" % [template.display_name, template.description]
			if not lines.has(line):
				lines.append(line)
	_wave_banner.text = "Wave %d" % wave_index
	_wave_banner_detail.text = "\n".join(lines)
	_wave_banner_detail.visible = not lines.is_empty()
	_wave_banner.modulate.a = 0.0
	_wave_banner.show()
	var hold: float = banner_hold if lines.is_empty() else banner_hold_special
	# The banner node is PROCESS_MODE_ALWAYS, so it finishes even if the tree gets paused.
	_banner_tween = _wave_banner.create_tween()
	_banner_tween.tween_property(_wave_banner, "modulate:a", 1.0, banner_fade_in)
	_banner_tween.tween_interval(hold)
	_banner_tween.tween_property(_wave_banner, "modulate:a", 0.0, banner_fade_out)
	_banner_tween.tween_callback(_wave_banner.hide)

## Show the "next wave" button with the remaining time, or hide it if [param time_left] <= 0.
func set_countdown(time_left: float, bonus: int) -> void:
	if time_left <= 0.0:
		_next_wave_button.hide()
		return
	var bonus_text: String = " (+%d)" % bonus if bonus > 0 else ""
	_next_wave_button.text = "Next wave%s\n%d s" % [bonus_text, ceili(time_left)]
	_next_wave_button.show()

## Hide the "next wave" button (game over).
func hide_next_wave_button() -> void:
	_next_wave_button.hide()

func set_enemy_count(count: int) -> void:
	enemy_count_label.text = str(count)

## Debug builds only: grant coins for testing.
func _on_debug_coins_button_pressed() -> void:
	CurrencyManager.earn(9999)

func _on_next_wave_button_pressed() -> void:
	next_wave_requested.emit()
