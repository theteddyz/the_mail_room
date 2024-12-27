extends Node3D

func _ready():
	EventBus.emitCustomSignal("register_object",[self])
