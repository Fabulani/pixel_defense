class_name Enemy extends Area2D

var _path_follow: PathFollow2D
var _health = 15
var _speed = 50

func setup(new_path_follow: PathFollow2D):
	_path_follow = new_path_follow

func _ready():
	add_to_group("enemies")

func _process(delta: float) -> void:
	_path_follow.progress += _speed*delta
	if _path_follow.progress_ratio >= 0.99:
		queue_free()


func _on_area_entered(bullet: Area2D):
	_health -= 1
	if _health <= 0:
		queue_free()
	bullet.queue_free()
