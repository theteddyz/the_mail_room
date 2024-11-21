extends Camera3D

var head: Node3D

var chasingRot: Quaternion

# Variables for velocity and acceleration for position
var position_velocity: Vector3 = Vector3.ZERO
var position_spring_strength: float = 100.0#50.0  # Controls how fast it accelerates towards target
var position_damping: float = 20.0   # Controls how fast it slows down after overshooting


# Variables for angular velocity and acceleration
var angular_velocity: Vector3 = Vector3.ZERO  # Track the angular velocity
var spring_strength: float = 150.0  # Controls how fast it accelerates towards target
var damping: float = 20.0 # Controls how fast it slows down after overshooting

# Cumulative rotations for the camera
var current_cumulative_rotation: Vector3 = Vector3.ZERO  # Track cumulative rotations for the camera

var previous_head_quat: Quaternion  # Store the previous frame's head rotation in quaternion
var target_cumulative_rotation: Vector3 = Vector3.ZERO  # Track cumulative rotations for the target

var cameraRotation: Quaternion
var currentZRotation: float

var shouldEnable: bool = false

var followingVelocity: Vector3 = Vector3.ZERO
var previousFollowingVelocity: Vector3 = Vector3.ZERO
var velocityLerpTowards: Vector3 = Vector3.ZERO

var initial_rotation_offset: Quaternion = Quaternion.IDENTITY  # To store the initial offset

func _ready() -> void:
	top_level = false
	head = get_parent()
	previous_head_quat = Quaternion.IDENTITY #head.global_transform.basis.get_rotation_quaternion()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	if shouldEnable:
		# Get the current and previous rotation of the head in quaternions
		var current_head_quat = head.global_transform.basis.get_rotation_quaternion()

		# Apply the initial offset to the head's quaternion
		# Extract only the Y-axis rotation from the initial offset
		var y_only_offset = Quaternion(Vector3.UP, initial_rotation_offset.get_euler().y)
		
		# Apply only the Y-axis offset to the head's rotation
		var adjusted_head_quat = current_head_quat

		# Convert adjusted quaternion to Euler angles
		var current_head_euler = adjusted_head_quat.get_euler()
		var previous_head_euler = previous_head_quat.get_euler()

		# Accumulate the target's rotation, allowing for multiple flips
		target_cumulative_rotation.x = accumulate_continuous_rotation(
			target_cumulative_rotation.x, 
			current_head_euler.x, 
			previous_head_euler.x
		)
		target_cumulative_rotation.y = accumulate_continuous_rotation(
			target_cumulative_rotation.y, 
			current_head_euler.y, 
			previous_head_euler.y
		)
		target_cumulative_rotation.z = accumulate_continuous_rotation(
			target_cumulative_rotation.z, 
			current_head_euler.z, 
			previous_head_euler.z
		)

		# Store the current head rotation quaternion for the next frame comparison
		previous_head_quat = adjusted_head_quat


		# Compute the rotational difference between current and target
		var rotational_difference = target_cumulative_rotation - current_cumulative_rotation 

		# Apply the spring force and damping
		#var angular_acceleration = rotational_difference * spring_strength 
		#angular_velocity += angular_acceleration * (pow(damping, delta) - 1.0)/log(damping);
		#angular_velocity *= pow(damping, delta)
		#print(pow(damping, delta))
		
		var resultX : Dictionary = spring_damper_exact(current_cumulative_rotation.x,angular_velocity.x,target_cumulative_rotation.x,0,spring_strength,damping,delta)
		var resultY : Dictionary = spring_damper_exact(current_cumulative_rotation.y,angular_velocity.y,target_cumulative_rotation.y,0,spring_strength,damping,delta)
		var resultZ : Dictionary = spring_damper_exact(current_cumulative_rotation.z,angular_velocity.z,target_cumulative_rotation.z,0,spring_strength,damping,delta)
		#chasingVelArray[symbolIndexInTotal] *= Math.pow(0.3, updateLogicDeltaTime*50);
		#chasingVelArray[symbolIndexInTotal] -= (chasingPosArray[symbolIndexInTotal]-componentDependencies.symbolDependency.getSymbol().getPositionY()) * 0.1 *updateLogicDeltaTime*200  // The force to pull it back to the resting point
											
		angular_velocity.x = resultX.v
		angular_velocity.y = resultY.v
		angular_velocity.z = resultZ.v

		# Update the current rotation with the angular velocity
		current_cumulative_rotation.x = resultX.x
		current_cumulative_rotation.y = resultY.x
		current_cumulative_rotation.z = resultZ.x

		# Convert the cumulative rotation (Euler angles) to a quaternion
		cameraRotation = Quaternion.from_euler(current_cumulative_rotation)
		
		#cameraRotation *= Quaternion.from_euler(Vector3(0,90,0))

		# Apply the new rotation to the camera
		global_transform.basis = Basis(cameraRotation)
		#currentZRotation = lerpf(currentZRotation, angular_velocity.y*0.008, delta*50)
		global_rotation.z += angular_velocity.y*0.008
		
		
		var rotation_quaternion = Quaternion.from_euler(global_rotation)
		followingVelocity = global_position - head.global_position
		velocityLerpTowards = velocityLerpTowards.lerp(((followingVelocity - previousFollowingVelocity)/delta)*0.1, delta*2)
		
		var axis: Vector3 = Vector3(0, 1, 0)  # Example axis: x-axis (change this for y or z)
		var angle: float = deg_to_rad(90)     # 90 degrees in radians

		# Create a quaternion representing a 90-degree rotation around the chosen axis
		var rotation_quat_90 = Quaternion(axis, angle)
		
		#global_rotation += rotation_quat_90 * (rotation_quaternion * velocityLerpTowards);
		previousFollowingVelocity = followingVelocity
		
		
		
		
		
		calculatePosition(delta)
	else:
		pass
		#This was causing me some problems dont know if its needed seems to work fine?
		#global_transform = head.global_transform

