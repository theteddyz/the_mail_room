@tool
extends MeshInstance3D
var video_player

func _ready():
	var sub = get_child(1)
	video_player = sub.get_child(0)
	video_player.play()
