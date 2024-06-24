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
var mailcart

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
var disable_look_movement = false
var disable_walk_movement = false

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
	mailcart = GameManager.get_mail_cart()
	starting_height = neck.position.y
	crouching_depth = starting_height - 0.5
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	crosshair.visible = false
	EventBus.connect("object_held",held_object)
	EventBus.connect("dropped_object",droppped_object)
	EventBus.connect("disable_player_movement",disable_movement_event)

func _input(event):
	# Mouse
	if event is InputEventMouseMotion && !is_reading && !disable_look_movement:
		persistent_state.rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	if interactable_finder.is_colliding() and Input.is_action_just_pressed("drive"):
		var collider = interactable_finder.get_collider()
		if collider and !is_holding_object:
			if collider.name == "Radio":
				var parent = collider.get_parent()
				parent.check_tape()
	if event is InputEventMouseButton:
		if event.is_action_released("interact") and is_holding_object and object_last_held is Package:
				if interactable_finder.is_colliding() and interactable_finder.get_collider().name == "Mailcart":
					print("ADDED PACKAGE")
					interactable_finder.get_collider().add_package(object_last_held)
					is_holding_object = false
					#TODO: If we are not carrying a package we should grab the currently inspected package in the mailcart
				else:
					dropped_package()
		if event.is_action_released("interact") and is_holding_object and object_last_held.name == "Radio":
			if interactable_finder.is_colliding() and interactable_finder.get_collider().name == "Mailcart":
				interactable_finder.get_collider().add_radio(object_last_held)
		if event.is_action_released("interact") and is_holding_object and object_last_held:
			pass
		if interactable_finder.is_colliding():
			var collider = interactable_finder.get_collider()
			# Handle Interaction
			if Input.is_action_just_pressed("interact") and !interact_cooldown and !is_reading:
				interact_cooldown = true
				get_tree().create_timer(0.5).connect("timeout", turnOffInteractCooldown)
				if collider.name == "Handlebar" and !is_holding_object:
					change_state.call("grabcart")
				elif collider.name == "Mailcart" and !is_holding_object:
					collider.grab_current_package()
				elif !is_holding_object: 
					collider.interact()
					
			if event.is_action_pressed("inspect") and collider.name == "Mailcart":
				print("Inspect pressed on MAILCART (will inspect package)")
				#TODO: The player should cease all movement (Different state?) and call a new function, mailcart.inspect()
				# which zooms the playercamera to inspect the highlighted package
	
			if event.is_action_pressed("scroll package down") and collider.name == "Mailcart":
				collider.scroll_package_down()

			if event.is_action_pressed("scroll package up") and collider.name == "Mailcart":
				collider.scroll_package_up()
				
			if event.is_action_pressed("scroll package down") and collider.name == "Radio":
				var parent = collider.get_parent()
				parent.change_station_up()
				
			if event.is_action_pressed("scroll package up") and collider.name == "Radio":
				var parent = collider.get_parent()
				parent.change_station_down()

func held_object(mass:float, object):
	is_holding_object = true
	object_last_held = object
	walking_speed = (walking_speed/mass) + 1
	sprinting_speed = (sprinting_speed/mass) + 1
	crouching_speed = (crouching_speed/mass) + 1

func grabbed_package(package: Package):
	is_holding_object = true
	object_last_held = package
	bind_package_to_player(package)
	
func bind_package_to_player(package: Package):
	package.position = package.hand_position
	package.rotation = package.hand_rotation
	package.freeze = true
	package.reparent(persistent_state.find_child("PackageHolder"), false)
	# MOVE PACKAGE TO PLAYER HERE
	
func dropped_package():
	is_holding_object = false
	unbind_package_from_player()
	
func unbind_package_from_player():
	object_last_held.freeze = false
	persistent_state.find_child("PackageHolder").get_child(0).reparent(persistent_state.get_parent(), true)
	# MOVE PACKAGE FROM PLAYER HERE

func droppped_object(mass:float,object):
	crouching_speed = 3.1
	walking_speed = 5.0
	sprinting_speed = 10.0
	is_holding_object = false

func turnOffInteractCooldown():
	interact_cooldown = false

func _process(delta):
	# Apply the movement
	rotation = Vector3.ZERO
	persistent_state.velocity.y = 0
	persistent_state.move_and_slide()
	checkObstructionRaycasts()
	regularMove(delta)
	updateCartLookStatus()
	
	# Interactable Stuff
	if interactable_finder.is_colliding() and !interact_cooldown and !is_reading and !is_holding_object and !disable_look_movement:
		crosshair.visible = true
	else: 
		crosshair.visible = false

func checkObstructionRaycasts():
	if standing_obstruction_raycast_0.is_colliding() or standing_obstruction_raycast_1.is_colliding()or standing_obstruction_raycast_2.is_colliding() or standing_obstruction_raycast_3.is_colliding():
		standing_is_blocked = true
	else:
		standing_is_blocked = false

func regularMove(delta):
	if !disable_walk_movement:
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
		direction = lerp(direction, (persistent_state.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * movement_lerp_speed)

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
				# We want to exempt packages from the headbop
				if is_holding_object and object_last_held is Package:
					object_last_held.position = object_last_held.hand_position - headbop_root.position
			else:
				headbop_root.position = lerp(headbop_root.position, Vector3.ZERO, crouching_lerp_speed)
		else:
			persistent_state.velocity.x = move_toward(persistent_state.velocity.x, 0, current_speed)
			persistent_state.velocity.z = move_toward(persistent_state.velocity.z, 0, current_speed)
			
func updateCartLookStatus():
	if mailcart:
		if !is_holding_object:
			if interactable_finder.is_colliding() and interactable_finder.get_collider().name == "Mailcart" and !is_holding_object:
				interactable_finder.get_collider().is_being_looked_at = true
			else:
				if(mailcart != null):
					mailcart.is_being_looked_at = false
			

func disable_movement_event(l:bool,w:bool):
	disable_look_movement = l
	disable_walk_movement = w
