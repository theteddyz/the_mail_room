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
		zone_Manager.respawn_rigid_bodies(zone_name,despawned_bodies)
		despawned_bodies = {}
		despawned = false



func _on_body_exited(body):
	despawn_rigid_bodies(zone_name)



func despawn_rigid_bodies(zone:String):
	if !despawned:
		despawned = true
		var desks = get_tree().get_nodes_in_group(zone)
		for desk in desks:
				var instance_id = desk.get_instance_id()
				despawned_bodies[instance_id] = {
					"scene_path": desk.scene_file_path,  # Use meta data for prefab path
					"position": desk.transform.origin,
					"rotation": desk.transform.basis.get_rotation_quaternion(),
					"parent":desk.get_parent(),
					"scale":desk.scale
				}
				desk.queue_free()
