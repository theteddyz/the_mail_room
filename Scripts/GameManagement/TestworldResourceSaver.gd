extends Node3D
@export var floor_num:int
func save():
	var save_dict = {
		#"filename" : get_scene_file_path(),
		"nodepath" : self.name,
		"levelpath" : get_scene_file_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"pos_z" : position.z,
	}
	return save_dict
	
func _ready():
	const FIRST_FLOOR_AMBIENCE_4 = preload("res://Assets/Audio/SoundFX/FirstFloorAmbience4.mp3")
	const FIRST_FLOOR_AMBIENCE_3 = preload("res://Assets/Audio/SoundFX/FirstFloorAmbience3.mp3")
	const FIRST_FLOOR_AMBIENCE_2 = preload("res://Assets/Audio/SoundFX/FirstFloorAmbience2.mp3")
	AudioController.ambiences = [FIRST_FLOOR_AMBIENCE_4, FIRST_FLOOR_AMBIENCE_3, FIRST_FLOOR_AMBIENCE_2]
