extends Camera3D

@onready var world = $".."
@onready var player = $"../Player"
@onready var radio = $"../Radio"
func _ready():
	$"../AnimationPlayer".play("Scene")
	pass


func playerMovementEnable():
	EventBus.emitCustomSignal("disable_player_movement",[false,true])
	radio.stop_blinking()
	queue_free()


func disablePlayerMovement():
	EventBus.emitCustomSignal("disable_player_movement",[true,true])
	player.global_rotation = global_rotation
