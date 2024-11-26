extends Node3D
@export var monitor_on:bool = true



func _ready():
	if monitor_on == false:
		pass
		#var on = $GrabableObjectTemplate/ComputerOn
		#on.visible = false
		#var off = $GrabableObjectTemplate/ComputerOff
		#off.visible = true
