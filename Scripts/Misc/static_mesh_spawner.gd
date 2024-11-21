extends MultiMeshInstance3D


func _ready():
	var walls = get_tree().get_nodes_in_group("multimesh")
	multimesh.instance_count = walls.size()
	multimesh.visible_instance_count = walls.size()
	for i in range(walls.size()):
		var wall = walls[i]
		var mesh_transform = wall.global_transform
		multimesh.set_instance_transform(i, mesh_transform)
		
