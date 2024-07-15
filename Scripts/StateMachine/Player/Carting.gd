extends State
class_name CartingState

@onready var neck = get_parent().get_node("Neck")
@onready var head = neck.get_node("Head")
@onready var headbop_root = head.get_node("HeadbopRoot")
@onready var mailcart
var cart_audio:AudioStreamPlayer3D

@export var cart_movement_lerp_speed = 3.85
@export var cart_sprinting_speed = 5.2
@export var cart_walking_speed = 3.8
@export var cart_turning_speed_modifier = 0.13
@export var volume_fade_speed = 3.0  # Speed at which the volume fades
var directionX = Vector3.ZERO
var directionZ = Vector3.ZERO
var direction = Vector3.ZERO
var rotate = 0.0
var was_moving = false
var target_volume = -80.0
# Called when the node enters the scene tree for the first time.
func _ready():
	mailcart = GameManager.get_mail_cart()
	mailcart.reparent(persistent_state, true)
	set_colliders_enabled("Carting_Collider",true)
	cart_audio = mailcart.find_child("AudioStreamPlayer3D")
	cart_audio.stream = preload("res://Assets/Audio/SoundFX/Cart.mp3")
	cart_audio.volume_db = target_volume

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
		if Input.is_action_pressed("sprint"):
			current_speed = cart_sprinting_speed
		else: 
			current_speed = cart_walking_speed
		
		# Get the input direction vector from input actions
		var input_dir = Input.get_vector("left", "right", "forward", "backward")

		# Calculate the movement direction based on the input and the player's basis
		var movement_direction = (persistent_state.global_basis * Vector3(0, 0, input_dir.y)).normalized()

		# Interpolate smoothly between the current direction and the movement direction
		direction = direction.lerp(movement_direction, delta * cart_movement_lerp_speed)

		# Apply movement based on the current speed and direction
		if direction.length() > 0.1:
			persistent_state.velocity.x = direction.x * current_speed
			persistent_state.velocity.z = direction.z * current_speed

		# Separate the rotation input (horizontal input)
		var horizontal_input = Vector2(input_dir.x, 0).normalized()
		var velocity_difference := (Quaternion.from_euler(global_rotation).inverse() * persistent_state.velocity);
		if horizontal_input.length() > 0.1 && input_dir.y != 0:
			# Calculate the target rotation based on the horizontal input
			var target_rotation = atan2(horizontal_input.x, horizontal_input.y)
			var current_rotation = persistent_state.rotation.y
			
			#Calculate relative velocity
			
			
			if velocity_difference.z < 0:
				rotate = lerp(rotate, deg_to_rad(0.5 * -input_dir.x * persistent_state.velocity.length()), delta*5)
				#rotate = deg_to_rad(0.5 * -input_dir.x * persistent_state.velocity.length())
				persistent_state.rotate_y(rotate)
			else :
				rotate = lerp(rotate, deg_to_rad(0.5 * input_dir.x * persistent_state.velocity.length()), delta*5)
				#rotate = deg_to_rad(0.5 * input_dir.x * persistent_state.velocity.length())
				persistent_state.rotate_y(rotate)
		else:
			if velocity_difference.z < 0:
				rotate = lerp(rotate, deg_to_rad(0.5 * -input_dir.x * persistent_state.velocity.length()), delta*5)
				#rotate = deg_to_rad(0.5 * -input_dir.x * persistent_state.velocity.length())
				persistent_state.rotate_y(rotate)
			else :
				rotate = lerp(rotate, deg_to_rad(0.5 * input_dir.x * persistent_state.velocity.length()), delta*5)
				#rotate = deg_to_rad(0.5 * input_dir.x * persistent_state.velocity.length())
				persistent_state.rotate_y(rotate)
			
			#persistent_state.rotate_y(rotate)
			persistent_state.velocity.z = move_toward(persistent_state.velocity.z, 0, delta*2)
			persistent_state.velocity.x = move_toward(persistent_state.velocity.x, 0, delta*2)
			
		if Input.is_action_pressed("drive"):
			releaseCart()
		persistent_state.velocity.y = 0
		persistent_state.move_and_slide()
		var is_moving = persistent_state.velocity.length() > 0.1
		if is_moving:
			target_volume = 0.0 
			if not was_moving:
				start_cart_audio()
		else:
			target_volume = -80.0
		was_moving = is_moving
		cart_audio.volume_db = lerp(cart_audio.volume_db, target_volume, delta * volume_fade_speed)

func releaseCart():
	stop_cart_audio()
	mailcart.reparent(persistent_state.get_parent())
	persistent_state.set_collision_mask_value(5, true)
	neck.position = Vector3(0, 1.8, 0)
	neck.rotation = Vector3.ZERO
	change_state.call("walking")
	set_colliders_enabled("Carting_Collider",false)

#func _physics_process(delta):

func set_colliders_enabled(group_name: String,enabled:bool) -> void:
	for collider in get_tree().get_nodes_in_group(group_name):
		collider.disabled = not enabled
func start_cart_audio():
	if cart_audio:
		cart_audio.play()

func stop_cart_audio():
	if cart_audio:
		cart_audio.stop()
		

