extends Node3D

var parent: CharacterBody3D
var velocityChaser: Vector3 = Vector3.ZERO  # Track the angular velocity
var spring_strength: float = 710.0  # Controls how fast it accelerates towards target
var damping: float = 5.0 # Controls how fast it slows down after overshooting
func _ready():
	top_level = true
	parent = get_parent()

func _physics_process(delta: float):

	var resultX : Dictionary = spring_damper_exact(global_position.x,velocityChaser.x,parent.global_position.x,0,spring_strength,damping,delta)
								
	velocityChaser.y = resultX.v
	global_position.x = resultX.x
	
	var resultZ : Dictionary = spring_damper_exact(global_position.z,velocityChaser.z,parent.global_position.z,0,spring_strength,damping,delta)
								
	velocityChaser.z = resultZ.v
	global_position.z = resultZ.x

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
