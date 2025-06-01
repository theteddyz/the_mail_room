extends Node3D
@export var target_scene_path := ""
@export_enum("Down", "Up")
var move_direction: int = 0
@export_enum("Mail Room", "Finance","Human Resources","Opening Floor")
var floor: int
@export_enum("Mail Room", "Finance","Human Resources","Opening Floor")
var target_destination: int

func save():
	var save_dict = {
		#"filename" : get_scene_file_path(),ww
		"nodepath" : self.name,
		"levelpath" : get_scene_file_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"pos_z" : position.z,
	}
	return save_dict

func _ready():
	GameManager.register_world(self)
	await get_tree().create_timer(2.5).timeout
	#var RIGID_BODIES = find_children("", "RigidBody3D", true, true)
	#for rb in RIGID_BODIES:
		#rb.visible = false
		#rb.process_mode = Node.PROCESS_MODE_DISABLED
