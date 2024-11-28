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
@export var disable_collider_on_grab:bool = true
@export var is_door:bool = false
@export var is_drawer:bool = false
@export var can_rotate:bool = true
@onready var grab_icon = preload("res://Scenes/Prefabs/MoveableObjects/grab_icon.tscn")
@export var is_picked_up = false
@onready var optimizer = preload("res://Scenes/Prefabs/MoveableObjects/grabbable_optimizer.tscn")
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
var player_cross_hair
signal collided(other_body)
const DOOR_TORQUE_MULTIPLIER: float = 0.02
const DRAWER_TORQUE_MULTIPLIER: float = 0.01
var mouse_line: MeshInstance3D
var is_grabbing_bool: bool = false
var mouse_line_material: ORMMaterial3D
var mouse_velocity:Vector2 = Vector2.ZERO
var previous_mouse_position = Vector2.ZERO
var previous_time = 0.0
var open:bool
var close:bool
var door_forward_position
var door_global_position
#This is just for the on screen visualizer very stupid fix should have one bool for this
var grabbed:bool
func _ready():
	var new_optimizer = optimizer.instantiate()
	add_child(new_optimizer)
	new_optimizer._setup()
	
	set_collision_layer_value(5,true)
	set_collision_mask_value(5,true)
	set_collision_mask_value(13,true)
	set_collision_mask_value(6,true)
	if GameManager.get_player() != null:
		player = GameManager.get_player()
	object_Interpolator = find_child("Interpolator")
	starting_angular_damp = angular_damp
	player_cross_hair = Gui.get_crosshair()
	freeze = true
	sleeping = true
	if player:
		camera = player.find_child("Camera")
		player_raycast = player.find_child("InteractableFinder")
	pickup_timer = Timer.new()
	pickup_timer.connect("timeout", Callable(self, "_on_pickup_timer_timeout"))
	connect("body_entered",Callable(self,"_on_body_entered"))
	mouse_line_material = ORMMaterial3D.new()
	mouse_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mouse_line_material.albedo_color = Color(0.5,0.5,0.5)
	#mouse_line_material.emission = Color(255,255,255)
	#mouse_line_material.emission_intensity = 1
	#mouse_line_material.emission_energy_multiplier = 1
	#mouse_line_material.emission_enabled = true
	previous_time = Time.get_ticks_msec()
	if is_door:
		door_forward_position = global_transform.basis.z.normalized()
		door_global_position = global_transform.origin


#Used by Both
func _input(event):
	if is_rotating and event is InputEventMouseMotion:
		handle_mouse_motion(event.relative)
	elif is_door and is_picked_up and event is InputEventMouseMotion:
		var player_inside = is_player_inside_room()
		var adjusted_relative = event.relative
		if player_inside:
			adjusted_relative.y = -event.relative.y
		previous_mouse_position = adjusted_relative
	elif is_drawer and is_picked_up and event is InputEventMouseMotion:
		previous_mouse_position = event.relative


func is_player_inside_room()-> bool:
	var door_forward: Vector3 = door_forward_position
	var door_to_player: Vector3 = (player.global_transform.origin - door_global_position).normalized()
	return door_forward.dot(door_to_player) < 0


func _process(_delta): #Tether the player to the object
	if is_picked_up:
		mouse_velocity = Vector2.ZERO
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
		if is_picked_up and !is_grabbing_bool:
			is_grabbing_bool = true
			call_deferred("_init_mouse_line")
	else:
		if !is_picked_up and is_grabbing_bool:
			is_grabbing_bool = false
			mouse_line.queue_free()

func _physics_process(delta):
	if freeze:
		pass 
	#if camera.global_transform.origin.distance_to(global_transform.origin) > 15:
	#	sleeping = true
		#visible = false
	#else:
		#visible = true
#	var distance_squared = camera_position.distance_to(object_position)
		
	# Quick check: is the object too far away?
	#if camera.global_transform.origin.distance_to(global_transform.origin) > 45:	
		#visible = false
