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
#Sprint Stamina 
var max_stamina:float = 200.0
var current_stamina:float = 200.0
var stamina_depletion_rate:float = 20.0
var stamina_recovery_rate:float = 10.0
var is_sprinting:bool = false
var can_sprint:bool = true
# Others
var starting_height:float
var crouching_depth:float
var interact_cooldown:bool = false
var is_reading:bool = false
var standing_is_blocked:bool = false
var held_mass:float
var is_holding_object:bool = false
var is_holding_package:bool = false
var is_looking_at_mailcart:bool = false
var object_last_held = null
var package_last_held = null
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
#Leaning
var lean_angle:float = 0.0
const max_lean_angle:float = 15.0
const lean_speed:float = 5.0
var is_leaning:bool = false
var original_neck_position:Vector3
# Called when the node enters the scene tree for the first time.
var stamina_bar
signal object_hovered(node)
signal object_unhovered()
#walking Sounds
var walking_audio_player:AudioStreamPlayer3D
var audio_timer:Timer
var push_force = 2
func _ready():
	package_holder = persistent_state.find_child("PackageHolder")
	mailcart = GameManager.get_mail_cart()
	starting_height = neck.position.y
	crouching_depth = starting_height - 0.5
	original_neck_position = neck.position
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	EventBus.connect("object_held",held_object)
	EventBus.connect("dropped_object",droppped_object)
	EventBus.connect("disable_player_movement",disable_movement_event)
	gui_anim = Gui.get_control_displayer()
	stamina_bar = Gui.get_stamina_bar()
	walking_audio_player = persistent_state.find_child("AudioStreamPlayer3D")
	audio_timer = walking_audio_player.find_child("sound_reset")
	audio_timer.connect("timeout", sound_timeout)


func _input(event):
	if event is InputEventMouseMotion:
		handle_mouse_motion(event)
	elif event is InputEventMouseButton:
		handle_mouse_button(event)
	elif event is InputEventKey:
		handle_keyboard_press(event)

func handle_mouse_motion(event):
	if !is_reading and !disable_look_movement:
		persistent_state.rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func handle_mouse_button(event):
	if event.is_action_released("interact"):
		pass
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


func handle_keyboard_press(event):
	if event.is_action_pressed("lean_left"):
		lean_left()
	elif event.is_action_pressed("lean_right"):
		lean_right()
	elif event.is_action_released("lean_left") or event.is_action_released("lean_right"):
		stop_leaning()
	elif event.is_action_pressed("drive"):
		var collider = interactable_finder.get_interactable()
		if collider and collider.name == "Handlebar":
			if !is_holding_package and !is_holding_object:
				change_state.call("grabcart")

func handle_radio_interaction():
	if interactable_finder.is_interactable("Mailcart"):
		interactable_finder.get_interactable().add_radio(object_last_held)


func handle_general_interaction():
	var collider = interactable_finder.get_interactable()
	if collider and !is_holding_object:
		ScareDirector.grabbable.emit(collider.name)
		match collider.name:
			mailcart.name:
				if is_holding_package:
					collider.add_package(package_last_held)
					package_last_held = null
					is_holding_package = false
				else:
					collider.grab_current_package()
					gui_anim.show_icon(false)
			"MailboxStand":
				if is_holding_package:
					collider.find_child("PackageDestination").deliver(package_last_held)
					package_last_held = null
					is_holding_package = false
			"ButtonRB2":
				collider.interact()
			_:
				if collider.has_method("grab"):
					collider.grab()
				elif collider.has_method("check_key"):
					collider.get_parent().grab()
				elif collider.has_method("interact"):
					collider.interact()
	elif !collider and is_holding_package:
		package_last_held.dropped()

func handle_inspect_released():
	if package_last_held:
		if package_last_held is Package:
			walking_speed = previous_walk_speed
			sprinting_speed = previous_sprinting_speed
			crouching_speed = previous_crouching_speed
			package_last_held.stop_inspect()
	elif object_last_held:
		if object_last_held.has_method("stop_rotating"):
			object_last_held.stop_rotating()

func handle_inspect():
	var collider = interactable_finder.get_interactable()
	if collider:
		match collider:
			_:
				if object_last_held:
					if object_last_held.has_method("start_rotating"):
						object_last_held.start_rotating()
	else:
		if is_holding_package and package_last_held is Package:
			previous_walk_speed = walking_speed
			previous_crouching_speed = crouching_speed
			previous_sprinting_speed = sprinting_speed
			walking_speed = 3
			sprinting_speed = 5
			crouching_speed = 2
			package_last_held.inspect()


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
	if object is Package:
		package_last_held = object
		is_holding_package = true
		walking_speed = (walking_speed/(1+mass*0.2)) + 1
		sprinting_speed = (sprinting_speed/(1+mass*0.2)) + 1
		crouching_speed = (crouching_speed/(1+mass*0.2)) + 1
	else:
		is_holding_object = true
		object_last_held = object
		walking_speed = (walking_speed/(1+mass*0.2)) + 1
		sprinting_speed = (sprinting_speed/(1+mass*0.2)) + 1
		crouching_speed = (crouching_speed/(1+mass*0.2)) + 1


