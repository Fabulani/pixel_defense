extends Camera2D

var drag: bool
@export var acceleration: float = 1
@export var keyboard_speed: float = 300
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 2
@export var max_zoom: float = 6

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == 3:
			drag = event.pressed
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom = Vector2(min(zoom.x + zoom_speed, max_zoom), min(zoom.y + zoom_speed, max_zoom))
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom = Vector2(max(zoom.x - zoom_speed, min_zoom), max(zoom.y - zoom_speed, min_zoom))
	if event is InputEventMouseMotion:
		if drag:
			# TODO: dragged location moves with cursor, as if dragging the map itself
			position -= event.relative * acceleration
	if event is InputEventScreenDrag:
		position -= event.relative * acceleration

func _process(delta):
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
		position += direction.normalized() * keyboard_speed * delta


func _on_hud_zoom_in_btn_pressed() -> void:
	zoom = Vector2(min(zoom.x + zoom_speed*3, max_zoom), min(zoom.y + zoom_speed*3, max_zoom))


func _on_hud_zoom_out_btn_pressed() -> void:
	zoom = Vector2(max(zoom.x - zoom_speed*3, min_zoom), max(zoom.y - zoom_speed*3, min_zoom))