#		return
	#else:
		#visible = true
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
	grabbed = true
	freeze = false
	sleeping = false
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	if pickup_timer.is_stopped():
		if !timerAdded:
			add_child(pickup_timer)
			timerAdded=true
		if is_door or is_drawer:
			EventBus.emitCustomSignal("disable_player_movement",[true,false])
		#itemPos = player.find_child("ItemHolder")
		camera = player.find_child("Camera")
		playerHead = player.find_child("Head")
		if should_freeze:
			freeze = false
		if disable_collider_on_grab:
			set_collision_layer_value(2,false)
		if player_raycast.is_colliding():
			grab_offset = player_raycast.get_collision_point() - global_transform.origin
			### For some reason you need this when reparenting the camera from/to player. player.find_child(camera) does not work.
			if camera == null:
				var headbop = playerHead.get_child(0)
				camera = headbop.get_child(3)
				if camera == null:
					print("Camera not found!")
					return
				var playerPosition:Vector3 = camera.global_transform.origin
				var objectPosition:Vector3 = player_raycast.get_collision_point()
				grab_distance = playerPosition.distance_to(objectPosition)
			else:
				var playerPosition:Vector3 = camera.global_transform.origin
				var objectPosition:Vector3 = player_raycast.get_collision_point()
				grab_distance = playerPosition.distance_to(objectPosition)
			
			initial_basis = global_transform.basis
			
			print("Grab distance: " , grab_distance);
			pickmeUp()
			enable_collision_decection()
			add_grab_point_indicator()
func dropMe(throw:bool):
	if is_picked_up and throw == false:
		if is_door or is_drawer:
			EventBus.emitCustomSignal("disable_player_movement",[false,false])
		EventBus.emitCustomSignal("dropped_object", [mass,self])
		#linear_damp = 10
		grabbed = false
		var currentPos = global_position
		is_picked_up = false
		global_position = currentPos
		#linear_damp = 0.1
		force_above_threshold_time = 0.0
		angular_damp = starting_angular_damp
		if disable_collider_on_grab:
			set_collision_layer_value(2,true)
		#if should_freeze:
			#sleeping = true
	else:
		throw_direction = (playerHead.global_transform.basis.z * -1).normalized()
		EventBus.emitCustomSignal("dropped_object",[mass,self])
		start_pickup_timer()
		force_above_threshold_time = 0.0
		angular_damp = starting_angular_damp
		apply_torque_impulse(calculate_torque_impulse())
		
		if should_freeze:
			sleeping = true
		if disable_collider_on_grab:
			set_collision_layer_value(2,true)
	remove_grab_point_indicator()
func pickmeUp():
	if is_picked_up:
		return
	#if parent.mass <= weightLimit:
	#TODO: Switch "null" to something "more" correct
	angular_damp = 10
	if disable_collider_on_grab:
		set_collision_layer_value(2,false)
	EventBus.emitCustomSignal("object_held", [mass, self])
	is_picked_up = true

func rotate_vector_global(offset: Vector3) -> Vector3:
	# Get the object's global transform
	var global_transform = self.global_transform
	# Extract the basis (rotation matrix) from the global transform
	var basisen = global_transform.basis
	
	var relative_basis = basisen * initial_basis.inverse()
	
	return (relative_basis * offset)
	
func update_position(delta):
	if !is_door and !is_drawer:
		var rotation_offset = rotate_vector_global(grab_offset)
		var forward = -camera.global_transform.basis.z
		var targetPosition: Vector3 = Vector3.ZERO
		var grab_range = 0
		if is_door:
			grab_range = 2
			targetPosition = (camera.global_transform.origin + forward.normalized()*grab_range) + -rotation_offset
		else:
			grab_range = grab_distance
			targetPosition = (camera.global_transform.origin + forward.normalized()*grab_range) + -rotation_offset
		var currentPosition:Vector3 = global_transform.origin
		_update_mouse_line((targetPosition + rotation_offset),currentPosition + rotation_offset)
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
	elif is_door and !is_drawer:
		var mouse_velocity = previous_mouse_position / delta
		if !mouse_velocity.is_finite():
			print("Invalid mouse velocity:", mouse_velocity)
		apply_door_torque(mouse_velocity * 0.5)
	elif !is_door and is_drawer:
		var mouse_velocity = previous_mouse_position / delta
		if !mouse_velocity.is_finite():
			print("Invalid mouse velocity:", mouse_velocity)
		apply_drawer_impluse(mouse_velocity)
