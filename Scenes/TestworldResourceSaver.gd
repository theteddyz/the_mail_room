extends Node3D
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
