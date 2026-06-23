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
## Accumulated path length per finger used for drag detection.
## Avoids relying on start-position which can be unavailable if events arrive out of order.
var _drag_distance: Dictionary[int, float] = {}
var _start_distance: float = 0.0
var _drag_active: bool = false
var _drag_threshold_px: float = 0.0


func _ready() -> void:
	var dpi: float = DisplayServer.screen_get_dpi()
	if dpi <= 0.0:
		dpi = 96.0  # fallback for web/headless where DPI is unavailable
	_drag_threshold_px = (DRAG_THRESHOLD_MM / 25.4) * dpi


func _unhandled_input(event: InputEvent) -> void:
	_track_touch_points(event)
	_handle_tap(event)
	_handle_pinch(event)
	_handle_pan(event)


func _handle_tap(event: InputEvent) -> void:
	if not event is InputEventScreenTouch:
		return
	if event.pressed:
		if _touch_points.size() == 1:
			_drag_active = false
			_drag_distance[event.index] = 0.0
	else:
		if not _drag_active and _touch_points.is_empty():
			tapped.emit(event.position)
			get_viewport().set_input_as_handled()
		_drag_distance.erase(event.index)


func _handle_pan(event: InputEvent) -> void:
	if not event is InputEventScreenDrag:
		return
	if _touch_points.size() == 1:
		if not _drag_active:
			_drag_distance[event.index] = _drag_distance.get(event.index, 0.0) + event.relative.length()
			if _drag_distance.get(event.index, 0.0) < _drag_threshold_px:
				return
			_drag_active = true
		pan_changed.emit(event.relative)
	elif _touch_points.size() == 2:
		# Two-finger always pans (combined with pinch)
		pan_changed.emit(event.relative * 0.5)


func _handle_pinch(event: InputEvent) -> void:
	if (not event is InputEventScreenDrag
		or _touch_points.size() != 2
		or _start_distance <= 0.001):
		return
	var positions: Array[Vector2] = _touch_points.values()
	var current_distance: float = positions[0].distance_to(positions[1])
	var pinch_ratio: float = current_distance / _start_distance
	var anchor_viewport_position: Vector2 = (positions[0] + positions[1]) * 0.5
	pinch_changed.emit(pinch_ratio, anchor_viewport_position)


func _track_touch_points(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
		else:
			_touch_points.erase(event.index)
		if _touch_points.size() == 2:
			var positions: Array[Vector2] = _touch_points.values()
			_start_distance = positions[0].distance_to(positions[1])
			_drag_active = true  # multi-touch always cancels tap
			pinch_started.emit()
		else:
			_start_distance = 0.0
	elif event is InputEventScreenDrag:
		_touch_points[event.index] = event.position
