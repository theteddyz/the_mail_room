extends Grabbable
#Grabbing Variables
@export var throw_strength: float = 700.0  
@export var weightLimit: float = 1000.0  
@export var max_lift_height: float = 100.0
@export var max_force:float = 300.0
@export var distance_threshold: float = 6.0
@export var drop_time_threshold: float = 0.5
@export var tether_distance: float = 2.5
@export var regrab_cooldown: float = 0.5
@export var should_freeze:bool = false
@export var can_rotate:bool = true
@onready var grab_icon = preload("res://Scenes/Prefabs/MoveableObjects/grab_icon.tscn")
var is_picked_up = false
var pickup_timer: Timer
var force_above_threshold_time: float = 0.0 
var player: CharacterBody3D
#var itemPos
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
var player_raycast:RayCast3D
var grab_offset: Vector3 = Vector3.ZERO
var grab_distance: float = 0
var initial_basis = Basis()  # To store the initial rotation basis
var starting_angular_damp:float
var is_tether_max_range: bool = false
var is_being_looked_at
var grab_point_indicator
signal collided(other_body)

func _ready():
	player = GameManager.get_player()
	object_Interpolator = find_child("Interpolator")
	starting_angular_damp = angular_damp
	
	if !should_freeze:
		freeze = false
	else:
		freeze = true
	if player:
		camera = player.find_child("Camera")
		player_raycast = player.find_child("InteractableFinder")
	pickup_timer = Timer.new()
	pickup_timer.connect("timeout", Callable(self, "_on_pickup_timer_timeout"))
	connect("body_entered",Callable(self,"_on_body_entered"))

#Used by Both
func _input(event):
	if is_rotating and event is InputEventMouseMotion:
		handle_mouse_motion(event.relative)
		
func _process(_delta): #Tether the player to the object
	if is_picked_up:
		var playerPosition:Vector3 = player.transform.origin;
		playerPosition.y = 0;
		#var targetPosition: Vector3 = itemPos.global_transform.origin + -grab_offset
		var objectPosition:Vector3 = global_transform.origin + grab_offset;
		objectPosition.y = 0;
		var directionTo:Vector3 = playerPosition - objectPosition;
		directionTo = directionTo.normalized();
		var distance:float = playerPosition.distance_to(objectPosition);
		if distance > tether_distance:
			var destination = objectPosition + directionTo*tether_distance;
			player.transform.origin.x = destination.x;
			player.transform.origin.z = destination.z;
			is_tether_max_range = true;
		else:
			is_tether_max_range = false;
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
func grab():
	if pickup_timer.is_stopped():
		if !timerAdded:
			add_child(pickup_timer)
			timerAdded=true
		#itemPos = player.find_child("ItemHolder")
		camera = player.find_child("Camera")
		playerHead = player.find_child("Head")
		set_collision_mask_value(3, false)
		set_collision_layer_value(3,false)
		if should_freeze:
			freeze = false
		if player_raycast.is_colliding():
			grab_offset = player_raycast.get_collision_point() - global_transform.origin
			
			var playerPosition:Vector3 = camera.global_transform.origin;
			var objectPosition:Vector3 = player_raycast.get_collision_point();
			grab_distance = playerPosition.distance_to(objectPosition);
			
			initial_basis = global_transform.basis
			
			print("Grab distance: " , grab_distance);
			pickmeUp()
			enable_collision_decection()
			add_grab_point_indicator()
func dropMe(throw:bool):
	if is_picked_up and throw == false:
		EventBus.emitCustomSignal("dropped_object", [mass,self])
		#linear_damp = 10
		var currentPos = global_position
		is_picked_up = false
		global_position = currentPos
		#linear_damp = 0.1
		force_above_threshold_time = 0.0
		angular_damp = starting_angular_damp
		set_collision_mask_value(3, true)
		set_collision_layer_value(3,true)
		if should_freeze:
			sleeping = true
	else:
		throw_direction = (playerHead.global_transform.basis.z * -1).normalized()
		EventBus.emitCustomSignal("dropped_object",[mass,self])
		start_pickup_timer()
		force_above_threshold_time = 0.0
		angular_damp = starting_angular_damp
		apply_torque_impulse(calculate_torque_impulse())
		set_collision_mask_value(3, true)
		set_collision_layer_value(3,true)
		if should_freeze:
			sleeping = true
	remove_grab_point_indicator()
func pickmeUp():
	if is_picked_up:
		return
	#if parent.mass <= weightLimit:
	#TODO: Switch "null" to something "more" correct
	angular_damp = 10
	set_collision_mask_value(3, false)
	set_collision_layer_value(3,false)
	EventBus.emitCustomSignal("object_held", [mass, get_parent()])
	is_picked_up = true

func rotate_vector_global(offset: Vector3) -> Vector3:
	# Get the object's global transform
	var global_transform = self.global_transform
	# Extract the basis (rotation matrix) from the global transform
	var basisen = global_transform.basis
	
	var relative_basis = basisen * initial_basis.inverse()
	
	return (relative_basis * offset)
	
func update_position(delta):
	var rotation_offset = rotate_vector_global(grab_offset)
	var forward = -camera.global_transform.basis.z
	var targetPosition: Vector3 = (camera.global_transform.origin + forward.normalized()*grab_distance) + -rotation_offset
	var currentPosition:Vector3 = global_transform.origin
	var directionTo:Vector3 = targetPosition - currentPosition
	var distance:float = currentPosition.distance_to(targetPosition)
	force = directionTo.normalized()*(pow(distance * 600,1))#/max(1,(parent.mass*0.15)))
	
	force = force.limit_length(max_force + (mass * 15) + player.velocity.length())
	
	apply_force(force, rotation_offset)
	
	if is_tether_max_range:
		force = (camera.global_transform.origin - currentPosition).normalized() * mass * 15
		apply_central_force(force)
	#var angleBetweenForceAndVelocity = min(90,force.angle_to(linear_velocity))*2
	
	apply_force(-linear_velocity * 20, rotation_offset) #* angleBetweenForceAndVelocity)		
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
	if can_rotate:
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
	axis_lock_linear_y = lock
func is_at_rest() -> bool:
	return linear_velocity.length_squared() <= 0.0001 and angular_velocity.length_squared() <= 0.0001

func calculate_torque_impulse() -> Vector3:
	var player_velocity = player.velocity
	var torque_impulse = Vector3(
		throw_direction.y * player_velocity.z - throw_direction.z * player_velocity.y,
		throw_direction.z * player_velocity.x - throw_direction.x * player_velocity.z,
		throw_direction.x * player_velocity.y - throw_direction.y * player_velocity.x
	)
	var random_factor = Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	torque_impulse += random_factor
	return torque_impulse * 3

func enable_collision_decection():
	await get_tree().create_timer(1).timeout
	set_contact_monitor(true)
	set_max_contacts_reported(10)

func _on_body_entered(body):
	if body.name == "monster":
		freeze = false
		sleeping = false
		var direction = (global_transform.origin - body.global_transform.origin).normalized()
		apply_impulse(transform.basis.z * (100 + mass),direction)

func add_grab_point_indicator():
	if player_raycast.is_colliding():
		var collision_point = player_raycast.get_collision_point()
		var local_collision_point = to_local(collision_point)
		grab_point_indicator = grab_icon.instantiate()
		grab_point_indicator.transform.origin = local_collision_point
		add_child(grab_point_indicator)

func remove_grab_point_indicator():
	if grab_point_indicator:
		grab_point_indicator.queue_free()

