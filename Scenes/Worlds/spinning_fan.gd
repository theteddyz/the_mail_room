extends Node3D
@export var axis: Vector3 = Vector3(0, 0, 1)
func _physics_process(delta: float) -> void:
	rotate_object_local(axis, deg_to_rad(225) * delta)
