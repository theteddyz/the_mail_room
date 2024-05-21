extends State
class_name WalkingState

# Nodes
@onready var head = get_parent().get_node("Head")
@onready var standing_collision_shape = get_parent().get_node("standing_collision_shape")
@onready var crouching_collision_shape = get_parent().get_node("crouching_collision_shape")
@onready var headbop_root = head.get_node("HeadbopRoot")
@onready var interactable_finder = head.get_node("InteractableFinder")
@onready var crosshair = headbop_root.get_node("Camera").get_node("Control").get_node("Crosshair")

@onready var standing_obstruction_raycast_0 = head.get_node("StandingObstructionRaycasts").get_node("StandingObstructionRaycast0")
@onready var standing_obstruction_raycast_1 = head.get_node("StandingObstructionRaycasts").get_node("StandingObstructionRaycast1")
@onready var standing_obstruction_raycast_2 = head.get_node("StandingObstructionRaycasts").get_node("StandingObstructionRaycast2")
@onready var standing_obstruction_raycast_3 = head.get_node("StandingObstructionRaycasts").get_node("StandingObstructionRaycast3")

# Speeds
var sprinting_speed = 10.0
var walking_speed = 5.0
var movement_lerp_speed = 8.2
var crouching_speed = 3.1
var crouching_lerp_speed = 0.18
# var current_speed = 5, this variable is used by parent
var direction = Vector3.ZERO

# Others
var starting_height
var crouching_depth
var interact_cooldown = false
var is_reading = false
var standing_is_blocked = false
var held_mass:float
var is_holding_object = false
# Headbopping
const head_bopping_walking_speed = 12
const head_bopping_walking_intensity = 0.1
const head_bopping_sprinting_speed = 20
const head_bopping_sprinting_intensity = 0.2
const head_bopping_crouching_speed = 9
const head_bopping_crouching_intensity = 0.05
var head_bopping_vector = Vector2.ZERO
var head_bopping_index = 0.0
var head_bopping_current = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	starting_height = head.position.y
	crouching_depth = starting_height - 0.5
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	crosshair.visible = false
	print("Walking State Ready")
	EventBus.connect("object_held",held_object)
	EventBus.connect("dropped_object",droppped_object)

func _input(event):
	# Mouse
	if event is InputEventMouseMotion && !is_reading:
		persistent_state.rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		get_viewport().set_input_as_handled()
		
	# Handle Interaction
	if Input.is_action_pressed("interact") and interactable_finder.is_colliding() and !interact_cooldown and !is_reading and !is_holding_object:
		var interactable = interactable_finder.get_collider()
		interact_cooldown = true
		get_tree().create_timer(0.5).connect("timeout", turnOffInteractCooldown)
		if interactable.name == "Handlebar":
			# TODO: STATE CHANGE TO CARTING
			change_state.call("grabcart")
		else: 
			interactable.interact()
		get_viewport().set_input_as_handled()

func held_object(mass:float):
	walking_speed = (walking_speed/mass) + 1
	sprinting_speed =(sprinting_speed/mass) + 1
	is_holding_object = true
func droppped_object(mass:float):
	#TODO:MAKE THESE VARIABLES
	walking_speed = 5.0
	sprinting_speed = 10.0
	is_holding_object = false

func turnOffInteractCooldown():
	interact_cooldown = false

func _process(delta):
	# Apply the movement
	persistent_state.move_and_slide()
	
func _physics_process(delta):
	# Check standing-obstruction
	checkObstructionRaycasts()
	regularMove(delta)

func checkObstructionRaycasts():
	if standing_obstruction_raycast_0.is_colliding() or standing_obstruction_raycast_1.is_colliding()or standing_obstruction_raycast_2.is_colliding() or standing_obstruction_raycast_3.is_colliding():
		standing_is_blocked = true
	else:
		standing_is_blocked = false

func regularMove(delta):
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
		if !standing_is_blocked:
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

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (persistent_state.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * movement_lerp_speed)

	if direction:
		persistent_state.velocity.x = direction.x * current_speed
		persistent_state.velocity.z = direction.z * current_speed
		
		# Head Bopping
		if Vector3(input_dir.x, 0, input_dir.y) != Vector3.ZERO:
			head_bopping_vector.y = sin(head_bopping_index)
			head_bopping_vector.x = sin(head_bopping_index/2)+0.5
			
			headbop_root.position.y = lerp(headbop_root.position.y, head_bopping_vector.y * (head_bopping_current / 2.0), delta * movement_lerp_speed)
			headbop_root.position.x = lerp(headbop_root.position.x, head_bopping_vector.x * (head_bopping_current), delta * movement_lerp_speed)
		else:
			headbop_root.position = lerp(headbop_root.position, Vector3.ZERO, crouching_lerp_speed)
	else:
		persistent_state.velocity.x = move_toward(persistent_state.velocity.x, 0, current_speed)
		persistent_state.velocity.z = move_toward(persistent_state.velocity.z, 0, current_speed)
	
	# Interactable-indicator
	if interactable_finder.is_colliding() and !interact_cooldown and !is_reading and !is_holding_object:
		crosshair.visible = true
	else: 
		crosshair.visible = false
