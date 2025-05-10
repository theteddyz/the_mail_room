extends Node3D
#If the object is breakable
@export var breakable: bool = false
#The object which the model will switch on (need to exist as invisible on the node)
@export var broken_models: Array[MeshInstance3D] = []
#Any objects which will break apart from this origin object
@export var broken_scene_prefabs: Array[PackedScene] = []
@export var broken_decals: Array[PackedScene] = []

@export var extra_scatter_force: float = 5.0
@export var random_spawn_offset_range: float = 0.2
@export var breakable_hinges: Array[HingeJoint3D] = []
#Basic model, the default state, not required if broken_models is empty
@export var normal_model: Node
#Threshold before the impact causes a breakage
@export var destruction_threshold = 15.0
#Threshold before the impact causes some sort of sound 
@export var impact_threshold = 3

#Any impact audio-player on the node
@export var impact_audios: AudioStreamPlayer3D
var impact_audios2: AudioStreamPlayer3D
var impact_audios3: AudioStreamPlayer3D
var index: int
#Any destruction audio-player on the node
@export var destruction_audios: AudioStreamPlayer3D
#Particles which to play during a breakage
@export var breakage_particles: Array[GPUParticles3D]

var grabbable_script = preload("res://Scripts/Grabbing_Types/Grab_Type.gd")

var broken:bool

var previousVelocity:Vector3 = Vector3.ZERO
var previousVelocity2:Vector3 = Vector3.ZERO
var previousRotation:Vector3 = Vector3.ZERO
var previousIsPickedUp:bool = false
var previousIsPickedUp2:bool = false
var previousIsPickedUp3:bool = false
var rigidbody:RigidBody3D
@export var initVolume:float = 0
@export var instabreak: bool = false
@export var general_sound_sphere_radius: float = 18
@export var breakage_sound_radius_multiplier: float = 1.5
@export var onlyPlayOnCollision:bool = false

func _ready():
	
	#if(impact_audios != null):
		#impact_audios.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
		#impact_audios.unit_size = 10
	#if(destruction_audios != null):
		#destruction_audios.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
		#destruction_audios.unit_size = 10
	if impact_audios:
		impact_audios2 = impact_audios.duplicate(true)
		add_child(impact_audios2)
		impact_audios2.max_polyphony = 50
		
	if impact_audios:
		impact_audios3 = impact_audios.duplicate(true)
		add_child(impact_audios3)
		impact_audios3.max_polyphony = 50
		
	if impact_audios:
		impact_audios.max_polyphony = 50
	broken = false
	rigidbody = get_parent()
	initVolume = impact_audios.volume_db if impact_audios != null else 0
	if instabreak:
		break_object()
		
	#for model in seperation_breakage_models:
		#model.freeze = true
		#model.visible = false
		#model.set_collision_layer_value(2,false)
		#model.set_collision_layer_value(5,false)
		#model.set_collision_mask_value(1,false)
		#model.set_collision_mask_value(2,false)
		#model.set_collision_mask_value(3,false)
		#model.set_collision_mask_value(4,false)
		#model.set_collision_mask_value(5,false)

func _physics_process(_delta: float):
	#if rigidbody.freeze:
		#set_physics_process(false)
	#else:
		#set_physics_process(true)
	if impact_audios and impact_audios2 and impact_audios3:
		if rigidbody.freeze:
			return
		if rigidbody.sleeping:
			return
		var currentVelocity = rigidbody.linear_velocity
		
		var currentRotation = rigidbody.angular_velocity
		
		var currentAcceleration = ((previousVelocity - currentVelocity)/_delta)*0.01;
		var currentRotAccel = ((previousRotation - currentRotation)/_delta)*0.01;
		
		var impact = currentAcceleration.length()*2 + currentRotAccel.length()*2;
		if(!previousIsPickedUp2 and !onlyPlayOnCollision and impact > impact_threshold):
			var volume = min(-40 + pow(impact,1.5),0) + initVolume
			if(destruction_audios != null and impact > destruction_threshold and !broken):
				destruction_audios.play()
				break_object()
			else:
				playImpactSound(volume)
			
			
		previousVelocity = rigidbody.linear_velocity
		previousVelocity2 = previousVelocity
		previousRotation = rigidbody.angular_velocity
		
		previousIsPickedUp3 = previousIsPickedUp2
		previousIsPickedUp2 = previousIsPickedUp
		if GrabbingManager.current_grabbed_object and GrabbingManager.current_grabbed_object.grab_type == 0 and GrabbingManager.current_grabbed_object == rigidbody:
			previousIsPickedUp = GrabbingManager.holding_object
		else:
			previousIsPickedUp = false
		
