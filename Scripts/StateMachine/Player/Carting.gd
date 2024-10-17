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
@export var cart_turning_speed_modifier: float = 1.4
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
func _ready():
	mailcart = GameManager.get_mail_cart()
	persistent_state.reparent(mailcart, true)
	persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_X, true)
	persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Z, true)
	persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Y, true)
	mailcart.get_node("PlayerCollider").set_disabled(false)
	#set_colliders_enabed("Carting_Collider",true)
	cart_audio = mailcart.find_child("AudioStreamPlayer3D2")
	cart_audio.stream = preload("res://Assets/Audio/SoundFX/Cart.mp3")
	cart_audio.volume_db = target_volume
	
	EventBus.emitCustomSignal("hide_icon")
	gui_anim = Gui.get_control_displayer()
	is_carting = true
	hinge_joint = find_child("HingeJoint")

func _input(event):
	#Mouse
	if event is InputEventMouseMotion:
		neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-110), deg_to_rad(110))
		
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-75), deg_to_rad(75))
		
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
	handle_head_bopping(delta)

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
	calculate_rotation_velocity(input_dir, delta)
	calculate_linear_velocity(delta)

func calculate_linear_velocity(delta):
	if abs(direction.y) > 0:
		# Get the forward direction in the object's local space (usually -Z axis in 3D)
		var local_forward = Vector3(0, 0, 1)  # Forward in local space is usually the negative Z-axis, but we are funky
		# Convert the local forward direction to the global space using the object's current transform
		var global_forward = mailcart.transform.basis * local_forward
		#if abs(mailcart.linear_velocity)  
		
		mailcart.linear_velocity = global_forward * direction.y * current_speed

func calculate_rotation_velocity(input_dir: Vector2, delta):
	if abs(direction.x) > 0:
		#var velocity_difference := (Quaternion.from_euler(global_rotation).inverse() * mailcart.linear_velocity)
		var global_velocity = mailcart.linear_velocity
		var local_velocity = mailcart.transform.basis.inverse() * global_velocity
		forward_velocity_signswitch_cooldown = lerp(forward_velocity_signswitch_cooldown, 1.0, delta * 1.33)
		if local_velocity.z > 0 and abs(local_velocity.z) > 0.05:
			if sign == 1:
				forward_velocity_signswitch_cooldown = 0
				sign = 0 
			mailcart.angular_velocity.y = direction.x * cart_turning_speed_modifier * forward_velocity_signswitch_cooldown
		else:
			if sign == 0:
				forward_velocity_signswitch_cooldown = 0
				sign = 1
			mailcart.angular_velocity.y = -direction.x * cart_turning_speed_modifier * forward_velocity_signswitch_cooldown

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
