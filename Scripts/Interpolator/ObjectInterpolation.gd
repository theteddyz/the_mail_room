extends Node3D
class_name Interpolator
@onready var parent = get_parent()
var mesh_instances = []
var meshScale
var update = false
var prevPosition
var currentPositon
var origin_scales = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if child is MeshInstance3D:
			mesh_instances.append(child)
			origin_scales[child] = child.scale
	prevPosition = parent.global_transform
	currentPositon = parent.global_transform



func _update_transform():
	prevPosition = currentPositon
	currentPositon = parent.global_transform

#This must be called and set to true in the physics_process on the grabbable object or wherever its being used
func setUpdate(updated:bool):
	update = updated

func _process(_delta):
	for mesh in mesh_instances:
		mesh.scale = origin_scales[mesh]
	
	if update:
		_update_transform()
		update = false
	var f = clamp(Engine.get_physics_interpolation_fraction(),0,1)
	for mesh in mesh_instances:
		mesh.global_transform = prevPosition.interpolate_with(currentPositon, f)
		mesh.scale = origin_scales[mesh]
