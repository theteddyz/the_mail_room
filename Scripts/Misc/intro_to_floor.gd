extends Node3D
var wall_door_warning = preload("res://Assets/Audio/SoundFX/VoiceLines/ElevatorDoorWarning.ogg")
@onready var elevator = $"../../Elevator"
var radio
var mail_cart
func _on_area_3d_body_entered(body):
	if body.name == "Mailcart":
		mail_cart = true
	if radio == null:
		radio = GameManager.get_player_radio()
	if body.name == "Player" and mail_cart == true:
		elevator.close_doors(false)
		radio.play_narrator_sound(wall_door_warning)
		queue_free()
