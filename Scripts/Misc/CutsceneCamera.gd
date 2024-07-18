extends Camera3D

@onready var world = $".."
@onready var player = $"../Player"
@onready var radio = $"../Radio"
@export var disable_cutScene:bool
func _ready():
	if !disable_cutScene:
		$"../AnimationPlayer".play("Scene")
	else:
		playerMovementEnable()
	pass


func playerMovementEnable():
	#EventBus.emitCustomSignal("disable_player_movement",[false,true])
	radio.stop_blinking()
	queue_free()


func disablePlayerMovement():
	#EventBus.emitCustomSignal("disable_player_movement",[true,true])
	if !disable_cutScene:
		player.global_rotation = global_rotation
