extends RigidBody3D
@export var float_force := 1.0
@export var water_drag := 0.05
@export var water_angular_drag := 0.05
@onready var gravity:float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var probes = $ProbeContainer.get_children()

const water_height := 0.0
var submerged := false
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
