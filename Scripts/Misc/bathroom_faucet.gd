extends Area3D

@onready var sink_audio:AudioStreamPlayer3D = $"../AudioStreamPlayer3D"
func _on_body_entered(body):
	if body.name == "Player":
		sink_audio.play()




func _on_body_exited(body):
	if body.name == "Player":
		sink_audio.stop()
