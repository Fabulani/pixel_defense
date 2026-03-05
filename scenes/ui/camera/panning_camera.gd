class_name PanningCamera extends Camera2D

@export_group("Panning")
@export var keyboard_pan_speed: float = 300

@export_group("Zoom")
@export var can_zoom: bool = true
@export var min_zoom: float = 1.0
@export var max_zoom: float = 5.0
@export var zoom_increment: float = 0.25
@export var zoom_rate: float = 8.0

# Target zoom for smooth zooming
var _target_zoom: float = 2.0

# Touch
var _touch_points: Dictionary[int, Vector2] = {}
var _start_distance: float = 0.0
var _start_zoom: float = 1.0

func _unhandled_input(event: InputEvent) -> void:
	_handle_mouse_input(event)
	_handle_touch_input(event)

func _process(_delta: float) -> void:
	_handle_keyboard_input(_delta)

func _handle_mouse_input(event: InputEvent) -> void:
	# Pan with middle mouse button
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
		position -= event.relative / zoom

	# Zoom with scroll wheel
	if can_zoom and event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(zoom_increment)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(-zoom_increment)

func _handle_touch_input(event: InputEvent) -> void:
	# Register touch points and calculate start distance for pinch zoom
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
		else:
			_touch_points.erase(event.index)

		if _touch_points.size() == 2:
			var positions: Array[Vector2] = _touch_points.values()
			_start_distance = positions[0].distance_to(positions[1])
			_start_zoom = zoom.x
		else:
			_start_distance = 0.0

	# Pinch to zoom (two fingers)
	if can_zoom and event is InputEventScreenDrag:
		_touch_points[event.index] = event.position
		if  _touch_points.size() == 2 and _start_distance > 0.0:
			var positions: Array[Vector2] = _touch_points.values()
			var current_distance: float = positions[0].distance_to(positions[1])
			var target_zoom: float = _start_zoom * (current_distance / _start_distance)
			_set_target_zoom(target_zoom)

	# Pan (single finger)
	if event is InputEventScreenDrag and _touch_points.size() == 1:
		position -= event.relative / zoom

func _handle_keyboard_input(_delta: float) -> void:
	# Pan with WASD or arrow keys
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if direction != Vector2.ZERO:
		position += direction.normalized() * keyboard_pan_speed * _delta

func _physics_process(_delta: float) -> void:
	zoom = lerp(zoom, _target_zoom * Vector2.ONE, zoom_rate * _delta)
	set_physics_process(not is_equal_approx(zoom.x, _target_zoom))

func _set_target_zoom(value: float) -> void:
	_target_zoom = clamp(value, min_zoom, max_zoom)
	set_physics_process(true)

func zoom_by(amount: float) -> void:
	_set_target_zoom(_target_zoom + amount)
