extends Camera2D

var drag: bool
@export var acceleration: float = 3

func _input(event):
	if event is InputEventMouseButton and event.button_index == 3:
		drag = event.pressed
	if event is InputEventMouseMotion:
		if drag:
			position -= event.relative * acceleration
