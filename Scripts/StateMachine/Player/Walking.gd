extends State
class_name WalkingState

# Nodes
@onready var neck = get_parent().get_node("Neck")
@onready var head = neck.get_node("Head")
@onready var standing_collision_shape = get_parent().get_node("standing_collision_shape")
@onready var crouching_collision_shape = get_parent().get_node("crouching_collision_shape")
@onready var headbop_root:Node = head.get_node("HeadbopRoot")
@onready var interactable_finder: RayCast3D = head.get_node("InteractableFinder")

var mailcart

@onready var standing_obstruction_raycast_0:RayCast3D  = head.get_node("StandingObstructionRaycasts").get_node("StandingObstructionRaycast0")
@onready var standing_obstruction_raycast_1:RayCast3D  = head.get_node("StandingObstructionRaycasts").get_node("StandingObstructionRaycast1")
@onready var standing_obstruction_raycast_2:RayCast3D  = head.get_node("StandingObstructionRaycasts").get_node("StandingObstructionRaycast2")
@onready var standing_obstruction_raycast_3:RayCast3D = head.get_node("StandingObstructionRaycasts").get_node("StandingObstructionRaycast3")

# Speeds
var sprinting_speed:float = 10.0
var walking_speed:float = 5.0
var movement_lerp_speed:float = 8.2
var crouching_speed:float = 3.1
var crouching_lerp_speed:float = 0.18
# var current_speed = 5, this variable is used by parent
var direction:Vector3 = Vector3.ZERO
var gui_anim:Control
# Others
var starting_height:float
var crouching_depth:float
var interact_cooldown:bool = false
var is_reading:bool = false
var standing_is_blocked:bool = false
var held_mass:float
var is_holding_object:bool = false
var is_looking_at_mailcart:bool = false
var object_last_held = null
var disable_look_movement:bool = false
var disable_walk_movement:bool = false

# Headbopping
const head_bopping_walking_speed:float = 12
const head_bopping_walking_intensity:float = 0.1
const head_bopping_sprinting_speed:float = 20
const head_bopping_sprinting_intensity:float = 0.2
const head_bopping_crouching_speed:float = 9
const head_bopping_crouching_intensity:float = 0.05
var head_bopping_vector:Vector2 = Vector2.ZERO
var head_bopping_index:float = 0.0
var head_bopping_current:float = 0.0
var text_displayer
# Called when the node enters the scene tree for the first time.
func _ready():
	mailcart = GameManager.get_mail_cart()
	starting_height = neck.position.y
	crouching_depth = starting_height - 0.5
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	EventBus.connect("object_held",held_object)
	EventBus.connect("dropped_object",droppped_object)
	EventBus.connect("disable_player_movement",disable_movement_event)
	EventBus.connect("package_failed_delivery",dropped_package)
	EventBus.connect("dropped_key",dropped_key)
	gui_anim = Gui.get_control_displayer()



func _input(event):
	if event is InputEventMouseMotion:
		handle_mouse_motion(event)
	elif event is InputEventMouseButton:
		handle_mouse_button(event)

func handle_mouse_motion(event):
	if !is_reading and !disable_look_movement:
		persistent_state.rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func handle_mouse_button(event):
	if event.is_action_released("interact"):
		handle_interact_release()
	elif  event.is_action_pressed("interact"):
		handle_general_interaction()
	elif event.is_action_pressed("inspect"):
		handle_inspect()
	elif event.is_action_pressed("scroll package down"):
		handle_scroll(true)
	elif event.is_action_pressed("scroll package up"):
		handle_scroll(false)


func handle_interact_release():
	if is_holding_object and object_last_held:
		if object_last_held is Package:
			handle_package_interaction()
		if object_last_held is Key:
			handle_key_interaction()
		elif object_last_held.name == "Radio":
			handle_radio_interaction()


func handle_package_interaction():
	var collider = interactable_finder.get_interactable()
	if collider != null:
		match collider.name:
			"Mailcart":
				collider.add_package(object_last_held)
				object_last_held = null
				is_holding_object = false
			"MailboxStand":
				collider.find_child("PackageDestination").deliver(object_last_held)
				object_last_held = null
				is_holding_object = false
			_:
				dropped_package()
	else:
		dropped_package()

func handle_key_interaction():
	var collider = interactable_finder.get_interactable()
	if collider != null:
		if collider.name == "Door_Lock":
			collider.check_key(object_last_held)
		else:
			dropped_key()
	else:
		dropped_key()

func handle_radio_interaction():
	if interactable_finder.is_interactable("Mailcart"):
		interactable_finder.get_interactable().add_radio(object_last_held)


