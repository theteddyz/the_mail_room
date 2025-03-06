extends MeshInstance3D
@onready var fan1:MeshInstance3D = $ComputerFan
@onready var fan2:MeshInstance3D = $ComputerFan_001
@export var rotation_speed: float = 1.0


func _process(delta):
	fan1.rotate_z(rotation_speed * delta)
	fan2.rotate_z(rotation_speed * delta)
