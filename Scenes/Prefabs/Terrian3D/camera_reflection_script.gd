extends Camera3D

var time: float = 0.0
var playerCam: Camera3D
@export var water: Node3D
@export var rotate: float
func _ready():
	var root = get_tree().root
	playerCam = GameManager.get_player_camera()


func _process(delta: float) -> void:

	var water_y = water.global_transform.origin.y
	var cam_transform = playerCam.global_transform

	# Mirror position over water plane (Y-axis reflection)
	var mirrored_pos = cam_transform.origin
	mirrored_pos.y = water_y - (mirrored_pos.y - water_y)

	transform.origin = mirrored_pos
	
	rotation.y = playerCam.global_rotation.y
	rotation.x = -playerCam.global_rotation.x
	rotation.z = -playerCam.global_rotation.z + 3.14159265 # rotate
