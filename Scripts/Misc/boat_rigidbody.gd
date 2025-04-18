extends RigidBody3D

@export var float_offset := 0.2  # Height above water
@export var rock_speed := 1.0  # Speed of the rocking motion
@export var rock_amount := 0.1  # Amount of rocking (in radians)
@export var forward_speed := 5.0  # Speed when rowing forward
@export var turn_speed := 2.0  # Speed of turning
@export var row_cooldown := 1.0

# Spring-damper parameters
@export var spring_strength := 555.0  # Controls how fast it accelerates towards target
@export var linear_damping := 25.0  # Controls how fast it slows down after overshooting

@export var angular_spring_strength := 155.0  # Controls how fast it accelerates towards target
@export var angular_damping := 1.0  # Controls how fast it slows down after overshooting

var can_row := true
var can_turn := true
var left := false
var right := false
var time := 0.0
var forward := false

# Spring-damper state variables
var angular_vel := Vector3.ZERO
var current_cumulative_rotation := Vector3.ZERO
var target_cumulative_rotation := Vector3.ZERO

@onready var water = $"../Water"
var boating:bool = false
func _ready():
	# Initialize the current rotation to match the target
	current_cumulative_rotation = Vector3.ZERO
	target_cumulative_rotation = Vector3.ZERO
	angular_vel = Vector3.ZERO



func _process(delta: float) -> void:
	#if event is InputEventKey:
	if boating:
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		if input_dir.length() != 0:
			if can_row:
				var angle = self.rotation
				var dir = 1
				if(input_dir.y > 0):
					dir = -1
				self.apply_torque_impulse(Vector3(0,-input_dir.x*dir,0)*basis*mass*0.5)
				self.apply_impulse(-self.basis.z*100 * -input_dir.y,self.basis*Vector3(0,0,0.5))
				self.apply_impulse(-Vector3.UP*20 * -input_dir.y,self.basis*Vector3(0,0,0.5))
				forward = true
				can_row = false
				await get_tree().create_timer(row_cooldown).timeout
				can_row = true
				forward = false
			#if event.pressed:
				#print("pressed")
				#match event.keycode:
					#KEY_UP:
						#print("Key Up")
						#if can_row:
							#var angle = self.rotation
							#print("Can Row")
							#self.apply_central_impulse(self.basis.z*2000)
							#forward = true
							#can_row = false
							#await get_tree().create_timer(row_cooldown).timeout
							#can_row = true
							#forward = false
					#KEY_LEFT:
						#left = true
					#KEY_RIGHT:
						#right = true
			#else:
				#match event.keycode:
					#KEY_LEFT:
						#left = false
					#KEY_RIGHT:
						#right = false

func _physics_process(delta: float) -> void:
	var global_rot = basis*Vector3.UP
	var angle_between = max(2-Vector3.UP.angle_to(global_rot),0)
	var push_dir = Vector3.UP#Vector3(-global_rot.x*0.2,1,-global_rot.z*0.2)
	var strength = 8500*delta*mass
	
	
	# 1. Get local right vector in global space
	var right = global_transform.basis.x.normalized()

	# 2. Project the linear velocity onto the right vector (sideways component)
	var lateral_speed = right.dot(linear_velocity)
	var lateral_velocity = right * lateral_speed

	var drag_strength = 10*delta*mass
	# 3. Apply opposing drag force
	var lateral_drag_force = -lateral_velocity * drag_strength
	apply_force(lateral_drag_force)
	
	if(global_position.y < angle_between):
		self.apply_force(push_dir.normalized()*(angle_between*0.2-global_position.y)*strength,Vector3(global_rot.x,0,global_rot.z)*0.15)
		
		# Apply spring-damper physics to each axis with adjusted parameters
		var result = spring_damper_exact(linear_velocity.y,linear_velocity.y,0,0,spring_strength,linear_damping,delta)
		linear_velocity.y = result.x
		
		result = spring_damper_exact(angular_velocity.y,angular_velocity.y,0,0,angular_spring_strength,angular_damping,delta)
		angular_velocity.y = result.x
		current_cumulative_rotation.y = result.x
		
		result = spring_damper_exact(angular_velocity.x,angular_velocity.x,0,0,angular_spring_strength,angular_damping,delta)
		angular_velocity.x = result.x
		current_cumulative_rotation.x = result.x
		
		result = spring_damper_exact(angular_velocity.z,angular_velocity.z,0,0,angular_spring_strength,angular_damping,delta)
		angular_velocity.z = result.x
		current_cumulative_rotation.y = result.x
		
		#var resultX : Dictionary = spring_damper_exact(current_cumulative_rotation.x,angular_velocity.x,shaken_target_rotation.x,0,spring_strength,damping,delta)
		#var resultY : Dictionary = spring_damper_exact(current_cumulative_rotation.y,angular_velocity.y,shaken_target_rotation.y,0,spring_strength,damping,delta)
		#var resultZ : Dictionary = spring_damper_exact(current_cumulative_rotation.z,angular_velocity.z,shaken_target_rotation.z,0,spring_strength,damping,delta)
		#angular_velocity.x = resultX.v
		#angular_velocity.y = resultY.v
		#angular_velocity.z = resultZ.v
		#current_cumulative_rotation.x = resultX.x
		#current_cumulative_rotation.y = resultY.x
		#current_cumulative_rotation.z = resultZ.x
		
		linear_damp = max(0.0, (Vector3.UP.angle_to(global_rot) - global_position.y) * 0.25 + pow(linear_velocity.length(), 1.1) * 0.15)
		#angular_damp = angle_between*1
	else:
		linear_damp = 0
		angular_damp = 0

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
