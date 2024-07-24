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
var previous_sprinting_speed:float
var walking_speed:float = 5.0
var previous_walk_speed:float
var movement_lerp_speed:float = 8.2
var crouching_speed:float = 3.1
var previous_crouching_speed:float
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
var package_holder
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

# Called when the node enters the scene tree for the first time.
func _ready():
	package_holder = persistent_state.find_child("PackageHolder")
	mailcart = GameManager.get_mail_cart()
	starting_height = neck.position.y
	crouching_depth = starting_height - 0.5
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	EventBus.connect("object_held",held_object)
	EventBus.connect("dropped_object",droppped_object)
	EventBus.connect("disable_player_movement",disable_movement_event)
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
	elif event.is_action_released("inspect"):
			handle_inspect_released()
	elif event.is_action_pressed("scroll package down"):
		handle_scroll(true)
	elif event.is_action_pressed("scroll package up"):
		handle_scroll(false)


func handle_interact_release():
	if object_last_held != null:
		if object_last_held.name != null:
			if is_holding_object and object_last_held:
				if object_last_held is Package:
					handle_package_interaction()
				if object_last_held is Key:
					handle_key_interaction()
				#elif object_last_held.name == "Radio":
					#handle_radio_interaction()


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
				object_last_held.dropped()
	else:
		object_last_held.dropped()

func handle_key_interaction():
	var collider = interactable_finder.get_interactable()
	if collider != null:
		if collider.name == "Door_Lock":
			collider.check_key(object_last_held)
		else:
			object_last_held.dropped()
	else:
		object_last_held.dropped()

func handle_radio_interaction():
	if interactable_finder.is_interactable("Mailcart"):
		interactable_finder.get_interactable().add_radio(object_last_held)


func handle_general_interaction():
	var collider = interactable_finder.get_interactable()
	if collider.has_method("interact") or collider.has_method("grab_current_package"):
		if collider and !is_holding_object:
			match collider.name:
				"Handlebar":
					change_state.call("grabcart")
				"Mailcart":
					collider.grab_current_package()
					gui_anim.show_icon(false)
				_:
					collider.interact()

func handle_inspect_released():
	if object_last_held is Package:
		walking_speed = previous_walk_speed
		sprinting_speed = previous_sprinting_speed
		crouching_speed = previous_crouching_speed
		object_last_held.stop_inspect()
	else:
		if object_last_held.has_method("stop_rotating"):
			object_last_held.stop_rotating()

func handle_inspect():
	var collider = interactable_finder.get_interactable()
	if collider:
		match collider:
			var col when col.name == "Mailcart":
				print("Inspect pressed on MAILCART (will inspect package)")
				# TODO: Implement mailcart.inspect()
			_:
				if object_last_held.has_method("start_rotating"):
					object_last_held.start_rotating()
	else:
		if is_holding_object and object_last_held is Package:
			previous_walk_speed = walking_speed
			previous_crouching_speed = crouching_speed
			previous_sprinting_speed = sprinting_speed
			walking_speed = 3
			sprinting_speed = 5
			crouching_speed = 2
			object_last_held.inspect()


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





func droppped_object(_mass:float,_object):
	crouching_speed = 3.1
	walking_speed = 5.0
	sprinting_speed = 10.0
	is_holding_object = false


func _process(delta):
	apply_movement(delta)
	handle_hovers(delta)

func apply_movement(delta):
	persistent_state.velocity.y = 0
	persistent_state.move_and_slide()
	check_obstruction_raycasts()
	regular_move(delta)

func handle_hovers(delta):
	if interactable_finder.is_colliding() and !interact_cooldown and !is_reading and !disable_look_movement:
		var collider = interactable_finder.get_collider()
		if collider.has_method("interact") or collider.has_method("grab_current_package"):
			if !is_holding_object:
					general_hover(collider,delta)
			else:
				if is_holding_object and object_last_held is Package:
					package_hover(collider)
				elif is_holding_object and object_last_held is Key:
					key_hover(collider)
		else:
			gui_anim.show_icon(false)
			EventBus.emitCustomSignal("hide_icon")
	else:
		gui_anim.show_icon(false)
		EventBus.emitCustomSignal("hide_icon")

func handle_mailcart_hover(collider, delta):
	collider.mailcart_hover(delta)


func package_hover(collider):
	if collider.name == "MailboxStand" or collider.name == "Mailcart":
		EventBus.emitCustomSignal("show_icon", ["deliverable"])

func key_hover(collider):
	if collider.name == "Door_Lock":
		EventBus.emitCustomSignal("show_icon", ["key"])

func general_hover(collider,delta):
	if collider != null:
		if collider.name == "Mailcart":
			handle_mailcart_hover(collider,delta)
		if collider and "icon_type" in collider:
			EventBus.emitCustomSignal("show_icon", [interactable_finder.get_collider().icon_type])
		else:
			EventBus.emitCustomSignal("show_icon", ["grab"])

func check_obstruction_raycasts():
	standing_is_blocked = standing_obstruction_raycast_0.is_colliding() or standing_obstruction_raycast_1.is_colliding() or standing_obstruction_raycast_2.is_colliding() or standing_obstruction_raycast_3.is_colliding()
func regular_move(delta):
	if !disable_walk_movement:
		handle_movement_input(delta)
		handle_head_bopping(delta)


func handle_movement_input(delta):
	if Input.is_action_pressed("crouch"):
		crouch(delta)
	else:
		if !standing_is_blocked:
			stand_or_walk(delta)
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (persistent_state.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * movement_lerp_speed)
	if direction:
		persistent_state.velocity.x = direction.x * current_speed
		persistent_state.velocity.z = direction.z * current_speed
	else:
		persistent_state.velocity.x = move_toward(persistent_state.velocity.x, 0, current_speed)
		persistent_state.velocity.z = move_toward(persistent_state.velocity.z, 0, current_speed)

func crouch(delta):
	standing_collision_shape.disabled = true
	crouching_collision_shape.disabled = false
	current_speed = crouching_speed
	neck.position.y = lerp(neck.position.y, crouching_depth, crouching_lerp_speed)
	head_bopping_current = head_bopping_crouching_intensity
	head_bopping_index += head_bopping_crouching_speed * delta

func stand_or_walk(delta):
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

func handle_head_bopping(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	if Vector3(input_dir.x, 0, input_dir.y) != Vector3.ZERO:
		head_bopping_vector.y = sin(head_bopping_index)
		head_bopping_vector.x = sin(head_bopping_index / 2) + 0.5
		headbop_root.position.y = lerp(headbop_root.position.y, head_bopping_vector.y * (head_bopping_current / 2.0), delta * movement_lerp_speed)
		headbop_root.position.x = lerp(headbop_root.position.x, head_bopping_vector.x * (head_bopping_current), delta * movement_lerp_speed)
		#if is_holding_object and object_last_held is Package:
			#object_last_held.position = object_last_held.hand_position - headbop_root.position
	else:
		headbop_root.position = lerp(headbop_root.position, Vector3.ZERO, crouching_lerp_speed)



func disable_movement_event(l:bool,w:bool):
	persistent_state.velocity = Vector3.ZERO
	disable_look_movement = l
	disable_walk_movement = w
