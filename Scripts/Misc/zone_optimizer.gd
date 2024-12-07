extends Node3D


var rigid_body_data:Dictionary = {}
var cached_scenes: Dictionary = {}

var world
func _ready():
	world = get_parent()

func preload_scenes(despawned_bodies:Dictionary):
	for instance_id in despawned_bodies.keys():
		var scene_path = despawned_bodies[instance_id]["scene_path"]
		if not cached_scenes.has(scene_path):
			cached_scenes[scene_path] = load(scene_path)

func respawn_rigid_bodies(zone:String,despawned_bodies:Dictionary):
	var count = 0
	for instance_id in despawned_bodies.keys():
		var data = despawned_bodies[instance_id]
		var scene = load(data["scene_path"])
		if scene:
			var body = scene.instantiate()
			data["parent"].call_deferred("add_child", body)
			body.add_to_group(zone)
			for children in body.get_children(true):
				if children is RigidBody3D:
					children.freeze = true
					children.sleeping = true
					children.request_ready()
			var new_transform = Transform3D(
				Basis(data["rotation"]),
				data["position"]
			)
			body.transform = new_transform
			body.scale = data["scale"]
			rigid_body_data[body.get_instance_id()] = data
			count += 1
			if count % 1 == 0:
				await get_tree().process_frame
