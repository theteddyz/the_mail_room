extends Node3D

func save():
	var root = get_tree().root
	var save_dict = {
		"nodepath" : root.get_child(root.get_child_count() - 1).name + "/" + "Player/Neck/" + name,
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rotation.x" : rotation.x,
		#"state" : state.get_class(),
	}
	return save_dict
