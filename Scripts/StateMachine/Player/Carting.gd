extends State
class_name CartingState

@onready var neck = get_parent().get_node("Neck")
@onready var head = neck.get_node("Head")
@onready var headbop_root = head.get_node("HeadbopRoot")
@onready var crosshair = headbop_root.get_node("Camera").get_node("Control").get_node("Crosshair")
@onready var mailcart = get_parent().get_parent().get_node("Mailcart")

@export var cart_movement_lerp_speed = 3.85
@export var cart_sprinting_speed = 5.2
@export var cart_walking_speed = 3.8
@export var cart_turning_speed_modifier = 0.13

var directionX = Vector3.ZERO
var directionZ = Vector3.ZERO
var direction = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Carting State Ready")
	mailcart.reparent(persistent_state, true)

func _input(event):
	# Mouse
	if event is InputEventMouseMotion:
		neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-110), deg_to_rad(110))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-75), deg_to_rad(75))
		get_viewport().set_input_as_handled()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("drive"):
		releaseCart()
		
	persistent_state.move_and_slide()

func releaseCart():
	mailcart.reparent(persistent_state.get_parent())
	persistent_state.set_collision_mask_value(5, true)
	neck.position = Vector3(0, 1.8, 0)
	change_state.call("walking")

func _physics_process(delta):
		if Input.is_action_pressed("sprint"):
			current_speed = cart_sprinting_speed
		else: 
			current_speed = cart_walking_speed
		
		# TODO: Add FreeLook & Turn from player position		
		
		
		# Get the input direction vector from input actions
		var input_dir = Input.get_vector("left", "right", "forward", "backward")

		# Calculate the movement direction based on the input and the player's basis
		var movement_direction = (persistent_state.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		# Interpolate smoothly between the current direction and the movement direction
		direction = direction.lerp(movement_direction, delta * cart_movement_lerp_speed)

		# Apply movement based on the current speed and direction
		if direction.length() > 0.1:
			persistent_state.velocity.x = direction.x * current_speed
			persistent_state.velocity.z = direction.z * current_speed

		# Separate the rotation input (horizontal input)
		var horizontal_input = Vector2(input_dir.x, 0).normalized()

		if horizontal_input.length() > 0.1:
			# Calculate the target rotation based on the horizontal input
			var target_rotation = atan2(horizontal_input.x, horizontal_input.y)
			var current_rotation = persistent_state.rotation.y

			# Smoothly interpolate the rotation towards the target rotation
			persistent_state.rotation.y = lerp_angle(current_rotation, target_rotation, delta * 2.25)

		#var input_dir = Input.get_vector("left", "right", "forward", "backward")
		#direction = lerp(direction, (persistent_state.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * cart_movement_lerp_speed)
#
		#if direction:
			#persistent_state.velocity.x = direction.x * current_speed
			#persistent_state.velocity.z = direction.z * current_speed
			#persistent_state.rotate_y(deg_to_rad(1) * 2.25 * direction.z)


		#var input_dir = Input.get_vector("left", "right", "forward", "backward")
		#direction = lerp(direction, (persistent_state.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * cart_movement_lerp_speed)
#
		#if direction:
			#persistent_state.velocity.x = direction.x * current_speed
			##persistent_state.velocity.z = direction.z * current_speed
			##persistent_state.rotate_y(deg_to_rad(1.75 * (persistent_state.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized().z))
			#
		#else:
			#persistent_state.velocity.x = move_toward(persistent_state.velocity.x, 0, current_speed)
			##persistent_state.velocity.z = move_toward(persistent_state.velocity.z, 0, 0)
			
		#if directionX or directionZ:
			#persistent_state.velocity.x = -directionX.z * current_speed
			#persistent_state.velocity.z = -directionZ.x * current_speed
		#else:
			#persistent_state.velocity.x = move_toward(persistent_state.velocity.z, 0, current_speed)
			#persistent_state.velocity.z = move_toward(persistent_state.velocity.x, 0, current_speed)
			

