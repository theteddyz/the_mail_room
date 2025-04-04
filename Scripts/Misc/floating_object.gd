@tool
extends RigidBody3D
@export var float_force := 1.0
@export var water_drag := 0.05
@export var water_angular_drag := 0.05
@onready var gravity:float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var probes = $ProbeContainer.get_children()

const water_height := 0.0
var submerged := false
func _ready():
	update_probes()
func update_probes():
	for probe in probes:
		# Remove old debug spheres
		for child in probe.get_children():
			if child is MeshInstance3D:
				child.queue_free()
				
		var debug_sphere = MeshInstance3D.new()
		debug_sphere.mesh = SphereMesh.new()
		debug_sphere.scale = Vector3(0.1, 0.1, 0.1)  # Small size
		probe.add_child(debug_sphere)  # Parent to probe, so no need to set position manually

func _process(delta):
	pass
	#if Engine.is_editor_hint():
		#update_probes()


func _physics_process(delta):
	submerged = false
	for probe in probes:
		var world_position = probe.global_transform.origin
		var depth = water_height - global_position.y
		if depth > 0:
			submerged = true
			var force = Vector3.UP * float_force * gravity * depth * mass / probes.size()
			apply_force(force, world_position - global_transform.origin) 
	if submerged:
		linear_velocity *= 1 - water_drag
		angular_velocity *= 1 - water_angular_drag


func _integrate_forces(state):
	if submerged:
		state.linear_velocity *= 1 - water_drag
		state.angular_velocity *= 1 - water_angular_drag
