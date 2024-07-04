extends Node3D
class_name Interpolator
@onready var mesh = get_child(0)
@onready var meshBroken = get_child(1)
@onready var parent = get_parent()
var meshScale
var update = false
var prevPosition
var currentPositon
var originScale

# Called when the node enters the scene tree for the first time.
func _ready():
	originScale = mesh.scale
	meshScale = mesh.scale
	prevPosition = parent.global_transform
	currentPositon = parent.global_transform



func _update_transform():
	prevPosition = currentPositon
	currentPositon = parent.global_transform

#This must be called and set to true in the physics_process on the grabbable object or wherever its being used
func setUpdate(updated:bool):
	update = updated

func _process(delta):
	mesh.scale = originScale
	
	if update:
		_update_transform()
		update = false
	var f = clamp(Engine.get_physics_interpolation_fraction(),0,1)
	mesh.global_transform = prevPosition.interpolate_with(currentPositon,f)
	if meshBroken != null:
		meshBroken.global_transform = prevPosition.interpolate_with(currentPositon,f)
		meshBroken.scale = meshScale
	#Stupid temp fix for now
	mesh.scale = meshScale
