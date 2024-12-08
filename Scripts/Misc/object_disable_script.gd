extends VisibleOnScreenNotifier3D
@export var mesh_target:MeshInstance3D
var parent_body:RigidBody3D
var player:CharacterBody3D
var distance_threshold:float = 20.0


func _setup():
	player = GameManager.get_player()
	parent_body = get_parent()
	#var mesh_target = find_first_mesh(parent_body)


func _on_screen_entered():
	if mesh_target:
		mesh_target.visible = true
		parent_body.freeze = false
	#if parent_body:
		#if check_distance_to_player():
			#parent_body.freeze = false
			#parent_body.sleeping = false
	

func find_first_mesh(node: Node):
	for child in node.get_children():
		if child is MeshInstance3D:
			mesh_target = child
			break


func _on_screen_exited():
	if mesh_target and !check_distance_to_player():
		pass
		mesh_target.visible = false
		mesh_target.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parent_body:
		if parent_body.linear_velocity == Vector3.ZERO :
			parent_body.freeze = true

func check_distance_to_player()-> bool:
	if parent_body and player:
		var distance = parent_body.global_transform.origin.distance_to(player.global_transform.origin)
		if distance <= distance_threshold:
			return true
		else:
			return false
	return false
