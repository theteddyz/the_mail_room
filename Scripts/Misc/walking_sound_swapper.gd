extends RayCast3D
var current_floor_type
var carpet_sound_stream = preload("res://Scenes/Prefabs/AudioPlayers/carpet_footsteps.tres")
var bathroom_sound_stream = preload("res://Scenes/Prefabs/AudioPlayers/bathroom_footsteps.tres")
var mail_room_sound_stream = preload("res://Scenes/Prefabs/AudioPlayers/mail_room_footsteps.tres")
var elevator_sound_stream = preload("res://Scenes/Prefabs/AudioPlayers/elevator_footsteps.tres")
@onready var audio_player:AudioStreamPlayer3D = $"../SpatialAudioPlayer3d"
func _process(delta):
	get_floor_type()
func get_floor_type():
	if is_colliding() :
		var collider = get_collider()
		if collider:
			if current_floor_type == null:
				current_floor_type = collider.floor_type
				change_sound(current_floor_type)
			elif current_floor_type != collider.floor_type:
				current_floor_type = collider.floor_type
				change_sound(current_floor_type)
			


func change_sound(s:String):
	match s:
		"carpet":
			#AudioServer.set_bus_effect_enabled(1, 0,true)
			
			audio_player.stream = carpet_sound_stream
		"bathroom":
			#AudioServer.set_bus_effect_enabled(1, 0,false)
			audio_player.stream = bathroom_sound_stream
		"mail_room":
			#AudioServer.set_bus_effect_enabled(1, 0,false)
			audio_player.stream = mail_room_sound_stream
		"elevator":
			#AudioServer.set_bus_effect_enabled(1, 0,false)
			audio_player.stream = elevator_sound_stream
