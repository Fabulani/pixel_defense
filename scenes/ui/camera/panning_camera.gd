class_name PanningCamera extends Camera2D

# Touch controls config
@export var rotation_speed: float = 1.0
@export var pan_speed: float = 1.0
@export var can_pan: bool = true
@export var can_zoom: bool = true
@export var can_rotate: bool = true

var touch_points: Dictionary = {}
var start_distance: float = 0.0
var start_zoom: float = 1.0
var start_angle: float = 0.0
var start_rotation: float = 0.0

# Mouse + KB controls
const MIN_ZOOM: float = 1.0
const MAX_ZOOM: float = 5.0
const ZOOM_INCREMENT: float = 0.25
const ZOOM_BTN_INCREMENT: float = 0.5
const ZOOM_RATE: float = 8.0
const KEYBOARD_PAN_SPEED: float = 300

var _target_zoom: float = 2.0

func _unhandled_input(event: InputEvent) -> void:
	_handle_mouse_input(event)
	_handle_touch_input(event)

func _handle_mouse_input(event: InputEvent) -> void:
	# Pan
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			position -= event.relative / zoom
			
	# Zoom
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_in(ZOOM_INCREMENT)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out(ZOOM_INCREMENT)

func _handle_touch_input(event: InputEvent) -> void:
	# Register touch points for later
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
		else:
			touch_points.erase(event.index)

	# Zoom
	if event is InputEventScreenTouch:
		if touch_points.size() == 2:
			# Two fingers on the screen. Register start distance for zoom calculation
			var touch_points_positions = touch_points.values()
			start_distance = touch_points_positions[0].distance_to(touch_points_positions[1])
			start_zoom = zoom.x
		elif touch_points.size() < 2:
			# One or no finger on the screen. Reset zoom start distance
			start_distance = 0.0
	if event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		if touch_points.size() == 2:
			# Two fingers on the screen. Calculate zoom based on distance ratio
			var touch_points_positions = touch_points.values()
			var current_distance = touch_points_positions[0].distance_to(touch_points_positions[1])
			var desired_zoom = clamp(start_zoom * (current_distance / start_distance), MIN_ZOOM, MAX_ZOOM)
			var delta = desired_zoom - _target_zoom
			if can_zoom:
				if delta > 0:
					zoom_in(delta)
				elif delta < 0:
					zoom_out(-delta)
			
	
	# Pan
	if event is InputEventScreenDrag and touch_points.size() == 1:
		position -= event.relative / zoom
		
	# TODO: zooming with pinching, and double-tab + drag up/down

func _handle_keyboard_input(_delta: float) -> void:
	# Panning with WASD or arrow keys
	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if direction != Vector2.ZERO:
		position += direction.normalized() * KEYBOARD_PAN_SPEED * _delta

func zoom_in(increment: float) -> void:
	_target_zoom = min(_target_zoom + increment, MAX_ZOOM)
	set_physics_process(true)

func zoom_out(decrement: float) -> void:
	_target_zoom = max(_target_zoom - decrement, MIN_ZOOM)
	set_physics_process(true)
	
func _physics_process(_delta: float) -> void:
	zoom = lerp(zoom, _target_zoom * Vector2.ONE, ZOOM_RATE * _delta)
	set_physics_process(not is_equal_approx(zoom.x, _target_zoom))

func _process(_delta: float) -> void:
	_handle_keyboard_input(_delta)

# TODO: move this to UI
func _on_hud_zoom_in_btn_pressed() -> void:
	zoom_in(ZOOM_BTN_INCREMENT) 

# TODO: move this to UI
func _on_hud_zoom_out_btn_pressed() -> void:
	zoom_out(ZOOM_BTN_INCREMENT)
