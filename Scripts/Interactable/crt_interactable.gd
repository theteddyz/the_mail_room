extends Interactable

@export var video_player:VideoStreamPlayer 
@export var audio_player:AudioStreamPlayer3D

func interact():
	if !video_player.is_playing():
		video_player.play()
		audio_player.play()

func stop_video():
	video_player.stop()
	audio_player.stop()
