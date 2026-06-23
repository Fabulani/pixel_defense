class_name PanningCamera extends Camera2D

@onready var touch_controls: TouchControls = $TouchControls
@onready var kbm_controls: KBMControls = $KBMControls

@export_group("Smoothing")
@export_range(0.0, 0.5, 0.01) var pan_smoothing: float = 0.2
@export_range(0.0, 0.5, 0.01) var zoom_smoothing: float = 0.2

@export_group("Actions")
@export var pan_action: String = "camera>pan"
@export var zoom_in_action: String = "camera>zoom+"
@export var zoom_out_action: String = "camera>zoom-"

@export_group("Zoom")
@export var can_zoom: bool = true
@export_range(0.01, 1, 0.01) var min_zoom: float = 1.0
@export_range(1, 20, 0.01) var max_zoom: float = 5.0
@export_range(0.01, 0.5, 0.01) var zoom_step_ratio: float = 0.1

@export_group("Pan")
@export_range(0.1, 1000, 0.1) var pan_speed: float = 500

## Viewport-space position used as zoom anchor for zoom-to-mouse behavior.
var _anchor_viewport_position: Vector2
## Zoom value when pinch gesture starts
var _pinch_start_zoom: float = zoom.x

var smooth_damp: SmoothDamp


func _ready() -> void:
	smooth_damp = SmoothDamp.new()
	smooth_damp.pan_smoothing = pan_smoothing
	smooth_damp.zoom_smoothing = zoom_smoothing
	smooth_damp.initialize(zoom, position)

	kbm_controls.pan_action = pan_action
	kbm_controls.zoom_in_action = zoom_in_action
	kbm_controls.zoom_out_action = zoom_out_action
	kbm_controls.setup()

	if DisplayServer.is_touchscreen_available():
		touch_controls.pan_changed.connect(_on_touch_pan_changed)
		touch_controls.pinch_changed.connect(_on_pinch_changed)
		touch_controls.pinch_started.connect(_on_pinch_started)
	else:
		kbm_controls.mouse_panned.connect(_on_mouse_panned)
		kbm_controls.zoomed.connect(_on_kbm_zoomed)


func _process(delta: float) -> void:
	_handle_directional_input(delta)
	_apply_smooth_damp(delta)


func _apply_smooth_damp(delta: float) -> void:
	# Shift position to keep the zoom anchor point stationary on screen
	var pre: Vector2 = _calculate_zoom_anchor(_anchor_viewport_position)
	zoom = smooth_damp.smooth_zoom(delta)
	var post: Vector2 = _calculate_zoom_anchor(_anchor_viewport_position)
	var anchor_offset: Vector2 = pre - post
	position = smooth_damp.smooth_pan(delta, anchor_offset)


## Calculate the zoom anchor position. Used in anchor offset calculations for
## zoom-to-mouse behavior.
func _calculate_zoom_anchor(cursor_viewport_pos: Vector2) -> Vector2:
	return to_local(get_canvas_transform().affine_inverse() * cursor_viewport_pos)


func _handle_directional_input(delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		"camera>pan_left",
		"camera>pan_right",
		"camera>pan_up",
		"camera>pan_down"
	)
	if direction != Vector2.ZERO:
		smooth_damp.position_goal += direction * pan_speed / zoom.x * delta


func _on_touch_pan_changed(screen_delta: Vector2) -> void:
	smooth_damp.position_goal -= screen_delta / zoom


func _on_mouse_panned(delta: Vector2) -> void:
	smooth_damp.position_goal -= delta / zoom


func _on_kbm_zoomed(direction: int, anchor: Vector2) -> void:
	if not can_zoom:
		return
	_anchor_viewport_position = anchor
	smooth_damp.zoom_goal *= (1.0 / (1.0 - zoom_step_ratio)) if direction > 0 \
		else (1.0 - zoom_step_ratio)
	smooth_damp.zoom_goal = smooth_damp.zoom_goal.clamp(
		min_zoom * Vector2.ONE, max_zoom * Vector2.ONE
	)


func _on_pinch_started() -> void:
	_pinch_start_zoom = zoom.x


func _on_pinch_changed(pinch_factor: float, anchor_viewport_pos: Vector2) -> void:
	if not can_zoom:
		return
	var new_zoom: float = clamp(_pinch_start_zoom * pinch_factor, min_zoom, max_zoom)
	_anchor_viewport_position = anchor_viewport_pos
	smooth_damp.zoom_goal = new_zoom * Vector2.ONE


## Zoom by an absolute amount, anchored at the screen center.
func zoom_by(amount: float) -> void:
	_anchor_viewport_position = get_viewport().get_visible_rect().size * 0.5
	smooth_damp.zoom_goal = (smooth_damp.zoom_goal + amount * Vector2.ONE).clamp(
		min_zoom * Vector2.ONE, max_zoom * Vector2.ONE
	)
