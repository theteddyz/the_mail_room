extends Node3D
@export var floor_num:int
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
	#var timer = Timer.new()
	#add_child(timer)
	#timer.one_shot = false
	#timer.start(10)
	#timer.timeout.connect(func(): AudioController.play_spatial_resource(load("res://Assets/Audio/SoundFX/AmbientNeutral/VentilationRumble4.ogg")))
