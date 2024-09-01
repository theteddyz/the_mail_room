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
@export var cart_movement_lerp_speed: float = 3.85
@export var cart_sprinting_speed: float = 5.2
@export var cart_walking_speed: float = 3.8
@export var cart_turning_speed_modifier: float = 0.13
@export var volume_fade_speed: float = 3.0  # Speed at which the volume fades

# Movement variables
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
func _ready():
	mailcart = GameManager.get_mail_cart()
	persistent_state.reparent(mailcart, true)
	persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_X, true)
	persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Z, true)
	persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Y, true)

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
	update_cart_speed()
	handle_gui_animation()
	update_movement_direction(delta)
	handle_cart_audio(delta)
	persistent_state.move_and_slide()
	update_audio_volume(delta)

func _physics_process(delta):
	apply_movement(delta)

func update_cart_speed():
	if Input.is_action_pressed("sprint"):
		current_speed = cart_sprinting_speed
	else:
		current_speed = cart_walking_speed

func handle_gui_animation():
	gui_anim.show_icon(false)

func update_movement_direction(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var movement_direction = (mailcart.global_basis * Vector3(0, 0, input_dir.y)).normalized()
	direction = direction.lerp(movement_direction, delta * cart_movement_lerp_speed)

func apply_movement(delta):
	if direction.length() > 0.1:
		mailcart.linear_velocity.x = direction.x * current_speed
		mailcart.linear_velocity.z = direction.z * current_speed
	update_rotation(delta)
	if direction.length() <= 0.1:
		stop_movement(delta)

func update_rotation(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var horizontal_input_normalized = Vector2(input_dir.x, 0).normalized()
	var velocity_difference := (Quaternion.from_euler(global_rotation).inverse() * mailcart.linear_velocity)
	if horizontal_input_normalized.length() > 0.1 and input_dir.y != 0:
		if velocity_difference.z < 0:
			_rotate = lerp(_rotate, deg_to_rad(0.5 * -input_dir.x * mailcart.linear_velocity.length()), delta * 5)
		else:
			_rotate = lerp(_rotate, deg_to_rad(0.5 * input_dir.x * mailcart.linear_velocity.length()), delta * 5)
		mailcart.rotate_y(_rotate)
	else:
		if velocity_difference.z < 0:
			_rotate = lerp(_rotate, deg_to_rad(0.5 * -input_dir.x * mailcart.linear_velocity.length()), delta * 5)
		else:
			_rotate = lerp(_rotate, deg_to_rad(0.5 * input_dir.x * mailcart.linear_velocity.length()), delta * 5)
		mailcart.rotate_y(_rotate)
		
func stop_movement(delta):
	mailcart.linear_velocity.z = move_toward(mailcart.linear_velocity.z, 0, delta * 2)
	mailcart.linear_velocity.x = move_toward(mailcart.linear_velocity.x, 0, delta * 2)

func handle_cart_audio(_delta):
	var is_moving = persistent_state.velocity.length() > 0.1
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
	is_carting = false
	stop_cart_audio()
	mailcart.get_node("Node3D").get_node("Handlebar").set_collision_layer_value(2, true)
	persistent_state.set_collision_layer_value(3, true)
	persistent_state.reparent(mailcart.get_parent())
	neck.position = Vector3(0, 1.8, 0)
	neck.rotation = Vector3.ZERO
	change_state.call("walking")
	persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_X, false)
	persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Z, false)
	persistent_state.set_axis_lock(PhysicsServer3D.BodyAxis.BODY_AXIS_LINEAR_Y, false)
	#set_colliders_enabled("Carting_Collider",false)

func set_colliders_enabled(group_name: String,enabled:bool) -> void:
	for collider in get_tree().get_nodes_in_group(group_name):
		collider.disabled = not enabled
		
func start_cart_audio():
	if cart_audio and not cart_audio.is_playing():
		cart_audio.play()

func stop_cart_audio():
	if cart_audio:
		cart_audio.stop()
