extends State
class_name WalkingState

# Nodes
@onready var neck = get_parent().get_node("Neck")
@onready var head = neck.get_node("Head")
@onready var standing_collision_shape = get_parent().get_node("standing_collision_shape")
@onready var crouching_collision_shape = get_parent().get_node("crouching_collision_shape")
@onready var headbop_root = head.get_node("HeadbopRoot")
@onready var interactable_finder: RayCast3D = head.get_node("InteractableFinder")
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
var is_looking_at_mailcart = false
var object_last_held = null

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
	starting_height = neck.position.y
	crouching_depth = starting_height - 0.5
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	crosshair.visible = false
	EventBus.connect("object_held",held_object)
	EventBus.connect("dropped_object",droppped_object)

func _input(event):
	# Mouse
	if event is InputEventMouseMotion && !is_reading:
		persistent_state.rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		get_viewport().set_input_as_handled()
	
	if event is InputEventMouseButton:
		if interactable_finder.is_colliding():
			var collider = interactable_finder.get_collider()
			
			# Handle Interaction
			if Input.is_action_pressed("interact") and !interact_cooldown and !is_reading:
				interact_cooldown = true
				get_tree().create_timer(0.5).connect("timeout", turnOffInteractCooldown)
				if collider.name == "Handlebar" and !is_holding_object:
					change_state.call("grabcart")
				elif collider.name == "Mailcart":
					if is_holding_object and object_last_held is Package:
						collider.add_package(object_last_held)
						is_holding_object = false
						#TODO: If we are carrying a package we should drop it and call the corresponding 
						#function (collider.add_package(package gameobject).
						#TODO: If we are not carrying a package we should grab the currently inspected package in the mailcart
				elif !is_holding_object: 
					collider.interact()
				get_viewport().set_input_as_handled()
			
			if event.is_action_pressed("inspect") and collider.name == "Mailcart":
				print("Inspect pressed on MAILCART (will inspect package)")
				#TODO: The player should cease all movement (Different state?) and call a new function, mailcart.inspect()
				# which zooms the playercamera to inspect the highlighted package
	
			if event.is_action_pressed("scroll package down") and collider.name == "Mailcart":
				collider.scroll_package_down()
	
			if event.is_action_pressed("scroll package up") and collider.name == "Mailcart":
				collider.scroll_package_up()

func held_object(mass:float, object: Node3D):
	print(object)
	is_holding_object = true
	if object != null:
		object_last_held = object
		if object is Package:
			print("IS PACKAGE!")
			# Do not think we want to impact the player
			pass
	else:
		walking_speed = (walking_speed/mass) + 1
		sprinting_speed =(sprinting_speed/mass) + 1
		crouching_speed =(crouching_speed/mass) + 1
	

func droppped_object(mass:float):
	#TODO:MAKE THESE VARIABLES
	crouching_speed = 3.1
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
	
	# Interactable Stuff
	if interactable_finder.is_colliding() and !interact_cooldown and !is_reading and !is_holding_object:
		crosshair.visible = true
	else: 
		crosshair.visible = false

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
		neck.position.y = lerp(neck.position.y, crouching_depth, crouching_lerp_speed)
		head_bopping_current = head_bopping_crouching_intensity
		head_bopping_index += head_bopping_crouching_speed * delta
	else:
		# if standing would collide
		if !standing_is_blocked:
			standing_collision_shape.disabled = false
			crouching_collision_shape.disabled = true
			neck.position.y = lerp(neck.position.y, starting_height, crouching_lerp_speed)
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
		
		#print("Direction Input: ", direction.z)
		#print("Player Rotation: ", persistent_state.rotation)
		
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