func handle_general_interaction():
	var collider = interactable_finder.get_interactable()
	if collider and !is_holding_object:
		match collider.name:
			"Handlebar":
				change_state.call("grabcart")
			"Mailcart":
				collider.grab_current_package()
				gui_anim.show_icon(false)
			_:
				collider.interact()

func handle_inspect():
	var collider = interactable_finder.get_interactable()
	if collider:
		match collider:
			var col when col.name == "Mailcart":
				print("Inspect pressed on MAILCART (will inspect package)")
				# TODO: Implement mailcart.inspect()
			_:
				if is_holding_object and object_last_held is Package:
					if text_displayer == null:
						text_displayer = Gui.get_address_displayer()
					show_label(object_last_held.package_address)
	else:
		if is_holding_object and object_last_held is Package:
			if text_displayer == null:
				text_displayer = Gui.get_address_displayer()
			show_label(object_last_held.package_address)

func handle_scroll(is_down):
	var collider = interactable_finder.get_interactable()
	if collider:
		match collider.name:
			"Mailcart":
				if is_down:
					gui_anim.scroll_down()
					collider.scroll_package_down()
				else:
					gui_anim.scroll_up()
					collider.scroll_package_up()
			"Radio":
				#TODO:Handle Radio Functionality
				var _parent = collider.get_parent()

func turnOffInteractCooldown():
	interact_cooldown = false

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
	package.reparent(persistent_state.find_child("PackageHolder"), false)
	package.position = package.hand_position
	package.rotation = package.hand_rotation
	package.freeze = true
	# MOVE PACKAGE TO PLAYER HERE

func dropped_package():
	is_holding_object = false
	unbind_package_from_player()

func show_label(text:String):
	text_displayer.show_text()
	text_displayer.set_text(text)


func grabbed_key(key:Key):
	is_holding_object = true
	object_last_held = key
	bind_key_to_player(key)

func bind_key_to_player(key:Key):
	key.reparent(persistent_state.find_child("PackageHolder"), false)
	key.position =Vector3.ZERO
	key.rotation = Vector3.ZERO
	key.freeze = true


func dropped_key():
	is_holding_object = false
	unbind_key_from_player()


func unbind_key_from_player():
	var child = persistent_state.find_child("PackageHolder").get_child(0)
	if(child != null):
		child.freeze = false
		child.reparent(persistent_state.get_parent(), true)


func unbind_package_from_player():
	var child = persistent_state.find_child("PackageHolder").get_child(0)
	if(child != null):
		child.set_collision_layer_value(2,true)
		object_last_held.freeze = false
		child.reparent(persistent_state.get_parent(), true)

func droppped_object(_mass:float,_object):
	crouching_speed = 3.1
	walking_speed = 5.0
	sprinting_speed = 10.0
	is_holding_object = false


func _process(delta):
	# Apply the movement
	persistent_state.velocity.y = 0
	persistent_state.move_and_slide()
	checkObstructionRaycasts()
	regularMove(delta)
	updateCartLookStatus()
	# Interactable Stuff
	if interactable_finder.is_colliding() and !interact_cooldown and !is_reading and !disable_look_movement:
		var collider = interactable_finder.get_collider()
		# If we are holding a package...
		if is_holding_object and object_last_held is Package:
			EventBus.emitCustomSignal("show_icon",["deliverable"])
			# If we are checking a mailbox...
			if collider.name == "MailboxStand":
				var destination_name = collider.find_child("PackageDestination").accepts_package_named
				var check = object_last_held.package_address == destination_name
				# if this is the right mailbox...
				if check:
					#MAIL-DELIVERABLE CROSSHAIR
					EventBus.emitCustomSignal("hide_icon")
					EventBus.emitCustomSignal("show_icon",["deliverable"])
		elif is_holding_object and object_last_held is Key:
			EventBus.emitCustomSignal("show_icon",["key"])
			if collider.name == "Door_Lock":
				if object_last_held.unlock_num == collider.unlock_number:
					EventBus.emitCustomSignal("show_icon",["key"])
		elif !is_holding_object:
			#INTERACT CROSSHAIR
			if collider and "icon_type" in collider:
				EventBus.emitCustomSignal("show_icon",[interactable_finder.get_collider().icon_type])
			else:
				EventBus.emitCustomSignal("show_icon",["grab"])
	else: 
		#NO CROSSHAIR
		EventBus.emitCustomSignal("hide_icon")

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
	if interactable_finder.is_colliding() and interactable_finder.get_collider().name != null:
		if interactable_finder.get_collider().name == "Mailcart":
			if !is_holding_object:
				interactable_finder.get_collider().is_being_looked_at = true
				gui_anim.show_icon(true)
	else:
			mailcart.is_being_looked_at = false
			gui_anim.show_icon(false)



func disable_movement_event(l:bool,w:bool):
	disable_look_movement = l
	disable_walk_movement = w
