extends Area2D

var path_follow: PathFollow2D

func setup(new_path_follow: PathFollow2D):
	path_follow = new_path_follow


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	path_follow.progress += 200*delta
	if path_follow.progress_ratio >= 0.99:
		print("damage")
		queue_free()


func _on_area_entered(bullet: Area2D):
	bullet.queue_free()