func _on_body_entered(_body):
	if(!previousIsPickedUp2 and !onlyPlayOnCollision):
		return
	#var other_body_velocity = body.linear_velocity if body is RigidBody3D else Vector3.ZERO
	#var relative_velocity = get_parent().linear_velocity - other_body_velocity
	#var impulse = relative_velocity.length()
	#var impulse = state.get_contact_impulse
	#var collision_force = impulse
	var currentAcceleration = (previousVelocity - rigidbody.linear_velocity);
	var currentRotAccel = (previousRotation - rigidbody.angular_velocity);
	var impact = currentAcceleration.length()*2 + currentRotAccel.length()*2;
	if impact > impact_threshold:
		var volume = min(-40 + pow(impact,1.5),0) + initVolume
		if(destruction_audios != null and impact > destruction_threshold and !broken):
			destruction_audios.play()
			break_object()
		else:
			print("COLLIDED")
			playImpactSound(volume)
		
		
func break_object():
	if broken:
		return

	broken = true
	spawn_sound_event(true)

	if destruction_audios:
		destruction_audios.play()

	var origin_transform = rigidbody.global_transform
	var origin_velocity = rigidbody.linear_velocity
	var origin_angular = rigidbody.angular_velocity

	for particle in breakage_particles:
		particle.emitting = true

	for hinge in breakable_hinges:
		hinge.set_flag(hinge.FLAG_ENABLE_MOTOR, false)


	for prefab in broken_decals:
		if prefab:
			var broken_instance = prefab.instantiate() as Decal
			get_tree().current_scene.add_child(broken_instance)
			broken_instance.global_position = rigidbody.global_position

			var velocity = previousVelocity2
			if velocity.length() > 0.001:
				var direction = -velocity.normalized()

				# Assume +Z is the decal's forward direction
				var forward = Vector3.UP

				# Get rotation axis and angle
				var axis = forward.cross(direction)
				var dot = forward.dot(direction)

				var rotation_quat := Quaternion()
				if axis.length() < 0.0001:
					if dot < 0.0:
						# Vectors are nearly opposite
						axis = forward.orthogonal().normalized()
						rotation_quat = Quaternion(axis, PI)
					else:
						# Vectors are the same direction, no rotation needed
						rotation_quat = Quaternion()
				else:
					var angle = acos(clamp(dot, -1.0, 1.0)) # Clamp for safety
					rotation_quat = Quaternion(axis.normalized(), angle)

				broken_instance.global_transform.basis = Basis(rotation_quat)
				#broken_instance.scale = Vector3(0.1,0.1,0.1)
			

	for prefab in broken_scene_prefabs:
		if prefab:
			var broken_instance = prefab.instantiate() as RigidBody3D
			get_tree().current_scene.add_child(broken_instance)

			# Random slight offset and rotation for realism
			var random_offset = Vector3(
				randf_range(-random_spawn_offset_range, random_spawn_offset_range),
				randf_range(-random_spawn_offset_range, random_spawn_offset_range),
				randf_range(-random_spawn_offset_range, random_spawn_offset_range)
			)
			var new_transform = origin_transform
			new_transform.origin += random_offset
			new_transform.basis = new_transform.basis.rotated(Vector3(randf(), randf(), randf()).normalized(), randf() * TAU)

			broken_instance.global_transform = new_transform

			broken_instance.linear_velocity = origin_velocity + Vector3(randf() - 0.5, randf(), randf() - 0.5) * extra_scatter_force
			broken_instance.angular_velocity = origin_angular + Vector3(randf(), randf(), randf()) * extra_scatter_force

	# Remove original object
	if broken_models.size() == 0:
		normal_model.visible = false
		rigidbody.freeze = true
		rigidbody.set_collision_layer_value(2,false)
		rigidbody.set_collision_layer_value(5,false)
		rigidbody.set_collision_mask_value(1,false)
		rigidbody.set_collision_mask_value(2,false)
		rigidbody.set_collision_mask_value(3,false)
		rigidbody.set_collision_mask_value(4,false)
		
	else:
		normal_model.visible = false
		for model in broken_models:
			model.visible = true

