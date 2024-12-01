extends State
class_name CartingState

# Node references
@onready var neck = get_parent().get_node("Neck")
@onready var head = neck.get_node("Head")
@onready var headbop_root = head.get_node("HeadbopRoot")
@onready var mailcart: RigidBody3D

# Audio player for the cart
var cart_audio: AudioStreamPlayer3D

# Exported variables for customization
@export var cart_acceleration_lerp_speed: float = 6.85
@export var cart_rotation_lerp_speed: float = 4.85

@export var cart_sprinting_speed: float = 6.65
@export var cart_walking_speed: float = 3.65
@export var cart_turning_speed_modifier: float = 2.4
@export var volume_fade_speed: float = 3.0  # Speed at which the volume fades

# Headbopping
const head_bopping_walking_frequency:float = 12
@export var head_bopping_walking_intensity:float = 0.1
const head_bopping_sprinting_frequency:float = 16.5
@export var head_bopping_sprinting_intensity:float = 0.2
var head_bopping:Vector2 = Vector2.ZERO
var head_bopping_sinetime:float = 0.0
var head_bopping_current_speed:float = 0.0

# Movement variables
var forward_velocity_signswitch_cooldown: float = 0
var directionX: Vector3 = Vector3.ZERO
var directionZ: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.ZERO
var _rotate: float = 0.0
var was_moving: bool = false
var target_volume: float = -80.0
var hinge_joint
# GUI and carting state
var gui_anim
var is_carting
var sign = 0
var drifting = false
var handlePos: Node3D

var initial_rotation_offset: Quaternion = Quaternion.IDENTITY  # To store the initial offset
var current_cumulative_rotation: Vector3 = Vector3.ZERO  # Track cumulative rotations for the camera
var current_head_quat: Quaternion
var previous_head_quat: Quaternion  # Store the previous frame's head rotation in quaternion
var target_cumulative_rotation: Vector3 = Vector3.ZERO  # Track cumulative rotations for the target
var angular_velocity: Vector3 = Vector3.ZERO  # Track the angular velocity
var spring_strength: float = 210.0  # Controls how fast it accelerates towards target
var damping: float = 15.0 # Controls how fast it slows down after overshooting
var mailcartRotation: Quaternion

func _ready():
	mailcart = GameManager.get_mail_cart()
	#persistent_state.reparent(mailcart, true)
	#persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_X, true)
	#persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Z, true)
	#persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Y, true)
	mailcart.get_node("PlayerCollider").set_disabled(false)
	#set_colliders_enabed("Carting_Collider",true)
	cart_audio = mailcart.find_child("AudioStreamPlayer3D2")
	cart_audio.stream = preload("res://Assets/Audio/SoundFX/Cart.mp3")
	cart_audio.volume_db = target_volume
	
	EventBus.emitCustomSignal("hide_icon")
	gui_anim = Gui.get_control_displayer()
	is_carting = true
	hinge_joint = find_child("HingeJoint")
	
	handlePos = mailcart.find_child("Handlebar").find_child("PlayerPosition")
	#head.top_level = true
	
	#previous_head_quat = Quaternion.IDENTITY #head.global_transform.basis.get_rotation_quaternion()
	#current_head_quat = head.global_transform.basis.get_rotation_quaternion()
	#target_cumulative_rotation = head.rotation
	current_cumulative_rotation = mailcart.rotation

func _input(event):
	#Mouse
	if event is InputEventMouseMotion:
		#neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		#neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-110), deg_to_rad(110))
		
		#head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		#head.rotation.x = clamp(head.rotation.x, deg_to_rad(-75), deg_to_rad(75))
		
		persistent_state.rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		
		
		get_viewport().set_input_as_handled()
	if Input.is_action_pressed("drive"):
		releaseCart()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	handle_gui_animation()
	update_cart_speed(delta)
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	# Turn Directions
	direction.x = lerp(direction.x, input_dir.x, delta * cart_rotation_lerp_speed)
	# Forward/Backward Direction
	direction.y = lerp(direction.y, input_dir.y, delta * cart_acceleration_lerp_speed)
	
	
	var targetPosition = Vector3(handlePos.global_position.x, persistent_state.global_position.y, handlePos.global_position.z)
	
	persistent_state.global_position = targetPosition
	
	handle_head_bopping(delta)
	handle_cart_audio(delta)
	#var parent_rotation = mailcart.rotation
	#head.set_rotation(- parent_rotation)

func handle_gui_animation():
	gui_anim.show_icon(false)

