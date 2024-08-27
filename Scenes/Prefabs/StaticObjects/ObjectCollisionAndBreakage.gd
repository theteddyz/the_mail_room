extends Node3D
#If the object is breakable
@export var breakable: bool = false
#The object which the model will switch on (need to exist as invisible on the node)
@export var broken_models: Array[MeshInstance3D] = []
#Any objects which will break apart from this origin object
@export var seperation_breakage_models: Array[RigidBody3D] = []

@export var breakable_hinges: Array[JoltHingeJoint3D] = []
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

var grabbable_script = preload("res://Scripts/MoveableObjects/GrabbableObject.gd")

var broken:bool

var previousVelocity:Vector3 = Vector3.ZERO
var previousRotation:Vector3 = Vector3.ZERO
var previousIsPickedUp:bool = false
var previousIsPickedUp2:bool = false
var previousIsPickedUp3:bool = false
var rigidbody:RigidBody3D
@export var initVolume:float = 0

@export var onlyPlayOnCollision:bool = false

func _ready():
	#if(impact_audios != null):
		#impact_audios.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
		#impact_audios.unit_size = 10
	#if(destruction_audios != null):
		#destruction_audios.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
		#destruction_audios.unit_size = 10
	impact_audios2 = impact_audios.duplicate(true)
	impact_audios3 = impact_audios.duplicate(true)
	add_child(impact_audios2)
	add_child(impact_audios3)
	impact_audios.max_polyphony = 50
	impact_audios2.max_polyphony = 50
	impact_audios3.max_polyphony = 50
	broken = false
	rigidbody = get_parent()

func _physics_process(_delta: float):
	var currentVelocity = rigidbody.linear_velocity
	
	var currentRotation = rigidbody.angular_velocity
	
	var currentAcceleration = ((previousVelocity - currentVelocity)/_delta)*0.01;
	var currentRotAccel = ((previousRotation - currentRotation)/_delta)*0.01;
	
	var impact = currentAcceleration.length()*2 + currentRotAccel.length()*2;
	if(impact > impact_threshold and !previousIsPickedUp2 and !onlyPlayOnCollision):
		var volume = min(-40 + pow(impact,1.5),0) + initVolume
		if(destruction_audios != null and impact > destruction_threshold and !broken):
			destruction_audios.play()
			break_object()
		else:
			playImpactSound(volume)
		
		
	previousVelocity = rigidbody.linear_velocity
	previousRotation = rigidbody.angular_velocity
	
	previousIsPickedUp3 = previousIsPickedUp2
	previousIsPickedUp2 = previousIsPickedUp
	previousIsPickedUp = rigidbody.is_picked_up
func _on_body_entered(body):
	#var other_body_velocity = body.linear_velocity if body is RigidBody3D else Vector3.ZERO
	#var relative_velocity = get_parent().linear_velocity - other_body_velocity
	#var impulse = relative_velocity.length()
	#var impulse = state.get_contact_impulse
	#var collision_force = impulse
	
	var currentAcceleration = (previousVelocity - rigidbody.linear_velocity);
	var currentRotAccel = (previousRotation - rigidbody.angular_velocity);
	var impact = currentAcceleration.length()*2 + currentRotAccel.length()*2;
	print("onlyPlayOnCollision: ",  onlyPlayOnCollision)
	print("(rigidbody.is_picked_up or onlyPlayOnCollision) and impact > impact_threshold: ",  (rigidbody.is_picked_up or onlyPlayOnCollision) and impact > impact_threshold)
	if((rigidbody.is_picked_up or onlyPlayOnCollision) and impact > impact_threshold):
		print("this shit",  min(-40 + pow(impact,1.5),0) + initVolume)
		var volume = min(-40 + pow(impact,1.5),0) + initVolume
		if(destruction_audios != null and impact > destruction_threshold and !broken):
			destruction_audios.play()
			break_object()
		else:
			playImpactSound(volume)
		
		
func break_object():
	broken = true
	#spawn_sound_event()
	#if(impact_audios != null):
	#	impact_audios.play()
	#if(destruction_audios != null):
	#	destruction_audios.play()
		
	for item in broken_models:
		item.visible = true
	
	if(normal_model != null):
		normal_model.visible = false
	
	for particle in breakage_particles:
		particle.emitting = true
		
	for hinge in breakable_hinges:
		hinge.motor_enabled = false
	#for model in seperation_breakage_models:
	#	model.reparent(get_tree().root.get_child(3))
	#	model.gravity_scale = 1
	#	model.set_collision_layer_value(2,true)
	#	model.set_script(grabbable_script)
	#	model.call("_ready")
		
func playImpactSound(volume: int):
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
	


func spawn_sound_event():
	var sound_event_area = Area3D.new()
	var shape = SphereShape3D.new()
	var collision_shape:CollisionShape3D = CollisionShape3D.new()
	shape.radius = 23
	collision_shape.shape = shape
	sound_event_area.add_child(collision_shape)
	sound_event_area.connect("body_entered", Callable(self, "_on_sound_event_area_body_entered"))
	get_tree().root.add_child(sound_event_area)
	sound_event_area.global_position = global_position
	await get_tree().create_timer(1).timeout
	sound_event_area.queue_free()

func _on_sound_event_area_body_entered(body):
	if body.has_method("on_hearing_sound"):
		body.on_hearing_sound(global_position)
"""
