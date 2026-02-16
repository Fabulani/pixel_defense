extends Area2D

var direction: Vector2
var speed := 800

func setup(pos, angle, bullet_enum):
	position = pos
	direction = Vector2.DOWN.rotated(angle)
	rotation = angle
	
func _process(_delta):
	position += direction * speed * _delta
