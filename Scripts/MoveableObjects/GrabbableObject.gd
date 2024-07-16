extends Grabbable
#Grabbing Variables
@export var throw_strength: float = 700.0  
@export var weightLimit: float = 1000.0  
@export var max_lift_height: float = 100.0
@export var max_force:float = 300.0
@export var distance_threshold: float = 1.0
@export var drop_time_threshold: float = 0.5
@export var regrab_cooldown: float = 0.5
@export var should_freeze:bool = false
var is_picked_up = false
var pickup_timer: Timer
var force_above_threshold_time: float = 0.0 
var player: CharacterBody3D
var itemPos
var playerHead
var camera:Camera3D
var throw_direction = Vector3.ZERO
var force:Vector3 = Vector3.ZERO
var timerAdded:bool = false
var detect_collision:bool = false
#Rotating Variables
@export var mouse_sensitivity: float = 1  
var is_rotating = false
var initial_mouse_position = Vector2.ZERO
#Interpolator
var object_Interpolator 
signal collided(other_body)


func _ready():
	player = GameManager.get_player()
	object_Interpolator = find_child("Interpolator")
	var root = get_tree().root
	var current_scene = root.get_child(root.get_child_count() - 1)
	if !should_freeze:
		freeze = false
	else:
		freeze = true
	if player:
		camera = player.find_child("Camera")
	pickup_timer = Timer.new()
	pickup_timer.connect("timeout", Callable(self, "_on_pickup_timer_timeout"))
	connect("body_entered",Callable(self,"_on_body_entered"))
#Used by Both
func _input(event):
	if is_rotating and event is InputEventMouseMotion:
		handle_mouse_motion(event.relative)
func _physics_process(delta):
	if object_Interpolator:
		object_Interpolator.setUpdate(true)
	if is_picked_up:
		handle_pickup(delta)
		update_rotation(delta)
	elif should_freeze and is_at_rest():
		freeze = true
func handle_pickup(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if not is_rotating:
				start_rotating()
		else:
			if is_rotating:
				stop_rotating()
			update_position(delta)
		if Input.is_action_just_pressed("drive"):
			if is_rotating:
				stop_rotating()
			dropMe(true)
			apply_force(throw_direction * throw_strength, throw_direction)
			is_picked_up = false
	else:
		if is_rotating:
			stop_rotating()
		dropMe(false)
#Grabbing Code
func interact():
	if pickup_timer.is_stopped():
		if !timerAdded:
			add_child(pickup_timer)
			timerAdded=true
		itemPos = player.find_child("ItemHolder")
		camera = player.find_child("Camera")
		playerHead = player.find_child("Head")
		if should_freeze:
			freeze = false
		pickmeUp()
		enable_collision_decection()
func dropMe(throw:bool):
	if is_picked_up and throw == false:
		EventBus.emitCustomSignal("dropped_object", [mass,self])
		#linear_damp = 10
		var currentPos = global_position
		is_picked_up = false
		global_position = currentPos
		#linear_damp = 0.1
		force_above_threshold_time = 0.0
		angular_damp = 1
		set_collision_mask_value(3, true)
		if should_freeze:
			sleeping = true
	else:
		throw_direction = (playerHead.global_transform.basis.z * -1).normalized()
		EventBus.emitCustomSignal("dropped_object",[mass,self])
		start_pickup_timer()
		force_above_threshold_time = 0.0
		angular_damp = 1
		set_collision_mask_value(3, true)
		if should_freeze:
			sleeping = true
func pickmeUp():
	if is_picked_up:
		return
	#if parent.mass <= weightLimit:
	#TODO: Switch "null" to something "more" correct
	angular_damp = 10
	set_collision_mask_value(3, false)
	EventBus.emitCustomSignal("object_held", [mass, get_parent()])
	is_picked_up = true
func update_position(delta):
	var targetPosition:Vector3 = itemPos.global_transform.origin
	var currentPosition:Vector3 = global_transform.origin
	var directionTo:Vector3 = targetPosition - currentPosition
	var distance:float = currentPosition.distance_to(targetPosition)
	force = directionTo.normalized()*(pow(distance * 600,1))#/max(1,(parent.mass*0.15)))
	
	force = force.limit_length(max_force + (mass * 4) + player.velocity.length())
	apply_central_force(force)
	var angleBetweenForceAndVelocity = min(90,force.angle_to(linear_velocity))*2
	
	apply_central_force(-linear_velocity * 20) #* angleBetweenForceAndVelocity)		
	if distance > distance_threshold:
		force_above_threshold_time += delta
		if force_above_threshold_time >= drop_time_threshold:
			dropMe(false)
	else:
		force_above_threshold_time = 0.0
func start_pickup_timer():
	pickup_timer.start(regrab_cooldown)
func _on_pickup_timer_timeout():
	pickup_timer.stop()
#Rotation Code
func handle_mouse_motion(mouse_relative: Vector2):
	angular_velocity.x = -mouse_relative.y * mouse_sensitivity
	angular_velocity.y = -mouse_relative.x * mouse_sensitivity
func update_rotation(delta):
	if is_rotating:
		var angular_impulse = angular_velocity * delta
		apply_torque_impulse(angular_impulse)
		angular_velocity *= 0.9
func start_rotating():
	is_rotating = true
	lock_axes(true)
	EventBus.emitCustomSignal("disable_player_movement",[true,true])
	initial_mouse_position = get_viewport().get_mouse_position()
func stop_rotating():
	lock_axes(false)
	EventBus.emitCustomSignal("disable_player_movement",[false,false])
	is_rotating = false
	angular_velocity = Vector3.ZERO
func lock_axes(lock: bool):
	axis_lock_linear_x = lock
	axis_lock_linear_z = lock
func is_at_rest() -> bool:
	return linear_velocity.length_squared() <= 0.0001 and angular_velocity.length_squared() <= 0.0001

func enable_collision_decection():
	await get_tree().create_timer(1).timeout
	set_contact_monitor(true)
	set_max_contacts_reported(1)