func spawn_sound_event(breakage: bool):
	var mult = 1
	if breakage:
		mult = breakage_sound_radius_multiplier
	var sound_event_area = Area3D.new()
	var shape = SphereShape3D.new()
	var collision_shape:CollisionShape3D = CollisionShape3D.new()
	sound_event_area.set_collision_mask_value(13, true)
	shape.radius = general_sound_sphere_radius * mult
	collision_shape.shape = shape
	sound_event_area.add_child(collision_shape)
	sound_event_area.connect("body_entered", Callable(self, "_on_sound_event_area_body_entered"))
	get_tree().root.add_child(sound_event_area)
	sound_event_area.global_position = global_position
	await get_tree().create_timer(0.25).timeout
	sound_event_area.queue_free()

func _on_sound_event_area_body_entered(body):
	if body.has_method("on_hearing_sound"):
		body.on_hearing_sound(global_position)
		

func playImpactSound(volume: int):
	spawn_sound_event(false)
	impact_audios.volume_db = volume
	impact_audios.play()
	match index:
		0:
			impact_audios.volume_db = volume
			impact_audios.play()
		1:
			impact_audios2.volume_db = volume
			impact_audios2.play()
		2:
			impact_audios3.volume_db = volume
			impact_audios3.play()
	index += 1
	if index > 2:
		index = 0
"""
# On the rigid body:
func _integrate_forces(state : PhysicsDirectBodyState3D):
	for contact_index in state.get_contact_count():
		var object_hit := state.get_contact_collider_object(contact_index)
		if (is_instance_valid(object_hit)): # To fix a case where an object hits the player as player is deleted during level transition (intermission)
			handle_rigid_body_collision(object_hit, state.get_contact_collider_position(contact_index), state.get_contact_local_velocity_at_position(contact_index), state.get_contact_impulse(contact_index))

#And in my physics Autoload:
func handle_rigid_body_collision(object_hit : Node3D, position : Vector3, velocity : Vector3, impulse : Vector3):
	# TODO: Sometimes impulse is 0, 0, 0, even though there is a solid impact.  Jolt bug?
	
	if (impulse.length() > 0.5):
		print("impulse: " , impulse.length());
		if(impact_audios != null):
			impact_audios.volume_db = min(-30 + pow(impulse.length(),1.5),0)
			impact_audios.max_polyphony = 50
			impact_audios.play()
			

func _on_body_entered(body):
	var collision_force = calculate_collision_force(body)
	if collision_force > impact_threshold && collision_force <= destruction_threshold:
		if(impact_audios != null):
			impact_audios.play()
			spawn_sound_event()
	if collision_force > destruction_threshold and !broken and breakable:
		break_object()
		
func calculate_collision_force(body):
	var impulse = 0.0
	var other_body_velocity = body.linear_velocity if body is RigidBody3D else Vector3.ZERO
	var relative_velocity = get_parent().linear_velocity - other_body_velocity
	impulse = get_parent().mass * relative_velocity.length()
	return impulse


"""
