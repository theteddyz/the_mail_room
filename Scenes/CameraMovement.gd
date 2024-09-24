extends Camera3D

var head: Node3D

var chasingRot: Quaternion

# Variables for angular velocity and acceleration
var angular_velocity: Vector3 = Vector3.ZERO  # Track the angular velocity
var spring_strength: float = 100.0#60.0  # Controls how fast it accelerates towards target
var damping: float = 15.0  # Controls how fast it slows down after overshooting

# Variables for velocity and acceleration for position
var position_velocity: Vector3 = Vector3.ZERO
var position_spring_strength: float = 80.0#50.0  # Controls how fast it accelerates towards target
var position_damping: float = 15.0  # Controls how fast it slows down after overshooting

var cameraRotation: Quaternion

var shouldEnable: bool = false

func _ready() -> void:
	
	head = get_parent()

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

func _input(event):
	if event.is_action_pressed("O"):
		shouldEnable = true
		var player = GameManager.get_player()
		var walkingScript = player.state
		walkingScript.head_bopping_walking_intensity = 0.2 #0.1
		walkingScript.head_bopping_sprinting_intensity = 0.4 #0.2
		walkingScript.head_bopping_crouching_intensity = 0.1 # 0.05
		global_transform = head.global_transform
		cameraRotation = Quaternion(head.global_transform.basis.get_rotation_quaternion())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if shouldEnable:
		# Get the target position (head global position)
		
		
		
		var target_position = head.global_position
		#target_position.y += 0.3

		# Compute the positional difference between the current and target positions
		var position_difference = target_position - global_position

		# Calculate a "spring" force towards the target position
		var position_acceleration = position_difference * position_spring_strength
		#position_acceleration.y += -982*delta

		# Update the velocity with acceleration and apply damping
		position_velocity += position_acceleration * delta
		position_velocity *= 1 - delta*position_damping
		#position_velocity -= position_velocity * position_damping * delta  # Apply damping to slow down overshooting

		# Update the position using the velocity
		global_position += position_velocity * delta
		

		var current_rot = cameraRotation
		var target_rot_smooth = Quaternion(head.global_transform.basis.get_rotation_quaternion())
		
		
		var smoothrot = slerp_generic(current_rot,target_rot_smooth, delta*70)



		# Get the current and target rotations in quaternion form
		var target_rot = smoothrot

		# Compute the rotational difference between current and target
		var rotational_difference = (current_rot.inverse() * target_rot).get_euler()

		# Calculate a "spring" force towards the target rotation
		var angular_acceleration = rotational_difference * spring_strength

		# Update the angular velocity with acceleration and apply damping
		angular_velocity += angular_acceleration * delta
		angular_velocity *= 1 - delta*damping
		#angular_velocity -= angular_velocity * damping * delta  # Apply damping to slow down overshooting

		# Convert the angular velocity (Euler angles) back to a quaternion using from_euler
		var angular_velocity_quat = Quaternion()
		angular_velocity_quat = Quaternion.from_euler(angular_velocity * delta)

		# Update the current rotation with the angular velocity
		var new_rotation = current_rot * angular_velocity_quat

		# Set the new rotation
		cameraRotation = new_rotation
		global_transform.basis = Basis(cameraRotation)
		global_rotation.z = angular_velocity.z*0.15
	else:
		global_transform = head.global_transform
