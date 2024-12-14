extends Node3D


var rigid_body_data:Dictionary = {}
var cached_scenes: Dictionary = {}
var world
func _ready():
	world = get_parent()




func _respawn_objects_on_new_thread(zone:String,despawned_bodies:Dictionary):
	respawn_rigid_bodies(zone,despawned_bodies)
	

func respawn_rigid_bodies(zone:String,despawned_bodies:Dictionary):
	var count = 0
	for instance_id in despawned_bodies.keys():
		var data = despawned_bodies[instance_id]
		var scene = load(data["scene_path"])
		var object = instance_from_id(instance_id)
		if scene:
			object.visible = true
			if object is RigidBody3D:
				object.sleeping = true
			for rb in object.get_children():
				if rb is RigidBody3D:
					rb.sleeping = true
