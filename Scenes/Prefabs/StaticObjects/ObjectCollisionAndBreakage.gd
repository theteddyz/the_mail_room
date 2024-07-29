extends Node3D

#If the object is breakable
@export var breakable: bool = false
#The object which the model will switch on (need to exist as invisible on the node)
@export var broken_models: Array[MeshInstance3D] = []
#Any objects which will break apart from this origin object
@export var seperation_breakage_models: Array[RigidBody3D] = []
#Basic model, the default state, not required if broken_models is empty
@export var normal_model: Node
#Threshold before the impact causes a breakage
@export var destruction_threshold = 5.0
#Threshold before the impact causes some sort of sound 
@export var impact_threshold = 0.5

#Any impact audio-player on the node
@export var impact_audios: AudioStreamPlayer3D
#Any destruction audio-player on the node
@export var destruction_audios: AudioStreamPlayer3D
#Particles which to play during a breakage
@export var breakage_particles: Array[GPUParticles3D]

var grabbable_script = preload("res://Scripts/MoveableObjects/GrabbableObject.gd")

var broken:bool

func _ready():
	broken = false
	
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
	
func break_object():
	broken = true
	spawn_sound_event()
	if(impact_audios != null):
		impact_audios.play()
	if(destruction_audios != null):
		destruction_audios.play()
		
	for item in broken_models:
		item.visible = true
	
	if(normal_model != null):
		normal_model.visible = false
	
	for particle in breakage_particles:
		particle.emitting = true
		
	for model in seperation_breakage_models:
		model.reparent(get_tree().root.get_child(3))
		model.gravity_scale = 1
		model.set_collision_layer_value(2,true)
		model.set_script(grabbable_script)
		model.call("_ready")

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
