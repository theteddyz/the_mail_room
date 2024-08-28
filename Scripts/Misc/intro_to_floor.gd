extends Node3D
var wall_door_warning = preload("res://Assets/Audio/SoundFX/VoiceLines/ElevatorDoorWarning.ogg")
@onready var elevator = $"../../Elevator"
var radio

func _on_area_3d_body_entered(body):
	if radio == null:
		radio = GameManager.get_player_radio()
	if body.name == "Player":
		await get_tree().create_timer(2.0).timeout
		elevator.close_doors()
		radio.play_narrator_sound(wall_door_warning)
		queue_free()
