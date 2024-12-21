extends VisibleOnScreenNotifier3D
@export var mesh_target:MeshInstance3D
@onready var ray_cast:RayCast3D = $RayCast3D
@onready var timer:Timer = $Timer
var parent_body:RigidBody3D
var player:CharacterBody3D
var distance_threshold:float = 10.0
var should_recheck:bool = false


func _setup():
	player = GameManager.get_player()
	timer.connect("timeout", Callable(self, "_check_occlusion"))
	parent_body = get_parent()
	var mesh_target = find_first_mesh(parent_body)
	

func find_first_mesh(node: Node):
	for child in node.get_children():
		if child is MeshInstance3D:
			mesh_target = child
			break

#func _process(delta):
	#if mesh_target:
		#if is_occluded():
			#mesh_target.visible = false
		#else:
			#mesh_target.visible = true

func check_distance_to_player()-> bool:
	if parent_body and player:
		var distance = parent_body.global_transform.origin.distance_to(player.global_transform.origin)
		if distance <= distance_threshold:
			return true
		else:
			return false
	return false

func _check_occlusion():
	if is_occluded():
		timer.start()
	else:
		should_recheck = false

func is_occluded() -> bool:
	if ray_cast:
		ray_cast.target_position = player.global_transform.origin
		ray_cast.target_position = player.global_transform.origin - global_transform.origin
		ray_cast.enabled = true
		if ray_cast.is_colliding():
			var collider = ray_cast.get_collider()
			if collider and collider != player and collider is StaticBody3D:
				return true
		return false
	return false
