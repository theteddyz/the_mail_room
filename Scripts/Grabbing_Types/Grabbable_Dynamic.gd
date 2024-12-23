extends Grabbable
@export var max_force:float = 300.0
var object:RigidBody3D
var holding_object:bool = false
var player:CharacterBody3D
var camera
var player_head
var is_rotating = false
var is_door:bool = false
var is_drawer:bool = false
var grab_offset: Vector3 = Vector3.ZERO
var player_raycast:RayCast3D
var initial_basis = Basis()
var grab_distance = 0
var force:Vector3 = Vector3.ZERO
var is_tether_max_range: bool = false
var _mass
var force_above_threshold_time: float = 0.0 
@export var tether_distance: float = 2.5
@export var distance_threshold: float = 6.0
@export var drop_time_threshold: float = 0.5
@export var throw_strength: float = 700.0  
var mouse_line: MeshInstance3D
var mouse_line_material: ORMMaterial3D
var throw_direction = Vector3.ZERO
func _ready():
	player = GameManager.get_player()
	camera = player.find_child("Camera")
	player_head = player.find_child("Head")
	player_raycast = player.find_child("InteractableFinder")
	mouse_line_material = ORMMaterial3D.new()
	mouse_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mouse_line_material.albedo_color = Color(0.5,0.5,0.5)
	call_deferred("_init_mouse_line")


func grab():
	set_physics_process(true)
	set_process(true)
	object = get_parent().current_grabbed_object
	object.freeze = false
	object.sleeping = false
	_mass = object.mass
	grab_offset = object.to_local(player_raycast.get_collision_point())
	#if pickup_timer.is_stopped():
		#if !timerAdded:
			#add_child(pickup_timer)
			#timerAdded=true

	if player_raycast.is_colliding():
		#grab_offset = player_raycast.get_collision_point() - object.global_transform.origin
		### For some reason you need this when reparenting the camera from/to player. player.find_child(camera) does not work.
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
			
			initial_basis = object.global_transform.basis
			
	pick_up_object()
	enable_collision_detection()
	EventBus.emitCustomSignal("show_icon",[object])


func _process(delta):
	if holding_object:
		update_line_position(delta)

func _physics_process(delta):
	if holding_object:
		update_position(delta)
		var playerPosition:Vector3 = player.transform.origin;
		playerPosition.y = 0;
		#var targetPosition: Vector3 = itemPos.global_transform.origin + -grab_offset
		var objectPosition:Vector3 = object.global_transform.origin + grab_offset;
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
		
		#update_rotation(delta)


func pick_up_object():
	#object.angular_damp = 10
	EventBus.emitCustomSignal("object_held", [_mass, object])
	holding_object = true

func enable_collision_detection():
	await get_tree().create_timer(1).timeout
	object.set_contact_monitor(true)
	object.set_max_contacts_reported(10)

func throw_object():
	throw_direction = (player_head.global_transform.basis.z * -1).normalized()
	object.apply_force(throw_direction * throw_strength, throw_direction)
	drop_object()

func start_rotating():
	pass
func stop_rotating():
	pass


func drop_object():
	holding_object = false
	EventBus.emitCustomSignal("dropped_object", [object.mass,self])
	EventBus.emitCustomSignal("hide_icon",["grabClosed"])
	#object.angular_damp = 1
	#object.linear_damp = 0.1
	_update_mouse_line(Vector3.ZERO,Vector3.ZERO)

func update_line_position(delta):
	var rotation_offset = rotate_vector_global(grab_offset)
	var forward = -camera.global_transform.basis.z
	var targetPosition: Vector3 = Vector3.ZERO
	var grab_range = grab_distance
	targetPosition = (camera.global_transform.origin + forward.normalized()*grab_range) + -rotation_offset
	var currentPosition:Vector3 = object.global_transform.origin
	_update_mouse_line((targetPosition + rotation_offset),currentPosition + rotation_offset)

func update_position(delta):
	var rotation_offset = rotate_vector_global(grab_offset)
	var forward = -camera.global_transform.basis.z
	var targetPosition: Vector3 = Vector3.ZERO
	var grab_range = grab_distance
	targetPosition = (camera.global_transform.origin + forward.normalized()*grab_range) + -rotation_offset
	var currentPosition:Vector3 = object.global_transform.origin
	var directionTo:Vector3 = targetPosition - currentPosition
	var distance:float = currentPosition.distance_to(targetPosition)
	force = directionTo.normalized()*(pow(distance * 600,1))#/max(1,(parent.mass*0.15)))
	force = force.limit_length(max_force + (_mass * 15) + player.velocity.length())
	object.apply_force(force, rotation_offset)
	if is_tether_max_range:
		force = (camera.global_transform.origin - currentPosition).normalized() * _mass * 15
		object.apply_central_force(force)
	#var angleBetweenForceAndVelocity = min(90,force.angle_to(linear_velocity))*2
	object.apply_force(-object.linear_velocity * 20, rotation_offset) #* angleBetweenForceAndVelocity)		
	if distance > distance_threshold:
		force_above_threshold_time += delta
		if force_above_threshold_time >= drop_time_threshold:
			drop_object()
	else:
		force_above_threshold_time = 0.0
	

func _update_mouse_line(position1:Vector3, position2:Vector3):
	if mouse_line != null:
		var mouse_pos = position1
		var mouse_line_immediate_mesh = mouse_line.mesh as ImmediateMesh
		if mouse_pos != null:
			#var mouse_pos_V3:Vector3 = mouse_pos
			mouse_line_immediate_mesh.clear_surfaces()
			mouse_line_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES,mouse_line_material)
			mouse_line_immediate_mesh.surface_add_vertex(position2)
			mouse_line_immediate_mesh.surface_add_vertex(position1)
			mouse_line_immediate_mesh.surface_end()

func _init_mouse_line():
	var result = await line(Vector3.ZERO, Vector3.ZERO, Color.WHITE)
	mouse_line = result




func line(pos1: Vector3, pos2: Vector3, _color = Color.WHITE, persist_ms = 0):
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
	if persist_ms == 1.0:
		await get_tree().physics_frame
		mesh_instance.queue_free()
	elif persist_ms > 0.0:
		await get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance


func rotate_vector_global(offset: Vector3) -> Vector3:
	# Get the object's global transform
	#var _global_transform = self.global_transform
	# Extract the basis (rotation matrix) from the global transform
	var basisen = object.global_transform.basis
	
	var relative_basis = basisen * initial_basis.inverse()
	
	return (relative_basis * offset)
