extends StaticBody3D
@onready var door:RigidBody3D

@export_range(0.0,1.0) var open_percentage = 0

const CLOSE_POSITION = Vector3(0.001, 0.0, 0.007)
const CLOSE_ROTATION = Vector3(0.0, 0.0, 0.0)
const OPEN_POSITION = Vector3(0.822, 0.0, -1.074)
const OPEN_ROTATION = Vector3(0.0, -90.0, 0.0)

func _ready():
	for child in get_children():
		if child is RigidBody3D:
			door = child
	remove_script()

func _process(delta: float) -> void:
	move_door_to_percentage(delta)
	




func move_door_to_percentage(delta):
	var new_position = CLOSE_POSITION.lerp(OPEN_POSITION, open_percentage)
	var new_rotation = CLOSE_ROTATION.lerp(OPEN_ROTATION, open_percentage)
	door.transform.origin = new_position
	door.transform.basis = Basis().rotated(Vector3(1, 0, 0), deg_to_rad(new_rotation.x))
	door.transform.basis = door.transform.basis.rotated(Vector3(0, 1, 0), deg_to_rad(new_rotation.y))
	door.transform.basis = door.transform.basis.rotated(Vector3(0, 0, 1), deg_to_rad(new_rotation.z))


func remove_script() -> void:
	await get_tree().create_timer(1.0).timeout 
	self.script = null
