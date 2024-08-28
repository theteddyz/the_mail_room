extends Interactable
@onready var audio_player:AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var root = $".."

func interact():
	if !root.locked:
		audio_player.play(0.0)
		root.call_elevator()
	else:
		pass
	
