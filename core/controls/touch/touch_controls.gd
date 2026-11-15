class_name TouchControls extends Node

## Emitted when a single touch is released without crossing the drag threshold.
signal tapped(position: Vector2)
## Emitted each frame a one- or two-finger pan moves. [param screen_delta] is in viewport pixels.
signal pan_changed(screen_delta: Vector2)
## Emitted when a second finger touches down, beginning a pinch gesture.
signal pinch_started()
## Emitted as a two-finger pinch changes. [param pinch_factor] is current/start finger distance.
signal pinch_changed(pinch_factor: float, anchor_viewport_pos: Vector2)

## Minimum movement in millimeters before a touch is classified as a drag.
## Using physical mm makes the threshold device-independent.
const DRAG_THRESHOLD_MM: float = 3.0

var _touch_points: Dictionary[int, Vector2] = {}
## Accumulated path length per finger (viewport units) used for drag detection.
## Avoids relying on start-position which can be unavailable if events arrive out of order.
var _drag_distance: Dictionary[int, float] = {}
var _start_distance: float = 0.0
## True once the gesture may pan without further threshold checks.
var _drag_active: bool = false
## True once the current gesture can no longer end in [signal tapped]: it crossed the
## drag threshold, involved a second finger, or was cancelled. Reset when a new gesture
## (first finger down on an empty screen) begins.
var _tap_blocked: bool = false
## Drag threshold in viewport units, recomputed at the start of every gesture.
var _drag_threshold: float = 0.0


func _notification(what: int) -> void:
	# A release can be lost when focus goes away; a stale finger would block every later tap.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_touch_points.clear()
		_drag_distance.clear()
		_start_distance = 0.0
		_tap_blocked = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		_track_drag(drag)
		_handle_pinch()
		_handle_pan(drag)


func _handle_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		if _touch_points.is_empty():
			_begin_gesture()
		else:
			# Any additional finger permanently disqualifies the gesture as a tap.
			_tap_blocked = true
			_drag_active = true
		_touch_points[touch.index] = touch.position
		_drag_distance[touch.index] = 0.0
		_update_pinch_start()
		return

	var known: bool = _touch_points.has(touch.index)
	_touch_points.erase(touch.index)
	_drag_distance.erase(touch.index)
	_update_pinch_start()
	if touch.canceled:
		_tap_blocked = true
		return
	# Only the last finger lifting can tap, and only if nothing blocked it.
	if known and _touch_points.is_empty() and not _tap_blocked:
		tapped.emit(touch.position)
		get_viewport().set_input_as_handled()


## (Re)arm the pinch whenever the finger count becomes exactly two.
func _update_pinch_start() -> void:
	if _touch_points.size() == 2:
		var positions: Array[Vector2] = _touch_points.values()
		_start_distance = positions[0].distance_to(positions[1])
		pinch_started.emit()
	else:
		_start_distance = 0.0


func _begin_gesture() -> void:
	_drag_active = false
	_tap_blocked = false
	_drag_distance.clear()
	_drag_threshold = _compute_drag_threshold()


## Converts [constant DRAG_THRESHOLD_MM] to viewport units using the current stretch scale.
func _compute_drag_threshold() -> float:
	var dpi: float = DisplayServer.screen_get_dpi()
	if dpi <= 0.0:
		dpi = 96.0  # fallback for web/headless where DPI is unavailable
	var threshold_physical_px: float = (DRAG_THRESHOLD_MM / 25.4) * dpi
	var window_size: Vector2 = Vector2(get_window().size)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if window_size.x <= 0.0 or window_size.y <= 0.0 \
		or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return threshold_physical_px
	# Physical pixels per viewport unit (stretch scale; min handles letterboxing).
	var physical_per_viewport: float = minf(
		window_size.x / viewport_size.x, window_size.y / viewport_size.y
	)
	if physical_per_viewport <= 0.0:
		return threshold_physical_px
	return threshold_physical_px / physical_per_viewport


func _handle_pan(drag: InputEventScreenDrag) -> void:
	if not _touch_points.has(drag.index):
		return
	if _touch_points.size() == 1:
		if not _drag_active:
			_drag_distance[drag.index] = _drag_distance.get(drag.index, 0.0) + drag.relative.length()
			if _drag_distance[drag.index] < _drag_threshold:
				return
			_drag_active = true
			_tap_blocked = true
		pan_changed.emit(drag.relative)
	elif _touch_points.size() == 2:
		# Two-finger always pans (combined with pinch)
		pan_changed.emit(drag.relative * 0.5)


func _handle_pinch() -> void:
	if _touch_points.size() != 2 or _start_distance <= 0.001:
		return
	var positions: Array[Vector2] = _touch_points.values()
	var current_distance: float = positions[0].distance_to(positions[1])
	var pinch_ratio: float = current_distance / _start_distance
	var anchor_viewport_position: Vector2 = (positions[0] + positions[1]) * 0.5
	pinch_changed.emit(pinch_ratio, anchor_viewport_position)


func _track_drag(drag: InputEventScreenDrag) -> void:
	# Ignore drags of fingers whose press we never saw (e.g. consumed by UI).
	if _touch_points.has(drag.index):
		_touch_points[drag.index] = drag.position
