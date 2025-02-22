extends Node
class_name cutscene

@export var cutscene_camera:Camera3D
func start_cutscene():
	cutscene_camera.make_current()
	EventBus.emitCustomSignal("disable_player_movement",[true,true])


func reset():
	var player_camera = GameManager.get_player_camera()
	player_camera.make_current()
	EventBus.emitCustomSignal("disable_player_movement",[false,false])