func calculatePosition(delta: float):
	
	var target_position = head.global_position
	#target_position.y += 0.3

	# Compute the positional difference between the current and target positions
	var position_difference = target_position - global_position

	# Calculate a "spring" force towards the target position
	var position_acceleration = position_difference * position_spring_strength
	#position_acceleration.y += -982*delta

	# Update the velocity with acceleration and apply damping
	#position_velocity *= pow(position_damping, delta)
	#position_velocity += position_acceleration * delta
	
	var resultX : Dictionary = spring_damper_exact(global_position.x,position_velocity.x,target_position.x,0,position_spring_strength,position_damping,delta)
	var resultY : Dictionary = spring_damper_exact(global_position.y,position_velocity.y,target_position.y,0,position_spring_strength,position_damping,delta)
	var resultZ : Dictionary = spring_damper_exact(global_position.z,position_velocity.z,target_position.z,0,position_spring_strength,position_damping,delta)
		
	position_velocity.x = resultX.v
	position_velocity.y = resultY.v
	position_velocity.z = resultZ.v

	# Update the current rotation with the angular velocity
	global_position.x = resultX.x
	global_position.y = resultY.x
	global_position.z = resultZ.x
	#position_velocity -= position_velocity * position_damping * delta  # Apply damping to slow down overshooting

	# Update the position using the velocity
	#global_position += position_velocity * delta
	



func _input(event):
	if event.is_action_pressed("O"):
		top_level = true
		shouldEnable = true
		var player = GameManager.get_player()
		var walkingScript = player.state
		walkingScript.head_bopping_walking_intensity = 0.2 #0.1
		walkingScript.head_bopping_sprinting_intensity = 0.4 #0.2
		if walkingScript.has_meta("head_bopping_crouching_intensity"):
			walkingScript.head_bopping_crouching_intensity = 0.1 # 0.05
		
		# Set the camera's transform to match the head initially
		#global_transform = head.global_transform
		global_transform.basis = head.global_transform.basis
		
		# Calculate the initial rotation offset between camera and head
		initial_rotation_offset = head.global_transform.basis.get_rotation_quaternion()

		# Initialize rotation state
		current_cumulative_rotation = Vector3.ZERO
		target_cumulative_rotation = Vector3.ZERO
		#previous_head_quat = head.global_transform.basis.get_rotation_quaternion()
	# A function to smoothly interpolate between two quaternions, similar to your slerp_generic
func slerp_generic(q0: Quaternion, q1: Quaternion, t: float) -> Quaternion:
	# If t is too large, divide it by two recursively
	if t > 1.0:
		var tmp = slerp_generic(q0, q1, t / 2)
		return tmp * q0.inverse() * tmp

	# It’s easier to handle negative t this way
	if t < 0.0:
		return slerp_generic(q1, q0, 1.0 - t)

	return q0.slerp(q1, t)

# Function to accumulate rotations based on difference, allowing infinite rotations
func accumulate_continuous_rotation(cumulative_rotation: float, current_euler: float, previous_euler: float) -> float:
	# Calculate the angle difference between current and previous frames
	var delta_angle = current_euler - previous_euler

	# Adjust delta to handle wrapping from 360 to 0 (or vice versa)
	if delta_angle > PI:
		delta_angle -= TAU  # 360 degrees (2 * PI)
	elif delta_angle < -PI:
		delta_angle += TAU

	# Add the delta angle to the cumulative rotation
	return cumulative_rotation + delta_angle

func spring_damper_exact(
	x: float, 
	v: float, 
	x_goal: float, 
	v_goal: float, 
	stiffness: float, 
	damping: float, 
	dt: float, 
	eps: float = 1e-5
) -> Dictionary:
	var g = x_goal
	var q = v_goal
	var s = stiffness
	var d = damping
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
