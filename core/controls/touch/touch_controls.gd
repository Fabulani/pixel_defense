class_name TouchControls extends Resource

signal pan_changed(screen_delta: Vector2)
signal pinch_changed(pinch_factor: float, anchor_viewport_pos: Vector2)
signal pinch_started()

## Screen touch points and their positions
var _touch_points: Dictionary[int, Vector2] = {}
## The start distance of the detected pinch gesture
var _start_distance: float = 0.0


## Handle touch inputs for pan and pinch.
func handle_input(event: InputEvent):
	_track_touch_points(event)
	_handle_pinch(event)
	_handle_pan(event)


func _handle_pan(event: InputEvent) -> void:
	if not event is InputEventScreenDrag:
		return
	var screen_delta := Vector2.ZERO
	if _touch_points.size() == 1:
		screen_delta = event.relative
	elif _touch_points.size() == 2:
		# Use 0.5 to maintain same speed as single-finger pan.
		screen_delta = event.relative * 0.5
	pan_changed.emit(screen_delta)


func _handle_pinch(event: InputEvent) -> void:
	if (not event is InputEventScreenDrag
		or _touch_points.size() != 2
		or _start_distance <= 0.001):
		return
	var positions: Array[Vector2] = _touch_points.values()
	var current_distance := positions[0].distance_to(positions[1])
	var pinch_ratio := current_distance / _start_distance
	#var new_zoom: float = clamp(_start_zoom * pinch_ratio, min_zoom, max_zoom)
	var anchor_viewport_position := (positions[0] + positions[1]) * 0.5
	#smooth_damp.zoom_goal = new_zoom * Vector2.ONE
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
			#_start_zoom = zoom.x
			pinch_started.emit()
		else:
			_start_distance = 0.0
	elif event is InputEventScreenDrag:
		_touch_points[event.index] = event.position
