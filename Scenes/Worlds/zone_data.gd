extends Node
@export var zone_name:String
var zone_Manager:Node3D
var despawned_bodies = {}
@export var despawn_on_start:bool
var despawned:bool = false
func _ready():
	zone_Manager = get_parent()
	if despawn_on_start:
		despawn_rigid_bodies(zone_name)
func _on_body_entered(body):
	if body.name == "Player" and despawned:
		zone_Manager._respawn_objects_on_new_thread(zone_name,despawned_bodies)
		despawned_bodies = {}
		despawned = false



func _on_body_exited(_body):
	despawn_rigid_bodies(zone_name)



func despawn_rigid_bodies(zone:String):
	if !despawned:
		despawned = true
		var objects = get_tree().get_nodes_in_group(zone)
		for object in objects:
			var should_despawn = true
			for rb in object.get_children(true):
				if rb is RigidBody3D:
					if rb.modified:
						object.remove_from_group(zone)
						should_despawn = false
						break
			if should_despawn:
				var instance_id = object.get_instance_id()
				despawned_bodies[instance_id] = {
					"scene_path": object.scene_file_path,  # Use meta data for prefab path
					"position": object.transform.origin,
					"rotation": object.transform.basis.get_rotation_quaternion(),
					"parent": object.get_parent(),
					"scale": object.scale
				}
				object.queue_free()
