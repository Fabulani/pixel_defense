class_name SmoothDamp extends Resource

@export_range(0.0, 0.5, 0.01) var pan_smoothing: float = 0.2
@export_range(0.0, 0.5, 0.01) var zoom_smoothing: float = 0.2

# Smooth zoom/pan state
var zoom_goal: Vector2
var position_goal: Vector2
var _damped_zoom: Array[Vector2]
var _damped_pan: Array[Vector2]


## Initialize the state.
func initialize(initial_zoom: Vector2, initial_position: Vector2) -> void:
	zoom_goal = initial_zoom
	position_goal = initial_position
	_damped_zoom = [initial_zoom, Vector2.ZERO]
	_damped_pan = [initial_position, Vector2.ZERO]


## Use smooth damping for zooming.
func smooth_zoom(delta: float) -> Vector2:
	_smooth_damp(_damped_zoom, zoom_goal, zoom_smoothing, delta)
	return _damped_zoom[0]


## Use smooth damping for panning. 
##
## `anchor_offset` can be used to adjust the position goal after zooming, which
## results in a zoom-to-mouse behavior. The expected order of operations is: [br]
## 1. calculate `pre = to_local(get_canvas_transform().affine_inverse() * cursor_viewport_pos)` [br]
## 2. apply `_smooth_zoom()` to Camera2D.zoom [br]
## 3. calculate `post` in the same way as `pre` [br]
## 4. calculate `anchor_offset = pre - post` [br]
## 5. apply `_smooth_pan()` to Camera2D.position [br]
## Note: `cursor_viewport_pos` is the cursor coordinates in screen space.
func smooth_pan(delta: float, anchor_offset: Vector2 = Vector2.ZERO) -> Vector2:
	_apply_anchor_offset(anchor_offset)  # Update anchor offset for zoom-to-mouse behavior
	_smooth_damp(_damped_pan, position_goal, pan_smoothing, delta)
	return _damped_pan[0]


## Helper function that applies the calculated anchor offset.
func _apply_anchor_offset(offset: Vector2) -> void:
	position_goal += offset
	_damped_pan[0] += offset

## Critically-damped spring smoothing. `state` is [current, velocity].
func _smooth_damp(state: Array[Vector2], target: Vector2, smooth_time: float, delta: float) -> void:
	# Speed up the spring for nicer input values 
	# and a behaviour closer to the "actual" time to come to rest
	smooth_time /= 2.0

	if smooth_time == 0.0:
		state[0] = target
		state[1] = Vector2.ZERO
		return

	var current := state[0]
	var velocity := state[1]
	var omega := 2.0 / smooth_time
	var x := omega * delta
	var expo := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change := current - target
	var original_to := target
	target = current - change
	var temp := (velocity + omega * change) * delta
	velocity = (velocity - omega * temp) * expo
	var output := target + (change + temp) * expo

	# Prevent overshooting
	if delta > 0:
		if (original_to.x > current.x) == (output.x > original_to.x):
			output.x = original_to.x
			velocity.x = (output.x - original_to.x) / delta
		if (original_to.y > current.y) == (output.y > original_to.y):
			output.y = original_to.y
			velocity.y = (output.y - original_to.y) / delta

	state[0] = output
	state[1] = velocity
