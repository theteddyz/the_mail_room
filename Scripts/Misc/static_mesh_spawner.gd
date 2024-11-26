extends MultiMeshInstance3D
@export_enum("base_wall","cubicle","base_wall_wood","small_wall","shelf","wall_with_door") var wall_type: String

func _ready():
	var walls = get_tree().get_nodes_in_group("multimesh")
	multimesh.instance_count = walls.size()
	multimesh.visible_instance_count = walls.size()
	for i in range(walls.size()):
		var wall = walls[i]
		if wall.wall_typed == wall_type:
			var mesh_transform = wall.global_transform
			multimesh.set_instance_transform(i, mesh_transform)
			var old_wall:MeshInstance3D = wall.get_child(0)
			old_wall.visible = false
			old_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
