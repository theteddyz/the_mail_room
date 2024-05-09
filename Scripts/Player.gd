extends CharacterBody3D

# Player Nodes
@onready var head = $Head
@onready var starting_height = head.position.y
@onready var standing_collision_shape = $standing_collision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var standing_obstruction_raycast:RayCast3D = $StandingObstructionRaycast

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var current_speed = 5.0
const walking_speed = 5.0
const sprinting_speed = 10.0
const crouching_speed = 3.1
const jump_velocity = 4.5
const mouse_sense = 0.25
@export var movement_lerp_speed = 8.2
@export var crouching_lerp_speed = 0.18
var direction = Vector3.ZERO
@onready var crouching_depth = starting_height - 0.5

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
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	if(Input.is_action_pressed("crouch")):
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, crouching_depth, crouching_lerp_speed)
	else:
		# if standing would collide
		if !standing_obstruction_raycast.is_colliding():
			standing_collision_shape.disabled = false
			crouching_collision_shape.disabled = true
			head.position.y = lerp(head.position.y, starting_height, crouching_lerp_speed)
			if Input.is_action_pressed("sprint"):
				current_speed = sprinting_speed
			else:
				current_speed = walking_speed

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * movement_lerp_speed)


	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
