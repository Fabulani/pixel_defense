class_name CameraShake extends Node

## Trauma-based screen shake. Child of a [Camera2D]; writes only [member Camera2D.offset].

## Trauma lost per second.
@export var decay_per_second: float = 1.5
## Maximum offset in screen pixels at full strength.
@export var max_offset: float = 6.0
## Noise sampling speed along time.
@export var noise_speed: float = 60.0

var _trauma: float = 0.0
var _time: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()
@onready var _camera: Camera2D = get_parent() as Camera2D


func _ready() -> void:
	# Keep playing while the tree is paused (end screen); the camera itself stays pausable.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0
	_noise.seed = randi()
	set_process(false)


## Add [param amount] of trauma, clamped to 0..1.
func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)
	if _trauma > 0.0:
		set_process(true)


func _process(delta: float) -> void:
	_trauma = maxf(_trauma - decay_per_second * delta, 0.0)
	if _trauma <= 0.0:
		_camera.offset = Vector2.ZERO
		set_process(false)
		return
	_time += delta * noise_speed
	var strength: float = _trauma * _trauma
	var noise_offset: Vector2 = Vector2(_noise.get_noise_2d(_time, 0.0), _noise.get_noise_2d(_time, 100.0))
	_camera.offset = noise_offset * max_offset * strength / _camera.zoom.x