func update_cart_speed(delta):
	if Input.is_action_pressed("sprint"):
		current_speed = cart_sprinting_speed
		head_bopping_current_speed = head_bopping_sprinting_intensity
		head_bopping_sinetime += head_bopping_sprinting_frequency * delta
	else:
		current_speed = cart_walking_speed
		head_bopping_current_speed = head_bopping_walking_intensity
		head_bopping_sinetime += head_bopping_walking_frequency * delta
		head_bopping_sinetime += delta

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	
	
	calculate_sideways_counter_force(delta)
	deaccelerate_forwards_momentum(delta)
	calculate_rotation_velocity(input_dir, delta)
	calculate_linear_velocity(delta)
	
	
	
		
		# Get the velocity of the mailcart
	var velocity = mailcart.linear_velocity

	## Check if the velocity is significant enough to calculate rotation
	#if velocity.length() > 0.001:  # Adjust the threshold as needed
		## Calculate the target position for look_at by projecting the velocity onto the XZ plane
		#var velocity_xz = Vector3(velocity.x, 0, velocity.z).normalized()
		#var target_position = mailcart.global_transform.origin + velocity_xz
#
		## Use look_at to calculate the rotation
		#var new_transform = mailcart.global_transform
		#new_transform = new_transform.looking_at(target_position, Vector3.UP)
#
		## Smoothly interpolate to the new rotation
		#var interpolation_factor = delta * 5.0  # Adjust the speed factor as needed
		#mailcart.global_transform.basis = mailcart.global_transform.basis.slerp(new_transform.basis, interpolation_factor)



	## Get the target rotation from the head
	#var head_global_transform = persistent_state.global_transform
	#var target_rotation = head_global_transform.basis.get_euler()
#
	## Limit the rotation to the Y-axis only
	#var target_quaternion = Quaternion(Vector3.UP, target_rotation.y)
#
	## Get the current rotation of the mailcart (limited to Y-axis)
	#var mailcart_transform = mailcart.global_transform
	#var current_rotation = mailcart_transform.basis.get_euler()
	#var current_quaternion = Quaternion(Vector3.UP, current_rotation.y)
#
	## Interpolate between the current and target rotations
	#current_quaternion = slerp_generic(current_quaternion, target_quaternion, delta * 5.0) # Adjust speed factor
#
	## Apply the new rotation to the mailcart
	#var new_basis = Basis(current_quaternion)
	#mailcart.global_transform.basis = new_basis
	
	
	
	
	
	if !Input.is_action_pressed("inspect"):
		current_head_quat = head.global_transform.basis.get_rotation_quaternion()
	# Apply the initial offset to the head's quaternion
	# Extract only the Y-axis rotation from the initial offset
	var y_only_offset = Quaternion(Vector3.UP, initial_rotation_offset.get_euler().y)
	
	# Apply only the Y-axis offset to the head's rotation
	var adjusted_head_quat = current_head_quat

	# Convert adjusted quaternion to Euler angles
	var current_head_euler = adjusted_head_quat.get_euler()
	var previous_head_euler = previous_head_quat.get_euler()

	target_cumulative_rotation.y = accumulate_continuous_rotation(
		target_cumulative_rotation.y, 
		current_head_euler.y, 
		previous_head_euler.y
	)

	# Store the current head rotation quaternion for the next frame comparison
	previous_head_quat = adjusted_head_quat


	# Compute the rotational difference between current and target
	var rotational_difference = target_cumulative_rotation - current_cumulative_rotation 
	
	var resultY : Dictionary = spring_damper_exact(current_cumulative_rotation.y,angular_velocity.y,target_cumulative_rotation.y,0,spring_strength / (1+calculate_difference(current_cumulative_rotation.y, target_cumulative_rotation.y)*2.25),damping,delta )
								
	angular_velocity.y = resultY.v

	# Update the current rotation with the angular velocity
	current_cumulative_rotation.y = resultY.x

	# Convert the cumulative rotation (Euler angles) to a quaternion
	mailcartRotation = Quaternion.from_euler(current_cumulative_rotation)

	# Apply the new rotation to the mailcart
	mailcart.transform.basis = Basis(mailcartRotation)



func calculate_sideways_counter_force(delta):
	var local_right = Vector3(1, 0, 0)
	var global_right = mailcart.transform.basis * local_right  # Transform local right to global right
	var velocity_in_right = mailcart.linear_velocity.dot(global_right)  # Project linear velocity onto global right
	
	mailcart.linear_velocity -= global_right * velocity_in_right * 0.05
	
	
func deaccelerate_forwards_momentum(delta):
	var local_forward = Vector3(0, 0, 1)  # Forward in local space is usually the negative Z-axis, but we are funky
	# Convert the local forward direction to the global space using the object's current transform
	var global_forward = mailcart.global_transform.basis * local_forward
	var velocity_in_forward = mailcart.linear_velocity.dot(global_forward)  # Project linear velocity onto global right
	if(abs(direction.y) > 0.5):
		mailcart.linear_velocity -= global_forward * velocity_in_forward * 0.05
	else:
		
		mailcart.linear_velocity -= global_forward * velocity_in_forward * 0.02
	

