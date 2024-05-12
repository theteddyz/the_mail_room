extends CharacterBody3D

#UI Nodes
@onready var pause_menu = $"../pauseMenu"

# Player Nodes
@onready var head = $Head
@onready var standing_collision_shape = $standing_collision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var headbop_root = $Head/HeadbopRoot
@onready var interactable_finder = $Head/InteractableFinder
@onready var standing_obstruction_raycast = $Head/StandingObstructionRaycast

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Head Bopping
const head_bopping_sprinting_speed = 20
const head_bopping_walking_speed = 12
const head_bopping_crouching_speed = 9

const head_bopping_crouching_intensity = 0.05
const head_bopping_walking_intensity = 0.1
const head_bopping_sprinting_intensity = 0.2

var head_bopping_vector = Vector2.ZERO
var head_bopping_index = 0.0
var head_bopping_current = 0.0

# Speed variables
@export var walking_speed = 5.0
@export var sprinting_speed = 10.0
@export var crouching_speed = 3.1
@export var jump_velocity = 4.5
@export var mouse_sense = 0.25
@export var movement_lerp_speed = 8.2
@export var crouching_lerp_speed = 0.18


@onready var starting_height = head.position.y
@onready var crouching_depth = starting_height - 0.5

# Privates
var current_speed = 5.0
var direction = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Mouse
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		get_viewport().set_input_as_handled()

func _shortcut_input(event):
	if event.is_action_pressed("escape"):
		pause_menu.game_paused()

func _physics_process(delta):
	# Input / State checks
	if(Input.is_action_pressed("crouch")):
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, crouching_depth, crouching_lerp_speed)
		head_bopping_current = head_bopping_crouching_intensity
		head_bopping_index += head_bopping_crouching_speed * delta
	else:
		# if standing would collide
		if !standing_obstruction_raycast.is_colliding():
			standing_collision_shape.disabled = false
			crouching_collision_shape.disabled = true
			head.position.y = lerp(head.position.y, starting_height, crouching_lerp_speed)
			if Input.is_action_pressed("sprint"):
				current_speed = sprinting_speed
				head_bopping_current = head_bopping_sprinting_intensity
				head_bopping_index += head_bopping_sprinting_speed * delta
			else:
				current_speed = walking_speed
				head_bopping_current = head_bopping_walking_intensity
				head_bopping_index += head_bopping_walking_speed * delta
				

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * movement_lerp_speed)

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		# Head Bopping
		if Vector3(input_dir.x, 0, input_dir.y) != Vector3.ZERO:
			head_bopping_vector.y = sin(head_bopping_index)
			head_bopping_vector.x = sin(head_bopping_index/2)+0.5
			
			headbop_root.position.y = lerp(headbop_root.position.y, head_bopping_vector.y * (head_bopping_current / 2.0), delta * movement_lerp_speed)
			headbop_root.position.x = lerp(headbop_root.position.x, head_bopping_vector.x * (head_bopping_current), delta * movement_lerp_speed)
		else:
			headbop_root.position = lerp(headbop_root.position, Vector3.ZERO, crouching_lerp_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	
	if interactable_finder.is_colliding():
		print("meme")

	move_and_slide()
