extends SpotLight3D

func _physics_process(delta: float) -> void:
	rotate_y(deg_to_rad(35 * delta))