func apply_drawer_impluse(mouse_velocity:Vector2):
	var impulse_amount = mouse_velocity.y * DOOR_TORQUE_MULTIPLIER
	var local_motion_axis = Vector3(0, 0, 1)
	var global_motion_axis = (global_transform.basis * local_motion_axis).normalized()
	var linear_impulse = global_motion_axis * impulse_amount * mass
	apply_central_impulse(linear_impulse * 0.1)
	apply_central_impulse(-linear_velocity * 0.1)
func apply_door_torque(mouse_velocity: Vector2):
	var player_inside = is_player_inside_room()
	var torque_direction = -1
	var torque
	if player_inside:
		torque_direction = 1 
	if player_inside:
		torque = mouse_velocity.y * DOOR_TORQUE_MULTIPLIER * torque_direction
	else: torque =  mouse_velocity.y * DOOR_TORQUE_MULTIPLIER
	var torque_force = Vector3(0, torque * mass, 0) 
	apply_torque_impulse(torque_force)
	apply_torque_impulse(-angular_velocity * 0.05) 

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
	EventBus.emitCustomSignal("show_icon",["grabClosed"])
	pass
	#if player_raycast.is_colliding():
		#var collision_point = player_raycast.get_collision_point()
		#var local_collision_point = to_local(collision_point)
		#grab_point_indicator = grab_icon.instantiate()
		#grab_point_indicator.transform.origin = local_collision_point
		#player_cross_hair.hide()
		#add_child(grab_point_indicator)

func remove_grab_point_indicator():
	EventBus.emitCustomSignal("hide_icon",["grabClosed"])
	pass
	#if grab_point_indicator:
	#	grab_point_indicator.queue_free()
	#	player_cross_hair.show()

func _init_mouse_line():

	var result = await line(Vector3.ZERO, Vector3.ZERO, Color.WHITE)
	mouse_line = result

func _update_mouse_line(position1:Vector3, position2:Vector3):
	if mouse_line != null:
		var mouse_pos = position1
		var mouse_line_immediate_mesh = mouse_line.mesh as ImmediateMesh
		if mouse_pos != null:
			var mouse_pos_V3:Vector3 = mouse_pos
			mouse_line_immediate_mesh.clear_surfaces()
			mouse_line_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES,mouse_line_material)
			mouse_line_immediate_mesh.surface_add_vertex(position2)
			mouse_line_immediate_mesh.surface_add_vertex(position1)
			mouse_line_immediate_mesh.surface_end()	

func line(pos1: Vector3, pos2: Vector3, color = Color.WHITE, persist_ms = 0):
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()	

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, mouse_line_material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()

	

	return await final_cleanup(mesh_instance, persist_ms)

func final_cleanup(mesh_instance: MeshInstance3D, persist_ms: float):
	get_tree().get_root().add_child(mesh_instance)
	if persist_ms == 1:
		await get_tree().physics_frame
		mesh_instance.queue_free()
	elif persist_ms > 0:
		await get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance


#func optimizations():
#	var camera_transform = camera.global_transform
#	var camera_position = camera_transform.origin
#	var object_position = global_transform.origin
	#if camera_position.distance_to(object_position) > 15:
	#	sleeping = true
		#visible = false
	#else:
		#visible = true



#	var distance_squared = camera_position.distance_to(object_position)
		
	# Quick check: is the object too far away?
#	if distance_squared > 45:
#		visible = false
#		return
#	else:
#		visible = true