func droppped_object(_mass:float,_object):
	if _object is Package:
		is_holding_package = false
		package_last_held = null
		crouching_speed = 3.1
		walking_speed = 5.0
		sprinting_speed = 10.0
	else:
		crouching_speed = 3.1
		walking_speed = 5.0
		sprinting_speed = 10.0
		is_holding_object = false
		object_last_held = null

func lean_left():
	lean_angle = max_lean_angle
	is_leaning = true
func lean_right():
	lean_angle = -max_lean_angle
	is_leaning = true
func stop_leaning():
	lean_angle = 0.0
	is_leaning = false

func _physics_process(delta):
	apply_pushes()

func _process(delta):
	apply_movement(delta)
	apply_leaning(delta)
	recover_stamina(delta)
	stamina_bar.update_stamina_bar(current_stamina)

func apply_movement(delta):
	persistent_state.velocity.y = 0
	persistent_state.move_and_slide()

	check_obstruction_raycasts()
	regular_move(delta)


func check_obstruction_raycasts():
	standing_is_blocked = standing_obstruction_raycast_0.is_colliding() or standing_obstruction_raycast_1.is_colliding() or standing_obstruction_raycast_2.is_colliding() or standing_obstruction_raycast_3.is_colliding()
func regular_move(delta):
	if !disable_walk_movement:
		handle_movement_input(delta)
		handle_head_bopping(delta)


func handle_movement_input(delta):
	if Input.is_action_pressed("crouch"):
		audio_timer.wait_time = 0.8
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
	if Input.is_action_pressed("sprint") and can_sprint:
		
		if current_stamina > 0:
			audio_timer.wait_time = 0.3
			current_speed = sprinting_speed
			head_bopping_current = head_bopping_sprinting_intensity
			head_bopping_index += head_bopping_sprinting_speed * delta
			is_sprinting = true
			current_stamina -= stamina_depletion_rate * delta
		else:
			audio_timer.wait_time = 0.6
			current_speed = walking_speed
			head_bopping_current = head_bopping_walking_intensity
			head_bopping_index += head_bopping_walking_speed * delta
			is_sprinting = false
	else:
		audio_timer.wait_time = 0.6
		current_speed = walking_speed
		head_bopping_current = head_bopping_walking_intensity
		head_bopping_index += head_bopping_walking_speed * delta
		is_sprinting = false
	if not Input.is_action_pressed("sprint"):
		can_sprint = true

func handle_head_bopping(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	if Vector3(input_dir.x, 0, input_dir.y) != Vector3.ZERO:
		if audio_timer.is_stopped():
			audio_timer.start()
		head_bopping_vector.y = sin(head_bopping_index)
		head_bopping_vector.x = sin(head_bopping_index / 2) + 0.5
		headbop_root.position.y = lerp(headbop_root.position.y, head_bopping_vector.y * (head_bopping_current / 2.0), delta * movement_lerp_speed)
		headbop_root.position.x = lerp(headbop_root.position.x, head_bopping_vector.x * (head_bopping_current), delta * movement_lerp_speed)
	else:
		audio_timer.stop()
		headbop_root.position = lerp(headbop_root.position, Vector3.ZERO, crouching_lerp_speed)

func apply_leaning(delta):
	if is_leaning:
		var lean_offset = Vector3()
		if lean_angle > 0:
			lean_offset.x = -0.3  # Move left
		elif lean_angle < 0:
			lean_offset.x = 0.3   # Move right
		neck.position = neck.position.lerp(original_neck_position + lean_offset, delta * lean_speed)
		var current_rotation_quat = Quaternion.from_euler(neck.rotation)
		var target_rotation_quat = Quaternion(Vector3(0, 0, 1), deg_to_rad(lean_angle))
		var interpolated_rotation_quat = current_rotation_quat.slerp(target_rotation_quat, delta * lean_speed)
		neck.rotation = interpolated_rotation_quat.get_euler()
	else:
		neck.position = neck.position.lerp(original_neck_position, delta * lean_speed)
		var current_rotation_quat = Quaternion.from_euler(neck.rotation)
		var target_rotation_quat = Quaternion(Vector3(0, 0, 1), deg_to_rad(lean_angle))
		var interpolated_rotation_quat = current_rotation_quat.slerp(target_rotation_quat, delta * lean_speed)
		neck.rotation = interpolated_rotation_quat.get_euler()

func recover_stamina(delta):
	if not is_sprinting and current_stamina < max_stamina:
		current_stamina += stamina_recovery_rate * delta
		if current_stamina > max_stamina:
			current_stamina = max_stamina


func disable_movement_event(l:bool,w:bool):
	persistent_state.velocity = Vector3.ZERO
	disable_look_movement = l
	disable_walk_movement = w

func sound_timeout():
	walking_audio_player.play()

func apply_pushes():
	for i in persistent_state.get_slide_collision_count():
		var c = persistent_state.get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			if c.get_collider().freeze:
				c.get_collider().freeze = false
			c.get_collider().apply_central_impulse(-c.get_normal() * current_speed)
