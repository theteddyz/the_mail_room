extends Node3D
func _physics_process(delta: float) -> void:
	rotate_z(deg_to_rad(225) * delta)
