extends Node3D

@export var float_offset := 0.2  # Height above water
@export var rock_speed := 1.0  # Speed of the rocking motion
@export var rock_amount := 0.1  # Amount of rocking (in radians)
@export var forward_speed := 5.0  # Speed when rowing forward
@export var turn_speed := 2.0  # Speed of turning
@export var row_cooldown := 0.6

# Spring-damper parameters
@export var spring_strength := 15.0  # Controls how fast it accelerates towards target
@export var damping := 5.0  # Controls how fast it slows down after overshooting

var can_row := true
var left := false
var right := false
var time := 0.0
var forward := false

# Spring-damper state variables
var angular_velocity := Vector3.ZERO
var current_cumulative_rotation := Vector3.ZERO
var target_cumulative_rotation := Vector3.ZERO

@onready var water = $"../Water"

func _ready():
	# Initialize the current rotation to match the target
	current_cumulative_rotation = Vector3.ZERO
	target_cumulative_rotation = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_UP:
					if can_row:
						forward = true
						can_row = false
						await get_tree().create_timer(row_cooldown).timeout
						can_row = true
						forward = false
				KEY_LEFT:
					left = true
				KEY_RIGHT:
					right = true
		else:
			match event.keycode:
				KEY_LEFT:
					left = false
				KEY_RIGHT:
					right = false

func _process(delta: float) -> void:
	time += delta
	
	# Calculate target rocking motion with reduced amplitude for testing
	var target_x = sin(time * rock_speed) * rock_amount
	var target_z = cos(time * rock_speed * 0.7) * rock_amount * 0.5
	
	# Update target rotation
	target_cumulative_rotation.x = target_x
	target_cumulative_rotation.z = target_z
	
	# Apply spring-damper physics to each axis with adjusted parameters
	var result_x = spring_damper_exact(
		current_cumulative_rotation.x,
		angular_velocity.x,
		target_cumulative_rotation.x,
		0,
		spring_strength,
		damping,
		delta
	)
	
	var result_z = spring_damper_exact(
		current_cumulative_rotation.z,
		angular_velocity.z,
		target_cumulative_rotation.z,
		0,
		spring_strength,
		damping,
		delta
	)
	
	# Update angular velocity and current rotation
	angular_velocity.x = result_x.v
	angular_velocity.z = result_z.v
	current_cumulative_rotation.x = result_x.x
	current_cumulative_rotation.z = result_z.x
	
	# Apply the rotation with direct mapping
	rotation.x = current_cumulative_rotation.x
	rotation.z = current_cumulative_rotation.z
	
	# Handle turning
	if left:
		rotation.y += turn_speed * delta
	elif right:
		rotation.y -= turn_speed * delta
	
	# Handle forward movement
	if forward:
		var forward_vec = -global_transform.basis.z
		position += forward_vec * forward_speed * delta
	
	position.y = 0.23

# Spring-damper helper functions from camera movement script
func spring_damper_exact(
	x: float, 
	v: float, 
	x_goal: float, 
	v_goal: float, 
	stiffness: float, 
	_damping: float, 
	dt: float, 
	eps: float = 1e-5
) -> Dictionary:
	var g = x_goal
	var q = v_goal
	var s = stiffness
	var d = _damping
	var c = g + (d * q) / (s + eps)
	var y = d / 2.0

	if abs(s - (d * d) / 4.0) < eps:  # Critically Damped
		var j0 = x - c
		var j1 = v + j0 * y
		
		var eydt = fast_negexp(y * dt)
		
		x = j0 * eydt + dt * j1 * eydt + c
		v = -y * j0 * eydt - y * dt * j1 * eydt + j1 * eydt

	elif s - (d * d) / 4.0 > 0.0:  # Under Damped
		var w = sqrt(s - (d * d) / 4.0)
		var j = sqrt(squaref(v + y * (x - c)) / (w * w + eps) + squaref(x - c))
		var p = fast_atan((v + (x - c) * y) / (-(x - c) * w + eps))
		
		j = j if (x - c) > 0.0 else -j
		
		var eydt = fast_negexp(y * dt)
		
		x = j * eydt * cos(w * dt + p) + c
		v = -y * j * eydt * cos(w * dt + p) - w * j * eydt * sin(w * dt + p)

	elif s - (d * d) / 4.0 < 0.0:  # Over Damped
		var y0 = (d + sqrt(d * d - 4 * s)) / 2.0
		var y1 = (d - sqrt(d * d - 4 * s)) / 2.0
		var j1 = (c * y0 - x * y0 - v) / (y1 - y0)
		var j0 = x - j1 - c
		
		var ey0dt = fast_negexp(y0 * dt)
		var ey1dt = fast_negexp(y1 * dt)

		x = j0 * ey0dt + j1 * ey1dt + c
		v = -y0 * j0 * ey0dt - y1 * j1 * ey1dt
	
	return {"x": x, "v": v}

func squaref(x: float) -> float:
	return x * x

func fast_atan(x: float) -> float:
	var z = abs(x)
	var w: float
	if z > 1.0:
		w = 1.0 / z
	else:
		w = z
	var y = (PI / 4.0) * w - w * (w - 1.0) * (0.2447 + 0.0663 * w)
	return sign(x) * (PI / 2.0 - y if z > 1.0 else y)

func fast_negexp(value: float) -> float:
	return exp(-value)
