extends Node3D


var rigid_body_data:Dictionary = {}
var cached_scenes: Dictionary = {}
var world
func _ready():
	world = get_parent()




func _respawn_objects_on_new_thread(zone:String,despawned_bodies:Dictionary):
	var thread:Thread
	thread = Thread.new()
	thread.start(respawn_rigid_bodies.bind(zone,despawned_bodies))
	

func respawn_rigid_bodies(zone:String,despawned_bodies:Dictionary):
	var count = 0
	for instance_id in despawned_bodies.keys():
		var data = despawned_bodies[instance_id]
		var scene = load(data["scene_path"])
		var object = instance_from_id(instance_id)
		if scene:
			object.visible = true
			object.process_mode = Node.PROCESS_MODE_INHERIT
			#object.visible = true
			#object.process_mode = Node.PROCESS_MODE_DISABLED
			#data["parent"].call_deferred("add_child", body)
			#body.call_deferred("add_to_group",zone)
			##for children in body.get_children(true):
				##children.call_deferred("request_ready")
			#var new_transform = Transform3D(
				#Basis(data["rotation"]),
				#data["position"]
			#)
			#body.transform = new_transform
			#body.scale = data["scale"]
			#rigid_body_data[body.get_instance_id()] = data
			#count += 1
			#if count == 1:
				#await get_tree().process_frame
				#await get_tree().process_frame
				#await get_tree().process_frame
				#count = 0
