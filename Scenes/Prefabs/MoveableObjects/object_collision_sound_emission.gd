extends Node3D
var rigidbody:RigidBody3D

@export var mult = 1
var previousVelocity:Vector3 = Vector3.ZERO
var previousRotation:Vector3 = Vector3.ZERO

@export var impact_audios: AudioStreamPlayer3D
@export var initVolume:float = 0
var target_node: Node = null


func _ready():
	rigidbody = get_parent()
	var root = get_tree().root
	target_node = root.get_child(root.get_child_count() - 1).find_child("cutter_ai")
	assert(target_node != null, "Target Node not assigned. Impact with this object and its soundevents wont work.")
	
func spawn_sound_event(volume):
	if !impact_audios.playing:
		impact_audios.volume_db = volume
		impact_audios.play()
		await target_node.state.on_hearing_sound() if target_node.state.has_method("on_hearing_sound") else null

func collide_with_player() -> void:
	spawn_sound_event(initVolume)