func calculate_linear_velocity(delta):
	if abs(direction.y) > 0:
		# Get the forward direction in the object's local space (usually -Z axis in 3D)
		var local_forward = Vector3(0, 0, 1)  # Forward in local space is usually the negative Z-axis, but we are funky
		# Convert the local forward direction to the global space using the object's current transform
		
		var global_forward = head.global_transform.basis * local_forward
		
		if Input.is_action_pressed("inspect"):
			global_forward = mailcart.global_transform.basis * local_forward

		
		mailcart.linear_velocity += global_forward * direction.y * current_speed *0.09


func calculate_rotation_velocity(input_dir: Vector2, delta):
	if abs(direction.x) > 0:
		#var velocity_difference := (Quaternion.from_euler(global_rotation).inverse() * mailcart.linear_velocity)
		#var global_velocity = mailcart.linear_velocity
		#var local_velocity = mailcart.transform.basis.inverse() * global_velocity
		#forward_velocity_signswitch_cooldown = lerp(forward_velocity_signswitch_cooldown, 1.0, delta * 1.33)
		#if local_velocity.z > 1.1:# and abs(local_velocity.z) > 0.05:
			#if sign == 1:
			#	forward_velocity_signswitch_cooldown = 0
			#	sign = 0 
		#	mailcart.angular_velocity.y = direction.x * cart_turning_speed_modifier * forward_velocity_signswitch_cooldown
		#else:
			#if sign == 0:
			#	forward_velocity_signswitch_cooldown = 0
			#	sign = 1
		#	mailcart.angular_velocity.y = -direction.x * cart_turning_speed_modifier * forward_velocity_signswitch_cooldown
		var local_right = Vector3(1, 0, 0)
		var global_right = mailcart.global_transform.basis * local_right
		mailcart.linear_velocity += global_right * direction.x * current_speed *0.09

func stop_linear_movement(delta):
	pass
	#mailcart.linear_velocity.z = move_toward(mailcart.linear_velocity.z, 0, delta * 1.33)
	#mailcart.linear_velocity.x = move_toward(mailcart.linear_velocity.x, 0, delta * 1.33)

func handle_cart_audio(_delta):
	var is_moving = mailcart.linear_velocity.length() > 0.1
	if is_moving and is_carting:
		target_volume = -10.0
		start_cart_audio()
	else:
		target_volume = -80.0
		was_moving = is_moving

func update_audio_volume(delta):
	if cart_audio:
		cart_audio.volume_db = lerp(cart_audio.volume_db, target_volume, delta * volume_fade_speed)

func releaseCart():
	mailcart.get_node("PlayerCollider").set_disabled(true)
	is_carting = false
	stop_cart_audio()
	mailcart.get_node("Handlebar").set_collision_layer_value(2, true)
	persistent_state.set_collision_layer_value(3, true)
	persistent_state.set_collision_mask_value(1, true)
	persistent_state.set_collision_mask_value(2, true)
	persistent_state.set_collision_mask_value(4, true)
	persistent_state.reparent(mailcart.get_parent())
	neck.position = Vector3(0, 1.8, 0)
	neck.rotation = Vector3.ZERO
	change_state.call("walking")
	persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_X, false)
	persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Z, false)
	persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Y, false)
	#set_colliders_enabled("Carting_Collider",false)

func handle_head_bopping(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	# "Linear" headbop
	if abs(input_dir.y) > 0:
		if abs(direction.y) > 0.05:
			head_bopping.y = sin(head_bopping_sinetime)
			headbop_root.position.y = lerp(headbop_root.position.y, head_bopping.y * 0.1, delta)
	else:
		headbop_root.position.y = lerp(headbop_root.position.y, 0.0, delta * 3)
		
	# "Angular" headbop
	if abs(input_dir.x) > 0:
		if direction.x > 0.05:
			head_bopping.x = sin(head_bopping_sinetime * 0.425 + 0.5)
			headbop_root.position.x = lerp(headbop_root.position.x, head_bopping.x * 0.16 + 0.12, delta)
		elif direction.x < 0.05:
			head_bopping.x = sin(head_bopping_sinetime * 0.425 + 0.5)
			headbop_root.position.x = lerp(headbop_root.position.x, head_bopping.x * 0.16 - 0.12, delta)
	else:
		headbop_root.position.x = lerp(headbop_root.position.x, 0.0, delta * 5.5)

func set_colliders_enabled(group_name: String,enabled:bool) -> void:
	for collider in get_tree().get_nodes_in_group(group_name):
		collider.disabled = not enabled
		
func start_cart_audio():
	if cart_audio and not cart_audio.is_playing():
		cart_audio.play()

func stop_cart_audio():
	if cart_audio:
		cart_audio.stop()



#DONT LOOK DOWN HERE

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

func calculate_difference(no_1, no_2):
	var angle = abs(no_1 - no_2)
	#if angle > 90.0:
		#return 180.0 - angle
	return angle

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
